public with sharing class SavCaseController {

    /* =========================
       GET CASE BY ID
       ========================= */
    @AuraEnabled(cacheable=true)
    public static Case getCaseById(Id caseId) {

        if (caseId == null) {
            return null;
        }

        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new AuraHandledException('No access to Case');
        }

        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Status, Priority, Origin, Description
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        if (!cases.isEmpty()) {
            return cases[0];
        } else {
            return null;
        }
    }

    /* =========================
       CREATE CASE
       ========================= */
    @AuraEnabled
    public static Id createCase(
        String subject, 
        String description, 
        String category, 
        String subcategory, 
        String orderNumber 
    ) {

        if (!Schema.sObjectType.Case.isCreateable()) {
            throw new AuraHandledException('No create permission on Case');
        }

        Case c = new Case();
        c.Subject = subject;
        c.Description = description;
        c.Status = 'New';
        c.Origin = 'Web';
        
        // Ajout de tes champs personnalisés
        c.Category__c = category;
        c.Subcategory__c = subcategory;
        c.OrderNumber__c = orderNumber;

        insert c;

        return c.Id;
    }
    /* =========================
       UPDATE CASE
       ========================= */
    @AuraEnabled
    public static void updateCase(Case caseRecord) {

        if (caseRecord == null) {
            return;
        }

        if (!Schema.sObjectType.Case.isUpdateable()) {
            throw new AuraHandledException('No update permission on Case');
        }

        update caseRecord;
    }

    /* =========================
       DELETE CASE
       ========================= */
    @AuraEnabled
    public static void deleteCase(Id caseId) {

        if (caseId == null) {
            return;
        }

        if (!Schema.sObjectType.Case.isDeletable()) {
            throw new AuraHandledException('No delete permission on Case');
        }

        Case c = new Case(Id = caseId);
        delete c;
    }

    /* =========================
       GET CASE LIST
       ========================= */
    @AuraEnabled(cacheable=true)
    public static List<Case> getCases() {

        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new AuraHandledException('No read access to Case');
        }

        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate
            FROM Case
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }
}