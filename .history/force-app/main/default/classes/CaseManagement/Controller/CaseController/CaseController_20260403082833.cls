@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseController {

    // 1. Définition du Wrapper (Indispensable qu'il soit public et statique)
    public class CaseRequest {
        @AuraEnabled public String subject;
        @AuraEnabled public String description;
        @AuraEnabled public String category;
        @AuraEnabled public String subcategory;
        @AuraEnabled public String clientSegment;
        @AuraEnabled public String productId;
    }

    @AuraEnabled
    public static Id createCase(CaseRequest req) {
        try {
            // Recherche du contact par l'Email de l'utilisateur connecté
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Contact ctc = [SELECT Id FROM Contact WHERE Email = :currentUser.Email LIMIT 1];

            Case c = new Case();
            c.Subject = req.subject;
            c.Description = req.description;
            c.Category__c = req.category;
            c.Subcategory__c = req.subcategory;
            c.Client_Segment__c = req.clientSegment;
            c.Produit__c = req.productId;
            c.ContactId = ctc.Id;
            c.Origin = 'Web';
            c.Status = 'New';

            insert c;
            return c.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la création : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getMyCases() {
        try {
            // Recherche par Email pour plus de flexibilité
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            List<Contact> relatedContacts = [SELECT Id FROM Contact WHERE Email = :currentUser.Email LIMIT 1];

            if (relatedContacts.isEmpty()) {
                return new List<Case>();
            }

            Id targetContactId = relatedContacts[0].Id;

            return [
                SELECT Id, CaseNumber, Subject, Status, Priority, Category__c, CreatedDate
                FROM Case
                WHERE ContactId = :targetContactId
                ORDER BY CreatedDate DESC
                LIMIT 100
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la récupération : ' + e.getMessage());
        }
    }
}