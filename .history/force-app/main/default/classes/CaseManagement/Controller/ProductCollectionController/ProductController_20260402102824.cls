@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductController {

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMyProducts() {
        try {
            // Récupération du ContactId de l'utilisateur connecté (Walid)
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id cid = currentUser.ContactId;

            // Si Walid n'est pas lié à un contact, on ne renvoie rien
            if (cid == null) {
                return new List<Product__c>();
            }

            // Requête filtrée sur le nouveau champ de relation
            return [
                SELECT Id, Name, Description__c, Price__c,
                       Image_URL__c, Collection__c
                FROM Product__c
                WHERE Owner_Contact__c = :cid
                AND Is_Active__c = true
                ORDER BY Name ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }
}