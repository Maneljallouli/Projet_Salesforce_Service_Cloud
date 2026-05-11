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

    @ AuraEnabled
    public static String createCase(Case newCase) {
        try {
            // 1. Liaison au contact de l'utilisateur connecté (Experience Cloud)
            Id userId = UserInfo.getUserId();
            User currentUser = [SELECT ContactId FROM User WHERE Id = :userId WITH USER_MODE LIMIT 1];
            
            if (currentUser.ContactId != null) {
                newCase.ContactId = currentUser.ContactId;
            }

            // 2. Valeurs forcées
            newCase.Status = 'New';
            newCase.Origin = 'Web';

            // 3. Règles d'assignation
            List<AssignmentRule> rules = [
                SELECT Id FROM AssignmentRule 
                WHERE SobjectType = 'Case' AND Active = true 
                WITH USER_MODE LIMIT 1
            ];

            if (!rules.isEmpty()) {
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = rules[0].Id;
                newCase.setOptions(dmlOpts);
            }

            Database.SaveResult sr = Database.insert(newCase, AccessLevel.USER_MODE);
            Case c = [SELECT CaseNumber FROM Case WHERE Id = :sr.getId() WITH USER_MODE];
            return c.CaseNumber;
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false) // CRITIQUE : Pas de cache pour que le nombre soit à jour
    public static List<Case> getCases() {
        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate, Category__c
            FROM Case
            WHERE ContactId IN (SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId())
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }
}