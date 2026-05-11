/**
 * @class       SavWizardController
 * @description Contrôleur pour le tunnel de création de demande SAV.
 * Version 1.3 - Correction finale (Field API & Sécurité)
 * * @author      Manel Jallouli
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

    /**
     * @description Récupère les demandes SAV du contact connecté avec pagination.
     */
    @AuraEnabled(cacheable=true)
    public static SavListWrapper getMySavRequests(Integer pageSize, Integer pageNum, String statut) {
        Id contactId = getInternalContactId();
        Integer safePageSize = (pageSize == null || pageSize > 50) ? 20 : pageSize;
        Integer safeOffset = ((pageNum == null || pageNum < 1) ? 0 : (pageNum - 1)) * safePageSize;

        SavListWrapper result = new SavListWrapper();
        
        // Utilisation de requêtes statiques pour éviter l'injection SOQL (PMD Fix)
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

    /**
     * @description Récupère la liste des catégories de SAV disponibles.
     */
    @AuraEnabled(cacheable=true)
    public static List<Categorie_SAV__c> getSavCategories() {
        return [SELECT Id, Name, Description__c FROM Categorie_SAV__c WITH USER_MODE ORDER BY Name ASC];
    }

    // ─── MÉTHODES D'ÉCRITURE ───────────────────────────────────────

    /**
     * @description Crée une nouvelle demande SAV.
     */
    @AuraEnabled
    public static Id createSavRequest(SavRequestInput requestData) {
        if (requestData == null || String.isBlank(requestData.produitClientId)) {
            throw new AuraHandledException('Données de demande invalides.');
        }

        Id contactId = getInternalContactId();

        // Correction du champ : Categorie_SAV__c
        Demande_SAV__c sav = new Demande_SAV__c(
            Contact__c         = contactId,
            Produit_Client__c  = requestData.produitClientId,
            Categorie_SAV__c   = requestData.categorieId, 
            Description__c     = requestData.description,
            Statut__c          = 'Soumise',
            Date_Soumission__c = System.now()
        );

        // Insertion sécurisée en mode utilisateur
        insert as user sav;
        return sav.Id;
    }

    // ─── PRIVÉ / HELPERS ──────────────────────────────────────────

    /**
     * @description Récupère l'ID du contact lié à l'utilisateur courant (Experience Cloud).
     */
    private static Id getInternalContactId() {
        User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE];
        
        if (u.ContactId == null) {
            throw new AuraHandledException('Erreur : Votre profil utilisateur n\'est pas lié à un Contact.');
        }
        
        return u.ContactId;
    }
}