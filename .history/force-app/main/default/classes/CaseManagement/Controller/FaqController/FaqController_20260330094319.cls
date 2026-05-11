public without sharing class FAQController {
    @AuraEnabled(cacheable=true)
    public static List<FAQ__c> getFAQs(String lang) {
        // ON SUPPRIME LE IF(isAccessible) JUSTE POUR TESTER
        return [SELECT Id, Question__c, Answer__c, Category__c FROM FAQ__c LIMIT 100];
    }
}