public without sharing class SavCaseController {

    @AuraEnabled
    public static String createCaseWithFile(Map<String, String> caseDetails, String fileName, String base64Data) {
        try {
            // Récupération du segment client
            User currentUser = [SELECT ContactId, Contact.Client_segment__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            Case newCase = new Case();
            newCase.Subject = caseDetails.get('subject');
            newCase.Description = caseDetails.get('description');
            newCase.Category__c = caseDetails.get('category'); 
            newCase.Subcategory__c = caseDetails.get('subcategory');
            newCase.Order_number__c = caseDetails.get('orderNumber');
            newCase.Origin = 'Web';
            newCase.ContactId = currentUser.ContactId;
            
            // Logique de priorité automatique
            newCase.Client_segment__c = currentUser.Contact.Client_segment__c;
            newCase.Priority = (newCase.Client_segment__c == 'VIP') ? 'High' : 'Medium';

            // Dates et Produit Personnalisé (Product__c)
            if(String.isNotBlank(caseDetails.get('purchaseDate'))) {
                newCase.Date_d_achat__c = Date.valueOf(caseDetails.get('purchaseDate'));
            }
            newCase.Canal_d_achat__c = caseDetails.get('channel');
            newCase.Produit__c = caseDetails.get('productId');

            insert newCase;

            // Création du fichier lié au Case
            if (String.isNotBlank(base64Data) && String.isNotBlank(fileName)) {
                ContentVersion cv = new ContentVersion();
                cv.Title = fileName;
                cv.PathOnClient = fileName;
                cv.VersionData = EncodingUtil.base64Decode(base64Data);
                cv.FirstPublishLocationId = newCase.Id; 
                insert cv;
            }

            return newCase.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMyProducts() {
        // Utilisation de ton objet personnalisé Product__c
        return [SELECT Id, Name FROM Product__c LIMIT 50];
    }
}