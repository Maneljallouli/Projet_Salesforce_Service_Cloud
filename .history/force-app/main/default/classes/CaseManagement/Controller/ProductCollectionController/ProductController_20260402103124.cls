@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductController {

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMyProducts() {
        try {
            // 1. Récupérer l'email de l'utilisateur connecté (ex: Walid Jallouli)
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            String userEmail = currentUser.Email;

            // 2. Trouver le contact qui possède cet email
            List<Contact> matchingContacts = [SELECT Id FROM Contact WHERE Email = :userEmail LIMIT 1];
            
            if (matchingContacts.isEmpty()) {
                return new List<Product__c>();
            }
            
            Id targetContactId = matchingContacts[0].Id;

            // 3. Filtrer les produits (sacs) liés à ce contact via le champ Master-Detail
            return [
                SELECT Id, 
                       Name, 
                       Description__c, 
                       Price__c,
                       Image_URL__c, 
                       Collection__c
                FROM Product__c
                WHERE Contact__c = :targetContactId
                AND Is_Active__c = true
                ORDER BY Name ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Erreur de récupération : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getMyCollections() {
        List<String> cols = new List<String>{'All'};
        try {
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            // On récupère les collections via l'email pour la cohérence
            List<Contact> matchingContacts = [SELECT Id FROM Contact WHERE Email = :currentUser.Email LIMIT 1];
            if (matchingContacts.isEmpty()) return cols;

            for (AggregateResult ar : [
                SELECT Collection__c col
                FROM Product__c
                WHERE Contact__c = :matchingContacts[0].Id
                AND Is_Active__c = true
                GROUP BY Collection__c
            ]) {
                String val = (String) ar.get('col');
                if (String.isNotBlank(val)) cols.add(val);
            }
        } catch (Exception e) {
            return cols;
        }
        return cols;
    }
}