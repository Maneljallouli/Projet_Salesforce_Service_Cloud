public with sharing class SavCaseController {

    /* =========================================================
       CREATE CASE (Mis à jour avec les nouveaux champs MJ)
       ========================================================= */
    @AuraEnabled
    public static String createCase(
        String subject, 
        String description, 
        String category, 
        String subcategory, 
        String orderNumber, 
        String clientSegment
    ) {
        // Vérification des permissions de création
        if (!Schema.sObjectType.Case.isCreateable()) {
            throw new AuraHandledException('Accès refusé : Impossible de créer une demande.');
        }

        try {
            Case c = new Case();
            c.Subject = subject;
            c.Description = description;
            c.Origin = 'Web';
            c.Status = 'New';
            
            // Assignation des champs personnalisés (Assurez-vous que ces API Names existent)
            c.Category__c = category;
            c.Subcategory__c = subcategory;
            c.OrderNumber__c = orderNumber; 
            c.ClientSegment__c = clientSegment;

            insert c;

            // On récupère le CaseNumber pour un affichage plus "Luxe" en retour
            Case insertedCase = [SELECT CaseNumber FROM Case WHERE Id = :c.Id LIMIT 1];
            return insertedCase.CaseNumber;

        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la création : ' + e.getMessage());
        }
    }

    /* =========================
       GET CASE BY ID
       ========================= */
    @AuraEnabled(cacheable=true)
    public static Case getCaseById(Id caseId) {
        if (caseId == null) return null;

        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new AuraHandledException('No access to Case');
        }

        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Status, Priority, Origin, Description, 
                   Category__c, Subcategory__c, OrderNumber__c, CreatedDate
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        return cases.isEmpty() ? null : cases[0];
    }

    /* =========================
       UPDATE CASE
       ========================= */
    @AuraEnabled
    public static void updateCase(Case caseRecord) {
        if (caseRecord == null) return;

        if (!Schema.sObjectType.Case.isUpdateable()) {
            throw new AuraHandledException('No update permission on Case');
        }

        try {
            update caseRecord;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur de mise à jour : ' + e.getMessage());
        }
    }

    /* =========================
       DELETE CASE
       ========================= */
    @AuraEnabled
    public static void deleteCase(Id caseId) {
        if (caseId == null) return;

        if (!Schema.sObjectType.Case.isDeletable()) {
            throw new AuraHandledException('No delete permission on Case');
        }

        try {
            delete new Case(Id = caseId);
        } catch (Exception e) {
            throw new AuraHandledException('Erreur de suppression : ' + e.getMessage());
        }
    }

    /* =========================
       GET CASE LIST
       ========================= */
    @AuraEnabled(cacheable=true)
    public static List<Case> getCases() {
        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new AuraHandledException('No read access to Case');
        }

        // On trie par date pour afficher les plus récentes en haut
        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate, Category__c
            FROM Case
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }
}