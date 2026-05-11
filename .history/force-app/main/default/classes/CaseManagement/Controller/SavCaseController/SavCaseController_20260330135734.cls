public with sharing class SavCaseController {

    @AuraEnabled
    public static String createCase(Map<String, String> caseDetails) {
        if (!Schema.sObjectType.Case.isCreateable()) {
            throw new AuraHandledException('Permissions insuffisantes.');
        }

        try {
            // Extraction des données
            String sub = caseDetails.get('subject');
            String descr = caseDetails.get('description');
            String cat = caseDetails.get('category');
            String subCat = caseDetails.get('subcategory');
            String orderNum = caseDetails.get('orderNumber');
            String seg = caseDetails.get('segment');
            String prio = caseDetails.get('priority'); // Ajout Priorité

            // Récupération Email User pour l'assignation
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
            
            Id contactId = null;
            List<Contact> matchingContacts = [SELECT Id FROM Contact WHERE Email = :currentUser.Email WITH USER_MODE LIMIT 1];
            if (!matchingContacts.isEmpty()) {
                contactId = matchingContacts[0].Id;
            }
            
            Case c = new Case();
            c.Subject = sub;
            c.Description = descr;
            c.ContactId = contactId;
            c.Priority = prio; // Priorité renseignée ici
            c.Origin = 'Web';
            
            // Mapping des champs personnalisés
            c.Category__c = cat; 
            c.Subcategory__c = subCat;
            c.Order_number__c = orderNum;
            c.Client_segment__c = seg;
            
            insert as user c;

            // RECUPERATION DU NUMERO DE CASE APRES INSERTION
            Case insertedCase = [SELECT CaseNumber FROM Case WHERE Id = :c.Id WITH USER_MODE];
            return insertedCase.CaseNumber;
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur technique : ' + e.getMessage());
        }
    }

    // Garde ta méthode getMyContactInfo telle quelle...
}