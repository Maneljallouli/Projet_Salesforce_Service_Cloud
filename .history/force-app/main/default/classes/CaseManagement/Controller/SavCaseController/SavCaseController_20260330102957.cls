public without sharing class SavCaseController {

    @AuraEnabled(cacheable=true)
    public static Case getCaseById(Id caseId) {
        if (caseId == null) {
            return null;
        }

        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, Origin, Description, 
                   Category__c, Subcategory__c, Order_number__c, Client_segment__c
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
            LIMIT 1
        ];
    }

    @AuraEnabled
    public static String createCase(Case newCase) {
        try {
            newCase.Status = 'New';
            newCase.Origin = 'Web';

            // Application des règles d'assignation
            List<AssignmentRule> rules = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
            if (!rules.isEmpty()) {
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = rules[0].Id;
                newCase.setOptions(dmlOpts);
            }

            // Insertion en mode USER_MODE pour PMD et sécurité
            Database.insert(newCase, AccessLevel.USER_MODE);

            // Récupération du numéro de case (ex: 00001553)
            Case c = [SELECT CaseNumber FROM Case WHERE Id = :newCase.Id WITH USER_MODE];
            return c.CaseNumber;
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateCase(Case caseRecord) {
        if (caseRecord != null) {
            Database.update(caseRecord, AccessLevel.USER_MODE);
        }
    }

    @AuraEnabled
    public static void deleteCase(Id caseId) {
        if (caseId != null) {
            Case c = new Case(Id = caseId);
            Database.delete(c, AccessLevel.USER_MODE);
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<Case> getCases() {
        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate, Category__c
            FROM Case
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }
}