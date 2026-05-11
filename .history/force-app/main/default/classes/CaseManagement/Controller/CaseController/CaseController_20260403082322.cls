@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseController {

    public class CaseRequest {
        @AuraEnabled public String subject;
        @AuraEnabled public String description;
        @AuraEnabled public String category;
        @AuraEnabled public String subcategory;
        @AuraEnabled public String clientSegment;
    }

    @AuraEnabled
    public static Id createCase(CaseRequest req) {
        try {
            // Récupération sécurisée du Contact
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            if (currentUser.ContactId == null) {
                throw new AuraHandledException('L\'utilisateur n\'est lié à aucun contact client.');
            }

            Case c = new Case();
            c.Subject = req.subject;
            c.Description = req.description;
            c.Category__c = req.category;
            c.Subcategory__c = req.subcategory;
            c.Client_Segment__c = req.clientSegment;
            c.ContactId = currentUser.ContactId; // Liaison automatique au bon client
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
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            if (currentUser.ContactId == null) return new List<Case>();

            // Utilisation de WITH USER_MODE pour la lecture propre des champs
            return [
                SELECT Id, CaseNumber, Subject, Status, Priority, Category__c, CreatedDate
                FROM Case
                WHERE ContactId = :currentUser.ContactId
                ORDER BY CreatedDate DESC
                LIMIT 100
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la récupération : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Case getCaseDetail(Id caseId) {
        try {
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            // Sécurité : on vérifie que le Case appartient bien au Contact de l'utilisateur
            return [
                SELECT Id, CaseNumber, Subject, Description, Status, Priority, 
                       Category__c, Subcategory__c, Client_Segment__c, CreatedDate
                FROM Case
                WHERE Id = :caseId AND ContactId = :currentUser.ContactId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Détails introuvables ou accès refusé.');
        }
    }
}