@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductController {

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMyProducts() {
        try {
            // 1. Récupération du ContactId lié à l'utilisateur connecté (Identique à CaseController)
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id contactId = currentUser.ContactId;

            // Si l'utilisateur n'est pas lié à un contact (ex: Admin), on retourne une liste vide
            if (contactId == null) {
                return new List<Product__c>();
            }

            // 2. Requête filtrée sur le champ Master-Detail 'Contact__c'
            return [
                SELECT Id, 
                       Name, 
                       Description__c, 
                       Price__c,
                       Image_URL__c, 
                       Collection__c
                FROM Product__c
                WHERE Contact__c = :contactId
                AND Is_Active__c = true
                ORDER BY Name ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la récupération des produits : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getCollections() {
        List<String> cols = new List<String>();
        cols.add('All');
        
        try {
            // Même logique de récupération du ContactId pour les filtres
            User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            if (u.ContactId != null) {
                for (AggregateResult ar : [
                    SELECT Collection__c col
                    FROM Product__c
                    WHERE Contact__c = :u.ContactId
                    AND Is_Active__c = true
                    GROUP BY Collection__c
                    ORDER BY Collection__c ASC
                ]) {
                    String colName = (String) ar.get('col');
                    if (String.isNotBlank(colName)) {
                        cols.add(colName);
                    }
                }
            }
        } catch (Exception e) {
            return cols;
        }
        return cols;
    }
}