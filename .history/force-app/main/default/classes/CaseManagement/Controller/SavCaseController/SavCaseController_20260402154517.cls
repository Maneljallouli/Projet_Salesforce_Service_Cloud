public without sharing class SavCaseController {

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMyProducts() {
        User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        if (currentUser.ContactId == null) {
            return new List<Product__c>();
        }
        return [SELECT Id, Name FROM Product__c WHERE Contact__c = :currentUser.ContactId LIMIT 50];
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
            
            if(String.isNotBlank(caseDetails.get('purchaseDate'))) {
                newCase.Date_d_achat__c = Date.valueOf(caseDetails.get('purchaseDate'));
            }
            newCase.Canal_d_achat__c = caseDetails.get('channel');

            newCase.Client_segment__c = currentUser.Contact.Client_segment__c;
            newCase.Priority = (newCase.Client_segment__c == 'VIP') ? 'High' : 'Medium';

            insert newCase;

            // --- AJOUT : CRÉATION DU FICHIER DANS LA MÊME TRANSACTION ---
            String base64 = caseDetails.get('fileBase64');
            String fName = caseDetails.get('fileName');

            if (String.isNotBlank(base64) && String.isNotBlank(fName)) {
                ContentVersion cv = new ContentVersion();
                cv.Title = fName;
                cv.PathOnClient = fName;
                cv.VersionData = EncodingUtil.base64Decode(base64);
                cv.FirstPublishLocationId = newCase.Id; // Liaison directe
                insert cv;
            }
            // ----------------------------------------------------------

            Case insertedCase = [SELECT CaseNumber FROM Case WHERE Id = :newCase.Id LIMIT 1];
            return insertedCase.CaseNumber; 

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}