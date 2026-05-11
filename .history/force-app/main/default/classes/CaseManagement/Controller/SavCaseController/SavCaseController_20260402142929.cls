public without sharing class SavCaseController {

    @AuraEnabled
    public static String createCase(Map<String, String> caseDetails) {
        try {
            // Extraction des données
            String sub = caseDetails.get('subject');
            String descr = caseDetails.get('description');
            String cat = caseDetails.get('category');
            String subCat = caseDetails.get('subcategory');
            String orderNum = caseDetails.get('orderNumber');
            // On conserve "seg" et "prio" au cas où ils seraient passés, 
            // mais on va privilégier la donnée du Contact ci-dessous.
            String seg = caseDetails.get('segment');
            String prio = caseDetails.get('priority');
            
            // Nouveaux champs
            String purchaseDate = caseDetails.get('purchaseDate');
            String channel = caseDetails.get('channel');
            String productId = caseDetails.get('productId');

            // Récupération de l'utilisateur courant et de son segment client via le Contact
            User currentUser = [SELECT Email, ContactId, Contact.Client_segment__c 
                                FROM User 
                                WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            Id contactId = currentUser.ContactId;
            String clientSegment = currentUser.Contact.Client_segment__c;

            // Si le contact n'est pas lié à l'utilisateur, on tente la recherche par email (ton code original)
            if (contactId == null) {
                List<Contact> matchingContacts = [SELECT Id, Client_segment__c FROM Contact WHERE Email = :currentUser.Email LIMIT 1];
                if (!matchingContacts.isEmpty()) {
                    contactId = matchingContacts[0].Id;
                    clientSegment = matchingContacts[0].Client_segment__c;
                }
            }
            
            // Création de l'objet Case
            Case newCase = new Case();
            newCase.Subject = sub;
            newCase.Description = descr;
            newCase.ContactId = contactId;
            
            // Assignation automatique du segment récupéré depuis le Contact
            newCase.Client_segment__c = (clientSegment != null) ? clientSegment : seg;
            
            // Logique de priorité basée sur le segment
            if(newCase.Client_segment__c == 'VIP') {
                newCase.Priority = 'High';
            } else {
                newCase.Priority = (prio != null) ? prio : 'Medium';
            }

            newCase.Origin = 'Web';
            newCase.Category__c = cat; 
            newCase.Subcategory__c = subCat;
            newCase.Order_number__c = orderNum;
            
            // Assignation des champs personnalisés (Noms en Français)
            if(String.isNotBlank(purchaseDate)) {
                newCase.Date_d_achat__c = Date.valueOf(purchaseDate);
            }
            newCase.Canal_d_achat__c = channel;
            newCase.Produit__c = productId;

            // Règle d'assignation
            List<AssignmentRule> arList = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
            if (!arList.isEmpty()) {
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = arList[0].Id;
                newCase.setOptions(dmlOpts);
            }

            insert newCase;
            
            // Retourne l'ID pour le composant lightning-file-upload
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