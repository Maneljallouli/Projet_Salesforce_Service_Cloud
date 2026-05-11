public with sharing class CaseController {

    @AuraEnabled
    public static Id createCase(
        String subject,
        String description,
        String category,
        String subcategory,
        String clientSegment
    ) {
        Case c = new Case();
        c.Subject       = subject;
        c.Description   = description;
        c.Category__c   = category;
        c.Subcategory__c = subcategory;
        c.Client_Segment__c = clientSegment;
        c.Origin        = 'Web';
        c.Status        = 'New';
        insert c;
        return c.Id;
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getMyCases() {
        Id contactId = [
            SELECT ContactId FROM User
            WHERE Id = :UserInfo.getUserId()
        ].ContactId;

        return [
            SELECT Id, CaseNumber, Subject, Status,
                   Priority, Category__c, CreatedDate
            FROM Case
            WHERE ContactId = :contactId
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Case getCaseDetail(Id caseId) {
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