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
            User currentUser = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
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

            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;
            newCase.setOptions(dmo);

            insert newCase;

            // La partie "File" a été supprimée ici conformément à ta demande.

            Case insertedCase = [SELECT CaseNumber, Status FROM Case WHERE Id = :newCase.Id LIMIT 1];

            User_Notification__c notif = new User_Notification__c(
                User__c = currentUser.Id,
                Case__c = newCase.Id,
                Message__c = 'Votre demande #' + insertedCase.CaseNumber + ' a bien été créée et assignée à notre équipe.',
                Status__c = insertedCase.Status,
                Is_Read__c = false
            );
            Database.insert(notif, AccessLevel.SYSTEM_MODE);

            return insertedCase.CaseNumber; 

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}