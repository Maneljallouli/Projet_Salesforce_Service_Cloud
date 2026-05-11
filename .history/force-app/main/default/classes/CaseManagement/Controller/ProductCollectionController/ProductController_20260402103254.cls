@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductController {

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMyProducts() {
        try {
            // 1. Récupérer les infos de l'utilisateur session (Id Contact et Email)
            User currentUser = [SELECT ContactId, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            Id targetContactId = currentUser.ContactId;

            // 2. Si le lien direct ContactId est vide, on cherche par l'Email
            if (targetContactId == null) {
                List<Contact> matchingContacts = [SELECT Id FROM Contact WHERE Email = :currentUser.Email LIMIT 1];
                if (!matchingContacts.isEmpty()) {
                    targetContactId = matchingContacts[0].Id;
                }
            }

            // 3. Si on n'a toujours pas de contact, on arrête pour éviter d'afficher tous les produits
            if (targetContactId == null) {
                return new List<Product__c>();
            }

            // 4. Requête filtrée sur le champ Master-Detail 'Contact__c'
            // On s'assure que le produit est actif pour l'affichage
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
            throw new AuraHandledException('Erreur de chargement des produits : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getCollections() {
        List<String> collections = new List<String>{'All'};
        try {
            // On réutilise la même logique de filtrage pour les catégories du menu
            User u = [SELECT ContactId, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id cid = u.ContactId;
            
            if (cid == null) {
                List<Contact> con = [SELECT Id FROM Contact WHERE Email = :u.Email LIMIT 1];
                if (!con.isEmpty()) cid = con[0].Id;
            }

            if (cid != null) {
                for (AggregateResult ar : [
                    SELECT Collection__c col 
                    FROM Product__c 
                    WHERE Contact__c = :cid AND Is_Active__c = true 
                    GROUP BY Collection__c
                ]) {
                    String val = (String) ar.get('col');
                    if (String.isNotBlank(val)) collections.add(val);
                }
            }
        } catch (Exception e) {
            return collections;
        }
        return collections;
    }
}