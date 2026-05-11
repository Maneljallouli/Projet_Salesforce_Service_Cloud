public without sharing class SavCaseController {

    @AuraEnabled(cacheable=false)
    public static List<Case> getMyCases() {
        Id userId = UserInfo.getUserId();
        
        // Récupération du ContactId de l'utilisateur connecté
        User u = [SELECT ContactId FROM User WHERE Id = :userId WITH USER_MODE LIMIT 1];

        if (u.ContactId == null) {
            return new List<Case>();
        }

        // Retourne uniquement les dossiers liés à ce contact
        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate, Category__c
            FROM Case
            WHERE ContactId = :u.ContactId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }

    @AuraEnabled
    public static String createCase(Case newCase) {
        try {
            Id userId = UserInfo.getUserId();
            User currentUser = [SELECT ContactId FROM User WHERE Id = :userId WITH USER_MODE LIMIT 1];
            
            // Assignation automatique au bon Contact
            if (currentUser.ContactId != null) {
                newCase.ContactId = currentUser.ContactId;
            }

            newCase.Status = 'New';
            newCase.Origin = 'Web';

            // Gestion des règles d'assignation
            List<AssignmentRule> rules = [
                SELECT Id FROM AssignmentRule 
                WHERE SobjectType = 'Case' AND Active = true 
                WITH USER_MODE 
                LIMIT 1
            ];

            if (!rules.isEmpty()) {
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = rules[0].Id;
                newCase.setOptions(dmlOpts);
            }

            // Insertion sécurisée
            Database.SaveResult sr = Database.insert(newCase, AccessLevel.USER_MODE);

            // Retourne le CaseNumber pour l'affichage LWC
            Case c = [SELECT CaseNumber FROM Case WHERE Id = :sr.getId() WITH USER_MODE];
            return c.CaseNumber;
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }

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
}