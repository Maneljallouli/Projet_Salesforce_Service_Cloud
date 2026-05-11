public without sharing class SavCaseController {

    @AuraEnabled
    public static String createCase(Map<String, String> caseDetails) {
        if (!Schema.sObjectType.Case.isCreateable()) {
            throw new AuraHandledException('Permissions insuffisantes.');
        }

        try {
            // Extraction des données du Map
            String sub = caseDetails.get('subject');
            String descr = caseDetails.get('description');
            String cat = caseDetails.get('category');
            String subCat = caseDetails.get('subcategory');
            String orderNum = caseDetails.get('orderNumber');
            String seg = caseDetails.get('segment');
            String prio = caseDetails.get('priority');

            // Lien avec le Contact via Email
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
            Id contactId = null;
            List<Contact> matchingContacts = [SELECT Id FROM Contact WHERE Email = :currentUser.Email WITH USER_MODE LIMIT 1];
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

            // --- DÉBUT DE LA RÈGLE D'ASSIGNATION ---
            // On récupère la règle d'assignation active sur l'objet Case
            AssignmentRule ar = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = true LIMIT 1];
            
            if (ar != null) {
                // Création de l'en-tête de DML pour activer la règle
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = ar.Id;
                dmlOpts.optAllOrNone = true; // Empêche l'insertion partielle
                
                // Application des options au Case
                newCase.setOptions(dmlOpts);
            }
            // --- FIN DE LA RÈGLE D'ASSIGNATION ---

            // Insertion (en utilisant Database.insert pour supporter les DMLOptions)
            Database.SaveResult sr = Database.insert(newCase, true);

            // Récupération du numéro de dossier pour le retour
            Case insertedCase = [SELECT CaseNumber FROM Case WHERE Id = :newCase.Id WITH USER_MODE];
            return insertedCase.CaseNumber;
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur technique : ' + e.getMessage());
        }
    }

    // Le reste du code (UserInfoWrapper, etc.) reste identique
    @AuraEnabled(cacheable=true)
    public static UserInfoWrapper getMyContactInfo() {
        User u = [SELECT FirstName, LastName, Email, Phone, City FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
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