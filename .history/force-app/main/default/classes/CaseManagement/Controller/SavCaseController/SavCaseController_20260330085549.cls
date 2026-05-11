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
    public static Id createCase(Case newCase) {
        // Vérification des permissions avec accolades pour PMD
        if (!Schema.sObjectType.Case.isCreateable()) {
            throw new AuraHandledException('No create permission on Case');
        }

        try {
            // Ces valeurs sont forcées côté serveur pour la sécurité
            newCase.Status = 'New';
            newCase.Origin = 'Web';

            // L'objet "newCase" contient déjà Category__c, Subcategory__c, etc.
            insert newCase;
            return newCase.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
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