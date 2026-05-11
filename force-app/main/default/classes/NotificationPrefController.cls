/**
 * @class       NotificationPrefController
 * @description Contrôleur Aura pour la gestion des préférences de notification.
 * @version     1.2 - Fix déploiement (Fields, Labels, Utils)
 */
public with sharing class NotificationPrefController {

    public class PrefsInput {
        @AuraEnabled public Boolean emailSav          { get; set; }
        @AuraEnabled public Boolean smsSav            { get; set; }
        @AuraEnabled public Boolean emailLivraison    { get; set; }
        @AuraEnabled public Boolean smsLivraison      { get; set; }
        @AuraEnabled public String  languePref        { get; set; }
        @AuraEnabled public String  telephoneSms      { get; set; }
    }

    private static final Set<String> ALLOWED_LANGUES = 
        new Set<String>{ 'fr', 'en', 'ar' };

    /**
     * Récupère les préférences du contact lié à l'utilisateur courant.
     */
    @AuraEnabled(cacheable=true)
    public static Preference_Notification__c getPreferences() {
        Id contactId = getInternalContactId();

        List<Preference_Notification__c> existing = [
            SELECT  Id, Email_SAV__c, SMS_SAV__c,
                    Email_Livraison__c, SMS_Livraison__c,
                    Langue_Preference__c, Telephone_SMS__c
            FROM    Preference_Notification__c
            WHERE   Contact__c = :contactId
            WITH    USER_MODE
            LIMIT   1
        ];

        if (!existing.isEmpty()) {
            return existing[0];
        }

        return new Preference_Notification__c(
            Email_SAV__c       = true,
            SMS_SAV__c         = false,
            Email_Livraison__c = true,
            SMS_Livraison__c   = false,
            Langue_Preference__c  = 'fr'
        );
    }

    /**
     * Sauvegarde ou met à jour les préférences.
     */
    @AuraEnabled
    public static void savePreferences(PrefsInput prefsData) {
        if (prefsData == null) {
            throw new AuraHandledException('Données invalides.');
        }

        Id contactId = getInternalContactId();

        // Validation SMS
        if ((prefsData.smsSav == true || prefsData.smsLivraison == true) 
                && String.isBlank(prefsData.telephoneSms)) {
            throw new AuraHandledException('Le numéro de téléphone est requis pour les SMS.');
        }

        if (String.isNotBlank(prefsData.telephoneSms) && !isValidE164(prefsData.telephoneSms)) {
            throw new AuraHandledException('Format de téléphone invalide (Ex: +33612345678).');
        }

        String langue = ALLOWED_LANGUES.contains(prefsData.languePref) ? prefsData.languePref : 'fr';

        Preference_Notification__c prefs = new Preference_Notification__c(
            Email_SAV__c          = prefsData.emailSav       ?? true,
            SMS_SAV__c            = prefsData.smsSav         ?? false,
            Email_Livraison__c    = prefsData.emailLivraison ?? true,
            SMS_Livraison__c      = prefsData.smsLivraison   ?? false,
            Langue_Preference__c  = langue,
            Telephone_SMS__c      = prefsData.telephoneSms
        );

        List<Preference_Notification__c> existing = [
            SELECT Id FROM Preference_Notification__c
            WHERE  Contact__c = :contactId 
            WITH   USER_MODE
            LIMIT  1
        ];

        if (existing.isEmpty()) {
            prefs.Contact__c = contactId;
            insert as user prefs;
        } else {
            prefs.Id = existing[0].Id;
            update as user prefs;
        }

        // Note: La mise à jour du champ langue sur Contact est désactivée 
        // car le champ Preferred_Language__c n'existe pas dans ton org.
    }

    // --- HELPER METHODS ---

    /**
     * Remplace ContactUtils.getCurrentContactId()
     * Récupère le contact lié à l'utilisateur du portail.
     */
    private static Id getInternalContactId() {
        User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE];
        if (u.ContactId == null) {
            // Pour le debug en tant qu'admin (hors portail), on peut retourner un ID de test
            throw new AuraHandledException('Aucun contact lié à cet utilisateur.');
        }
        return u.ContactId;
    }

    private static Boolean isValidE164(String phone) {
        return Pattern.matches('^\\+[1-9]\\d{6,14}$', phone);
    }
}