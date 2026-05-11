public with sharing class ProductController {

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getProducts(String collection) {
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
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getCollections() {
        List<String> cols = new List<String>();
        cols.add('All');
        for (AggregateResult ar : [
            SELECT Collection__c col
            FROM Product__c
            WHERE Is_Active__c = true
            GROUP BY Collection__c
            ORDER BY Collection__c ASC
        ]) {
            cols.add((String) ar.get('col'));
        }
        return cols;
    }
}