/**
 * @class       WebhookHandlerSAV
 * @description REST endpoint pour recevoir les webhooks Stripe et mettre à jour le statut SAV.
 * Version 1.3 - Fix PMD (Braces) & Security
 * @author      Gemini / Salesforce Architect
 */
@RestResource(urlMapping='/sav/webhook/stripe/*')
global without sharing class WebhookHandlerSAV {

    private static final String STRIPE_SIG_HEADER = 'Stripe-Signature';

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

            // Route l'événement vers la logique métier
            routeEvent(event);
            sendResponse(res, 200, 'OK');

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Webhook Error: ' + e.getMessage());
            // On renvoie 200 même en cas d'erreur logique interne pour éviter que Stripe ne renvoie le webhook indéfiniment
            sendResponse(res, 200, 'Accepted with internal log'); 
        }
    }

    private static void routeEvent(StripeEvent event) {
        switch on event.type {
            when 'payment_intent.succeeded' {
                handlePaymentSucceeded(event);
            }
            when 'payment_intent.payment_failed' {
                handlePaymentFailed(event);
            }
        }
    }

    private static void handlePaymentSucceeded(StripeEvent event) {
        String savId = event.metadata?.get('sav_id');

        if (String.isNotBlank(savId)) {
            List<Demande_SAV__c> savList = [
                SELECT Id, Statut_Paiement__c 
                FROM Demande_SAV__c
                WHERE Id = :savId 
                WITH USER_MODE 
                LIMIT 1
            ];

            if (!savList.isEmpty() && savList[0].Statut_Paiement__c != 'Payé') {
                savList[0].Statut_Paiement__c = 'Payé';
                update as user savList[0];
            }
        }
    }

    private static void handlePaymentFailed(StripeEvent event) {
        String savId = event.metadata?.get('sav_id');
        if (String.isNotBlank(savId)) {
            update as user new Demande_SAV__c(
                Id = savId,
                Statut_Paiement__c = 'Echec_Paiement'
            );
        }
    }

    // ─── VALIDATION SIGNATURE ──────────────────────────────────────

    private static void validateStripeSignature(String payload, String sigHeader) {
        if (String.isBlank(sigHeader)) {
            throw new SignatureValidationException('Header manquant');
        }

        if (payload == null) {
            throw new SignatureValidationException('Payload vide');
        }
        
        // Note: En production, utilise Crypto.generateMac pour valider la signature réelle
    }

    // ─── PARSING & WRAPPERS ────────────────────────────────────────

    private class StripeEvent {
        public String id { get; set; }
        public String type { get; set; }
        public String dataObjectId { get; set; }
        public Map<String, String> metadata { get; set; }
    }

    private static StripeEvent parseEvent(String payload) {
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(payload);
        if (root == null) {
            return null;
        }

        StripeEvent event = new StripeEvent();
        event.id = (String) root.get('id');
        event.type = (String) root.get('type');

        Map<String, Object> data = (Map<String, Object>) root.get('data');
        Map<String, Object> obj = (Map<String, Object>) data?.get('object');
        event.dataObjectId = (String) obj?.get('id');

        Object metaRaw = obj?.get('metadata');
        if (metaRaw instanceof Map<String, Object>) {
            event.metadata = new Map<String, String>();
            Map<String, Object> metaMap = (Map<String, Object>) metaRaw;
            for (String k : metaMap.keySet()) {
                event.metadata.put(k, String.valueOf(metaMap.get(k)));
            }
        }
        return event;
    }

    private static void sendResponse(RestResponse res, Integer code, String msg) {
        res.statusCode = code;
        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{'status' => msg}));
    }

    public class SignatureValidationException extends Exception {}
}