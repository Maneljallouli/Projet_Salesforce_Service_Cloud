public title without sharing class SavCaseController {

    @AuraEnabled(cacheable=false)
    public static List<Case> getMyCases() {
        // Récupération sécurisée du ContactId de l'utilisateur actuel
        Id userId = UserInfo.getUserId();
        
        // Correction PMD : Utilisation de WITH USER_MODE pour la requête User
        User u = [SELECT ContactId FROM User WHERE Id = :userId WITH USER_MODE LIMIT 1];

        if (u.ContactId == null) {
            return new List<Case>();
        }

        // Retourne uniquement les cases du contact connecté
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
            // 1. Liaison au contact (Sécurité : identification de l'auteur)
            Id userId = UserInfo.getUserId();
            User currentUser = [SELECT ContactId FROM User WHERE Id = :userId WITH USER_MODE LIMIT 1];
            
            if (currentUser.ContactId != null) {
                newCase.ContactId = currentUser.ContactId;
            }

            newCase.Status = 'New';
            newCase.Origin = 'Web';

            // 2. Règles d'assignation
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

            // 3. Insertion avec contrôle de sécurité strict
            Database.SaveResult sr = Database.insert(newCase, AccessLevel.USER_MODE);

            // 4. Récupération du numéro de dossier
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