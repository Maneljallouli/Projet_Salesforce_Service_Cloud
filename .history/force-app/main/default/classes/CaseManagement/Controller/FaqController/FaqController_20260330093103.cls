public without sharing class FAQController {

    @AuraEnabled(cacheable=true)
    public static List<FAQ__c> getFAQs(String lang) {
        // On rend la recherche insensible à la casse (fr vs FR)
        String langUpper = (lang != null) ? lang.toUpperCase() : 'FR';

        // On retire la vérification Schema.isAccessible() qui bloque souvent 
        // les utilisateurs Guest/External sur Experience Cloud
        return [
            SELECT Id, Question__c, Answer__c, Category__c
            FROM FAQ__c
            WHERE Language__c = :langUpper
            ORDER BY Category__c ASC, Question__c ASC
            LIMIT 100
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getFAQCategories(String lang) {
        String langUpper = (lang != null) ? lang.toUpperCase() : 'FR';
        
        List<String> cats = new List<String>();
        for (AggregateResult ar : [
            SELECT Category__c cat
            FROM FAQ__c
            WHERE Language__c = :langUpper
            GROUP BY Category__c
            ORDER BY Category__c ASC
        ]) {
            String categoryName = (String) ar.get('cat');
            if (String.isNotBlank(categoryName)) {
                cats.add(categoryName);
            }
        }
        return cats;
    }
}