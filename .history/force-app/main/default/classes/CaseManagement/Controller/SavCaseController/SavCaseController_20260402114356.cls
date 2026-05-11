public without sharing class SavCaseController {

    @AuraEnabled
    public static String createCase(Map<String, String> caseDetails) {
        try {
            // Extraction des données de la Map
            String sub = caseDetails.get('subject');
            String descr = caseDetails.get('description');
            String cat = caseDetails.get('category');
            String subCat = caseDetails.get('subcategory');
            String orderNum = caseDetails.get('orderNumber');
            String seg = caseDetails.get('segment');
            String prio = caseDetails.get('priority');
            
            // Nouveaux champs
            String purchaseDate = caseDetails.get('purchaseDate');
            String channel = caseDetails.get('channel');
            String productId = caseDetails.get('productId');

            // Récupération de l'email de l'utilisateur courant
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            Id contactId = null;
            List<Contact> matchingContacts = [SELECT Id FROM Contact WHERE Email = :currentUser.Email LIMIT 1];
            if (!matchingContacts.isEmpty()) {
                contactId = matchingContacts[0].Id;
            }
            
            // Création de l'objet Case
            Case newCase = new Case();
            newCase.Subject = sub;
            newCase.Description = descr;
            newCase.ContactId = contactId;
            newCase.Priority = prio;
            newCase.Origin = 'Web';
            newCase.Category__c = cat; 
            newCase.Subcategory__c = subCat;
            newCase.Order_number__c = orderNum;
            newCase.Client_segment__c = seg;
            
            // Assignation des nouveaux champs
            if(String.isNotBlank(purchaseDate)) {
                newCase.Date_d_achat__c = Date.valueOf(purchaseDate);
            }
            newCase.Purchase_Channel__c = channel;
            newCase.Product_Concerned__c = productId;

            // Règle d'assignation
            List<AssignmentRule> arList = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
            if (!arList.isEmpty()) {
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = arList[0].Id;
                newCase.setOptions(dmlOpts);
            }

            insert newCase;
            
            // On retourne l'ID pour que le LWC puisse y attacher des fichiers
            return newCase.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static UserInfoWrapper getMyContactInfo() {
        User u = [SELECT FirstName, LastName, Email, Phone, City FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        UserInfoWrapper wrapper = new UserInfoWrapper();
        wrapper.firstName = u.FirstName;
        wrapper.lastName = u.LastName;
        wrapper.email = u.Email;
        wrapper.phone = u.Phone;
        wrapper.city = u.City;
        return wrapper;
    }

    public class UserInfoWrapper {
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String city;
    }
}