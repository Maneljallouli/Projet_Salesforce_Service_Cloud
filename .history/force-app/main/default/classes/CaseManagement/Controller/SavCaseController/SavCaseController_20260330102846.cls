public without sharing class SavCaseController {

    /* =========================
       GET CASE BY ID
       ========================= */
    @AuraEnabled(cacheable=true)
    public static Case getCaseById(Id caseId) {
        if (caseId == null) {
            return null;
        }

        // Utilisation de sans restriction isAccessible pour garantir la vue sur le portail
        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, Origin, Description, 
                   Category__c, Subcategory__c, Order_number__c, Client_segment__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
    }

    /* =========================
       CREATE CASE (Updated with Assignment Rules & CaseNumber)
       ========================= */
    @AuraEnabled
    public static String createCase(Case newCase) {
        try {
            // 1. Forcer les valeurs par défaut pour la sécurité
            newCase.Status = 'New';
            newCase.Origin = 'Web';

            // 2. Préparation du Header pour les règles d'assignation (Assignment Rules)
            // Cela permet d'envoyer automatiquement le case vers la bonne Queue
            AssignmentRule ar = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
            
            if (ar != null) {
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = ar.Id;
                newCase.setOptions(dmlOpts);
            }

            // 3. Insertion du Case
            insert newCase;

            // 4. Récupération et renvoi du CaseNumber (ex: 00001553) au lieu de l'ID technique
            Case insertedCase = [SELECT CaseNumber FROM Case WHERE Id = :newCase.Id LIMIT 1];
            return insertedCase.CaseNumber;
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }

    /* =========================
       UPDATE CASE
       ========================= */
    @AuraEnabled
    public static void updateCase(Case caseRecord) {
        if (caseRecord != null) {
            update caseRecord;
        }
    }

    /* =========================
       DELETE CASE
       ========================= */
    @AuraEnabled
    public static void deleteCase(Id caseId) {
        if (caseId != null) {
            delete new Case(Id = caseId);
        }
    }

    /* =========================
       GET CASE LIST (Total count support)
       ========================= */
    @AuraEnabled(cacheable=false) // On retire le cache pour forcer l'actualisation du nombre de cases
    public static List<Case> getCases() {
        // Retourne la liste triée par date pour que le client voie son dernier case en haut
        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate, Category__c
            FROM Case
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }
}