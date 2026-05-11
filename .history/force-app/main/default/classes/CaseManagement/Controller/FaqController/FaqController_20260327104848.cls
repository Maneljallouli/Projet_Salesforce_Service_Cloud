public with sharing class FAQController {

    @AuraEnabled(cacheable=true)
    public static List<FAQ__c> getFAQs(String lang) {

        // Vérification CRUD (READ) sur FAQ__c
        if (!Schema.sObjectType.FAQ__c.isAccessible()) {
            throw new AuraHandledException('Accès refusé à FAQ__c');
        }

        return [
            SELECT Id, Question__c, Answer__c, Category__c
            FROM FAQ__c
            WHERE Language__c = :lang
            ORDER BY Category__c ASC, Question__c ASC
            LIMIT 100
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getFAQCategories(String lang) {

        // Vérification CRUD (READ) sur FAQ__c
        if (!Schema.sObjectType.FAQ__c.isAccessible()) {
            throw new AuraHandledException('Accès refusé à FAQ__c');
        }

        List<String> cats = new List<String>();
        for (AggregateResult ar : [
            SELECT Category__c cat
            FROM FAQ__c
            WHERE Language__c = :lang
            GROUP BY Category__c
            ORDER BY Category__c ASC
        ]) {
            cats.add((String) ar.get('cat'));
        }
        return cats;
    }
}