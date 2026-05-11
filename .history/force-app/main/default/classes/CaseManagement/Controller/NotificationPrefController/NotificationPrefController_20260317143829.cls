/**
 * @class       NotificationPrefController
 * @description AuraEnabled controller for managing notification preferences
 *              on the Experience Cloud portal.
 *              One Preference_Notification__c record per Contact (upsert pattern).
 *
 * @author      Salesforce Architect
 * @version     1.0
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

    // Allowed locale values — whitelist to prevent arbitrary values
    private static final Set<String> ALLOWED_LANGUES =
        new Set<String>{ 'fr', 'en', 'ar', 'zh', 'ja', 'it', 'de', 'es' };

    // ─────────────────────────────────────────────────────────────
    // READ
    // ─────────────────────────────────────────────────────────────

    /**
     * Returns notification preferences for the current user.
     * Creates a default record if none exists.
     */
    @AuraEnabled(cacheable=true)
    public static Preference_Notification__c getPreferences() {
        Id contactId = ContactUtils.getCurrentContactId();

        List<Preference_Notification__c> existing = [
            SELECT  Id, Email_SAV__c, SMS_SAV__c,
                    Email_Livraison__c, SMS_Livraison__c,
                    Email_Promotionnel__c,
                    Langue_Preference__c, Telephone_SMS__c
            FROM    Preference_Notification__c
            WHERE   Contact__c = :contactId
            WITH    SECURITY_ENFORCED
            LIMIT   1
        ];

        if (!existing.isEmpty()) return existing[0];

        // Return default (transient — not persisted here)
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
     * Phone number is validated before storage.
     * @param prefsData  Populated PrefsInput wrapper
     */
    @AuraEnabled
    public static void savePreferences(PrefsInput prefsData) {
        if (prefsData == null) {
            throw new AuraHandledException(Label.Prefs_Error_InvalidInput);
        }

        Id contactId = ContactUtils.getCurrentContactId();

        // Validate phone if SMS enabled
        if ((prefsData.smsSav == true || prefsData.smsLivraison == true)
                && String.isBlank(prefsData.telephoneSms)) {
            throw new AuraHandledException(Label.Prefs_Error_PhoneRequired);
        }

        if (String.isNotBlank(prefsData.telephoneSms)
                && !isValidE164(prefsData.telephoneSms)) {
            throw new AuraHandledException(Label.Prefs_Error_InvalidPhone);
        }

        // Validate langue
        String langue = ALLOWED_LANGUES.contains(prefsData.languePref)
            ? prefsData.languePref : 'fr';

        // Upsert using external Id pattern on Contact__c
        Preference_Notification__c prefs = new Preference_Notification__c(
            Email_SAV__c          = prefsData.emailSav          ?? true,
            SMS_SAV__c            = prefsData.smsSav            ?? false,
            Email_Livraison__c    = prefsData.emailLivraison    ?? true,
            SMS_Livraison__c      = prefsData.smsLivraison      ?? false,
            Email_Promotionnel__c = prefsData.emailPromotionnel ?? false,
            Langue_Preference__c  = langue,
            Telephone_SMS__c      = prefsData.telephoneSms
        );

        List<Preference_Notification__c> existing = [
            SELECT Id FROM Preference_Notification__c
            WHERE  Contact__c = :contactId LIMIT 1
        ];

        if (existing.isEmpty()) {
            prefs.Contact__c = contactId;
            insert prefs;
        } else {
            prefs.Id = existing[0].Id;
            update prefs;
        }

        // Sync language preference back to Contact
        update new Contact(
            Id = contactId,
            Preferred_Language__c = langue
        );
    }

    // ─────────────────────────────────────────────────────────────
    // PRIVATE HELPERS
    // ─────────────────────────────────────────────────────────────

    /**
     * Basic E.164 phone number validation: +<country_code><number>, 7-15 digits.
     */
    private static Boolean isValidE164(String phone) {
        return Pattern.matches('^\\+[1-9]\\d{6,14}$', phone);
    }
}