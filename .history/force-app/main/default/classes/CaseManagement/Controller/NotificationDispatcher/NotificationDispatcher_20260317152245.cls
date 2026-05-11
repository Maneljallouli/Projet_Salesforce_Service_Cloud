/**
 * @class       NotificationDispatcher
 * @description Multi-channel notification engine for SAV status changes.
 * CRUD/FLS-safe with WITH USER_MODE, PMD-clean (Design & Security).
 */
public with sharing class NotificationDispatcher {

    // ─── CONTEXT WRAPPER (To fix ExcessiveParameterList) ───────────
    private class DispatchContext {
        public Demande_SAV__c sav;
        public Preference_Notification__c prefs;
        public SAV_Notification_Config__mdt config;
        public String langue;
        public NotificationResult result;

        public DispatchContext(Demande_SAV__c s, Preference_Notification__c p, SAV_Notification_Config__mdt c, NotificationResult res) {
            this.sav = s;
            this.prefs = p;
            this.config = c;
            this.langue = s.Langue_Client__c ?? 'fr';
            this.result = res;
        }
    }

    // ─── INNER CLASSES ─────────────────────────────────────────────
    public class NotificationRequest {
        @InvocableVariable(label='SAV Record Id' required=true)
        public Id savId;
        @InvocableVariable(label='Ancien Statut')
        public String ancienStatut;
        @InvocableVariable(label='Nouveau Statut' required=true)
        public String nouveauStatut;
    }

    public class NotificationResult {
        @InvocableVariable(label='Email envoyé')  public Boolean emailSent = false;
        @InvocableVariable(label='SMS envoyé')    public Boolean smsSent = false;
        @InvocableVariable(label='Push envoyé')   public Boolean pushSent = false;
        @InvocableVariable(label='Erreur message') public String  errorMessage;
    }

    // ─── INVOCABLE ENTRY POINT ─────────────────────────────────────
    @InvocableMethod(label='Dispatch SAV Notification' description='Sends email, SMS, and push notification')
    public static List<NotificationResult> dispatchFromFlow(List<NotificationRequest> requests) {
        Set<Id> savIds = new Set<Id>();
        for (NotificationRequest req : requests) {
            if (req.savId != null) {
                savIds.add(req.savId);
            }
        }

        Map<Id, Demande_SAV__c> savMap = buildSavMap(savIds);
        Map<Id, Preference_Notification__c> prefsMap = buildPrefsMap(savMap);
        Map<String, SAV_Notification_Config__mdt> configMap = buildConfigMap();

        List<NotificationResult> results = new List<NotificationResult>();
        for (NotificationRequest req : requests) {
            results.add(processSingleRequest(req, savMap, prefsMap, configMap));
        }
        return results;
    }

    private static NotificationResult processSingleRequest(
        NotificationRequest req, 
        Map<Id, Demande_SAV__c> savMap, 
        Map<Id, Preference_Notification__c> prefsMap, 
        Map<String, SAV_Notification_Config__mdt> configMap
    ) {
        NotificationResult res = new NotificationResult();
        try {
            Demande_SAV__c sav = savMap.get(req.savId);
            SAV_Notification_Config__mdt config = configMap.get(req.nouveauStatut);

            if (sav == null) {
                res.errorMessage = 'SAV record not found: ' + req.savId;
                return res;
            }
            if (config == null) {
                return res;
            }

            // Encapsulation des paramètres dans le contexte
            DispatchContext ctx = new DispatchContext(sav, prefsMap.get(sav.Contact__c), config, res);

            handleEmail(ctx);
            handleSms(ctx);
            handlePush(ctx);

        } catch (Exception e) {
            res.errorMessage = e.getMessage();
        }
        return res;
    }

    // ─── DISPATCH HANDLERS (Now with 1 single parameter) ───────────

    private static void handleEmail(DispatchContext ctx) {
        if (ctx.prefs?.Email_SAV__c == true && String.isNotBlank(ctx.config.Email_Template_API__c)) {
            sendEmail(ctx.sav, ctx.config.Email_Template_API__c);
            ctx.result.emailSent = true;
        }
    }

    private static void handleSms(DispatchContext ctx) {
        if (ctx.prefs?.SMS_SAV__c == true && String.isNotBlank(ctx.prefs.Telephone_SMS__c)) {
            String template = (ctx.langue == 'en') ? ctx.config.SMS_Template_EN__c : ctx.config.SMS_Template_FR__c;
            if (String.isNotBlank(template)) {
                sendSms(ctx.prefs.Telephone_SMS__c, mergeSmsTemplate(template, ctx.sav));
                ctx.result.smsSent = true;
            }
        }
    }

    private static void handlePush(DispatchContext ctx) {
        if (ctx.config.Envoyer_Push__c == true) {
            sendPushNotification(ctx.sav, ctx.langue);
            ctx.result.pushSent = true;
        }
    }

    // ─── CORE NOTIFICATION LOGIC ───────────────────────────────────

    private static void sendEmail(Demande_SAV__c sav, String templateApiName) {
        List<EmailTemplate> templates = [
            SELECT Id FROM EmailTemplate 
            WHERE DeveloperName = :templateApiName 
            WITH USER_MODE LIMIT 1
        ];
        
        if (templates.isEmpty()) {
            throw new NotificationException('Template missing: ' + templateApiName);
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(sav.Contact__c);
        mail.setWhatId(sav.Id);
        mail.setTemplateId(templates[0].Id);
        mail.setSaveAsActivity(false);
        mail.setTreatTargetObjectAsRecipient(true);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail }, false);
    }

    private static void sendSms(String toPhone, String body) {
        String fromPhone = getConfig('TWILIO_FROM_NUMBER');
        String accountSid = getConfig('TWILIO_ACCOUNT_SID');

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:NC_Twilio/2010-04-01/Accounts/' + accountSid + '/Messages.json');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('To=' + EncodingUtil.urlEncode(toPhone, 'UTF-8') +
                    '&From=' + EncodingUtil.urlEncode(fromPhone, 'UTF-8') +
                    '&Body=' + EncodingUtil.urlEncode(body, 'UTF-8'));

        new Http().send(req);
    }

    private static void sendPushNotification(Demande_SAV__c sav, String langue) {
        List<CustomNotificationType> notifTypes = [
            SELECT Id FROM CustomNotificationType 
            WHERE DeveloperName = 'SAV_Status_Update' 
            WITH USER_MODE LIMIT 1
        ];
        
        if (notifTypes.isEmpty()) { return; }

        Messaging.CustomNotification notif = new Messaging.CustomNotification();
        notif.setNotificationTypeId(notifTypes[0].Id);
        notif.setTitle(sav.Produit_Client__r?.Nom_Produit__c ?? 'SAV Update');
        notif.setBody((langue == 'en') ? 'Update on your repair' : 'Mise à jour de votre réparation');
        notif.setTargetId(sav.Id);
        notif.send(new Set<String>{ sav.Contact__c });
    }

    // ─── BULK HELPERS ──────────────────────────────────────────────

    private static Map<Id, Demande_SAV__c> buildSavMap(Set<Id> savIds) {
        Map<Id, Demande_SAV__c> result = new Map<Id, Demande_SAV__c>();
        if (savIds.isEmpty()) { return result; }
        for (Demande_SAV__c sav : [
            SELECT Id, Name, Statut__c, Contact__c, Contact__r.FirstName, 
                   Langue_Client__c, Montant_Final__c, Produit_Client__r.Nom_Produit__c
            FROM Demande_SAV__c WHERE Id IN :savIds WITH USER_MODE
        ]) {
            result.put(sav.Id, sav);
        }
        return result;
    }

    private static Map<Id, Preference_Notification__c> buildPrefsMap(Map<Id, Demande_SAV__c> savMap) {
        Set<Id> contactIds = new Set<Id>();
        for (Demande_SAV__c sav : savMap.values()) {
            if (sav.Contact__c != null) { contactIds.add(sav.Contact__c); }
        }
        
        Map<Id, Preference_Notification__c> result = new Map<Id, Preference_Notification__c>();
        if (contactIds.isEmpty()) { return result; }
        
        for (Preference_Notification__c p : [
            SELECT Contact__c, Email_SAV__c, SMS_SAV__c, Telephone_SMS__c
            FROM Preference_Notification__c WHERE Contact__c IN :contactIds WITH USER_MODE
        ]) {
            result.put(p.Contact__c, p);
        }
        return result;
    }

    private static Map<String, SAV_Notification_Config__mdt> buildConfigMap() {
        Map<String, SAV_Notification_Config__mdt> result = new Map<String, SAV_Notification_Config__mdt>();
        for (SAV_Notification_Config__mdt cfg : [
            SELECT Statut__c, Email_Template_API__c, SMS_Template_FR__c, SMS_Template_EN__c, Envoyer_Push__c
            FROM SAV_Notification_Config__mdt WITH USER_MODE
        ]) {
            result.put(cfg.Statut__c, cfg);
        }
        return result;
    }

    private static String getConfig(String key) {
        List<Portal_Config__mdt> configs = [
            SELECT Value__c FROM Portal_Config__mdt 
            WHERE DeveloperName = :key WITH USER_MODE LIMIT 1
        ];
        if (configs.isEmpty()) { throw new NotificationException('Config missing: ' + key); }
        return configs[0].Value__c;
    }

    private static String mergeSmsTemplate(String template, Demande_SAV__c sav) {
        return template
            .replace('{prenom}', sav.Contact__r?.FirstName ?? '')
            .replace('{numero}', sav.Name ?? '');
    }

    public class NotificationException extends Exception {}
}