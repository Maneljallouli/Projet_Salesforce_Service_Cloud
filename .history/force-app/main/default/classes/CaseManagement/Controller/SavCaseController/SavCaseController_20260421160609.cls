public without sharing class SavCaseController {

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMyProducts() {
        // Recherche par Email pour s'assurer que le 2ème client voit ses produits
        User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        List<Contact> relatedContacts = [SELECT Id FROM Contact WHERE Email = :currentUser.Email LIMIT 1];
        
        if (relatedContacts.isEmpty()) {
            return new List<Product__c>();
        }

        Id targetContactId = relatedContacts[0].Id;
        
        return [SELECT Id, Name FROM Product__c WHERE Contact__c = :targetContactId LIMIT 50];
    }

    @AuraEnabled
    public static String createCase(Map<String, String> caseDetails) {
        try {
            // Récupération de l'Email et du segment via le Contact lié à l'email
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            Contact ctc = [SELECT Id, Client_segment__c FROM Contact WHERE Email = :currentUser.Email LIMIT 1];
            
            Case newCase = new Case();
            newCase.Subject = caseDetails.get('subject');
            newCase.Description = caseDetails.get('description');
            newCase.Category__c = caseDetails.get('category'); 
            newCase.Subcategory__c = caseDetails.get('subcategory');
            newCase.Order_number__c = caseDetails.get('orderNumber');
            newCase.Origin = 'Web';
            newCase.ContactId = ctc.Id; // Liaison via le contact trouvé par email
            newCase.Produit__c = caseDetails.get('productId');
            
            if(String.isNotBlank(caseDetails.get('purchaseDate'))) {
                newCase.Date_d_achat__c = Date.valueOf(caseDetails.get('purchaseDate'));
            }
            newCase.Canal_d_achat__c = caseDetails.get('channel');

            newCase.Client_segment__c = ctc.Client_segment__c;
            newCase.Priority = (newCase.Client_segment__c == 'VIP') ? 'High' : 'Medium';

            insert newCase;

            // 🔥 AJOUTEZ CES 4 LIGNES POUR DÉCLENCHER AGENTFORCE
            Map<String,Object> flowInputs = new Map<String,Object>();
            flowInputs.put('CaseId', newCase.Id);
            Flow.Interview.Run_Agentforce agentFlow = new Flow.Interview.Run_Agentforce(flowInputs);
            agentFlow.start();

            Case insertedCase = [SELECT CaseNumber FROM Case WHERE Id = :newCase.Id LIMIT 1];
            return insertedCase.CaseNumber; 

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}