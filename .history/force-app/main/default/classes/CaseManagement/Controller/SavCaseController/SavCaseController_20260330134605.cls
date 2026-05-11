public with sharing class SavCaseController {

    /**
     * Crée un Case et l'assigne automatiquement au Contact qui a le même email que l'User connecté
     */
    @AuraEnabled
    public static void createCase(String subject, String description, String priority, String type) {
        try {
            // 1. Récupérer l'email de l'utilisateur qui clique sur "Envoyer"
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            // 2. Chercher le contact qui possède cet email
            List<Contact> matchingContacts = [SELECT Id FROM Contact WHERE Email = :currentUser.Email LIMIT 1];
            
            Case newCase = new Case();
            newCase.Subject = subject;
            newCase.Description = description;
            newCase.Priority = priority;
            newCase.Type = type;
            newCase.Origin = 'Web'; // Origine pour ton portail Luxe

            // 3. Liaison cruciale : si l'email correspond, on lie le Case au Contact
            if (!matchingContacts.isEmpty()) {
                newCase.ContactId = matchingContacts[0].Id;
            }
            
            insert newCase;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la création du ticket : ' + e.getMessage());
        }
    }

    /**
     * Récupère les infos de l'User pour alimenter le Header (Nom, Email, Tel, Ville)
     */
    @AuraEnabled(cacheable=true)
    public static UserInfoWrapper getMyContactInfo() {
        try {
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
        } catch (Exception e) {
            throw new AuraHandledException('Erreur profil : ' + e.getMessage());
        }
    }

    // Classe interne pour structurer les données envoyées au JS
    public class UserInfoWrapper {
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String city;
    }
}