@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductController {

    /**
     * Récupère uniquement les produits (sacs) appartenant au contact connecté
     */
    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMyProducts() {
        try {
            // 1. Identification du contact lié à l'utilisateur Walid Jallouli
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id cid = currentUser.ContactId;

            // Sécurité : si aucun contact n'est lié (ex: Admin système), on ne renvoie rien
            if (cid == null) {
                return new List<Product__c>();
            }

            // 2. Requête filtrée sur votre champ Master-Detail 'Contact__c'
            return [
                SELECT Id, 
                       Name, 
                       Description__c, 
                       Price__c,
                       Image_URL__c, 
                       Collection__c
                FROM Product__c
                WHERE Contact__c = :cid
                AND Is_Active__c = true
                ORDER BY Name ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Erreur technique : ' + e.getMessage());
        }
    }

    /**
     * Utile pour afficher les catégories de sacs possédés par le client
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getMyCollections() {
        List<String> cols = new List<String>{'All'};
        try {
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            for (AggregateResult ar : [
                SELECT Collection__c col
                FROM Product__c
                WHERE Contact__c = :currentUser.ContactId
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