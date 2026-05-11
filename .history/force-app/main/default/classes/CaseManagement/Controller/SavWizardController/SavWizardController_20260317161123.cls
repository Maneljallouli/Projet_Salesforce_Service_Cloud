/**
 * @class       SavWizardController
 * @description Contrôleur pour le tunnel de création de demande SAV.
 * Version 1.1 - Déploiement sécurisé (Fix fields & Utils)
 */
public with sharing class SavWizardController {

    // ─── CLASSES INTERNES ──────────────────────────────────────────

    public class SavRequestInput {
        @AuraEnabled public String  produitClientId { get; set; }
        @AuraEnabled public String  categorieId      { get; set; }
        @AuraEnabled public String  description      { get; set; }
        @AuraEnabled public String  canalRetour      { get; set; }
    }

    public class SavDetailWrapper {
        @AuraEnabled public Demande_SAV__c record { get; set; }
        @AuraEnabled public Boolean canValidate   { get; set; }
        @AuraEnabled public Boolean canPay        { get; set; }
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

        String query = 'SELECT Id, Name, Statut__c, Date_Soumission__c, Produit_Client__r.Nom_Produit__c ' +
                       'FROM Demande_SAV__c WHERE Contact__c = :contactId ';
        
        if (String.isNotBlank(statut)) {
            query += 'AND Statut__c = :statut ';
        }
        
        query += 'WITH USER_MODE ORDER BY Date_Soumission__c DESC LIMIT :safePageSize OFFSET :safeOffset';

        SavListWrapper result = new SavListWrapper();
        result.records = Database.query(query);
        result.totalCount = [SELECT COUNT() FROM Demande_SAV__c WHERE Contact__c = :contactId WITH USER_MODE];
        
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<Categorie_SAV__c> getSavCategories() {
        // Utilisation de Name au lieu de Nom__c (standard Salesforce)
        return [SELECT Id, Name, Description__c FROM Categorie_SAV__c WITH USER_MODE ORDER BY Name ASC];
    }

    // ─── MÉTHODES D'ÉCRITURE ───────────────────────────────────────

    @AuraEnabled
    public static Id createSavRequest(SavRequestInput requestData) {
        if (requestData == null || String.isBlank(requestData.produitClientId)) {
            throw new AuraHandledException('Données de demande invalides.');
        }

        Id contactId = getInternalContactId();

        Demande_SAV__c sav = new Demande_SAV__c(
            Contact__c         = contactId,
            Produit_Client__c  = requestData.produitClientId,
            Categorie__c       = requestData.categorieId,
            Description__c     = requestData.description,
            Statut__c          = 'Soumise'
        );

        insert as user sav;
        return sav.Id;
    }

    @AuraEnabled
    public static void validateReception(Id savId) {
        updateSavStatus(savId, 'Livré', 'Validé');
    }

    @AuraEnabled
    public static void approveDevis(Id savId) {
        updateSavStatus(savId, 'Devis_Envoyé', 'Devis_Approuvé');
    }

    // ─── PRIVÉ / HELPERS ──────────────────────────────────────────

    private static void updateSavStatus(Id savId, String oldStatus, String newStatus) {
        Id contactId = getInternalContactId();
        List<Demande_SAV__c> records = [
            SELECT Id FROM Demande_SAV__c 
            WHERE Id = :savId AND Contact__c = :contactId AND Statut__c = :oldStatus 
            WITH USER_MODE LIMIT 1
        ];

        if (records.isEmpty()) {
            throw new AuraHandledException('Action impossible : Statut actuel non compatible.');
        }

        records[0].Statut__c = newStatus;
        update as user records[0];
    }

    private static Id getInternalContactId() {
        User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE];
        if (u.ContactId == null) throw new AuraHandledException('Utilisateur non lié à un contact.');
        return u.ContactId;
    }
}