public with sharing class NotificationDispatcher {

    // ─────────────────────────────
    // DTOs
    // ─────────────────────────────
    public class NotificationRequest {
        @InvocableVariable(required=true)
        public Id savId;

        @InvocableVariable
        public String ancienStatut;

        @InvocableVariable(required=true)
        public String nouveauStatut;
    }

    public class NotificationResult {
        @InvocableVariable public Boolean emailSent;
        @InvocableVariable public Boolean smsSent;
        @InvocableVariable public Boolean pushSent;
        @InvocableVariable public String errorMessage;
    }

    // Wrapper pour réduire paramètres
    private class DispatchContext {
        public Case c;
        public Preference_Notification__c prefs;
        public SAV_Notification_Config__mdt conf;
        public String langue;
        public Id caseId;
    }

    // ─────────────────────────────
    // ENTRY POINT
    // ─────────────────────────────
    @InvocableMethod
    public static List<NotificationResult> dispatchFromFlow(List<NotificationRequest> requests) {

        Map<Id, Case> caseMap = CaseService.loadCases(requests);
        Map<Id, Preference_Notification__c> prefsMap = PrefService.loadPrefs(caseMap);
        Map<String, SAV_Notification_Config__mdt> configMap = ConfigService.loadConfigs();

        List<NotificationResult> results = new List<NotificationResult>();

        for (NotificationRequest req : requests) {
            results.add(processRequest(req, caseMap, prefsMap, configMap));
        }

        return results;
    }

    // ─────────────────────────────
    // CORE PROCESS (SIMPLIFIED)
    // ─────────────────────────────
    private static NotificationResult processRequest(
        NotificationRequest req,
        Map<Id, Case> caseMap,
        Map<Id, Preference_Notification__c> prefsMap,
        Map<String, SAV_Notification_Config__mdt> configMap
    ) {
        NotificationResult result = initResult();

        try {
            DispatchContext ctx = buildContext(req, caseMap, prefsMap, configMap);

            if (ctx == null) {
                result.errorMessage = 'Invalid context';
                return result;
            }

            sendAllChannels(ctx, result);

        } catch (Exception e) {
            result.errorMessage = e.getMessage();
        }

        return result;
    }

    private static NotificationResult initResult() {
        NotificationResult r = new NotificationResult();
        r.emailSent = false;
        r.smsSent = false;
        r.pushSent = false;
        return r;
    }

    // ─────────────────────────────
    // CONTEXT BUILDER
    // ─────────────────────────────
    private static DispatchContext buildContext(
        NotificationRequest req,
        Map<Id, Case> caseMap,
        Map<Id, Preference_Notification__c> prefsMap,
        Map<String, SAV_Notification_Config__mdt> configMap
    ) {
        Case c = caseMap.get(req.savId);
        if (c == null) return null;

        DispatchContext ctx = new DispatchContext();
        ctx.c = c;
        ctx.caseId = req.savId;
        ctx.prefs = prefsMap.get(c.ContactId);
        ctx.conf = configMap.get(req.nouveauStatut);
        ctx.langue = resolveLangue(c);

        return ctx.conf == null ? null : ctx;
    }

    // ─────────────────────────────
    // CHANNEL DISPATCH
    // ─────────────────────────────
    private static void sendAllChannels(DispatchContext ctx, NotificationResult result) {

        result.emailSent = EmailService.send(ctx);
        result.smsSent   = SmsService.send(ctx);
        result.pushSent  = PushService.send(ctx);
    }

    // ─────────────────────────────
    // EMAIL SERVICE
    // ─────────────────────────────
    private class EmailService {
        static Boolean send(DispatchContext ctx) {
            if (ctx.prefs?.Email_SAV__c != true) return false;
            if (String.isBlank(ctx.conf.Email_Template_API__c)) return false;

            try {
                if (!Schema.sObjectType.EmailTemplate.isAccessible()) return false;

                EmailTemplate tpl = [
                    SELECT Id FROM EmailTemplate
                    WHERE DeveloperName = :ctx.conf.Email_Template_API__c
                    LIMIT 1
                ];

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setTargetObjectId(ctx.c.ContactId);
                mail.setWhatId(ctx.c.Id);
                mail.setTemplateId(tpl.Id);

                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
                return true;

            } catch (Exception e) {
                System.debug(e.getMessage());
                return false;
            }
        }
    }

    // ─────────────────────────────
    // SMS SERVICE
    // ─────────────────────────────
    private class SmsService {
        static Boolean send(DispatchContext ctx) {

            if (ctx.prefs?.SMS_SAV__c != true) return false;
            if (String.isBlank(ctx.prefs.Telephone_SMS__c)) return false;

            String tpl = ctx.langue == 'en'
                ? ctx.conf.SMS_Template_EN__c
                : ctx.conf.SMS_Template_FR__c;

            if (String.isBlank(tpl)) return false;

            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:NC_Twilio');
                req.setMethod('POST');

                new Http().send(req);
                return true;

            } catch (Exception e) {
                System.debug(e.getMessage());
                return false;
            }
        }
    }

    // ─────────────────────────────
    // PUSH SERVICE
    // ─────────────────────────────
    private class PushService {
        static Boolean send(DispatchContext ctx) {

            if (ctx.conf.Envoyer_Push__c != true) return false;

            try {
                Messaging.CustomNotification notif = new Messaging.CustomNotification();
                notif.setTitle('Update');
                notif.setBody('Status changed');
                notif.setTargetId(ctx.c.Id);
                notif.send(new Set<String>{ String.valueOf(ctx.c.ContactId) });

                return true;

            } catch (Exception e) {
                System.debug(e.getMessage());
                return false;
            }
        }
    }

    // ─────────────────────────────
    // SERVICES (DATA)
    // ─────────────────────────────
    private class CaseService {
        static Map<Id, Case> loadCases(List<NotificationRequest> reqs) {
            Set<Id> ids = new Set<Id>();
            for (NotificationRequest r : reqs) {
                if (r.savId != null) ids.add(r.savId);
            }

            return new Map<Id, Case>([
                SELECT Id, Status, Subject, ContactId
                FROM Case WHERE Id IN :ids
            ]);
        }
    }

    private class PrefService {
        static Map<Id, Preference_Notification__c> loadPrefs(Map<Id, Case> cases) {

            Set<Id> contactIds = new Set<Id>();
            for (Case c : cases.values()) {
                if (c.ContactId != null) contactIds.add(c.ContactId);
            }

            return new Map<Id, Preference_Notification__c>([
                SELECT Contact__c, Email_SAV__c, SMS_SAV__c, Telephone_SMS__c
                FROM Preference_Notification__c
                WHERE Contact__c IN :contactIds
            ]);
        }
    }

    private class ConfigService {
        static Map<String, SAV_Notification_Config__mdt> loadConfigs() {

            Map<String, SAV_Notification_Config__mdt> mapCfg = new Map<String, SAV_Notification_Config__mdt>();

            for (SAV_Notification_Config__mdt c : [
                SELECT Status_Case__c, Email_Template_API__c,
                       SMS_Template_FR__c, SMS_Template_EN__c,
                       Envoyer_Push__c
                FROM SAV_Notification_Config__mdt
            ]) {
                mapCfg.put(c.Status_Case__c, c);
            }

            return mapCfg;
        }
    }

    // ─────────────────────────────
    // HELPERS
    // ─────────────────────────────
    private static String resolveLangue(Case c) {
        return 'fr';
    }
}