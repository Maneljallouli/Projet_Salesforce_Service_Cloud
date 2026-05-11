/**
 * @class       SavWizardController
 * @description Contrôleur pour le tunnel de création de demande SAV.
 * Version 1.2 - Fix Sécurité SOQL & Accolades
 */
public with sharing class SavWizardController {

    // ─── CLASSES INTERNES (Wrappers pour LWC) ──────────────────────

    public class SavRequestInput {
        @AuraEnabled public String produitClientId { get; set; }
        @AuraEnabled public String categorieId      { get; set; }
        @AuraEnabled public String description      { get; set; }
    }

    public class SavListWrapper {
        @AuraEnabled public List<Demande_SAV__c> records { get; set; }
        @AuraEnabled public Integer totalCount           { get; set; }
    }

    // ─── MÉTHODES DE LECTURE ───────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static SavListWrapper getMySavRequests(Integer pageSize, Integer pageNum, String statut) {
        Id contactId = getInternalContactId();
        Integer safePageSize = (pageSize == null || pageSize > 50) ? 20 : pageSize;
        Integer safeOffset = ((pageNum == null || pageNum < 1) ? 0 : (pageNum - 1)) * safePageSize;

        SavListWrapper result = new SavListWrapper();
        
        // Requête statique pour éviter toute injection SOQL et améliorer la performance
        if (String.isNotBlank(statut)) {
            result.records = [
                SELECT Id, Name, Statut__c, Date_Soumission__c, Produit_Client__r.Nom_Produit__c 
                FROM Demande_SAV__c 
                WHERE Contact__c = :contactId AND Statut__c = :statut
                WITH USER_MODE 
                ORDER BY Date_Soumission__c DESC 
                LIMIT :safePageSize OFFSET :safeOffset
            ];
        } else {
            result.records = [
                SELECT Id, Name, Statut__c, Date_Soumission__c, Produit_Client__r.Nom_Produit__c 
                FROM Demande_SAV__c 
                WHERE Contact__c = :contactId
                WITH USER_MODE 
                ORDER BY Date_Soumission__c DESC 
                LIMIT :safePageSize OFFSET :safeOffset
            ];
        }

        result.totalCount = [SELECT COUNT() FROM Demande_SAV__c WHERE Contact__c = :contactId WITH USER_MODE];
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Categorie_SAV__c> getSavCategories() {
        return [SELECT Id, Name, Description__c FROM Categorie_SAV__c WITH USER_MODE ORDER BY Name ASC];
    }

    // ─── MÉTHODES D'ÉCRITURE ───────────────────────────────────────

    @AuraEnabled
    public static Id createSavRequest(SavRequestInput requestData) {
        if (requestData == null || String.isBlank(requestData.produitClientId)) {
            throw new AuraHandledException('Données de demande invalides.');
        }

        Id contactId = getInternalContactId();

        // Correction du champ Categorie__c -> Categorie_SAV__c (à confirmer selon ton schéma)
        Demande_SAV__c sav = new Demande_SAV__c(
            Contact__c         = contactId,
            Produit_Client__c  = requestData.produitClientId,
            Categorie_SAV__c   = requestData.categorieId, 
            Description__c     = requestData.description,
            Statut__c          = 'Soumise'
        );

        insert as user sav;
        return sav.Id;
    }

    // ─── PRIVÉ / HELPERS ──────────────────────────────────────────

    private static Id getInternalContactId() {
        User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE];
        if (u.ContactId == null) {
            throw new AuraHandledException('Votre compte utilisateur n\'est pas lié à un Contact.');
        }
        return u.ContactId;
    }
}