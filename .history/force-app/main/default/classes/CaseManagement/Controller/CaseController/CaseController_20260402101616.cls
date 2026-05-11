@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseController {

    // Wrapper pour éviter ExcessiveParameterList
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
            // Récupération du Contact lié à l'utilisateur connecté (Mode Système)
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id contactId = currentUser.ContactId;

            Case c = new Case();
            c.Subject = req.subject;
            c.Description = req.description;
            c.Category__c = req.category;
            c.Subcategory__c = req.subcategory;
            c.Client_Segment__c = req.clientSegment;
            c.ContactId = contactId;
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
            // Récupération du ContactId (Mode Système pour ignorer les restrictions de licence)
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id contactId = currentUser.ContactId;

            // Si l'utilisateur n'est pas lié à un contact, on retourne une liste vide
            if (contactId == null) {
                return new List<Case>();
            }

            return [
                SELECT Id,
                       CaseNumber,
                       Subject,
                       Status,
                       Priority,
                       Category__c,
                       CreatedDate
                FROM Case
                WHERE ContactId = :contactId
                ORDER BY CreatedDate DESC
                LIMIT 100
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la récupération : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Integer getMyCasesCount() {
        User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Id contactId = currentUser.ContactId;

        if (contactId == null) return 0;

        return [SELECT COUNT() FROM Case WHERE ContactId = :contactId];
    }

    @AuraEnabled(cacheable=true)
    public static Case getCaseDetail(Id caseId) {
        try {
            return [
                SELECT Id,
                       CaseNumber,
                       Subject,
                       Description,
                       Status,
                       Priority,
                       Category__c,
                       Subcategory__c,
                       Client_Segment__c,
                       CreatedDate,
                       LastModifiedDate
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Détails introuvables : ' + e.getMessage());
        }
    }
}