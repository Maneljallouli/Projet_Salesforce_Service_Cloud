public without sharing class SavCaseController {

    @AuraEnabled(cacheable=true)
    public static Case getCaseById(Id caseId) {
        if (caseId == null) {
            return null;
        }

        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new AuraHandledException('Accès refusé aux Cases');
        }

        List<Schema.SObjectField> requiredFields = new List<Schema.SObjectField>{
            Case.Id, Case.CaseNumber, Case.Subject, Case.Status, Case.Priority,
            Case.Origin, Case.Description, Case.Category__c, Case.Subcategory__c,
            Case.Order_number__c, Case.Client_segment__c
        };

        for (Schema.SObjectField f : requiredFields) {
            if (!f.getDescribe().isAccessible()) {
                throw new AuraHandledException('Accès refusé à un champ nécessaire du Case');
            }
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
            // Vérification CRUD sur Case
            if (!Schema.sObjectType.Case.isCreateable()) {
                throw new AuraHandledException('Création de Case interdite');
            }

            // Vérification FLS sur les champs utilisés
            List<Schema.SObjectField> createFields = new List<Schema.SObjectField>{
                Case.Subject, Case.Description, Case.Category__c, Case.Subcategory__c,
                Case.Client_segment__c, Case.ContactId, Case.Origin, Case.Status
            };
            for (Schema.SObjectField f : createFields) {
                if (!f.getDescribe().isCreateable()) {
                    throw new AuraHandledException('Accès refusé à un champ nécessaire du Case');
                }
            }

            // Récupérer le Contact du User connecté
            User currentUser = [
                SELECT ContactId 
                FROM User 
                WHERE Id = :UserInfo.getUserId()
                WITH USER_MODE
                LIMIT 1
            ];

            if (currentUser.ContactId == null) {
                throw new AuraHandledException(
                    'Votre compte portail n’est pas lié à un Contact. Veuillez contacter l’administrateur.'
                );
            }

            newCase.ContactId = currentUser.ContactId;

            // Valeurs forcées
            newCase.Status = 'New';
            newCase.Origin = 'Web';

            // Vérifier si une règle d’assignation active existe
            if (Schema.sObjectType.AssignmentRule.isAccessible()) {
                List<AssignmentRule> rules = [
                    SELECT Id 
                    FROM AssignmentRule 
                    WHERE SobjectType = 'Case' AND Active = true 
                    WITH USER_MODE
                    LIMIT 1
                ];

                if (!rules.isEmpty()) {
                    Database.DMLOptions dmlOpts = new Database.DMLOptions();
                    dmlOpts.assignmentRuleHeader.assignmentRuleId = rules[0].Id;
                    newCase.setOptions(dmlOpts);
                }
            }

            Database.SaveResult sr = Database.insert(newCase, AccessLevel.USER_MODE);

            Case c = [
                SELECT CaseNumber 
                FROM Case 
                WHERE Id = :sr.getId() 
                WITH USER_MODE
                LIMIT 1
            ];
            return c.CaseNumber;

        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<Case> getCases() {
        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new AuraHandledException('Accès refusé aux Cases');
        }

        // Récupérer le Contact du User connecté
        User currentUser = [
            SELECT ContactId 
            FROM User 
            WHERE Id = :UserInfo.getUserId() 
            WITH USER_MODE
            LIMIT 1
        ];

        if (currentUser.ContactId == null) {
            // Aucun Contact → retourne une liste vide
            return new List<Case>();
        }

        List<Schema.SObjectField> requiredFields = new List<Schema.SObjectField>{
            Case.Id, Case.CaseNumber, Case.Subject, Case.Status, Case.Priority, Case.CreatedDate, Case.Category__c
        };

        for (Schema.SObjectField f : requiredFields) {
            if (!f.getDescribe().isAccessible()) {
                throw new AuraHandledException('Accès refusé à un champ nécessaire du Case');
            }
        }

        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate, Category__c
            FROM Case
            WHERE ContactId = :currentUser.ContactId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }
}