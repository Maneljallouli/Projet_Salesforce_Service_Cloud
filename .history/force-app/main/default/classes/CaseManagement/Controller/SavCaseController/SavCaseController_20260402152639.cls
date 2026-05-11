public without sharing class SavCaseController {

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMyProducts() {
        // 1. Récupérer le ContactId de l'utilisateur connecté
        User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        if (currentUser.ContactId == null) {
            return new List<Product__c>();
        }

        // 2. Retourner uniquement les produits liés à ce contact
        return [SELECT Id, Name 
                FROM Product__c 
                WHERE Contact__c = :currentUser.ContactId 
                LIMIT 50];
    }

    @AuraEnabled
    public static String createCase(Map<String, String> caseDetails) {
        try {
            User currentUser = [SELECT ContactId, Contact.Client_segment__c 
                                FROM User 
                                WHERE Id = :UserInfo.getUserId() 
                                LIMIT 1];
            
            Case newCase = new Case();
            newCase.Subject = caseDetails.get('subject');
            newCase.Description = caseDetails.get('description');
            newCase.Category__c = caseDetails.get('category'); 
            newCase.Subcategory__c = caseDetails.get('subcategory');
            newCase.Order_number__c = caseDetails.get('orderNumber');
            newCase.Origin = 'Web';
            newCase.ContactId = currentUser.ContactId;
            newCase.Produit__c = caseDetails.get('productId');
            
            // --- AJOUT DES CHAMPS MANQUANTS ---
            if(String.isNotBlank(caseDetails.get('purchaseDate'))) {
                newCase.Date_d_achat__c = Date.valueOf(caseDetails.get('purchaseDate'));
            }
            newCase.Canal_d_achat__c = caseDetails.get('channel');
            // ----------------------------------

            newCase.Client_segment__c = currentUser.Contact.Client_segment__c;
            newCase.Priority = (newCase.Client_segment__c == 'VIP') ? 'High' : 'Medium';

            // Insertion du Case
            insert newCase;

            // CRITIQUE : On récupère le CaseNumber APRES l'insertion
            Case insertedCase = [SELECT CaseNumber FROM Case WHERE Id = :newCase.Id LIMIT 1];
            
            // On retourne le numéro de dossier (ex: 00001024) au LWC
            return insertedCase.CaseNumber; 

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}