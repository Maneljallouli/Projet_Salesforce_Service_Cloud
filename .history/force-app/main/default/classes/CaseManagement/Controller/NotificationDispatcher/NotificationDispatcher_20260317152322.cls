/**
 * @class       NotificationDispatcher
 * @description Multi-channel notification engine for SAV status changes.
 * Final fix for ExcessiveParameterList using Property Initialization.
 */
public with sharing class NotificationDispatcher {

    // ─── CONTEXT WRAPPER (Fix: Removed long constructor) ───────────
    private class DispatchContext {
        public Demande_SAV__c sav;
        public Preference_Notification__c prefs;
        public SAV_Notification_Config__mdt config;
        public String langue;
        public NotificationResult result;
        
        // Constructeur vide pour éviter la règle ExcessiveParameterList
        public DispatchContext() {}
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
    @InvocableMethod(label='Dispatch SAV Notification')
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
            // Utilisation d'un wrapper unique pour le traitement global
            results.add(processSingleRequest(req, savMap, prefsMap, configMap));
        }
        return results;
    }

    /**
     * @description Toujours une liste de paramètres longue ? 
     * On regroupe les maps dans un seul objet de ressources si PMD persiste.
     */
    private static NotificationResult processSingleRequest(
        NotificationRequest req, 
        Map<Id, Demande_SAV__c> savMap, 
        Map<Id, Preference_Notification__c> prefsMap, 
        Map<String, SAV_Notification_Config__mdt> configMap
    ) {
        NotificationResult res = new NotificationResult();
        try {
            Demande_SAV__c currentSav = savMap.get(req.savId);
            if (currentSav == null) {
                res.errorMessage = 'SAV record not found';
                return res;
            }

            // Initialisation propriété par propriété (évite le constructeur long)
            DispatchContext ctx = new DispatchContext();
            ctx.sav = currentSav;
            ctx.config = configMap.get(req.nouveauStatut);
            ctx.prefs = prefsMap.get(currentSav.Contact__c);
            ctx.result = res;
            ctx.langue = currentSav.Langue_Client__c ?? 'fr';

            if (ctx.config != null) {
                handleEmail(ctx);
                handleSms(ctx);
                handlePush(ctx);
            }

        } catch (Exception e) {
            res.errorMessage = e.getMessage();
        }
        return res;
    }

    // ─── HANDLERS (Un seul paramètre : Parfait pour PMD) ───────────

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

    // ─── CORE LOGIC (PRIVATE HELPERS) ──────────────────────────────

    private static void sendEmail(Demande_SAV__c sav, String templateApiName) {
        List<EmailTemplate> templates = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateApiName WITH USER_MODE LIMIT 1];
        if (templates.isEmpty()) { return; }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(sav.Contact__c);
        mail.setTemplateId(templates[0].Id);
        mail.setWhatId(sav.Id);
        mail.setSaveAsActivity(false);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail }, false);
    }

    private static void sendSms(String phone, String msg) {
        // Logique Twilio simplifiée pour la démo
        System.debug('Sending SMS to ' + phone + ': ' + msg);
    }

    private static void sendPushNotification(Demande_SAV__c sav, String langue) {
        // Logique Push simplifiée
        System.debug('Push sent for SAV ' + sav.Id);
    }

    // ─── DATA LOADERS ──────────────────────────────────────────────

    private static Map<Id, Demande_SAV__c> buildSavMap(Set<Id> ids) {
        return new Map<Id, Demande_SAV__c>([SELECT Id, Name, Contact__c, Langue_Client__c, Statut__c FROM Demande_SAV__c WHERE Id IN :ids WITH USER_MODE]);
    }

    private static Map<Id, Preference_Notification__c> buildPrefsMap(Map<Id, Demande_SAV__c> smap) {
        Set<Id> cIds = new Set<Id>();
        for(Demande_SAV__c s : smap.values()) { if(s.Contact__c != null) cIds.add(s.Contact__c); }
        Map<Id, Preference_Notification__c> pMap = new Map<Id, Preference_Notification__c>();
        for(Preference_Notification__c p : [SELECT Contact__c, Email_SAV__c, SMS_SAV__c, Telephone_SMS__c FROM Preference_Notification__c WHERE Contact__c IN :cIds WITH USER_MODE]) {
            pMap.put(p.Contact__c, p);
        }
        return pMap;
    }

    private static Map<String, SAV_Notification_Config__mdt> buildConfigMap() {
        Map<String, SAV_Notification_Config__mdt> cMap = new Map<String, SAV_Notification_Config__mdt>();
        for(SAV_Notification_Config__mdt c : [SELECT Statut__c, Email_Template_API__c, SMS_Template_FR__c, SMS_Template_EN__c, Envoyer_Push__c FROM SAV_Notification_Config__mdt WITH USER_MODE]) {
            cMap.put(c.Statut__c, c);
        }
        return cMap;
    }

    private static String mergeSmsTemplate(String t, Demande_SAV__c s) {
        return t.replace('{numero}', s.Name ?? '');
    }

    private static String getConfig(String k) {
        List<Portal_Config__mdt> cfgs = [SELECT Value__c FROM Portal_Config__mdt WHERE DeveloperName = :k WITH USER_MODE LIMIT 1];
        return cfgs.isEmpty() ? '' : cfgs[0].Value__c;
    }

    public class NotificationException extends Exception {}
}