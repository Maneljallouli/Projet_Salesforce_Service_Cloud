public with sharing class FAQController {

    @AuraEnabled(cacheable=true)
    public static List<FAQ__c> getFAQs(String lang) {
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