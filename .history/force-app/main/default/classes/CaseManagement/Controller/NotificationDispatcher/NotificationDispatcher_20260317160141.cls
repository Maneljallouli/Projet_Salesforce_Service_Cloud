/**
 * @class       NotificationDispatcher
 * @description Moteur de notification multi-canal pour les changements de statut SAV.
 * Correction : Suppression des champs inexistants sur SAV_Notification_Config__mdt.
 */
public with sharing class NotificationDispatcher {

    // ─── RESOURCE WRAPPERS ──────────────────────────────────────────
    
    private class NotificationResources {
        public Map<Id, Demande_SAV__c> savMap;
        public Map<Id, Preference_Notification__c> prefsMap;
        public Map<String, SAV_Notification_Config__mdt> configMap;
    }

    private class DispatchContext {
        public Demande_SAV__c sav;
        public Preference_Notification__c prefs;
        public SAV_Notification_Config__mdt config;
        public String langue;
        public NotificationResult result;
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
        @InvocableVariable(label='Email envoyé')   public Boolean emailSent = false;
        @InvocableVariable(label='SMS envoyé')     public Boolean smsSent = false;
        @InvocableVariable(label='Push envoyé')    public Boolean pushSent = false;
        @InvocableVariable(label='Erreur message') public String  errorMessage;
    }

    // ─── INVOCABLE ENTRY POINT ─────────────────────────────────────

    @InvocableMethod(label='Dispatch SAV Notification' description='Envoie des notifications basées sur le statut')
    public static List<NotificationResult> dispatchFromFlow(List<NotificationRequest> requests) {
        Set<Id> savIds = new Set<Id>();
        for (NotificationRequest req : requests) {
            if (req.savId != null) {
                savIds.add(req.savId);
            }
        }

        NotificationResources resources = new NotificationResources();
        resources.savMap = buildSavMap(savIds);
        resources.prefsMap = buildPrefsMap(resources.savMap);
        resources.configMap = buildConfigMap();

        List<NotificationResult> results = new List<NotificationResult>();
        for (NotificationRequest req : requests) {
            results.add(processSingleRequest(req, resources));
        }
        return results;
    }

    private static NotificationResult processSingleRequest(NotificationRequest req, NotificationResources res) {
        NotificationResult result = new NotificationResult();
        try {
            Demande_SAV__c currentSav = res.savMap.get(req.savId);
            if (currentSav == null) {
                result.errorMessage = 'Enregistrement SAV introuvable';
                return result;
            }

            DispatchContext ctx = new DispatchContext();
            ctx.sav = currentSav;
            ctx.config = res.configMap.get(req.nouveauStatut);
            ctx.prefs = res.prefsMap.get(currentSav.Contact__c);
            ctx.result = result;
            ctx.langue = (currentSav.Langue_Client__c != null) ? currentSav.Langue_Client__c : 'fr';

            if (ctx.config != null) {
                handleEmail(ctx);
                handleSms(ctx);
                handlePush(ctx);
            }
        } catch (Exception e) {
            result.errorMessage = e.getMessage();
        }
        return result;
    }

    // ─── HANDLERS ──────────────────────────────────────────────────

    private static void handleEmail(DispatchContext ctx) {
        if (ctx.prefs != null && ctx.prefs.Email_SAV__c == true && String.isNotBlank(ctx.config.Email_Template_API__c)) {
            sendEmail(ctx.sav, ctx.config.Email_Template_API__c);
            ctx.result.emailSent = true;
        }
    }

    private static void handleSms(DispatchContext ctx) {
        if (ctx.prefs != null && ctx.prefs.SMS_SAV__c == true && String.isNotBlank(ctx.prefs.Telephone_SMS__c)) {
            String template = (ctx.langue == 'en') ? ctx.config.SMS_Template_EN__c : ctx.config.SMS_Template_FR__c;
            if (String.isNotBlank(template)) {
                sendSms(ctx.prefs.Telephone_SMS__c, mergeSmsTemplate(template, ctx.sav));
                ctx.result.smsSent = true;
            }
        }
    }

    private static void handlePush(DispatchContext ctx) {
        // Le push est activé par défaut ici car le champ Envoyer_Push__c est absent du Metadata
        sendPushNotification(ctx.sav, ctx.langue);
        ctx.result.pushSent = true;
    }

    // ─── CORE LOGIC ────────────────────────────────────────────────

    private static void sendEmail(Demande_SAV__c sav, String templateApiName) {
        List<EmailTemplate> templates = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateApiName WITH USER_MODE LIMIT 1];
        if (!templates.isEmpty()) { 
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(sav.Contact__c);
            mail.setTemplateId(templates[0].Id);
            mail.setWhatId(sav.Id);
            mail.setSaveAsActivity(false);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail }, false);
        }
    }

    private static void sendSms(String phone, String msg) {
        System.debug(LoggingLevel.INFO, 'Envoi SMS vers ' + phone + ' : ' + msg);
    }

    private static void sendPushNotification(Demande_SAV__c sav, String langue) {
        List<CustomNotificationType> notifTypes = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'SAV_Status_Update' WITH USER_MODE LIMIT 1];
        if (!notifTypes.isEmpty()) { 
            Messaging.CustomNotification notif = new Messaging.CustomNotification();
            notif.setNotificationTypeId(notifTypes[0].Id);
            notif.setTitle(sav.Name);
            notif.setBody((langue == 'en') ? 'Your SAV request status has changed.' : 'Le statut de votre demande SAV a été mis à jour.');
            notif.setTargetId(sav.Id);
            try {
                notif.send(new Set<String>{ sav.Contact__c });
            } catch (Exception e) {
                System.debug('Push error: ' + e.getMessage());
            }
        }
    }

    // ─── DATA LOADERS ──────────────────────────────────────────────

    private static Map<Id, Demande_SAV__c> buildSavMap(Set<Id> ids) {
        return new Map<Id, Demande_SAV__c>([SELECT Id, Name, Contact__c, Langue_Client__c, Statut__c FROM Demande_SAV__c WHERE Id IN :ids WITH USER_MODE]);
    }

    private static Map<Id, Preference_Notification__c> buildPrefsMap(Map<Id, Demande_SAV__c> smap) {
        Set<Id> cIds = new Set<Id>();
        for(Demande_SAV__c s : smap.values()) { 
            if(s.Contact__c != null) { 
                cIds.add(s.Contact__c); 
            } 
        }
        Map<Id, Preference_Notification__c> pMap = new Map<Id, Preference_Notification__c>();
        for(Preference_Notification__c p : [SELECT Contact__c, Email_SAV__c, SMS_SAV__c, Telephone_SMS__c FROM Preference_Notification__c WHERE Contact__c IN :cIds WITH USER_MODE]) {
            pMap.put(p.Contact__c, p);
        }
        return pMap;
    }

    private static Map<String, SAV_Notification_Config__mdt> buildConfigMap() {
        Map<String, SAV_Notification_Config__mdt> cMap = new Map<String, SAV_Notification_Config__mdt>();
        // Suppression du champ Envoyer_Push__c de la requête pour éviter l'erreur de déploiement
        for(SAV_Notification_Config__mdt c : [
            SELECT Statut__c, Email_Template_API__c, SMS_Template_FR__c, SMS_Template_EN__c 
            FROM SAV_Notification_Config__mdt 
            WITH USER_MODE
        ]) {
            cMap.put(c.Statut__c, c);
        }
        return cMap;
    }

    private static String mergeSmsTemplate(String t, Demande_SAV__c s) {
        if (String.isBlank(t)) { 
            return ''; 
        }
        return t.replace('{numero}', s.Name != null ? s.Name : '');
    }

    public class NotificationException extends Exception {}
}