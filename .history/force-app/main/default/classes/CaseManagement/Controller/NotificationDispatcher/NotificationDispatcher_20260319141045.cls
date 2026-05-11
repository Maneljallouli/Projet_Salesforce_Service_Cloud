public with sharing class NotificationDispatcher {

    // ================================
    // WRAPPER CONTEXT (fix param list)
    // ================================
    private class DispatchContext {
        public Case c;
        public Preference_Notification__c prefs;
        public SAV_Notification_Config__mdt conf;
        public String langue;
        public Id caseId;
    }

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

    @InvocableMethod
    public static List<NotificationResult> dispatchFromFlow(List<NotificationRequest> requests) {

        Set<Id> caseIds = new Set<Id>();
        for (NotificationRequest r : requests) {
            if (r.savId != null) {
                caseIds.add(r.savId);
            }
        }

        Map<Id, Case> caseMap = buildCaseMap(caseIds);
        Map<Id, Preference_Notification__c> prefsMap = buildPrefsMap(caseMap);
        Map<String, SAV_Notification_Config__mdt> configMap = buildConfigMap();

        List<NotificationResult> results = new List<NotificationResult>();

        for (NotificationRequest req : requests) {

            NotificationResult res = new NotificationResult();
            initResult(res);

            try {
                DispatchContext ctx = buildContext(req, caseMap, prefsMap, configMap);

                if (ctx == null) {
                    res.errorMessage = 'Invalid context';
                } else {
                    processNotifications(ctx, res);
                }

            } catch (Exception e) {
                res.errorMessage = e.getMessage();
                System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            }

            results.add(res);
        }

        return results;
    }

    // ================================
    // CORE LOGIC (split → reduce complexity)
    // ================================
    private static void processNotifications(DispatchContext ctx, NotificationResult res) {

        if (canSendEmail(ctx)) {
            res.emailSent = trySendEmail(ctx);
        }

        if (canSendSms(ctx)) {
            res.smsSent = trySendSms(ctx);
        }

        if (canSendPush(ctx)) {
            res.pushSent = trySendPush(ctx);
        }
    }

    // ================================
    // CONDITIONS
    // ================================
    private static Boolean canSendEmail(DispatchContext ctx) {
        return ctx.prefs != null
            && ctx.prefs.Email_SAV__c
            && String.isNotBlank(ctx.conf.Email_Template_API__c);
    }

    private static Boolean canSendSms(DispatchContext ctx) {
        return ctx.prefs != null
            && ctx.prefs.SMS_SAV__c
            && String.isNotBlank(ctx.prefs.Telephone_SMS__c);
    }

    private static Boolean canSendPush(DispatchContext ctx) {
        return ctx.conf != null && ctx.conf.Envoyer_Push__c;
    }

    // ================================
    // EMAIL
    // ================================
    private static Boolean trySendEmail(DispatchContext ctx) {
        try {
            sendEmail(ctx.c, ctx.conf.Email_Template_API__c);
            return true;
        } catch (Exception e) {
            logError('EMAIL', ctx.caseId, e);
            return false;
        }
    }

    private static void sendEmail(Case c, String templateApiName) {

        if (!Schema.sObjectType.EmailTemplate.isAccessible()) {
            throw new NotificationException('No access to EmailTemplate');
        }

        List<EmailTemplate> templates = [
            SELECT Id FROM EmailTemplate
            WHERE DeveloperName = :templateApiName LIMIT 1
        ];

        if (templates.isEmpty()) {
            throw new NotificationException('Template not found');
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(c.ContactId);
        mail.setTemplateId(templates[0].Id);
        mail.setWhatId(c.Id);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
    }

    // ================================
    // SMS
    // ================================
    private static Boolean trySendSms(DispatchContext ctx) {
        try {
            String tpl = ctx.langue == 'en'
                ? ctx.conf.SMS_Template_EN__c
                : ctx.conf.SMS_Template_FR__c;

            String body = mergeSmsTemplate(tpl, ctx.c);

            sendSms(ctx.prefs.Telephone_SMS__c, body);
            return true;

        } catch (Exception e) {
            logError('SMS', ctx.caseId, e);
            return false;
        }
    }

    private static void sendSms(String toPhone, String body) {

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:NC_Twilio');
        req.setMethod('POST');
        req.setBody(body);

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() >= 300) {
            throw new NotificationException('SMS failed');
        }
    }

    // ================================
    // PUSH
    // ================================
    private static Boolean trySendPush(DispatchContext ctx) {
        try {
            sendPush(ctx.c, ctx.langue);
            return true;
        } catch (Exception e) {
            logError('PUSH', ctx.caseId, e);
            return false;
        }
    }

    private static void sendPush(Case c, String langue) {

        if (!Schema.sObjectType.CustomNotificationType.isAccessible()) {
            return;
        }

        List<CustomNotificationType> types = [
            SELECT Id FROM CustomNotificationType
            LIMIT 1
        ];

        if (types.isEmpty()) {
            return;
        }

        Messaging.CustomNotification notif = new Messaging.CustomNotification();
        notif.setNotificationTypeId(types[0].Id);
        notif.setTitle('Case update');
        notif.setBody('Status: ' + c.Status);
        notif.setTargetId(c.Id);

        notif.send(new Set<String>{ String.valueOf(c.ContactId) });
    }

    // ================================
    // HELPERS
    // ================================
    private static DispatchContext buildContext(
        NotificationRequest req,
        Map<Id, Case> caseMap,
        Map<Id, Preference_Notification__c> prefsMap,
        Map<String, SAV_Notification_Config__mdt> configMap
    ) {
        Case c = caseMap.get(req.savId);

        if (c == null) {
            return null;
        }

        DispatchContext ctx = new DispatchContext();
        ctx.c = c;
        ctx.caseId = c.Id;
        ctx.prefs = prefsMap.get(c.ContactId);
        ctx.conf = configMap.get(req.nouveauStatut);
        ctx.langue = resolveLangue(c);

        return ctx;
    }

    private static void initResult(NotificationResult r) {
        r.emailSent = false;
        r.smsSent = false;
        r.pushSent = false;
    }

    private static void logError(String type, Id caseId, Exception e) {
        System.debug(LoggingLevel.ERROR,
            type + ' ERROR Case ' + caseId + ' : ' + e.getMessage());
    }

    private static String mergeSmsTemplate(String template, Case c) {
        if (template == null) {
            return '';
        }

        return template.replace('{numero}', c.CaseNumber);
    }

    private static String resolveLangue(Case c) {
        try {
            String lang = (String)c.get('Langue_Client__c');
            if (lang != null) {
                return lang;
            }
        } catch (Exception e) {
            System.debug('Lang field missing');
        }
        return 'fr';
    }

    // ================================
    // DATA LAYER
    // ================================
    private static Map<Id, Case> buildCaseMap(Set<Id> ids) {

        Map<Id, Case> result = new Map<Id, Case>();

        if (!Schema.sObjectType.Case.isAccessible()) {
            return result;
        }

        for (Case c : [
            SELECT Id, Status, ContactId, CaseNumber
            FROM Case
            WHERE Id IN :ids
        ]) {
            result.put(c.Id, c);
        }

        return result;
    }

    private static Map<Id, Preference_Notification__c> buildPrefsMap(Map<Id, Case> caseMap) {

        Map<Id, Preference_Notification__c> res = new Map<Id, Preference_Notification__c>();

        if (!Schema.sObjectType.Preference_Notification__c.isAccessible()) {
            return res;
        }

        for (Preference_Notification__c p : [
            SELECT Contact__c, Email_SAV__c, SMS_SAV__c, Telephone_SMS__c
            FROM Preference_Notification__c
        ]) {
            res.put(p.Contact__c, p);
        }

        return res;
    }

    private static Map<String, SAV_Notification_Config__mdt> buildConfigMap() {

        Map<String, SAV_Notification_Config__mdt> res = new Map<String, SAV_Notification_Config__mdt>();

        for (SAV_Notification_Config__mdt c : [
            SELECT Status_Case__c, Email_Template_API__c,
                   SMS_Template_FR__c, SMS_Template_EN__c, Envoyer_Push__c
            FROM SAV_Notification_Config__mdt
        ]) {
            res.put(c.Status_Case__c, c);
        }

        return res;
    }

    public class NotificationException extends Exception {}
}