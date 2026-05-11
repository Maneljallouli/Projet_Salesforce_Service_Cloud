@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductController {

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMyProducts() { // Renommé pour plus de clarté
        try {
            // 1. Récupérer le ContactId de l'utilisateur Walid Jallouli connecté
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id contactId = currentUser.ContactId;

            if (contactId == null) {
                return new List<Product__c>();
            }

            // 2. Filtrer les produits appartenant à ce contact spécifique
            // Remplace 'Owner_Contact__c' par le nom exact de ton champ de relation
            return [
                SELECT Id, Name, Description__c, Price__c,
                       Image_URL__c, Collection__c
                FROM Product__c
                WHERE Owner_Contact__c = :contactId
                AND Is_Active__c = true
                ORDER BY Name ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }
}