/**
 * @class       WebhookHandlerSAV
 * @description REST endpoint for receiving Stripe webhooks.
 *              Exposed as a public Site.com page (no SF auth required).
 *              Validates Stripe-Signature HMAC before processing.
 *
 *              Endpoint URL: /services/apexrest/sav/webhook/stripe
 *
 *              Supported events:
 *                - payment_intent.succeeded
 *                - payment_intent.payment_failed
 *                - charge.refunded
 *                - charge.dispute.created
 *
 *              Idempotency: each webhook event is deduplicated by event ID
 *              stored in Webhook_Event_Log__c.
 *
 * @author      Salesforce Architect
 * @version     1.0
 */
@RestResource(urlMapping='/sav/webhook/stripe/*')
global without sharing class WebhookHandlerSAV {

    // Stripe signs webhooks with HMAC-SHA256
    private static final String STRIPE_SIG_HEADER = 'Stripe-Signature';
    private static final Integer WEBHOOK_TOLERANCE_SEC = 300; // 5 minutes

    // ─────────────────────────────────────────────────────────────
    // REST ENTRY POINT
    // ─────────────────────────────────────────────────────────────

    @HttpPost
    global static void handlePost() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        String payload   = req.requestBody?.toString();
        String sigHeader = req.headers?.get(STRIPE_SIG_HEADER);

        try {
            // 1. Validate signature
            validateStripeSignature(payload, sigHeader);

            // 2. Parse event
            StripeEvent event = parseEvent(payload);
            if (event == null) {
                sendResponse(res, 400, 'Could not parse event');
                return;
            }

            // 3. Idempotency check
            if (eventAlreadyProcessed(event.id)) {
                // Already handled — return 200 to prevent Stripe retry
                sendResponse(res, 200, 'Already processed');
                return;
            }

            // 4. Route to handler
            Boolean handled = routeEvent(event);

            // 5. Log the event
            logWebhookEvent(event, handled ? 'Processed' : 'Ignored');

            sendResponse(res, 200, 'OK');

        } catch (SignatureValidationException e) {
            System.debug(LoggingLevel.ERROR, 'Stripe signature invalid: ' + e.getMessage());
            sendResponse(res, 400, 'Invalid signature');

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'WebhookHandlerSAV error: ' + e.getMessage()
                + '\n' + e.getStackTraceString());
            // Return 200 to Stripe to prevent infinite retries for application errors
            // Log separately for investigation
            logWebhookError(payload, e.getMessage());
            sendResponse(res, 200, 'Accepted with error');
        }
    }

    // ─────────────────────────────────────────────────────────────
    // EVENT ROUTING
    // ─────────────────────────────────────────────────────────────

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
                // Unhandled event type — log and return 200
                return false;
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // EVENT HANDLERS
    // ─────────────────────────────────────────────────────────────

    private static void handlePaymentSucceeded(StripeEvent event) {
        String paymentIntentId = event.dataObjectId;
        String savId           = event.metadata?.get('sav_id');

        if (String.isBlank(savId)) {
            // Try to find SAV by PaymentIntent Id
            List<Demande_SAV__c> found = [
                SELECT Id, Statut_Paiement__c
                FROM   Demande_SAV__c
                WHERE  Payment_Intent_ID__c = :paymentIntentId
                LIMIT  1
            ];
            if (!found.isEmpty()) savId = found[0].Id;
        }

        if (String.isBlank(savId)) {
            throw new WebhookException('SAV Id not found for PaymentIntent: ' + paymentIntentId);
        }

        List<Demande_SAV__c> savList = [
            SELECT Id, Statut_Paiement__c
            FROM   Demande_SAV__c
            WHERE  Id = :savId
            LIMIT  1
        ];

        if (savList.isEmpty()) {
            throw new WebhookException('Demande_SAV__c not found: ' + savId);
        }

        // Idempotent: only update if not already paid
        if (savList[0].Statut_Paiement__c != 'Payé') {
            update new Demande_SAV__c(
                Id                    = savId,
                Statut_Paiement__c    = 'Payé',
                Payment_Intent_ID__c  = paymentIntentId
            );

            // Trigger invoice generation asynchronously
            InvoicePDFGenerator.generateAsync(savId);

            // Trigger confirmation notification
            NotificationDispatcher.dispatch(savId, 'Paiement_Confirme');
        }
    }

    private static void handlePaymentFailed(StripeEvent event) {
        String paymentIntentId = event.dataObjectId;
        String savId           = event.metadata?.get('sav_id');

        if (String.isBlank(savId)) {
            List<Demande_SAV__c> found = [
                SELECT Id FROM Demande_SAV__c
                WHERE  Payment_Intent_ID__c = :paymentIntentId LIMIT 1
            ];
            if (!found.isEmpty()) savId = found[0].Id;
        }

        if (String.isBlank(savId)) return; // Cannot match — skip

        update new Demande_SAV__c(
            Id                 = savId,
            Statut_Paiement__c = 'Echec_Paiement',
            Note_Interne__c    = 'Stripe payment failed. Event: ' + event.id
        );

        // Notify client to retry
        NotificationDispatcher.dispatch(savId, 'Paiement_Echoue');
    }

    private static void handleChargeRefunded(StripeEvent event) {
        String paymentIntentId = event.relatedPaymentIntentId;
        if (String.isBlank(paymentIntentId)) return;

        List<Demande_SAV__c> savList = [
            SELECT Id, Statut_Paiement__c
            FROM   Demande_SAV__c
            WHERE  Payment_Intent_ID__c = :paymentIntentId LIMIT 1
        ];

        if (!savList.isEmpty() && savList[0].Statut_Paiement__c == 'Payé') {
            update new Demande_SAV__c(
                Id                 = savList[0].Id,
                Statut_Paiement__c = 'Remboursé'
            );
        }
    }

    private static void handleDisputeCreated(StripeEvent event) {
        // Escalate to admin team via Case
        insert new Case(
            Subject     = 'Dispute Stripe: ' + event.dataObjectId,
            Description = 'Stripe dispute reçu.\nEvent ID: ' + event.id
                        + '\nType: ' + event.type,
            Priority    = 'High',
            Status      = 'New',
            Origin      = 'Web'
        );
    }

    // ─────────────────────────────────────────────────────────────
    // STRIPE SIGNATURE VALIDATION
    // ─────────────────────────────────────────────────────────────

    /**
     * Validates the Stripe-Signature header using HMAC-SHA256.
     * Format: t=<timestamp>,v1=<signature>[,v0=<old_signature>]
     *
     * Algorithm:
     *   1. Extract timestamp and signature from header
     *   2. Check timestamp is within tolerance
     *   3. Compute HMAC of (timestamp + '.' + payload) with webhook secret
     *   4. Compare with provided signature (constant-time)
     */
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
                if (kv[0].trim() == 't')  timestamp = Long.valueOf(kv[1].trim());
                if (kv[0].trim() == 'v1') v1Sig     = kv[1].trim();
            }
        }

        if (timestamp == null || String.isBlank(v1Sig)) {
            throw new SignatureValidationException('Malformed Stripe-Signature header');
        }

        // Replay attack protection
        Long nowSeconds = System.now().getTime() / 1000;
        if (Math.abs(nowSeconds - timestamp) > WEBHOOK_TOLERANCE_SEC) {
            throw new SignatureValidationException('Webhook timestamp out of tolerance');
        }

        // Retrieve webhook secret from Custom Metadata
        String secret = getWebhookSecret();

        // Compute expected signature: HMAC_SHA256(secret, timestamp + '.' + payload)
        String signedPayload = String.valueOf(timestamp) + '.' + payload;
        Blob   hmac = Crypto.generateMac(
            'HmacSHA256',
            Blob.valueOf(signedPayload),
            Blob.valueOf(secret)
        );
        String expectedSig = EncodingUtil.convertToHex(hmac);

        // Constant-time comparison to prevent timing attacks
        if (!constantTimeEquals(expectedSig, v1Sig)) {
            throw new SignatureValidationException('Signature mismatch');
        }
    }

    /**
     * Constant-time string comparison — avoids timing side-channel leaks.
     */
    private static Boolean constantTimeEquals(String a, String b) {
        if (a == null || b == null || a.length() != b.length()) return false;
        Integer diff = 0;
        for (Integer i = 0; i < a.length(); i++) {
            diff |= a.charAt(i) ^ b.charAt(i);
        }
        return diff == 0;
    }

    // ─────────────────────────────────────────────────────────────
    // EVENT PARSING
    // ─────────────────────────────────────────────────────────────

    private class StripeEvent {
        public String              id                     { get; set; }
        public String              type                   { get; set; }
        public String              dataObjectId           { get; set; }
        public Map<String, String> metadata               { get; set; }
        public String              relatedPaymentIntentId { get; set; }
    }

    private static StripeEvent parseEvent(String payload) {
        try {
            Map<String, Object> root =
                (Map<String, Object>) JSON.deserializeUntyped(payload);

            StripeEvent event = new StripeEvent();
            event.id   = (String) root.get('id');
            event.type = (String) root.get('type');

            Map<String, Object> data = (Map<String, Object>) root.get('data');
            Map<String, Object> obj  = (Map<String, Object>) data?.get('object');

            event.dataObjectId = (String) obj?.get('id');

            // Extract metadata (present on PaymentIntent events)
            Object metaRaw = obj?.get('metadata');
            if (metaRaw instanceof Map<String, Object>) {
                event.metadata = new Map<String, String>();
                for (String k : ((Map<String, Object>) metaRaw).keySet()) {
                    event.metadata.put(k,
                        String.valueOf(((Map<String, Object>) metaRaw).get(k)));
                }
            }

            // For charge events, extract linked payment_intent
            event.relatedPaymentIntentId = (String) obj?.get('payment_intent');

            return event;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Event parse error: ' + e.getMessage());
            return null;
        }
    }

    // ─────────────────────────────────────────────────────────────
    // IDEMPOTENCY & LOGGING
    // ─────────────────────────────────────────────────────────────

    private static Boolean eventAlreadyProcessed(String eventId) {
        if (String.isBlank(eventId)) return false;
        return [
            SELECT COUNT()
            FROM   Webhook_Event_Log__c
            WHERE  Event_ID__c = :eventId
            AND    Statut__c  = 'Processed'
        ] > 0;
    }

    private static void logWebhookEvent(StripeEvent event, String statut) {
        try {
            insert new Webhook_Event_Log__c(
                Event_ID__c  = event.id,
                Event_Type__c = event.type,
                Statut__c    = statut,
                Object_ID__c = event.dataObjectId,
                Received_At__c = System.now()
            );
        } catch (Exception e) {
            // DML in webhook logging — absorb silently to not block 200 response
            System.debug(LoggingLevel.WARN, 'Event log insert failed: ' + e.getMessage());
        }
    }

    private static void logWebhookError(String payload, String errorMsg) {
        try {
            insert new Webhook_Event_Log__c(
                Event_Type__c  = 'ERROR',
                Statut__c      = 'Failed',
                Error_Message__c = errorMsg,
                Raw_Payload__c  = payload?.left(32000), // LongText limit safety
                Received_At__c  = System.now()
            );
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error log insert failed: ' + e.getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────────────────────────

    private static String getWebhookSecret() {
        List<Portal_Config__mdt> configs = [
            SELECT Value__c FROM Portal_Config__mdt
            WHERE  DeveloperName = 'STRIPE_WEBHOOK_SECRET' LIMIT 1
        ];
        if (configs.isEmpty()) {
            throw new WebhookException('STRIPE_WEBHOOK_SECRET not configured');
        }
        return configs[0].Value__c;
    }

    private static void sendResponse(RestResponse res, Integer statusCode, String body) {
        res.statusCode = statusCode;
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf('{"status":"' + body + '"}');
    }

    // ─────────────────────────────────────────────────────────────
    // CUSTOM EXCEPTIONS
    // ─────────────────────────────────────────────────────────────

    public class SignatureValidationException extends Exception {}
    public class WebhookException extends Exception {}
}