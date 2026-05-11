/**
 * @class       FaqController
 * @description Controller optimisé pour Knowledge (Langues: FR, EN, AR)
 * @author      Gemini / Salesforce Architect
 */
public with sharing class FaqController {

    // Mapping restreint selon ta demande
    private static final Map<String, String> LANG_MAP = new Map<String, String>{
        'fr' => 'fr',
        'en' => 'en_US',
        'ar' => 'ar'
    };

    private static final Integer MAX_SEARCH_RESULTS = 20;
    private static final Integer MAX_CATEGORY_ARTICLES = 10;

    // --- WRAPPERS ---
    public class ArticleWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String summary { get; set; }
        @AuraEnabled public String urlName { get; set; }
        @AuraEnabled public String categoryName { get; set; }
        @AuraEnabled public DateTime lastPublished { get; set; }
    }

    public class ArticleDetailWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String body { get; set; }
        @AuraEnabled public String summary { get; set; }
        @AuraEnabled public String categoryName { get; set; }
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
        
        // On passe par l'objet de jonction pour éviter l'erreur sur DataCategoryName
        AggregateResult[] grouped = [
            SELECT DataCategoryName, COUNT(ParentId) cnt
            FROM Knowledge__DataCategorySelection
            WHERE Parent.PublishStatus = 'online'
            AND Parent.Language = :sfLang
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

    @AuraEnabled(cacheable=false)
    public static ArticleDetailWrapper getArticleDetail(String urlName, String langue) {
        String sfLang = resolveLang(langue);

        // Remplacement de Body__c par Summary pour éviter l'erreur de déploiement
        // Si tu as un champ riche, remplace 'Summary' par son nom API (ex: Content__c)
        List<KnowledgeArticleVersion> articles = [
            SELECT Id, Title, Summary, UrlName, LastPublishedDate
            FROM KnowledgeArticleVersion
            WHERE UrlName = :urlName 
            AND PublishStatus = 'online' 
            AND Language = :sfLang
            WITH SECURITY_ENFORCED 
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

    // --- HELPERS ---

    private static String resolveLang(String lang) {
        if (String.isBlank(lang)) return 'fr';
        String lowerLang = lang.toLowerCase();
        return LANG_MAP.containsKey(lowerLang) ? LANG_MAP.get(lowerLang) : 'en_US';
    }

    private static List<ArticleWrapper> toWrapperList(List<KnowledgeArticleVersion> articles, String defaultCategory) {
        List<ArticleWrapper> result = new List<ArticleWrapper>();
        for (KnowledgeArticleVersion a : articles) {
            ArticleWrapper w = new ArticleWrapper();
            w.id = a.Id;
            w.title = a.Title;
            w.summary = a.Summary;
            w.urlName = a.UrlName;
            w.categoryName = defaultCategory;
            w.lastPublished = a.LastPublishedDate;
            result.add(w);
        }
        return result;
    }
}