public without sharing class FAQController {

    @AuraEnabled(cacheable=true)
    public static List<FAQ__c> getFAQs(String lang) {
        // Protection contre les valeurs nulles et gestion de la casse
        String searchLang = (String.isNotBlank(lang)) ? lang.toUpperCase() : 'FR';

        // L'utilisation de "WITH USER_MODE" indique à PMD que vous déléguez 
        // la sécurité au moteur Salesforce, ce qui valide la règle ApexCRUDViolation.
        return [
            SELECT Id, Question__c, Answer__c, Category__c
            FROM FAQ__c
            WHERE Language__c = :searchLang
            WITH USER_MODE
            ORDER BY Category__c ASC, Question__c ASC
            LIMIT 100
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getFAQCategories(String lang) {
        String searchLang = (String.isNotBlank(lang)) ? lang.toUpperCase() : 'FR';
        
        List<String> categories = new List<String>();
        
        // Ajout de WITH USER_MODE ici aussi pour PMD
        List<AggregateResult> results = [
            SELECT Category__c cat
            FROM FAQ__c
            WHERE Language__c = :searchLang
            GROUP BY Category__c
            WITH USER_MODE
            ORDER BY Category__c ASC
        ];

        for (AggregateResult ar : results) {
            String catName = (String) ar.get('cat');
            if (String.isNotBlank(catName)) {
                categories.add(catName);
            }
        }
        return categories;
    }
}