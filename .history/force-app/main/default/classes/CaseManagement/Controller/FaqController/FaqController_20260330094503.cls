public without sharing class FAQController {

    @AuraEnabled(cacheable=true)
    public static List<FAQ__c> getFAQs(String lang) {
        // 1. Vérification CRUD manuelle pour apaiser PMD
        if (!Schema.sObjectType.FAQ__c.isAccessible()) {
            return new List<FAQ__c>(); // Retourne une liste vide au lieu de planter
        }

        String searchLang = (String.isNotBlank(lang)) ? lang.toUpperCase() : 'FR';

        return [
            SELECT Id, Question__c, Answer__c, Category__c
            FROM FAQ__c
            WHERE Language__c = :searchLang
            ORDER BY Category__c ASC, Question__c ASC
            LIMIT 100
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getFAQCategories(String lang) {
        // 1. Vérification CRUD manuelle pour apaiser PMD
        if (!Schema.sObjectType.FAQ__c.isAccessible()) {
            return new List<String>();
        }

        String searchLang = (String.isNotBlank(lang)) ? lang.toUpperCase() : 'FR';
        List<String> categories = new List<String>();
        
        // Correction de l'ordre : GROUP BY puis ORDER BY
        for (AggregateResult ar : [
            SELECT Category__c cat
            FROM FAQ__c
            WHERE Language__c = :searchLang
            GROUP BY Category__c
            ORDER BY Category__c ASC
        ]) {
            String catName = (String) ar.get('cat');
            if (String.isNotBlank(catName)) {
                categories.add(catName);
            }
        }
        return categories;
    }
}