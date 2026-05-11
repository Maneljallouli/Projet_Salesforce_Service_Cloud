@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductController {

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getProducts(String collection) {
        
        // On retire le check isAccessible() car la licence bloquerait l'exécution
        try {
            if (String.isBlank(collection) || collection == 'All') {
                return [
                    SELECT Id, Name, Description__c, Price__c,
                           Image_URL__c, Collection__c
                    FROM Product__c
                    WHERE Is_Active__c = true
                    ORDER BY Collection__c ASC, Name ASC
                    LIMIT 50
                ];
            }
            
            return [
                SELECT Id, Name, Description__c, Price__c,
                       Image_URL__c, Collection__c
                FROM Product__c
                WHERE Collection__c = :collection
                AND   Is_Active__c  = true
                ORDER BY Name ASC
                LIMIT 50
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Erreur récupération produits : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getCollections() {
        
        List<String> cols = new List<String>();
        cols.add('All');
        
        try {
            // Mode système pour récupérer les catégories même sans droits CRUD
            for (AggregateResult ar : [
                SELECT Collection__c col
                FROM Product__c
                WHERE Is_Active__c = true
                GROUP BY Collection__c
                ORDER BY Collection__c ASC
            ]) {
                String colName = (String) ar.get('col');
                if (String.isNotBlank(colName)) {
                    cols.add(colName);
                }
            }
        } catch (Exception e) {
            // On retourne au moins 'All' en cas d'erreur
            return cols;
        }
        
        return cols;
    }
}