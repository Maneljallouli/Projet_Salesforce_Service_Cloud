/**
 * @class       PaymentController
 * @description AuraEnabled controller for payment processing via Stripe.
 *              Creates PaymentIntents server-side, confirms payments,
 *              and exposes methods for the LWC luxePaymentModal component.
 *
 *              Named Credential required: NC_Stripe
 *                URL: https://api.stripe.com
 *                Auth: Password (username = 'Bearer', password = sk_live_xxx)
 *                OR:   Per-User Named Credential with org-level secret
 *
 *              All amounts in minor units (centimes for EUR).
 *              Client secret is returned to LWC — Stripe.js handles
 *              3DS/SCA on the browser side.
 *
 * @author      Salesforce Architect
 * @version     1.0
 */
public with sharing class PaymentController {

    private static final String STRIPE_API_VERSION = '2024-06-20';
    private static final Integer HTTP_TIMEOUT_MS    = 15000;

    // ─────────────────────────────────────────────────────────────
    // INNER CLASSES
    // ─────────────────────────────────────────────────────────────

    public class PaymentIntentResult {
        @AuraEnabled public String  clientSecret    { get; set; }
        @AuraEnabled public String  paymentIntentId { get; set; }
        @AuraEnabled public Integer amount          { get; set; }
        @AuraEnabled public String  currency        { get; set; }
    }

    public class PaymentConfirmInput {
        @AuraEnabled public Id     savId           { get; set; }
        @AuraEnabled public String paymentIntentId { get; set; }
        @AuraEnabled public String status          { get; set; }
    }

    // ─────────────────────────────────────────────────────────────
    // CREATE PAYMENT INTENT
    // ─────────────────────────────────────────────────────────────

    /**
     * Creates a Stripe PaymentIntent for a given SAV devis.
     * Amount is derived from Montant_Final__c on the record — NOT from the client.
     * @param savId     Demande_SAV__c Id
     * @param currency  ISO 4217 currency code (e.g. 'EUR')
     * @return          PaymentIntentResult with clientSecret for Stripe.js
     */
    @AuraEnabled
    public static PaymentIntentResult createPaymentIntent(Id savId, String currency) {

        // 1. Ownership + status validation
        Id contactId = ContactUtils.getCurrentContactId();

        List<Demande_SAV__c> records = [
            SELECT  Id, Name, Montant_Final__c, Statut__c,
                    Statut_Paiement__c,
                    Contact__c, Contact__r.Email,
                    Contact__r.FirstName, Contact__r.LastName,
                    Produit_Client__r.Nom_Produit__c
            FROM    Demande_SAV__c
            WHERE   Id          = :savId
            AND     Contact__c  = :contactId
            WITH    SECURITY_ENFORCED
            LIMIT   1
        ];

        if (records.isEmpty()) {
            throw new AuraHandledException(Label.Payment_Error_NotFound);
        }

        Demande_SAV__c sav = records[0];

        if (sav.Statut_Paiement__c == 'Payé') {
            throw new AuraHandledException(Label.Payment_Error_AlreadyPaid);
        }
        if (sav.Statut__c != 'Devis_Approuve') {
            throw new AuraHandledException(Label.Payment_Error_InvalidStatus);
        }
        if (sav.Montant_Final__c == null || sav.Montant_Final__c <= 0) {
            throw new AuraHandledException(Label.Payment_Error_InvalidAmount);
        }

        // 2. Convert to minor units (Decimal → Integer centimes)
        Integer amountMinor = (sav.Montant_Final__c * 100).intValue();
        String  safeCurrency = (String.isBlank(currency) ? 'EUR' : currency).toLowerCase();

        // 3. Build Stripe request body
        Map<String, Object> bodyParams = new Map<String, Object>{
            'amount'        => amountMinor,
            'currency'      => safeCurrency,
            'description'   => 'SAV Réparation ' + sav.Name
                               + ' - ' + sav.Produit_Client__r.Nom_Produit__c,
            'receipt_email' => sav.Contact__r.Email,
            'metadata[sav_id]'          => String.valueOf(sav.Id),
            'metadata[sav_number]'      => sav.Name,
            'metadata[contact_email]'   => sav.Contact__r.Email,
            'metadata[salesforce_org]'  => UserInfo.getOrganizationId()
        };

        // 4. Call Stripe API
        HttpResponse res = stripePost('/v1/payment_intents', bodyParams);

        Map<String, Object> intent =
            (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        if (res.getStatusCode() != 200) {
            Map<String, Object> errorObj = (Map<String, Object>) intent.get('error');
            String msg = errorObj != null
                ? (String) errorObj.get('message') : 'Unknown Stripe error';
            throw new AuraHandledException('Stripe: ' + msg);
        }

        // 5. Cache the PaymentIntent Id on the SAV record
        update new Demande_SAV__c(
            Id                    = savId,
            Payment_Intent_ID__c  = (String) intent.get('id')
        );

        PaymentIntentResult result = new PaymentIntentResult();
        result.clientSecret    = (String)  intent.get('client_secret');
        result.paymentIntentId = (String)  intent.get('id');
        result.amount          = amountMinor;
        result.currency        = safeCurrency;
        return result;
    }

    // ─────────────────────────────────────────────────────────────
    // CONFIRM PAYMENT (called after Stripe.js confirms)
    // ─────────────────────────────────────────────────────────────

    /**
     * Confirms payment after Stripe.js completes on the client.
     * Verifies PaymentIntent status directly with Stripe API (do not trust client).
     * Updates Demande_SAV__c and triggers invoice generation.
     */
    @AuraEnabled
    public static void confirmPayment(PaymentConfirmInput input) {
        if (input == null || input.savId == null) {
            throw new AuraHandledException(Label.Payment_Error_InvalidInput);
        }

        Id contactId = ContactUtils.getCurrentContactId();

        // 1. Reload SAV — verify ownership + matching PaymentIntent Id
        List<Demande_SAV__c> records = [
            SELECT  Id, Statut_Paiement__c, Payment_Intent_ID__c, Contact__c
            FROM    Demande_SAV__c
            WHERE   Id         = :input.savId
            AND     Contact__c = :contactId
            WITH    SECURITY_ENFORCED
            LIMIT   1
        ];

        if (records.isEmpty()) {
            throw new AuraHandledException(Label.Payment_Error_NotFound);
        }
        Demande_SAV__c sav = records[0];

        if (sav.Statut_Paiement__c == 'Payé') {
            return; // Idempotent — already processed (webhook may have arrived first)
        }

        // 2. Verify PaymentIntent with Stripe (server-to-server — cannot trust client status)
        if (String.isBlank(sav.Payment_Intent_ID__c)) {
            throw new AuraHandledException(Label.Payment_Error_NoIntent);
        }

        HttpResponse verifyRes = stripeGet(
            '/v1/payment_intents/' + sav.Payment_Intent_ID__c);

        Map<String, Object> verifiedIntent =
            (Map<String, Object>) JSON.deserializeUntyped(verifyRes.getBody());

        String verifiedStatus = (String) verifiedIntent.get('status');

        if (verifiedStatus != 'succeeded') {
            throw new AuraHandledException(
                Label.Payment_Error_NotSucceeded + ' (' + verifiedStatus + ')');
        }

        // 3. Update SAV
        update new Demande_SAV__c(
            Id                    = input.savId,
            Statut_Paiement__c    = 'Payé',
            Payment_Intent_ID__c  = sav.Payment_Intent_ID__c
        );

        // 4. Async invoice generation
        InvoicePDFGenerator.generateAsync(input.savId);
    }

    // ─────────────────────────────────────────────────────────────
    // REFUND (internal use / admin)
    // ─────────────────────────────────────────────────────────────

    /**
     * Initiates a full refund via Stripe.
     * Requires admin permission — not exposed to portal users.
     */
    public static void refundPayment(Id savId) {
        PermissionUtils.requirePermission('SAV_Admin');

        List<Demande_SAV__c> records = [
            SELECT Id, Statut_Paiement__c, Payment_Intent_ID__c, Montant_Final__c
            FROM   Demande_SAV__c
            WHERE  Id = :savId WITH SECURITY_ENFORCED LIMIT 1
        ];

        if (records.isEmpty()) throw new PaymentException('SAV not found');
        Demande_SAV__c sav = records[0];

        if (sav.Statut_Paiement__c != 'Payé') {
            throw new PaymentException('Cannot refund: payment status is '
                + sav.Statut_Paiement__c);
        }

        Map<String, Object> refundParams = new Map<String, Object>{
            'payment_intent' => sav.Payment_Intent_ID__c,
            'reason'         => 'requested_by_customer'
        };

        HttpResponse res = stripePost('/v1/refunds', refundParams);
        if (res.getStatusCode() != 200) {
            throw new PaymentException('Stripe refund failed: ' + res.getBody());
        }

        update new Demande_SAV__c(
            Id                 = savId,
            Statut_Paiement__c = 'Remboursé'
        );
    }

    // ─────────────────────────────────────────────────────────────
    // HTTP HELPERS
    // ─────────────────────────────────────────────────────────────

    private static HttpResponse stripePost(
            String path, Map<String, Object> params) {
        HttpRequest req = buildStripeRequest(path, 'POST');
        req.setBody(encodeFormBody(params));
        return executeRequest(req);
    }

    private static HttpResponse stripeGet(String path) {
        HttpRequest req = buildStripeRequest(path, 'GET');
        return executeRequest(req);
    }

    private static HttpRequest buildStripeRequest(String path, String method) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:NC_Stripe' + path);
        req.setMethod(method);
        req.setHeader('Stripe-Version', STRIPE_API_VERSION);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setTimeout(HTTP_TIMEOUT_MS);
        return req;
    }

    private static HttpResponse executeRequest(HttpRequest req) {
        HttpResponse res = new Http().send(req);
        // Log for audit
        System.debug(LoggingLevel.INFO,
            'Stripe ' + req.getMethod() + ' ' + req.getEndpoint()
            + ' → ' + res.getStatusCode());
        return res;
    }

    /**
     * URL-encodes a flat or 1-level nested Map to application/x-www-form-urlencoded.
     * Handles metadata[key]=value pattern required by Stripe API.
     */
    private static String encodeFormBody(Map<String, Object> params) {
        List<String> parts = new List<String>();
        for (String k : params.keySet()) {
            Object v = params.get(k);
            if (v != null) {
                parts.add(
                    EncodingUtil.urlEncode(k, 'UTF-8')
                    + '='
                    + EncodingUtil.urlEncode(String.valueOf(v), 'UTF-8')
                );
            }
        }
        return String.join(parts, '&');
    }

    // ─────────────────────────────────────────────────────────────
    // CUSTOM EXCEPTION
    // ─────────────────────────────────────────────────────────────

    public class PaymentException extends Exception {}
}