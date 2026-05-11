/**
 * @class       NotificationDispatcher
 * @description Multi-channel notification engine for SAV status changes.
 *              Dispatches Email (SF Templates), SMS (Twilio via Named Credential),
 *              and Salesforce Custom Push Notifications.
 *
 *              Called from Record-Triggered Flow after Demande_SAV__c status change.
 *              Designed as invocable for Flow compatibility + direct Apex calls.
 *
 *              Bulk-safe: accepts List<NotificationRequest> in @InvocableMethod.
 *
 * @author      Salesforce Architect
 * @version     1.0
 */
public class NotificationDispatcher {

    // ─────────────────────────────────────────────────────────────
    // INNER CLASSES
    // ─────────────────────────────────────────────────────────────

    public class NotificationRequest {
        @InvocableVariable(label='SAV Record Id' required=true)
        public Id savId;

        @InvocableVariable(label='Ancien Statut')
        public String ancienStatut;

        @InvocableVariable(label='Nouveau Statut' required=true)
        public String nouveauStatut;
    }

    public class NotificationResult {
        @InvocableVariable(label='Email envoyé')  public Boolean emailSent;
        @InvocableVariable(label='SMS envoyé')    public Boolean smsSent;
        @InvocableVariable(label='Push envoyé')   public Boolean pushSent;
        @InvocableVariable(label='Erreur message') public String  errorMessage;
    }

    // ─────────────────────────────────────────────────────────────
    // INVOCABLE ENTRY POINT (Flow)
    // ─────────────────────────────────────────────────────────────

    @InvocableMethod(
        label='Dispatch SAV Notification'
        description='Sends email, SMS, and push notification on SAV status change')
    public static List<NotificationResult> dispatchFromFlow(
            List<NotificationRequest> requests) {

        // Bulk fetch all SAV records in one SOQL
        Set<Id> savIds = new Set<Id>();
        for (NotificationRequest req : requests) {
            if (req.savId != null) savIds.add(req.savId);
        }

        Map<Id, Demande_SAV__c> savMap = buildSavMap(savIds);
        Map<Id, Preference_Notification__c> prefsMap = buildPrefsMap(savMap);
        Map<String, SAV_Notification_Config__mdt> configMap = buildConfigMap();

        List<NotificationResult> results = new List<NotificationResult>();

        for (NotificationRequest req : requests) {
            NotificationResult result = new NotificationResult();
            try {
                Demande_SAV__c sav = savMap.get(req.savId);
                if (sav == null) {
                    result.errorMessage = 'SAV record not found: ' + req.savId;
                    results.add(result);
                    continue;
                }

                Preference_Notification__c prefs =
                    prefsMap.get(sav.Contact__c);
                SAV_Notification_Config__mdt config =
                    configMap.get(req.nouveauStatut);

                if (config == null) {
                    // No notification configured for this status — skip silently
                    results.add(result);
                    continue;
                }

                String langue = sav.Langue_Client__c ?? 'fr';

                // EMAIL
                if (prefs?.Email_SAV__c == true
                        && String.isNotBlank(config.Email_Template_API__c)) {
                    try {
                        sendEmail(sav, config.Email_Template_API__c);
                        result.emailSent = true;
                    } catch (Exception e) {
                        System.debug(LoggingLevel.ERROR,
                            'Email failed for ' + req.savId + ': ' + e.getMessage());
                    }
                }

                // SMS
                if (prefs?.SMS_SAV__c == true
                        && String.isNotBlank(prefs.Telephone_SMS__c)) {
                    String smsTemplate = langue == 'en'
                        ? config.SMS_Template_EN__c
                        : config.SMS_Template_FR__c;
                    if (String.isNotBlank(smsTemplate)) {
                        try {
                            sendSms(
                                prefs.Telephone_SMS__c,
                                mergeSmsTemplate(smsTemplate, sav)
                            );
                            result.smsSent = true;
                        } catch (Exception e) {
                            System.debug(LoggingLevel.ERROR,
                                'SMS failed for ' + req.savId + ': ' + e.getMessage());
                        }
                    }
                }

                // PUSH NOTIFICATION
                if (config.Envoyer_Push__c == true) {
                    try {
                        sendPushNotification(sav, langue);
                        result.pushSent = true;
                    } catch (Exception e) {
                        System.debug(LoggingLevel.ERROR,
                            'Push failed for ' + req.savId + ': ' + e.getMessage());
                    }
                }

            } catch (Exception e) {
                result.errorMessage = e.getMessage();
                // Log but do not rethrow — allow bulk batch to continue
                System.debug(LoggingLevel.ERROR,
                    'NotificationDispatcher error for ' + req.savId + ': ' + e.getMessage());
            }
            results.add(result);
        }
        return results;
    }

    // ─────────────────────────────────────────────────────────────
    // DIRECT APEX CALL (for non-Flow contexts)
    // ─────────────────────────────────────────────────────────────

    public static void dispatch(Id savId, String nouveauStatut) {
        NotificationRequest req = new NotificationRequest();
        req.savId         = savId;
        req.nouveauStatut = nouveauStatut;
        dispatchFromFlow(new List<NotificationRequest>{ req });
    }

    // ─────────────────────────────────────────────────────────────
    // EMAIL
    // ─────────────────────────────────────────────────────────────

    private static void sendEmail(Demande_SAV__c sav, String templateApiName) {
        List<EmailTemplate> templates = [
            SELECT Id FROM EmailTemplate
            WHERE  DeveloperName = :templateApiName
            LIMIT  1
        ];
        if (templates.isEmpty()) {
            throw new NotificationException('Email template not found: ' + templateApiName);
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(sav.Contact__c);
        mail.setWhatId(sav.Id);
        mail.setTemplateId(templates[0].Id);
        mail.setSaveAsActivity(false);
        mail.setTreatTargetObjectAsRecipient(true);

        Messaging.SendEmailResult[] results =
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail }, false);

        if (!results[0].isSuccess()) {
            throw new NotificationException(
                'Email send failed: ' + results[0].getErrors()[0].getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────
    // SMS (Twilio via Named Credential)
    // ─────────────────────────────────────────────────────────────

    private static void sendSms(String toPhone, String body) {
        // Named Credential: NC_Twilio (Auth: Password, Twilio AccountSid:AuthToken)
        String fromPhone = getConfig('TWILIO_FROM_NUMBER');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            'callout:NC_Twilio/2010-04-01/Accounts/'
            + getConfig('TWILIO_ACCOUNT_SID')
            + '/Messages.json'
        );
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setTimeout(10000);
        req.setBody(
            'To='   + EncodingUtil.urlEncode(toPhone,   'UTF-8') +
            '&From=' + EncodingUtil.urlEncode(fromPhone, 'UTF-8') +
            '&Body=' + EncodingUtil.urlEncode(body,      'UTF-8')
        );

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new NotificationException(
                'Twilio error ' + res.getStatusCode() + ': ' + res.getBody());
        }
    }

    // ─────────────────────────────────────────────────────────────
    // PUSH NOTIFICATION (Salesforce Custom Notification)
    // ─────────────────────────────────────────────────────────────

    private static void sendPushNotification(Demande_SAV__c sav, String langue) {
        List<CustomNotificationType> notifTypes = [
            SELECT Id FROM CustomNotificationType
            WHERE  DeveloperName = 'SAV_Status_Update'
            LIMIT  1
        ];
        if (notifTypes.isEmpty()) return; // Custom notif type not deployed, skip

        String produitNom = sav.Produit_Client__r?.Nom_Produit__c ?? 'Votre pièce';
        String statut     = (sav.Statut__c ?? '').replace('_', ' ');

        String title = produitNom;
        String msgBody = langue == 'en'
            ? 'Your repair request has been updated: ' + statut
            : 'Votre demande SAV a été mise à jour : ' + statut;

        Messaging.CustomNotification notif = new Messaging.CustomNotification();
        notif.setNotificationTypeId(notifTypes[0].Id);
        notif.setTitle(title);
        notif.setBody(msgBody);
        notif.setTargetId(sav.Id);
        notif.send(new Set<String>{ sav.Contact__c });
    }

    // ─────────────────────────────────────────────────────────────
    // BULK DATA HELPERS
    // ─────────────────────────────────────────────────────────────

    private static Map<Id, Demande_SAV__c> buildSavMap(Set<Id> savIds) {
        Map<Id, Demande_SAV__c> result = new Map<Id, Demande_SAV__c>();
        if (savIds.isEmpty()) return result;

        for (Demande_SAV__c sav : [
            SELECT  Id, Name, Statut__c, Contact__c,
                    Contact__r.Email, Contact__r.FirstName, Contact__r.LastName,
                    Langue_Client__c, Artisan_Responsable__c, Note_Atelier__c,
                    Numero_Suivi_Sortant__c, Montant_Final__c,
                    Produit_Client__r.Nom_Produit__c
            FROM    Demande_SAV__c
            WHERE   Id IN :savIds
        ]) {
            result.put(sav.Id, sav);
        }
        return result;
    }

    private static Map<Id, Preference_Notification__c> buildPrefsMap(
            Map<Id, Demande_SAV__c> savMap) {

        Set<Id> contactIds = new Set<Id>();
        for (Demande_SAV__c sav : savMap.values()) {
            if (sav.Contact__c != null) contactIds.add(sav.Contact__c);
        }

        Map<Id, Preference_Notification__c> result = new Map<Id, Preference_Notification__c>();
        if (contactIds.isEmpty()) return result;

        for (Preference_Notification__c p : [
            SELECT  Contact__c, Email_SAV__c, SMS_SAV__c,
                    Telephone_SMS__c, Email_Livraison__c, SMS_Livraison__c
            FROM    Preference_Notification__c
            WHERE   Contact__c IN :contactIds
        ]) {
            result.put(p.Contact__c, p);
        }

        // Default prefs for contacts with no record
        for (Id cId : contactIds) {
            if (!result.containsKey(cId)) {
                result.put(cId, new Preference_Notification__c(
                    Email_SAV__c = true, SMS_SAV__c = false
                ));
            }
        }
        return result;
    }

    private static Map<String, SAV_Notification_Config__mdt> buildConfigMap() {
        Map<String, SAV_Notification_Config__mdt> result =
            new Map<String, SAV_Notification_Config__mdt>();
        for (SAV_Notification_Config__mdt cfg : [
            SELECT  Statut__c, Email_Template_API__c,
                    SMS_Template_FR__c, SMS_Template_EN__c, Envoyer_Push__c
            FROM    SAV_Notification_Config__mdt
        ]) {
            result.put(cfg.Statut__c, cfg);
        }
        return result;
    }

    // ─────────────────────────────────────────────────────────────
    // SMS TEMPLATE MERGE
    // ─────────────────────────────────────────────────────────────

    private static String mergeSmsTemplate(String template, Demande_SAV__c sav) {
        return template
            .replace('{prenom}',   sav.Contact__r?.FirstName ?? '')
            .replace('{numero}',   sav.Name ?? '')
            .replace('{produit}',  sav.Produit_Client__r?.Nom_Produit__c ?? '')
            .replace('{statut}',   (sav.Statut__c ?? '').replace('_', ' '))
            .replace('{montant}',  sav.Montant_Final__c != null
                ? String.valueOf(sav.Montant_Final__c.setScale(2)) + ' €' : '')
            .replace('{tracking}', sav.Numero_Suivi_Sortant__c ?? '');
    }

    // ─────────────────────────────────────────────────────────────
    // CONFIG HELPER
    // ─────────────────────────────────────────────────────────────

    private static String getConfig(String key) {
        List<Portal_Config__mdt> configs = [
            SELECT Value__c FROM Portal_Config__mdt
            WHERE  DeveloperName = :key LIMIT 1
        ];
        if (configs.isEmpty()) {
            throw new NotificationException('Config key not found: ' + key);
        }
        return configs[0].Value__c;
    }

    // ─────────────────────────────────────────────────────────────
    // CUSTOM EXCEPTION
    // ─────────────────────────────────────────────────────────────

    public class NotificationException extends Exception {}
}