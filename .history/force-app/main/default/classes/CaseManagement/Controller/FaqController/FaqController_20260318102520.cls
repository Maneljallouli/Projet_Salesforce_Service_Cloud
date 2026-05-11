/**
 * @class       FaqController
 * @description Controller optimisé pour Knowledge avec correction de syntaxe SOQL
 * Version 1.3 - Fix SOQL Aggregate Syntax
 */
public with sharing class FaqController {

    private static final Map<String, String> LANG_MAP = new Map<String, String>{
        'fr' => 'fr',
        'en' => 'en_US',
        'ar' => 'ar'
    };

    // --- WRAPPERS ---
    public class ArticleDetailWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String body { get; set; }
        @AuraEnabled public String summary { get; set; }
        @AuraEnabled public DateTime lastPublished { get; set; }
    }

    public class CategoryWrapper {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public Integer articleCount { get; set; }
    }

    // --- LOGIQUE DE RÉCUPÉRATION ---

    @AuraEnabled(cacheable=true)
    public static List<CategoryWrapper> getFaqCategories(String langue) {
        String sfLang = resolveLang(langue);
        List<CategoryWrapper> cats = new List<CategoryWrapper>();
        
        // CORRECTION : WITH USER_MODE doit être AVANT le GROUP BY
        AggregateResult[] grouped = [
            SELECT DataCategoryName, COUNT(ParentId) cnt
            FROM Knowledge__DataCategorySelection
            WHERE Parent.PublishStatus = 'online'
            AND Parent.Language = :sfLang
            WITH USER_MODE 
            GROUP BY DataCategoryName
        ];

        for (AggregateResult row : grouped) {
            CategoryWrapper cat = new CategoryWrapper();
            cat.name = (String) row.get('DataCategoryName');
            cat.label = (String) row.get('DataCategoryName');
            cat.articleCount = (Integer) row.get('cnt');
            cats.add(cat);
        }
        return cats;
    }

    @AuraEnabled(cacheable=true)
    public static ArticleDetailWrapper getArticleDetail(String urlName, String langue) {
        String sfLang = resolveLang(langue);

        List<KnowledgeArticleVersion> articles = [
            SELECT Id, Title, Summary, UrlName, LastPublishedDate
            FROM KnowledgeArticleVersion
            WHERE UrlName = :urlName 
            AND PublishStatus = 'online' 
            AND Language = :sfLang
            WITH USER_MODE 
            LIMIT 1
        ];

        if (articles.isEmpty()) {
            throw new AuraHandledException('Article introuvable.');
        }

        KnowledgeArticleVersion art = articles[0];
        ArticleDetailWrapper detail = new ArticleDetailWrapper();
        detail.id = art.Id;
        detail.title = art.Title;
        detail.summary = art.Summary;
        detail.body = art.Summary; 
        detail.lastPublished = art.LastPublishedDate;
        
        return detail;
    }

    private static String resolveLang(String lang) {
        if (String.isBlank(lang)) {
            return 'fr';
        }
        String lowerLang = lang.toLowerCase();
        return LANG_MAP.containsKey(lowerLang) ? LANG_MAP.get(lowerLang) : 'en_US';
    }
}