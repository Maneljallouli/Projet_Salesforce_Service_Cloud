@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseController {

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
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            List<Contact> relatedContacts = [SELECT Id FROM Contact WHERE Email = :currentUser.Email LIMIT 1];

            if (relatedContacts.isEmpty()) return new List<Case>();

            return [
                SELECT Id, CaseNumber, Subject, Status, Priority, Category__c, CreatedDate
                FROM Case
                WHERE ContactId = :relatedContacts[0].Id
                ORDER BY CreatedDate DESC
                LIMIT 100
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la récupération : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Integer getMyCasesCount() {
        try {
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            List<Contact> relatedContacts = [SELECT Id FROM Contact WHERE Email = :currentUser.Email LIMIT 1];

            if (relatedContacts.isEmpty()) return 0;

            return [SELECT COUNT() FROM Case WHERE ContactId = :relatedContacts[0].Id];
        } catch (Exception e) {
            return 0;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Case getCaseDetail(Id caseId) {
        try {
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Contact ctc = [SELECT Id FROM Contact WHERE Email = :currentUser.Email LIMIT 1];

            return [
                SELECT Id, CaseNumber, Subject, Description, Status, Priority, 
                       Category__c, Subcategory__c, Client_Segment__c, CreatedDate
                FROM Case
                WHERE Id = :caseId AND ContactId = :ctc.Id
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Détails introuvables.');
        }
    }
}