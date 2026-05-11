/**
 * @class       FaqController
 * @description Controller optimisé pour Knowledge (Langues: FR, EN, AR)
 * Version 1.2 - Fix PMD (CRUD & Style)
 * @author      Gemini / Salesforce Architect
 */
public with sharing class FaqController {

    private static final Map<String, String> LANG_MAP = new Map<String, String>{
        'fr' => 'fr',
        'en' => 'en_US',
        'ar' => 'ar'
    };

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
        @AuraEnabled public DateTime lastPublished { get; set; }
    }

    public class CategoryWrapper {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public Integer articleCount { get; set; }
    }

    // --- LOGIQUE DE RÉCUPÉRATION ---

    /**
     * @description Récupère les catégories basées sur les articles publiés.
     */
    @AuraEnabled(cacheable=true)
    public static List<CategoryWrapper> getFaqCategories(String langue) {
        String sfLang = resolveLang(langue);
        List<CategoryWrapper> cats = new List<CategoryWrapper>();
        
        // Fix ApexCRUDViolation : Ajout de WITH USER_MODE
        AggregateResult[] grouped = [
            SELECT DataCategoryName, COUNT(ParentId) cnt
            FROM Knowledge__DataCategorySelection
            WHERE Parent.PublishStatus = 'online'
            AND Parent.Language = :sfLang
            GROUP BY DataCategoryName
            WITH USER_MODE 
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

    /**
     * @description Récupère le contenu complet d'un article FAQ.
     */
    @AuraEnabled(cacheable=true)
    public static ArticleDetailWrapper getArticleDetail(String urlName, String langue) {
        String sfLang = resolveLang(langue);

        // WITH USER_MODE assure que l'utilisateur a le droit de lire Knowledge
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
        detail.body = art.Summary; // Utilise Summary si le champ riche n'est pas encore créé
        detail.lastPublished = art.LastPublishedDate;
        
        return detail;
    }

    // --- HELPERS ---

    private static String resolveLang(String lang) {
        if (String.isBlank(lang)) {
            return 'fr';
        }
        String lowerLang = lang.toLowerCase();
        return LANG_MAP.containsKey(lowerLang) ? LANG_MAP.get(lowerLang) : 'en_US';
    }
}