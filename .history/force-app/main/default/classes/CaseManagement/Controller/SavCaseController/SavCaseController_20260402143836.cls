public without sharing class SavCaseController {

    @AuraEnabled
    public static String createCase(Map<String, String> caseDetails) {
        try {
            // 1. Récupération de l'utilisateur avec les infos de son Contact
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
            newCase.Origin = 'Web';
            newCase.ContactId = currentUser.ContactId;
            
            // Assignation automatique du Segment depuis le Contact
            newCase.Client_segment__c = currentUser.Contact.Client_segment__c;
            
            // Priorité automatique : Haute pour VIP, Moyenne pour les autres
            newCase.Priority = (newCase.Client_segment__c == 'VIP') ? 'High' : 'Medium';

            // Champs de garantie et produit
            if(String.isNotBlank(caseDetails.get('purchaseDate'))) {
                newCase.Date_d_achat__c = Date.valueOf(caseDetails.get('purchaseDate'));
            }
            newCase.Canal_d_achat__c = caseDetails.get('channel');
            newCase.Produit__c = caseDetails.get('productId');

            // Règle d'assignation (pour envoyer vers la file d'attente SAV)
            List<AssignmentRule> arList = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
            if (!arList.isEmpty()) {
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = arList[0].Id;
                newCase.setOptions(dmlOpts);
            }

            insert newCase;
            
            // Retourne l'ID pour le composant de téléchargement de fichiers
            return newCase.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMyProducts() {
        // Optionnel : si tu n'as pas encore de ProductController séparé
        return [SELECT Id, Name FROM Product__c LIMIT 50];
    }
}