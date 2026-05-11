public without sharing class SavCaseController {

    @AuraEnabled
    public static String createCase(Map<String, String> caseDetails) {
        try {
            // 1. Récupération de l'utilisateur
            User currentUser = [SELECT ContactId, Contact.Client_segment__c 
                                FROM User 
                                WHERE Id = :UserInfo.getUserId() 
                                LIMIT 1];
            
            // 2. Création de la requête
            Case newCase = new Case();
            newCase.Subject = caseDetails.get('subject');
            newCase.Description = caseDetails.get('description');
            newCase.Category__c = caseDetails.get('category'); 
            newCase.Subcategory__c = caseDetails.get('subcategory');
            newCase.Order_number__c = caseDetails.get('orderNumber'); // Champ Numéro de commande
            newCase.Origin = 'Web';
            newCase.ContactId = currentUser.ContactId;
            
            newCase.Client_segment__c = currentUser.Contact.Client_segment__c;
            newCase.Priority = (newCase.Client_segment__c == 'VIP') ? 'High' : 'Medium';

            if(String.isNotBlank(caseDetails.get('purchaseDate'))) {
                newCase.Date_d_achat__c = Date.valueOf(caseDetails.get('purchaseDate'));
            }
            newCase.Canal_d_achat__c = caseDetails.get('channel');
            newCase.Produit__c = caseDetails.get('productId');

            // Règle d'assignation
            List<AssignmentRule> arList = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
            if (!arList.isEmpty()) {
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = arList[0].Id;
                newCase.setOptions(dmlOpts);
            }

            insert newCase;
            return newCase.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMyProducts() {
        // Retour à la version initiale qui affiche les produits de l'objet personnalisé
        return [SELECT Id, Name FROM Product__c LIMIT 50];
    }
}