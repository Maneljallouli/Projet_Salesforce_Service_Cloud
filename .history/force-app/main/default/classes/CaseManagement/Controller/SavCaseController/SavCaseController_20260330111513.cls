public without sharing class SavCaseController {

    public class CaseRequest {
        @AuraEnabled public String subject;
        @AuraEnabled public String description;
        @AuraEnabled public String category;
        @AuraEnabled public String subcategory;
        @AuraEnabled public String clientSegment;
        @AuraEnabled public String contactEmail; // email du contact pour assignation
    }

    @AuraEnabled
    public static String createCase(CaseRequest req) {
        try {
            // Vérification CRUD
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

            // Récupérer le Contact par email
            if (req.contactEmail == null || req.contactEmail.trim() == '') {
                throw new AuraHandledException('Email du contact non fourni');
            }

            if (!Schema.sObjectType.Contact.isAccessible()) {
                throw new AuraHandledException('Accès refusé aux Contacts');
            }

            Contact contact = [
                SELECT Id 
                FROM Contact 
                WHERE Email = :req.contactEmail
                LIMIT 1
            ];

            if (contact == null) {
                throw new AuraHandledException('Aucun contact trouvé pour cet email');
            }

            // Création du Case
            Case newCase = new Case();
            newCase.Subject = req.subject;
            newCase.Description = req.description;
            newCase.Category__c = req.category;
            newCase.Subcategory__c = req.subcategory;
            newCase.Client_segment__c = req.clientSegment;
            newCase.ContactId = contact.Id;
            newCase.Status = 'New';
            newCase.Origin = 'Web';

            // Assignment Rule active
            if (Schema.sObjectType.AssignmentRule.isAccessible()) {
                List<AssignmentRule> rules = [
                    SELECT Id 
                    FROM AssignmentRule 
                    WHERE SobjectType = 'Case' AND Active = true 
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
            ];
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
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=false)
    public static List<Case> getCases(String contactEmail) {
        if (contactEmail == null || contactEmail.trim() == '') {
            return new List<Case>();
        }

        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new AuraHandledException('Accès refusé aux Cases');
        }

        // Récupérer le contact par email
        if (!Schema.sObjectType.Contact.isAccessible()) {
            throw new AuraHandledException('Accès refusé aux Contacts');
        }

        List<Contact> contacts = [
            SELECT Id 
            FROM Contact 
            WHERE Email = :contactEmail
            LIMIT 1
        ];

        if (contacts.isEmpty()) {
            return new List<Case>();
        }

        Id contactId = contacts[0].Id;

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
            WHERE ContactId = :contactId
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }
}