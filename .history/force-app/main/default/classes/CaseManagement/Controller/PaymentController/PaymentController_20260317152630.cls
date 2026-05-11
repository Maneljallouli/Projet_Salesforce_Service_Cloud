/**
 * @class       PaymentController
 * @description AuraEnabled controller for payment processing via Stripe.
 * Fixed: ApexCRUDViolation with USER_MODE and CodeStyle braces.
 *
 * @author      Salesforce Architect
 * @version     1.1
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
        @AuraEnabled public Id      savId           { get; set; }
        @AuraEnabled public String paymentIntentId { get; set; }
        @AuraEnabled public String status          { get; set; }
    }

    // ─────────────────────────────────────────────────────────────
    // CREATE PAYMENT INTENT
    // ─────────────────────────────────────────────────────────────

    @AuraEnabled
    public static PaymentIntentResult createPaymentIntent(Id savId, String currency) {

        Id contactId = ContactUtils.getCurrentContactId();

        // Fix: switched to USER_MODE for SOQL
        List<Demande_SAV__c> records = [
            SELECT  Id, Name, Montant_Final__c, Statut__c,
                    Statut_Paiement__c,
                    Contact__c, Contact__r.Email,
                    Contact__r.FirstName, Contact__r.LastName,
                    Produit_Client__r.Nom_Produit__c
            FROM    Demande_SAV__c
            WHERE   Id          = :savId
            AND     Contact__c  = :contactId
            WITH    USER_MODE
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

        Integer amountMinor = (sav.Montant_Final__c * 100).intValue();
        String  safeCurrency = (String.isBlank(currency) ? 'EUR' : currency).toLowerCase();

        Map<String, Object> bodyParams = new Map<String, Object>{
            'amount'        => amountMinor,
            'currency'      => safeCurrency,
            'description'   => 'SAV Réparation ' + sav.Name + ' - ' + sav.Produit_Client__r.Nom_Produit__c,
            'receipt_email' => sav.Contact__r.Email,
            'metadata[sav_id]'          => String.valueOf(sav.Id),
            'metadata[sav_number]'      => sav.Name,
            'metadata[contact_email]'   => sav.Contact__r.Email,
            'metadata[salesforce_org]'  => UserInfo.getOrganizationId()
        };

        HttpResponse res = stripePost('/v1/payment_intents', bodyParams);
        Map<String, Object> intent = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

        if (res.getStatusCode() != 200) {
            Map<String, Object> errorObj = (Map<String, Object>) intent.get('error');
            String msg = errorObj != null ? (String) errorObj.get('message') : 'Unknown Stripe error';
            throw new AuraHandledException('Stripe: ' + msg);
        }

        // Fix: Added AS USER_MODE for DML (Ligne 118)
        Demande_SAV__c toUpdate = new Demande_SAV__c(
            Id                    = savId,
            Payment_Intent_ID__c  = (String) intent.get('id')
        );
        update as user toUpdate;

        PaymentIntentResult result = new PaymentIntentResult();
        result.clientSecret    = (String)  intent.get('client_secret');
        result.paymentIntentId = (String)  intent.get('id');
        result.amount          = amountMinor;
        result.currency        = safeCurrency;
        return result;
    }

    // ─────────────────────────────────────────────────────────────
    // CONFIRM PAYMENT
    // ─────────────────────────────────────────────────────────────

    @AuraEnabled
    public static void confirmPayment(PaymentConfirmInput input) {
        if (input == null || input.savId == null) {
            throw new AuraHandledException(Label.Payment_Error_InvalidInput);
        }

        Id contactId = ContactUtils.getCurrentContactId();

        List<Demande_SAV__c> records = [
            SELECT  Id, Statut_Paiement__c, Payment_Intent_ID__c, Contact__c
            FROM    Demande_SAV__c
            WHERE   Id         = :input.savId
            AND     Contact__c = :contactId
            WITH    USER_MODE
            LIMIT   1
        ];

        if (records.isEmpty()) {
            throw new AuraHandledException(Label.Payment_Error_NotFound);
        }
        Demande_SAV__c sav = records[0];

        if (sav.Statut_Paiement__c == 'Payé') {
            return; 
        }

        if (String.isBlank(sav.Payment_Intent_ID__c)) {
            throw new AuraHandledException(Label.Payment_Error_NoIntent);
        }

        HttpResponse verifyRes = stripeGet('/v1/payment_intents/' + sav.Payment_Intent_ID__c);
        Map<String, Object> verifiedIntent = (Map<String, Object>) JSON.deserializeUntyped(verifyRes.getBody());
        String verifiedStatus = (String) verifiedIntent.get('status');

        if (verifiedStatus != 'succeeded') {
            throw new AuraHandledException(Label.Payment_Error_NotSucceeded + ' (' + verifiedStatus + ')');
        }

        // Fix: Added AS USER_MODE for DML (Ligne 186)
        Demande_SAV__c updateSav = new Demande_SAV__c(
            Id                    = input.savId,
            Statut_Paiement__c    = 'Payé',
            Payment_Intent_ID__c  = sav.Payment_Intent_ID__c
        );
        update as user updateSav;

        InvoicePDFGenerator.generateAsync(input.savId);
    }

    // ─────────────────────────────────────────────────────────────
    // REFUND
    // ─────────────────────────────────────────────────────────────

    public static void refundPayment(Id savId) {
        PermissionUtils.requirePermission('SAV_Admin');

        List<Demande_SAV__c> records = [
            SELECT Id, Statut_Paiement__c, Payment_Intent_ID__c, Montant_Final__c
            FROM   Demande_SAV__c
            WHERE  Id = :savId WITH USER_MODE LIMIT 1
        ];

        // Fix: Code Style - Braces (Ligne 213)
        if (records.isEmpty()) {
            throw new PaymentException('SAV not found');
        }
        
        Demande_SAV__c sav = records[0];

        if (sav.Statut_Paiement__c != 'Payé') {
            throw new PaymentException('Cannot refund: payment status is ' + sav.Statut_Paiement__c);
        }

        Map<String, Object> refundParams = new Map<String, Object>{
            'payment_intent' => sav.Payment_Intent_ID__c,
            'reason'         => 'requested_by_customer'
        };

        HttpResponse res = stripePost('/v1/refunds', refundParams);
        if (res.getStatusCode() != 200) {
            throw new PaymentException('Stripe refund failed: ' + res.getBody());
        }

        // Fix: Added AS USER_MODE for DML (Ligne 231)
        Demande_SAV__c refundSav = new Demande_SAV__c(
            Id                 = savId,
            Statut_Paiement__c = 'Remboursé'
        );
        update as user refundSav;
    }

    // ─────────────────────────────────────────────────────────────
    // HTTP HELPERS & PRIVATE METHODS
    // ─────────────────────────────────────────────────────────────

    private static HttpResponse stripePost(String path, Map<String, Object> params) {
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
        return new Http().send(req);
    }

    private static String encodeFormBody(Map<String, Object> params) {
        List<String> parts = new List<String>();
        for (String k : params.keySet()) {
            Object v = params.get(k);
            if (v != null) {
                parts.add(EncodingUtil.urlEncode(k, 'UTF-8') + '=' + EncodingUtil.urlEncode(String.valueOf(v), 'UTF-8'));
            }
        }
        return String.join(parts, '&');
    }

    public class PaymentException extends Exception {}
}