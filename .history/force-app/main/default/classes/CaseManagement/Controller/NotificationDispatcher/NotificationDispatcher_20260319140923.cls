public with sharing class NotificationDispatcher {

    // ─────────────────────────────────────────────────────────────
    // INNER CLASSES
    // ─────────────────────────────────────────────────────────────

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
        @InvocableVariable public String  errorMessage;
    }

    // ─────────────────────────────────────────────────────────────
    // ENTRY POINT
    // ─────────────────────────────────────────────────────────────

    @InvocableMethod
    public static List<NotificationResult> dispatchFromFlow(List<NotificationRequest> requests) {

        Map<Id, Case> caseMap = buildCaseMap(extractIds(requests));
        Map<Id, Preference_Notification__c> prefsMap = buildPrefsMap(caseMap);
        Map<String, SAV_Notification_Config__mdt> configMap = buildConfigMap();

        List<NotificationResult> results = new List<NotificationResult>();

        for (NotificationRequest req : requests) {
            results.add(processSingleRequest(req, caseMap, prefsMap, configMap));
        }

        return results;
    }

    // ─────────────────────────────────────────────────────────────
    // CORE LOGIC (LOW COMPLEXITY)
    // ─────────────────────────────────────────────────────────────

    private static NotificationResult processSingleRequest(
        NotificationRequest req,
        Map<Id, Case> caseMap,
        Map<Id, Preference_Notification__c> prefsMap,
        Map<String, SAV_Notification_Config__mdt> configMap
    ) {
        NotificationResult result = initResult();

        try {
            Case c = caseMap.get(req.savId);
            if (c == null) {
                return error(result, 'Case not found');
            }

            SAV_Notification_Config__mdt conf = configMap.get(req.nouveauStatut);
            if (conf == null) {
                return result;
            }

            Preference_Notification__c prefs = prefsMap.get(c.ContactId);
            String langue = resolveLangue(c);

            handleEmail(result, c, prefs, conf);
            handleSms(result, c, prefs, conf, langue);
            handlePush(result, c, conf, langue);

        } catch (Exception e) {
            result.errorMessage = e.getMessage();
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }

        return result;
    }

    private static NotificationResult initResult() {
        NotificationResult r = new NotificationResult();
        r.emailSent = false;
        r.smsSent   = false;
        r.pushSent  = false;
        return r;
    }

    private static NotificationResult error(NotificationResult r, String msg) {
        r.errorMessage = msg;
        return r;
    }

    // ─────────────────────────────────────────────────────────────
    // CHANNEL HANDLERS
    // ─────────────────────────────────────────────────────────────

    private static void handleEmail(NotificationResult r, Case c,
        Preference_Notification__c prefs,
        SAV_Notification_Config__mdt conf) {

        if (prefs?.Email_SAV__c == true &&
            String.isNotBlank(conf.Email_Template_API__c)) {

            r.emailSent = trySendEmail(c, conf.Email_Template_API__c);
        }
    }

    private static void handleSms(NotificationResult r, Case c,
        Preference_Notification__c prefs,
        SAV_Notification_Config__mdt conf,
        String langue) {

        if (prefs?.SMS_SAV__c == true &&
            String.isNotBlank(prefs.Telephone_SMS__c)) {

            String tpl = langue == 'en'
                ? conf.SMS_Template_EN__c
                : conf.SMS_Template_FR__c;

            if (String.isNotBlank(tpl)) {
                r.smsSent = trySendSms(
                    prefs.Telephone_SMS__c,
                    mergeSmsTemplate(tpl, c)
                );
            }
        }
    }

    private static void handlePush(NotificationResult r, Case c,
        SAV_Notification_Config__mdt conf,
        String langue) {

        if (conf.Envoyer_Push__c == true) {
            r.pushSent = trySendPush(c, langue);
        }
    }

    // ─────────────────────────────────────────────────────────────
    // EMAIL
    // ─────────────────────────────────────────────────────────────

    private static Boolean trySendEmail(Case c, String templateName) {
        try {
            if (!Schema.sObjectType.EmailTemplate.isAccessible()) return false;

            EmailTemplate tpl = [
                SELECT Id FROM EmailTemplate
                WHERE DeveloperName = :templateName LIMIT 1
            ];

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(c.ContactId);
            mail.setTemplateId(tpl.Id);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
            return true;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            return false;
        }
    }

    // ─────────────────────────────────────────────────────────────
    // SMS
    // ─────────────────────────────────────────────────────────────

    private static Boolean trySendSms(String phone, String body) {
        try {
            sendSms(phone, body);
            return true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            return false;
        }
    }

    private static void sendSms(String phone, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:NC_Twilio');
        req.setMethod('POST');
        req.setBody(body);
        new Http().send(req);
    }

    // ─────────────────────────────────────────────────────────────
    // PUSH
    // ─────────────────────────────────────────────────────────────

    private static Boolean trySendPush(Case c, String lang) {
        try {
            Messaging.CustomNotification notif = new Messaging.CustomNotification();
            notif.setTitle('Update');
            notif.setBody(formatStatus(c.Status));
            notif.setTargetId(c.Id);
            notif.send(new Set<String>{String.valueOf(c.ContactId)});
            return true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            return false;
        }
    }

    // ─────────────────────────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────────────────────────

    private static Set<Id> extractIds(List<NotificationRequest> reqs) {
        Set<Id> ids = new Set<Id>();
        for (NotificationRequest r : reqs) {
            if (r.savId != null) ids.add(r.savId);
        }
        return ids;
    }

    private static Map<Id, Case> buildCaseMap(Set<Id> ids) {
        Map<Id, Case> mapCases = new Map<Id, Case>();
        if (ids.isEmpty()) return mapCases;

        if (!Schema.sObjectType.Case.isAccessible()) return mapCases;

        for (Case c : [
            SELECT Id, Status, Subject, ContactId
            FROM Case WHERE Id IN :ids
        ]) {
            mapCases.put(c.Id, c);
        }
        return mapCases;
    }

    private static Map<Id, Preference_Notification__c> buildPrefsMap(Map<Id, Case> cases) {
        Map<Id, Preference_Notification__c> mapPrefs = new Map<Id, Preference_Notification__c>();

        Set<Id> contactIds = new Set<Id>();
        for (Case c : cases.values()) {
            if (c.ContactId != null) contactIds.add(c.ContactId);
        }

        if (!Schema.sObjectType.Preference_Notification__c.isAccessible()) return mapPrefs;

        for (Preference_Notification__c p : [
            SELECT Contact__c, Email_SAV__c, SMS_SAV__c, Telephone_SMS__c
            FROM Preference_Notification__c
            WHERE Contact__c IN :contactIds
        ]) {
            mapPrefs.put(p.Contact__c, p);
        }

        return mapPrefs;
    }

    private static Map<String, SAV_Notification_Config__mdt> buildConfigMap() {
        Map<String, SAV_Notification_Config__mdt> mapCfg = new Map<String, SAV_Notification_Config__mdt>();

        for (SAV_Notification_Config__mdt c : [
            SELECT Status_Case__c, Email_Template_API__c,
                   SMS_Template_FR__c, SMS_Template_EN__c, Envoyer_Push__c
            FROM SAV_Notification_Config__mdt
        ]) {
            mapCfg.put(c.Status_Case__c, c);
        }
        return mapCfg;
    }

    private static String resolveLangue(Case c) {
        try {
            return (String)c.get('Langue_Client__c');
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, e.getMessage());
            return 'fr';
        }
    }

    private static String mergeSmsTemplate(String tpl, Case c) {
        return tpl.replace('{sujet}', c.Subject);
    }

    private static String formatStatus(String status) {
        return status == null ? '' : status;
    }

    public class NotificationException extends Exception {}
}