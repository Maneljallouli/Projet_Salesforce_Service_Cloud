public without sharing class SavCaseController {

    @AuraEnabled
    public static String createCase(Map<String, String> caseDetails) {
        // 1. SUPPRESSION du check isCreateable() 
        // Car la licence External Apps renverra toujours 'false' même en without sharing.

        try {
            // Extraction des données
            String sub = caseDetails.get('subject');
            String descr = caseDetails.get('description');
            String cat = caseDetails.get('category');
            String subCat = caseDetails.get('subcategory');
            String orderNum = caseDetails.get('orderNumber');
            String seg = caseDetails.get('segment');
            String prio = caseDetails.get('priority');

            // 2. SUPPRESSION de WITH USER_MODE dans les requêtes SOQL
            // On récupère l'email de l'utilisateur courant en mode système
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            Id contactId = null;
            List<Contact> matchingContacts = [SELECT Id FROM Contact WHERE Email = :currentUser.Email LIMIT 1];
            if (!matchingContacts.isEmpty()) {
                contactId = matchingContacts[0].Id;
            }
            
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

            // --- RÈGLE D'ASSIGNATION ---
            List<AssignmentRule> arList = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
            
            if (!arList.isEmpty()) {
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = arList[0].Id;
                dmlOpts.optAllOrNone = true;
                newCase.setOptions(dmlOpts);
            }

            // 3. INSERTION en mode système
            Database.SaveResult sr = Database.insert(newCase, true);

            // 4. RÉCUPÉRATION du numéro (sans USER_MODE)
            Case insertedCase = [SELECT CaseNumber FROM Case WHERE Id = :newCase.Id LIMIT 1];
            return insertedCase.CaseNumber;
            
        } catch (Exception e) {
            // On renvoie une erreur plus précise pour le debug
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static UserInfoWrapper getMyContactInfo() {
        // Suppression du WITH USER_MODE ici aussi pour assurer la lecture
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