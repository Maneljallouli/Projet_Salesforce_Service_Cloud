public with sharing class SavCaseController {

    @AuraEnabled
    public static void createCase(Map<String, String> caseDetails) {
        // Vérification de sécurité CRUD pour la création
        if (!Schema.sObjectType.Case.isCreateable()) {
            throw new AuraHandledException('Permissions insuffisantes pour créer un ticket.');
        }

        try {
            String subject = caseDetails.get('subject');
            String description = caseDetails.get('description');
            String priority = caseDetails.get('priority');
            String type = caseDetails.get('type');

            // Récupération de l'email de l'utilisateur connecté
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            Id contactId = null;
            // Vérification de sécurité CRUD pour la lecture des contacts
            if (Schema.sObjectType.Contact.isAccessible()) {
                List<Contact> matchingContacts = [SELECT Id FROM Contact WHERE Email = :currentUser.Email LIMIT 1];
                if (!matchingContacts.isEmpty()) {
                    contactId = matchingContacts[0].Id;
                }
            }
            
            Case newCase = new Case(
                Subject = subject,
                Description = description,
                Priority = priority,
                Type = type,
                Origin = 'Web',
                ContactId = contactId
            );
            
            insert newCase;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur technique : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static UserInfoWrapper getMyContactInfo() {
        // Vérification de sécurité CRUD pour l'objet User
        if (!Schema.sObjectType.User.isAccessible()) {
            throw new AuraHandledException('Accès au profil restreint.');
        }

        User u = [SELECT FirstName, LastName, Email, Phone, City 
                  FROM User 
                  WHERE Id = :UserInfo.getUserId() 
                  LIMIT 1];

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