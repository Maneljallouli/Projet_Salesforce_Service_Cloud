public with sharing class SavCaseController {

    @AuraEnabled
    public static void createCase(Map<String, String> caseDetails) {
        // Vérification explicite pour le DML (PMD Security)
        if (!Schema.sObjectType.Case.isCreateable()) {
            throw new AuraHandledException('Permissions insuffisantes pour créer un ticket.');
        }

        try {
            String subject = caseDetails.get('subject');
            String description = caseDetails.get('description');
            String priority = caseDetails.get('priority');
            String type = caseDetails.get('type');

            // Utilisation de WITH USER_MODE pour respecter les règles CRUD/FLS automatiquement
            User currentUser = [
                SELECT Email 
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                WITH USER_MODE 
                LIMIT 1
            ];
            
            Id contactId = null;
            // Recherche du contact en mode utilisateur pour valider les accès
            List<Contact> matchingContacts = [
                SELECT Id 
                FROM Contact 
                WHERE Email = :currentUser.Email 
                WITH USER_MODE 
                LIMIT 1
            ];

            if (!matchingContacts.isEmpty()) {
                contactId = matchingContacts[0].Id;
            }
            
            Case newCase = new Case(
                Subject = subject,
                Description = description,
                Priority = priority,
                Type = type,
                Origin = 'Web',
                ContactId = contactId
            );
            
            // Insertion en mode utilisateur pour valider les droits de création
            Database.insert(newCase, AccessLevel.USER_MODE);
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur technique : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static UserInfoWrapper getMyContactInfo() {
        try {
            // Requête sécurisée avec WITH USER_MODE
            User u = [
                SELECT FirstName, LastName, Email, Phone, City 
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                WITH USER_MODE 
                LIMIT 1
            ];

            UserInfoWrapper wrapper = new UserInfoWrapper();
            wrapper.firstName = u.FirstName;
            wrapper.lastName = u.LastName;
            wrapper.email = u.Email;
            wrapper.phone = u.Phone;
            wrapper.city = u.City;
            
            return wrapper;
        } catch (Exception e) {
            throw new AuraHandledException('Accès au profil restreint ou erreur : ' + e.getMessage());
        }
    }

    public class UserInfoWrapper {
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String city;
    }
}