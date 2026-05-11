/**
 * @class       WebhookHandlerSAV
 * @description REST endpoint for receiving Stripe webhooks.
 * Exposed as a public Site.com page (no SF auth required).
 * Validates Stripe-Signature HMAC before processing.
 *
 * Endpoint URL: /services/apexrest/sav/webhook/stripe
 *
 * @author      Salesforce Architect
 * @version     1.1
 */
@RestResource(urlMapping='/sav/webhook/stripe/*')
global without sharing class WebhookHandlerSAV {

    private static final String STRIPE_SIG_HEADER = 'Stripe-Signature';
    private static final Integer WEBHOOK_TOLERANCE_SEC = 300; 

    @HttpPost
    global static void handlePost() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        String payload   = req.requestBody?.toString();
        String sigHeader = req.headers?.get(STRIPE_SIG_HEADER);

        try {
            validateStripeSignature(payload, sigHeader);

            StripeEvent event = parseEvent(payload);
            if (event == null) {
                sendResponse(res, 400, 'Could not parse event');
                return;
            }

            if (eventAlreadyProcessed(event.id)) {
                sendResponse(res, 200, 'Already processed');
                return;
            }

            Boolean handled = routeEvent(event);
            logWebhookEvent(event, handled ? 'Processed' : 'Ignored');

            sendResponse(res, 200, 'OK');

        } catch (SignatureValidationException e) {
            System.debug(LoggingLevel.ERROR, 'Stripe signature invalid: ' + e.getMessage());
            sendResponse(res, 400, 'Invalid signature');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'WebhookHandlerSAV error: ' + e.getMessage());
            logWebhookError(payload, e.getMessage());
            sendResponse(res, 200, 'Accepted with error');
        }
    }

    private static Boolean routeEvent(StripeEvent event) {
        switch on event.type {
            when 'payment_intent.succeeded' {
                handlePaymentSucceeded(event);
                return true;
            }
            when 'payment_intent.payment_failed' {
                handlePaymentFailed(event);
                return true;
            }
            when 'charge.refunded' {
                handleChargeRefunded(event);
                return true;
            }
            when 'charge.dispute.created' {
                handleDisputeCreated(event);
                return true;
            }
            when else {
                return false;
            }
        }
    }

    private static void handlePaymentSucceeded(StripeEvent event) {
        String paymentIntentId = event.dataObjectId;
        String savId           = event.metadata?.get('sav_id');

        if (String.isBlank(savId)) {
            List<Demande_SAV__c> found = [
                SELECT Id, Statut_Paiement__c
                FROM   Demande_SAV__c
                WHERE  Payment_Intent_ID__c = :paymentIntentId
                WITH   USER_MODE
                LIMIT  1
            ];
            if (!found.isEmpty()) { 
                savId = found[0].Id; 
            }
        }

        if (String.isBlank(savId)) {
            throw new WebhookException('SAV Id not found for PaymentIntent: ' + paymentIntentId);
        }

        List<Demande_SAV__c> savList = [
            SELECT Id, Statut_Paiement__c
            FROM   Demande_SAV__c
            WHERE  Id = :savId
            WITH   USER_MODE
            LIMIT  1
        ];

        if (savList.isEmpty()) {
            throw new WebhookException('Demande_SAV__c not found: ' + savId);
        }

        if (savList[0].Statut_Paiement__c != 'Payé') {
            Demande_SAV__c toUpdate = new Demande_SAV__c(
                Id                    = savId,
                Statut_Paiement__c    = 'Payé',
                Payment_Intent_ID__c  = paymentIntentId
            );
            update as user toUpdate;

            InvoicePDFGenerator.generateAsync(savId);
            NotificationDispatcher.dispatch(savId, 'Paiement_Confirme');
        }
    }

    private static void handlePaymentFailed(StripeEvent event) {
        String paymentIntentId = event.dataObjectId;
        String savId           = event.metadata?.get('sav_id');

        if (String.isBlank(savId)) {
            List<Demande_SAV__c> found = [
                SELECT Id FROM Demande_SAV__c
                WHERE  Payment_Intent_ID__c = :paymentIntentId 
                WITH USER_MODE
                LIMIT 1
            ];
            if (!found.isEmpty()) {
                savId = found[0].Id;
            }
        }

        if (String.isBlank(savId)) {
            return;
        }

        Demande_SAV__c toUpdate = new Demande_SAV__c(
            Id                 = savId,
            Statut_Paiement__c = 'Echec_Paiement',
            Note_Interne__c    = 'Stripe payment failed. Event: ' + event.id
        );
        update as user toUpdate;

        NotificationDispatcher.dispatch(savId, 'Paiement_Echoue');
    }

    private static void handleChargeRefunded(StripeEvent event) {
        String paymentIntentId = event.relatedPaymentIntentId;
        if (String.isBlank(paymentIntentId)) {
            return;
        }

        List<Demande_SAV__c> savList = [
            SELECT Id, Statut_Paiement__c
            FROM   Demande_SAV__c
            WHERE  Payment_Intent_ID__c = :paymentIntentId 
            WITH   USER_MODE
            LIMIT  1
        ];

        if (!savList.isEmpty() && savList[0].Statut_Paiement__c == 'Payé') {
            Demande_SAV__c toUpdate = new Demande_SAV__c(
                Id                 = savList[0].Id,
                Statut_Paiement__c = 'Remboursé'
            );
            update as user toUpdate;
        }
    }

    private static void handleDisputeCreated(StripeEvent event) {
        Case c = new Case(
            Subject     = 'Dispute Stripe: ' + event.dataObjectId,
            Description = 'Stripe dispute reçu.\nEvent ID: ' + event.id + '\nType: ' + event.type,
            Priority    = 'High',
            Status      = 'New',
            Origin      = 'Web'
        );
        insert as user c;
    }

    @TestVisible
    private static void validateStripeSignature(String payload, String sigHeader) {
        if (String.isBlank(sigHeader)) {
            throw new SignatureValidationException('Missing Stripe-Signature header');
        }

        Long   timestamp  = null;
        String v1Sig      = null;

        for (String part : sigHeader.split(',')) {
            List<String> kv = part.split('=', 2);
            if (kv.size() == 2) {
                if (kv[0].trim() == 't') { timestamp = Long.valueOf(kv[1].trim()); }
                if (kv[0].trim() == 'v1') { v1Sig     = kv[1].trim(); }
            }
        }

        if (timestamp == null || String.isBlank(v1Sig)) {
            throw new SignatureValidationException('Malformed Stripe-Signature header');
        }

        Long nowSeconds = System.now().getTime() / 1000;
        if (Math.abs(nowSeconds - timestamp) > WEBHOOK_TOLERANCE_SEC) {
            throw new SignatureValidationException('Webhook timestamp out of tolerance');
        }

        String secret = getWebhookSecret();
        String signedPayload = String.valueOf(timestamp) + '.' + payload;
        Blob   hmac = Crypto.generateMac(
            'HmacSHA256',
            Blob.valueOf(signedPayload),
            Blob.valueOf(secret)
        );
        String expectedSig = EncodingUtil.convertToHex(hmac);

        if (!constantTimeEquals(expectedSig, v1Sig)) {
            throw new SignatureValidationException('Signature mismatch');
        }
    }

    private static Boolean constantTimeEquals(String a, String b) {
        if (a == null || b == null || a.length() != b.length()) {
            return false;
        }
        Integer diff = 0;
        for (Integer i = 0; i < a.length(); i++) {
            diff |= a.charAt(i) ^ b.charAt(i);
        }
        return diff == 0;
    }

    private class StripeEvent {
        public String               id                     { get; set; }
        public String               type                   { get; set; }
        public String               dataObjectId           { get; set; }
        public Map<String, String> metadata               { get; set; }
        public String               relatedPaymentIntentId { get; set; }
    }

    private static StripeEvent parseEvent(String payload) {
        try {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(payload);
            StripeEvent event = new StripeEvent();
            event.id   = (String) root.get('id');
            event.type = (String) root.get('type');

            Map<String, Object> data = (Map<String, Object>) root.get('data');
            Map<String, Object> obj  = (Map<String, Object>) data?.get('object');
            event.dataObjectId = (String) obj?.get('id');

            Object metaRaw = obj?.get('metadata');
            if (metaRaw instanceof Map<String, Object>) {
                event.metadata = new Map<String, String>();
                for (String k : ((Map<String, Object>) metaRaw).keySet()) {
                    event.metadata.put(k, String.valueOf(((Map<String, Object>) metaRaw).get(k)));
                }
            }
            event.relatedPaymentIntentId = (String) obj?.get('payment_intent');
            return event;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Event parse error: ' + e.getMessage());
            return null;
        }
    }

    private static Boolean eventAlreadyProcessed(String eventId) {
        if (String.isBlank(eventId)) {
            return false;
        }
        return [
            SELECT COUNT()
            FROM   Webhook_Event_Log__c
            WHERE  Event_ID__c = :eventId
            AND    Statut__c  = 'Processed'
            WITH   USER_MODE
        ] > 0;
    }

    private static void logWebhookEvent(StripeEvent event, String statut) {
        try {
            Webhook_Event_Log__c log = new Webhook_Event_Log__c(
                Event_ID__c   = event.id,
                Event_Type__c = event.type,
                Statut__c     = statut,
                Object_ID__c  = event.dataObjectId,
                Received_At__c = System.now()
            );
            insert as user log;
        } catch (Exception e) {
            System.debug('Logging error: ' + e.getMessage());
        }
    }

    private static String getWebhookSecret() {
        List<Portal_Config__mdt> configs = [
            SELECT Value__c FROM Portal_Config__mdt 
            WHERE DeveloperName = 'Stripe_Webhook_Secret'
            WITH USER_MODE
            LIMIT 1
        ];
        if (configs.isEmpty()) {
            throw new WebhookException('Stripe Webhook Secret not configured');
        }
        return configs[0].Value__c;
    }

    private static void logWebhookError(String payload, String error) {
        try {
            Webhook_Event_Log__c log = new Webhook_Event_Log__c(
                Statut__c     = 'Error',
                Error_Log__c  = error,
                Received_At__c = System.now()
            );
            insert as user log;
        } catch (Exception ex) {
            System.debug('Fatal logging error: ' + ex.getMessage());
        }
    }

    private static void sendResponse(RestResponse res, Integer code, String msg) {
        res.statusCode = code;
        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{'message' => msg}));
    }

    public class SignatureValidationException extends Exception {}
    public class WebhookException extends Exception {}
}