public with sharing class SavCaseController {

    @AuraEnabled
    public static String createCase(Map<String, String> caseDetails) {
        try {
            // Utilisation de "with security enforced" pour PMD
            User currentUser = [SELECT ContactId, Contact.Client_segment__c 
                                FROM User 
                                WHERE Id = :UserInfo.getUserId() 
                                WITH SECURITY_ENFORCED
                                LIMIT 1];
            
            Case newCase = new Case();
            newCase.Subject = caseDetails.get('subject');
            newCase.Description = caseDetails.get('description');
            newCase.Category__c = caseDetails.get('category'); 
            newCase.Subcategory__c = caseDetails.get('subcategory');
            newCase.Order_number__c = caseDetails.get('orderNumber');
            newCase.Origin = 'Web';
            newCase.ContactId = currentUser.ContactId;
            
            newCase.Client_segment__c = currentUser.Contact.Client_segment__c;
            newCase.Priority = (newCase.Client_segment__c == 'VIP') ? 'High' : 'Medium';

            if(String.isNotBlank(caseDetails.get('purchaseDate'))) {
                newCase.Date_d_achat__c = Date.valueOf(caseDetails.get('purchaseDate'));
            }
            newCase.Canal_d_achat__c = caseDetails.get('channel');
            newCase.Produit__c = caseDetails.get('productId');

            // Vérification des règles d'assignation
            List<AssignmentRule> arList = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
            if (!arList.isEmpty()) {
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = arList[0].Id;
                newCase.setOptions(dmlOpts);
            }

            // Insertion sécurisée
            if (Schema.sObjectType.Case.isCreateable()) {
                insert newCase;
            } else {
                throw new AuraHandledException('Permissions insuffisantes pour créer un dossier.');
            }
            
            return newCase.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMyProducts() {
        // On récupère le contact de l'utilisateur
        User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
        
        // CORRECTION ICI : Remplace 'Contact__c' par le vrai nom de ton champ de relation
        // si Salesforce renvoie encore une erreur.
        return [SELECT Id, Name 
                FROM Product__c 
                WHERE Contact__c = :u.ContactId 
                WITH SECURITY_ENFORCED 
                LIMIT 50];
    }
}