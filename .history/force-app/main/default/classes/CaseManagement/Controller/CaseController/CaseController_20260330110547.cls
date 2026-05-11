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

        // Vérification FLS pour les champs
        if (!Schema.sObjectType.Case.fields.Subject.isCreateable() ||
            !Schema.sObjectType.Case.fields.Description.isCreateable() ||
            !Schema.sObjectType.Case.fields.Category__c.isCreateable() ||
            !Schema.sObjectType.Case.fields.Subcategory__c.isCreateable() ||
            !Schema.sObjectType.Case.fields.Client_Segment__c.isCreateable() ||
            !Schema.sObjectType.Case.fields.ContactId.isCreateable() ||
            !Schema.sObjectType.Case.fields.Origin.isCreateable() ||
            !Schema.sObjectType.Case.fields.Status.isCreateable()) {
            throw new AuraHandledException('Accès refusé à un ou plusieurs champs du Case');
        }

        // Récupération du Contact lié à l'utilisateur connecté
        Id contactId = null;
        if (Schema.sObjectType.User.fields.ContactId.isAccessible()) {
            contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].ContactId;
        } else {
            throw new AuraHandledException('Accès refusé au champ ContactId sur User');
        }

        Case c = new Case();
        c.Subject = req.subject;
        c.Description = req.description;
        c.Category__c = req.category;
        c.Subcategory__c = req.subcategory;
        c.Client_Segment__c = req.clientSegment;
        c.ContactId = contactId;
        c.Origin = 'Web';
        c.Status = 'New';

        insert c;
        return c.Id;
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getMyCases() {

        // Vérification CRUD (READ)
        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new AuraHandledException('Accès refusé aux Case');
        }

        // Vérification FLS sur champs utilisés
        List<Schema.SObjectField> requiredFields = new List<Schema.SObjectField>{
            Case.Id, Case.CaseNumber, Case.Subject, Case.Status,
            Case.Priority, Case.Category__c, Case.CreatedDate, Case.ContactId
        };
        for (Schema.SObjectField f : requiredFields) {
            if (!f.getDescribe().isAccessible()) {
                throw new AuraHandledException('Accès refusé à un champ nécessaire du Case');
            }
        }

        // Récupération ContactId utilisateur
        Id contactId = null;
        if (Schema.sObjectType.User.fields.ContactId.isAccessible()) {
            contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].ContactId;
        } else {
            throw new AuraHandledException('Accès refusé au champ ContactId sur User');
        }

        return [
            SELECT Id,
                   CaseNumber,
                   Subject,
                   Status,
                   Priority,
                   Category__c,
                   CreatedDate
            FROM Case
            WHERE ContactId = :contactId
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Integer getMyCasesCount() {

        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new AuraHandledException('Accès refusé aux Case');
        }

        // Récupération ContactId utilisateur
        Id contactId = null;
        if (Schema.sObjectType.User.fields.ContactId.isAccessible()) {
            contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].ContactId;
        } else {
            throw new AuraHandledException('Accès refusé au champ ContactId sur User');
        }

        return [SELECT COUNT() FROM Case WHERE ContactId = :contactId];
    }

    @AuraEnabled(cacheable=true)
    public static Case getCaseDetail(Id caseId) {

        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new AuraHandledException('Accès refusé au Case');
        }

        List<Schema.SObjectField> requiredFields = new List<Schema.SObjectField>{
            Case.Id, Case.CaseNumber, Case.Subject, Case.Description,
            Case.Status, Case.Priority, Case.Category__c,
            Case.Subcategory__c, Case.Client_Segment__c,
            Case.CreatedDate, Case.LastModifiedDate
        };
        for (Schema.SObjectField f : requiredFields) {
            if (!f.getDescribe().isAccessible()) {
                throw new AuraHandledException('Accès refusé à un champ nécessaire du Case');
            }
        }

        return [
            SELECT Id,
                   CaseNumber,
                   Subject,
                   Description,
                   Status,
                   Priority,
                   Category__c,
                   Subcategory__c,
                   Client_Segment__c,
                   CreatedDate,
                   LastModifiedDate
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    }
}