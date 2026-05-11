/**
 * @class       NotificationDispatcher
 * @description Multi-channel notification engine for SAV Case status changes.
 *              Dispatches Email (SF Templates), SMS (Twilio via Named Credential),
 *              and Salesforce Custom Push Notifications.
 *
 *              v2.0 — Pivot vers Case standard :
 *                - Demande_SAV__c       → Case (objet standard)
 *                - Contact__c           → ContactId (relation standard Case)
 *                - Statut__c            → Status (champ standard Case)
 *                - Langue_Client__c     → champ custom conservé, lu via get()
 *                - Produit_Client__r    → Produit_Concerne__r (lookup custom)
 *                - Montant_Final__c     → supprimé (hors scope)
 *                - Numero_Suivi_Sortant__c → supprimé (hors scope)
 *                - SMS tokens mis à jour : {prenom} {numero} {sujet} {statut}
 *                                          {produit} {conseiller}
 *                - SAV_Notification_Config__mdt : Statut__c → Status_Case__c
 *
 *              Bulk-safe : accepte List<NotificationRequest> pour Flow.
 *              Appelé depuis : Case_Notification_Flow (Record-Triggered).
 *
 * @author      Salesforce Architect
 * @version     2.0
 */
public with sharing class NotificationDispatcher {

    // ─────────────────────────────────────────────────────────────
    // INNER CLASSES
    // ─────────────────────────────────────────────────────────────

    public class NotificationRequest {
        @InvocableVariable(label='Case Id' required=true)
        public Id savId; // nom "savId" conservé pour compatibilité Flow

        @InvocableVariable(label='Ancien statut Case')
        public String ancienStatut;

        @InvocableVariable(label='Nouveau statut Case' required=true)
        public String nouveauStatut;
    }

    public class NotificationResult {
        @InvocableVariable(label='Email envoyé')   public Boolean emailSent;
        @InvocableVariable(label='SMS envoyé')     public Boolean smsSent;
        @InvocableVariable(label='Push envoyé')    public Boolean pushSent;
        @InvocableVariable(label='Erreur message') public String  errorMessage;
    }

    // ─────────────────────────────────────────────────────────────
    // INVOCABLE ENTRY POINT (Flow)
    // ─────────────────────────────────────────────────────────────

    @InvocableMethod(
        label='Dispatch SAV Case Notification'
        description='Sends email, SMS and push notification on Case status change')
    public static List<NotificationResult> dispatchFromFlow(
            List<NotificationRequest> requests) {

        Set<Id> caseIds = new Set<Id>();
        for (NotificationRequest req : requests) {
            if (req.savId != null) { caseIds.add(req.savId); }
        }

        Map<Id, Case>                             caseMap   = buildCaseMap(caseIds);
        Map<Id, Preference_Notification__c>       prefsMap  = buildPrefsMap(caseMap);
        Map<String, SAV_Notification_Config__mdt> configMap = buildConfigMap();

        List<NotificationResult> results = new List<NotificationResult>();

        for (NotificationRequest req : requests) {
            NotificationResult result = new NotificationResult();
            result.emailSent = false;
            result.smsSent   = false;
            result.pushSent  = false;

            try {
                Case c = caseMap.get(req.savId);
                if (c == null) {
                    result.errorMessage = 'Case not found: ' + req.savId;
                    results.add(result);
                    continue;
                }

                Preference_Notification__c prefs  = prefsMap.get(c.ContactId);
                SAV_Notification_Config__mdt conf = configMap.get(req.nouveauStatut);

                if (conf == null) {
                    results.add(result);
                    continue;
                }

                String langue = resolveLangue(c);

                if (prefs?.Email_SAV__c == true
                        && String.isNotBlank(conf.Email_Template_API__c)) {
                    result.emailSent = trySendEmail(c, conf.Email_Template_API__c, req.savId);
                }

                if (prefs?.SMS_SAV__c == true
                        && String.isNotBlank(prefs.Telephone_SMS__c)) {
                    String tpl = langue == 'en' ? conf.SMS_Template_EN__c : conf.SMS_Template_FR__c;
                    if (String.isNotBlank(tpl)) {
                        result.smsSent = trySendSms(
                            prefs.Telephone_SMS__c,
                            mergeSmsTemplate(tpl, c),
                            req.savId
                        );
                    }
                }

                if (conf.Envoyer_Push__c == true) {
                    result.pushSent = trySendPush(c, langue, req.savId);
                }

            } catch (Exception e) {
                result.errorMessage = e.getMessage();
                System.debug(LoggingLevel.ERROR,
                    'NotificationDispatcher error Case ' + req.savId + ': ' + e.getMessage());
            }
            results.add(result);
        }
        return results;
    }

    // ─────────────────────────────────────────────────────────────
    // DIRECT APEX CALL
    // ─────────────────────────────────────────────────────────────

    public static void dispatch(Id caseId, String nouveauStatut) {
        NotificationRequest req = new NotificationRequest();
        req.savId         = caseId;
        req.nouveauStatut = nouveauStatut;
        dispatchFromFlow(new List<NotificationRequest>{ req });
    }

    // ─────────────────────────────────────────────────────────────
    // EMAIL
    // ─────────────────────────────────────────────────────────────

    private static Boolean trySendEmail(Case c, String templateApiName, Id caseId) {
        try {
            sendEmail(c, templateApiName);
            return true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Email failed Case ' + caseId + ': ' + e.getMessage());
            return false;
        }
    }

    private static void sendEmail(Case c, String templateApiName) {
        List<EmailTemplate> templates = [
            SELECT Id FROM EmailTemplate
            WHERE  DeveloperName = :templateApiName LIMIT 1
        ];
        if (templates.isEmpty()) {
            throw new NotificationException('Email template not found: ' + templateApiName);
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(c.ContactId);
        mail.setWhatId(c.Id);
        mail.setTemplateId(templates[0].Id);
        mail.setSaveAsActivity(false);
        mail.setTreatTargetObjectAsRecipient(true);

        Messaging.SendEmailResult[] res =
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail }, false);
        if (!res[0].isSuccess()) {
            throw new NotificationException(
                'Email send failed: ' + res[0].getErrors()[0].getMessage());
        }
    }

    // ─────────────────────────────────────────────────────────────
    // SMS (Twilio via Named Credential NC_Twilio)
    // ─────────────────────────────────────────────────────────────

    private static Boolean trySendSms(String toPhone, String body, Id caseId) {
        try {
            sendSms(toPhone, body);
            return true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'SMS failed Case ' + caseId + ': ' + e.getMessage());
            return false;
        }
    }

    private static void sendSms(String toPhone, String body) {
        String fromPhone  = getConfig('TWILIO_FROM_NUMBER');
        String accountSid = getConfig('TWILIO_ACCOUNT_SID');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            'callout:NC_Twilio/2010-04-01/Accounts/' + accountSid + '/Messages.json'
        );
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setTimeout(10000);
        req.setBody(
            'To='    + EncodingUtil.urlEncode(toPhone,   'UTF-8') +
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
    // PUSH NOTIFICATION
    // ─────────────────────────────────────────────────────────────

    private static Boolean trySendPush(Case c, String langue, Id caseId) {
        try {
            sendPushNotification(c, langue);
            return true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Push failed Case ' + caseId + ': ' + e.getMessage());
            return false;
        }
    }

    private static void sendPushNotification(Case c, String langue) {
        List<CustomNotificationType> notifTypes = [
            SELECT Id FROM CustomNotificationType
            WHERE  DeveloperName = 'SAV_Status_Update' LIMIT 1
        ];
        if (notifTypes.isEmpty()) { return; }

        String title   = getProduitNom(c);
        String msgBody = langue == 'en'
            ? 'Your request has been updated: ' + formatStatus(c.Status)
            : 'Votre demande a été mise à jour : ' + formatStatus(c.Status);

        Messaging.CustomNotification notif = new Messaging.CustomNotification();
        notif.setNotificationTypeId(notifTypes[0].Id);
        notif.setTitle(title);
        notif.setBody(msgBody);
        notif.setTargetId(c.Id);
        notif.send(new Set<String>{ String.valueOf(c.ContactId) });
    }

    // ─────────────────────────────────────────────────────────────
    // BULK DATA HELPERS
    // ─────────────────────────────────────────────────────────────

    private static Map<Id, Case> buildCaseMap(Set<Id> caseIds) {
        Map<Id, Case> result = new Map<Id, Case>();
        if (caseIds.isEmpty()) { return result; }

        for (Case c : [
            SELECT  Id, CaseNumber, Subject, Status, Priority,
                    ContactId,
                    Contact.FirstName, Contact.LastName, Contact.Email,
                    AccountId,
                    RecordType.DeveloperName,
                    OwnerId, Owner.Name,
                    CreatedDate, LastModifiedDate
            FROM    Case
            WHERE   Id IN :caseIds
            WITH    SECURITY_ENFORCED
        ]) {
            result.put(c.Id, c);
        }

        // Custom fields queried via Database.query() to avoid compile errors
        enrichWithCustomFields(result, caseIds);
        return result;
    }

    @TestVisible
    private static void enrichWithCustomFields(Map<Id, Case> caseMap, Set<Id> caseIds) {
        try {
            List<SObject> rows = Database.query(
                'SELECT Id, Langue_Client__c, '
                + 'Produit_Concerne__c, Produit_Concerne__r.Nom_Produit__c '
                + 'FROM Case WHERE Id IN :caseIds'
            );
            for (SObject row : rows) {
                Id cId = (Id) row.get('Id');
                if (!caseMap.containsKey(cId)) { continue; }
                Case c = caseMap.get(cId);
                c.put('Langue_Client__c',    row.get('Langue_Client__c'));
                c.put('Produit_Concerne__c', row.get('Produit_Concerne__c'));
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,
                'enrichWithCustomFields: fields not available — ' + e.getMessage());
        }
    }

    private static Map<Id, Preference_Notification__c> buildPrefsMap(
            Map<Id, Case> caseMap) {
        Set<Id> contactIds = new Set<Id>();
        for (Case c : caseMap.values()) {
            if (c.ContactId != null) { contactIds.add(c.ContactId); }
        }
        Map<Id, Preference_Notification__c> result =
            new Map<Id, Preference_Notification__c>();
        if (contactIds.isEmpty()) { return result; }

        for (Preference_Notification__c p : [
            SELECT  Contact__c, Email_SAV__c, SMS_SAV__c,
                    Telephone_SMS__c, Langue_Preference__c
            FROM    Preference_Notification__c
            WHERE   Contact__c IN :contactIds
            WITH    SECURITY_ENFORCED
        ]) {
            result.put(p.Contact__c, p);
        }
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
            SELECT  Status_Case__c, Email_Template_API__c,
                    SMS_Template_FR__c, SMS_Template_EN__c, Envoyer_Push__c
            FROM    SAV_Notification_Config__mdt
            WHERE   IsActive__c = true
        ]) {
            result.put(cfg.Status_Case__c, cfg);
        }
        return result;
    }

    // ─────────────────────────────────────────────────────────────
    // SMS TEMPLATE MERGE
    //
    // Tokens :
    //   {prenom}     → Contact.FirstName
    //   {numero}     → Case.CaseNumber  (ex: 00001234)
    //   {sujet}      → Case.Subject
    //   {statut}     → Case.Status (label lisible FR)
    //   {produit}    → Produit_Concerne__r.Nom_Produit__c ou Subject
    //   {conseiller} → Case.Owner.Name
    //
    // Exemples de templates FR :
    //   "New"         → "Bonjour {prenom}, votre demande {numero} a bien été créée."
    //   "In Progress" → "Bonjour {prenom}, votre demande {numero} est en cours de traitement."
    //   "Resolved"    → "Bonjour {prenom}, votre demande {numero} est résolue. Confirmez en vous connectant au portail."
    //
    // Exemples de templates EN :
    //   "New"         → "Hi {prenom}, your request {numero} has been received."
    //   "Resolved"    → "Hi {prenom}, your request {numero} is resolved. Please confirm on the portal."
    // ─────────────────────────────────────────────────────────────

    @TestVisible
    private static String mergeSmsTemplate(String template, Case c) {
        return template
            .replace('{prenom}',     c.Contact?.FirstName  ?? '')
            .replace('{numero}',     c.CaseNumber          ?? '')
            .replace('{sujet}',      c.Subject             ?? '')
            .replace('{statut}',     formatStatus(c.Status))
            .replace('{produit}',    getProduitNom(c))
            .replace('{conseiller}', c.Owner?.Name         ?? '');
    }

    // ─────────────────────────────────────────────────────────────
    // PRIVATE HELPERS
    // ─────────────────────────────────────────────────────────────

    private static String resolveLangue(Case c) {
        try {
            String lang = (String) c.get('Langue_Client__c');
            if (lang == 'en' || lang == 'fr') { return lang; }
        } catch (Exception e) { /* champ pas encore déployé */ }
        return 'fr';
    }

    private static String getProduitNom(Case c) {
        try {
            SObject ref = c.getSObject('Produit_Concerne__r');
            if (ref != null) {
                String nom = (String) ref.get('Nom_Produit__c');
                if (String.isNotBlank(nom)) { return nom; }
            }
        } catch (Exception e) { /* relation pas disponible */ }
        return c.Subject ?? 'Votre demande';
    }

    private static final Map<String, String> STATUS_LABELS = new Map<String, String>{
        'New'               => 'Nouvelle demande',
        'In Progress'       => 'En cours de traitement',
        'Waiting Client'    => 'En attente de votre réponse',
        'Waiting Logistics' => 'En attente logistique',
        'Resolved'          => 'Résolue',
        'Closed'            => 'Fermée'
    };

    private static String formatStatus(String status) {
        if (status == null) { return ''; }
        return STATUS_LABELS.containsKey(status) ? STATUS_LABELS.get(status) : status;
    }

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

    public class NotificationException extends Exception {}
}