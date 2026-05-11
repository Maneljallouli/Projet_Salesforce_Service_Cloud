public with sharing class CaseController {

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

        // Vérification CRUD (CREATE)
        if (!Schema.sObjectType.Case.isCreateable()) {
            throw new AuraHandledException('Permission refusée pour créer un Case');
        }

        Case c = new Case();
        c.Subject = req.subject;
        c.Description = req.description;
        c.Category__c = req.category;
        c.Subcategory__c = req.subcategory;
        c.Client_Segment__c = req.clientSegment;
        c.Origin = 'Web';
        c.Status = 'New';

        insert c;
        return c.Id;
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getMyCases() {

        // Vérification CRUD (READ) sur Case
        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new AuraHandledException('Accès refusé aux Case');
        }

        // Vérification CRUD (READ) sur User
        if (!Schema.sObjectType.User.isAccessible()) {
            throw new AuraHandledException('Accès refusé à User');
        }

        Id contactId = [
            SELECT ContactId 
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ].ContactId;

        return [
            SELECT Id, CaseNumber, Subject, Status,
                   Priority, Category__c, CreatedDate
            FROM Case
            WHERE ContactId = :contactId
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Case getCaseDetail(Id caseId) {

        // Vérification CRUD (READ)
        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new AuraHandledException('Accès refusé au Case');
        }

        return [
            SELECT Id, CaseNumber, Subject, Description,
                   Status, Priority, Category__c,
                   Subcategory__c, Client_Segment__c,
                   CreatedDate, LastModifiedDate
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    }
}