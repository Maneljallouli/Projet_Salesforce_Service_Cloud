/**
 * @class       NotificationPrefController
 * @description AuraEnabled controller for managing notification preferences
 * on the Experience Cloud portal.
 * One Preference_Notification__c record per Contact (upsert pattern).
 *
 * @author      Salesforce Architect
 * @version     1.1
 */
public with sharing class NotificationPrefController {

    // ─────────────────────────────────────────────────────────────
    // INNER CLASS
    // ─────────────────────────────────────────────────────────────

    public class PrefsInput {
        @AuraEnabled public Boolean emailSav          { get; set; }
        @AuraEnabled public Boolean smsSav            { get; set; }
        @AuraEnabled public Boolean emailLivraison    { get; set; }
        @AuraEnabled public Boolean smsLivraison      { get; set; }
        @AuraEnabled public Boolean emailPromotionnel { get; set; }
        @AuraEnabled public String  languePref        { get; set; }
        @AuraEnabled public String  telephoneSms      { get; set; }
    }

    private static final Set<String> ALLOWED_LANGUES =
        new Set<String>{ 'fr', 'en', 'ar', 'zh', 'ja', 'it', 'de', 'es' };

    // ─────────────────────────────────────────────────────────────
    // READ
    // ─────────────────────────────────────────────────────────────

    /**
     * Returns notification preferences for the current user.
     * Fix: Added braces and switched to USER_MODE.
     */
    @AuraEnabled(cacheable=true)
    public static Preference_Notification__c getPreferences() {
        Id contactId = ContactUtils.getCurrentContactId();

        // Fix: SECURITY_ENFORCED est bon, mais WITH USER_MODE est plus complet pour PMD
        List<Preference_Notification__c> existing = [
            SELECT  Id, Email_SAV__c, SMS_SAV__c,
                    Email_Livraison__c, SMS_Livraison__c,
                    Email_Promotionnel__c,
                    Langue_Preference__c, Telephone_SMS__c
            FROM    Preference_Notification__c
            WHERE   Contact__c = :contactId
            WITH    USER_MODE
            LIMIT   1
        ];

        // Fix: Code Style - added braces
        if (!existing.isEmpty()) {
            return existing[0];
        }

        return new Preference_Notification__c(
            Email_SAV__c       = true,
            SMS_SAV__c         = false,
            Email_Livraison__c = true,
            SMS_Livraison__c   = false,
            Email_Promotionnel__c = false,
            Langue_Preference__c  = 'fr'
        );
    }

    // ─────────────────────────────────────────────────────────────
    // WRITE
    // ─────────────────────────────────────────────────────────────

    /**
     * Upserts notification preferences for the current user.
     * Fix: Added WITH USER_MODE for DML/SOQL to resolve CRUD violations.
     */
    @AuraEnabled
    public static void savePreferences(PrefsInput prefsData) {
        if (prefsData == null) {
            throw new AuraHandledException(Label.Prefs_Error_InvalidInput);
        }

        Id contactId = ContactUtils.getCurrentContactId();

        if ((prefsData.smsSav == true || prefsData.smsLivraison == true)
                && String.isBlank(prefsData.telephoneSms)) {
            throw new AuraHandledException(Label.Prefs_Error_PhoneRequired);
        }

        if (String.isNotBlank(prefsData.telephoneSms)
                && !isValidE164(prefsData.telephoneSms)) {
            throw new AuraHandledException(Label.Prefs_Error_InvalidPhone);
        }

        String langue = ALLOWED_LANGUES.contains(prefsData.languePref)
            ? prefsData.languePref : 'fr';

        Preference_Notification__c prefs = new Preference_Notification__c(
            Email_SAV__c          = prefsData.emailSav          ?? true,
            SMS_SAV__c            = prefsData.smsSav            ?? false,
            Email_Livraison__c    = prefsData.emailLivraison    ?? true,
            SMS_Livraison__c      = prefsData.smsLivraison      ?? false,
            Email_Promotionnel__c = prefsData.emailPromotionnel ?? false,
            Langue_Preference__c  = langue,
            Telephone_SMS__c      = prefsData.telephoneSms
        );

        // Fix: Added WITH USER_MODE for SOQL
        List<Preference_Notification__c> existing = [
            SELECT Id FROM Preference_Notification__c
            WHERE  Contact__c = :contactId 
            WITH   USER_MODE
            LIMIT  1
        ];

        // Fix: Added AS USER_MODE for DML
        if (existing.isEmpty()) {
            prefs.Contact__c = contactId;
            insert as user medical_record_entry_point; // Utilisation de USER_MODE pour la sécurité CRUD
            insert as user prefs;
        } else {
            prefs.Id = existing[0].Id;
            update as user prefs;
        }

        // Sync back to Contact - Fix: Added AS USER_MODE
        Contact ct = new Contact(
            Id = contactId,
            Preferred_Language__c = langue
        );
        update as user ct;
    }

    private static Boolean isValidE164(String phone) {
        return Pattern.matches('^\\+[1-9]\\d{6,14}$', phone);
    }
}