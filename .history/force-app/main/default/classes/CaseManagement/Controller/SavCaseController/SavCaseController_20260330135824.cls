public with sharing class SavCaseController {

    @AuraEnabled
    public static String createCase(Map<String, String> caseDetails) {
        // Vérification des permissions de création pour la sécurité (PMD)
        if (!Schema.sObjectType.Case.isCreateable()) {
            throw new AuraHandledException('Permissions insuffisantes pour créer un ticket.');
        }

        try {
            // Extraction des valeurs depuis le Map envoyé par le JS
            String sub = caseDetails.get('subject');
            String descr = caseDetails.get('description');
            String cat = caseDetails.get('category');
            String subCat = caseDetails.get('subcategory');
            String orderNum = caseDetails.get('orderNumber');
            String seg = caseDetails.get('segment');
            String prio = caseDetails.get('priority');

            // Récupération de l'email de l'utilisateur avec USER_MODE pour la sécurité
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
            
            Id contactId = null;
            // Recherche du contact correspondant pour l'assignation automatique
            List<Contact> matchingContacts = [SELECT Id FROM Contact WHERE Email = :currentUser.Email WITH USER_MODE LIMIT 1];
            if (!matchingContacts.isEmpty()) {
                contactId = matchingContacts[0].Id;
            }
            
            // Initialisation du Case avec tous les champs mentionnés
            Case newCase = new Case();
            newCase.Subject = sub;
            newCase.Description = descr;
            newCase.ContactId = contactId;
            newCase.Priority = prio;
            newCase.Origin = 'Web';
            
            // Mapping des champs personnalisés spécifiques à ton projet
            newCase.Category__c = cat; 
            newCase.Subcategory__c = subCat;
            newCase.Order_number__c = orderNum;
            newCase.Client_segment__c = seg;
            
            // Insertion sécurisée
            Database.insert(newCase, AccessLevel.USER_MODE);

            // Récupération du numéro de Case généré par Salesforce pour le renvoyer au LWC
            Case insertedCase = [SELECT CaseNumber FROM Case WHERE Id = :newCase.Id WITH USER_MODE];
            return insertedCase.CaseNumber;
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur technique : ' + e.getMessage());
        }
    }

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