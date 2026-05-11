/**
 * @class       FaqController
 * @description AuraEnabled controller for the self-service FAQ / Knowledge Base
 *              on Experience Cloud. Supports multilingual articles, category
 *              browsing, full-text search, and article feedback (helpful / not).
 *
 *              Requires Knowledge to be enabled and articles published.
 *              Language mapping: fr → fr, en → en_US, ar → ar, zh → zh_CN, ja → ja
 *
 * @author      Salesforce Architect
 * @version     1.0
 */
public with sharing class FaqController {

    // Map portal language codes to Salesforce Knowledge language codes
    private static final Map<String, String> LANG_MAP = new Map<String, String>{
        'fr' => 'fr',
        'en' => 'en_US',
        'ar' => 'ar',
        'zh' => 'zh_CN',
        'ja' => 'ja',
        'it' => 'it',
        'de' => 'de',
        'es' => 'es'
    };

    private static final Integer MAX_SEARCH_RESULTS = 20;
    private static final Integer MAX_CATEGORY_ARTICLES = 10;

    // ─────────────────────────────────────────────────────────────
    // INNER CLASSES
    // ─────────────────────────────────────────────────────────────

    public class ArticleWrapper {
        @AuraEnabled public String  id           { get; set; }
        @AuraEnabled public String  title        { get; set; }
        @AuraEnabled public String  summary      { get; set; }
        @AuraEnabled public String  urlName      { get; set; }
        @AuraEnabled public String  categoryName { get; set; }
        @AuraEnabled public Integer viewCount    { get; set; }
        @AuraEnabled public DateTime lastPublished { get; set; }
    }

    public class ArticleDetailWrapper {
        @AuraEnabled public String   id            { get; set; }
        @AuraEnabled public String   title         { get; set; }
        @AuraEnabled public String   body          { get; set; }
        @AuraEnabled public String   summary       { get; set; }
        @AuraEnabled public String   categoryName  { get; set; }
        @AuraEnabled public DateTime lastPublished { get; set; }
        @AuraEnabled public List<ArticleWrapper> related { get; set; }
    }

    public class CategoryWrapper {
        @AuraEnabled public String  name         { get; set; }
        @AuraEnabled public String  label        { get; set; }
        @AuraEnabled public Integer articleCount { get; set; }
    }

    public class SearchResult {
        @AuraEnabled public List<ArticleWrapper> articles    { get; set; }
        @AuraEnabled public Integer              totalFound  { get; set; }
        @AuraEnabled public String               queryUsed   { get; set; }
    }

    // ─────────────────────────────────────────────────────────────
    // CATEGORY BROWSING
    // ─────────────────────────────────────────────────────────────

    /**
     * Returns all FAQ categories with article counts.
     * @param langue  Portal language code (fr / en / ar / zh / ja)
     */
    @AuraEnabled(cacheable=true)
    public static List<CategoryWrapper> getFaqCategories(String langue) {
        String sfLang = resolveLang(langue);

        // DataCategoryGroupSelection query to get category structure
        // Using KnowledgeArticleVersion as the primary object
        AggregateResult[] grouped = [
            SELECT  DataCategoryName, DataCategoryGroupName, COUNT(Id) cnt
            FROM    KnowledgeArticleVersion
            WHERE   PublishStatus = 'online'
            AND     Language      = :sfLang
            GROUP BY DataCategoryName, DataCategoryGroupName
            ORDER BY DataCategoryName ASC
        ];

        List<CategoryWrapper> cats = new List<CategoryWrapper>();
        for (AggregateResult row : grouped) {
            CategoryWrapper cat = new CategoryWrapper();
            cat.name         = (String)  row.get('DataCategoryName');
            cat.label        = (String)  row.get('DataCategoryGroupName');
            cat.articleCount = (Integer) row.get('cnt');
            cats.add(cat);
        }
        return cats;
    }

    // ─────────────────────────────────────────────────────────────
    // ARTICLE RETRIEVAL
    // ─────────────────────────────────────────────────────────────

    /**
     * Returns articles for a given category.
     * @param categoryName  DataCategory developer name
     * @param langue        Portal language code
     * @param pageNum       1-based page (default 1)
     */
    @AuraEnabled(cacheable=true)
    public static List<ArticleWrapper> getArticlesByCategory(
            String  categoryName,
            String  langue,
            Integer pageNum) {

        String  sfLang   = resolveLang(langue);
        Integer offset   = ((pageNum == null || pageNum < 1) ? 0 : pageNum - 1)
                           * MAX_CATEGORY_ARTICLES;

        List<KnowledgeArticleVersion> articles = [
            SELECT  Id, Title, Summary, UrlName, LastPublishedDate
            FROM    KnowledgeArticleVersion
            WHERE   PublishStatus      = 'online'
            AND     Language           = :sfLang
            AND     DataCategoryName   = :categoryName
            WITH    SECURITY_ENFORCED
            ORDER BY LastPublishedDate DESC
            LIMIT   :MAX_CATEGORY_ARTICLES
            OFFSET  :offset
        ];

        return toWrapperList(articles, categoryName);
    }

    /**
     * Returns full article detail by URL name (slug).
     * Increments view count asynchronously.
     * @param urlName  KnowledgeArticleVersion.UrlName
     * @param langue   Portal language code
     */
    @AuraEnabled(cacheable=false)
    public static ArticleDetailWrapper getArticleDetail(
            String urlName, String langue) {

        String sfLang = resolveLang(langue);

        List<KnowledgeArticleVersion> articles = [
            SELECT  Id, Title, Summary, UrlName,
                    DataCategoryName, LastPublishedDate,
                    Body__c   /* Custom rich text field on article type */
            FROM    KnowledgeArticleVersion
            WHERE   UrlName       = :urlName
            AND     PublishStatus = 'online'
            AND     Language      = :sfLang
            WITH    SECURITY_ENFORCED
            LIMIT   1
        ];

        if (articles.isEmpty()) {
            throw new AuraHandledException(Label.FAQ_Error_ArticleNotFound);
        }

        KnowledgeArticleVersion art = articles[0];

        // Related articles (same category, excluding current)
        List<KnowledgeArticleVersion> relatedArticles = [
            SELECT Id, Title, Summary, UrlName, LastPublishedDate
            FROM   KnowledgeArticleVersion
            WHERE  DataCategoryName = :art.DataCategoryName
            AND    PublishStatus    = 'online'
            AND    Language         = :sfLang
            AND    Id              != :art.Id
            WITH   SECURITY_ENFORCED
            ORDER BY LastPublishedDate DESC
            LIMIT  4
        ];

        // Async view count increment
        incrementViewCountAsync(art.Id);

        ArticleDetailWrapper detail = new ArticleDetailWrapper();
        detail.id           = art.Id;
        detail.title        = art.Title;
        detail.summary      = art.Summary;
        detail.body         = art.Body__c;
        detail.categoryName = art.DataCategoryName;
        detail.lastPublished = art.LastPublishedDate;
        detail.related       = toWrapperList(relatedArticles, art.DataCategoryName);
        return detail;
    }

    // ─────────────────────────────────────────────────────────────
    // FULL-TEXT SEARCH
    // ─────────────────────────────────────────────────────────────

    /**
     * Searches Knowledge articles using SOSL.
     * @param searchTerm  User input (sanitised internally)
     * @param langue      Portal language code
     * @return            SearchResult wrapper
     */
    @AuraEnabled(cacheable=true)
    public static SearchResult searchArticles(String searchTerm, String langue) {

        if (String.isBlank(searchTerm) || searchTerm.trim().length() < 2) {
            throw new AuraHandledException(Label.FAQ_Error_SearchTooShort);
        }

        String sfLang = resolveLang(langue);

        // Sanitise: remove SOSL special chars
        String sanitised = searchTerm.trim()
            .replaceAll('[^a-zA-Z0-9àâäéèêëîïôùûüçÀÂÄÉÈÊËÎÏÔÙÛÜÇ\\s\\-]', '')
            .trim();

        if (sanitised.length() < 2) {
            throw new AuraHandledException(Label.FAQ_Error_SearchInvalid);
        }

        String soslQuery = sanitised + '*'; // Wildcard suffix for partial match

        List<List<SObject>> searchResults = Search.query(
            'FIND :soslQuery IN ALL FIELDS RETURNING '
            + 'KnowledgeArticleVersion ('
            + '  Id, Title, Summary, UrlName, DataCategoryName, LastPublishedDate '
            + '  WHERE PublishStatus = \'online\' AND Language = \'' + sfLang + '\''
            + '  ORDER BY LastPublishedDate DESC'
            + '  LIMIT ' + MAX_SEARCH_RESULTS
            + ')'
        );

        List<KnowledgeArticleVersion> matched =
            (List<KnowledgeArticleVersion>) searchResults[0];

        SearchResult result    = new SearchResult();
        result.articles        = toWrapperList(matched, null);
        result.totalFound      = matched.size();
        result.queryUsed       = sanitised;
        return result;
    }

    // ─────────────────────────────────────────────────────────────
    // ARTICLE FEEDBACK
    // ─────────────────────────────────────────────────────────────

    /**
     * Records "helpful / not helpful" feedback on an article.
     * Creates a Knowledge Article Feedback record (custom or standard).
     */
    @AuraEnabled
    public static void submitFeedback(String articleId, Boolean isHelpful) {
        if (String.isBlank(articleId)) {
            throw new AuraHandledException(Label.FAQ_Error_InvalidArticle);
        }

        Id contactId = null;
        try {
            contactId = ContactUtils.getCurrentContactId();
        } catch (Exception e) {
            // Guest user — allow anonymous feedback
        }

        insert new Article_Feedback__c(
            Article_Id__c  = articleId,
            Is_Helpful__c  = isHelpful,
            Contact__c     = contactId,
            Timestamp__c   = System.now()
        );
    }

    // ─────────────────────────────────────────────────────────────
    // POPULAR ARTICLES (for homepage FAQ widget)
    // ─────────────────────────────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static List<ArticleWrapper> getPopularArticles(String langue, Integer limitCount) {
        String  sfLang    = resolveLang(langue);
        Integer safeLimit = (limitCount == null || limitCount < 1 || limitCount > 10)
            ? 5 : limitCount;

        List<KnowledgeArticleVersion> articles = [
            SELECT Id, Title, Summary, UrlName, DataCategoryName, LastPublishedDate
            FROM   KnowledgeArticleVersion
            WHERE  PublishStatus = 'online'
            AND    Language      = :sfLang
            WITH   SECURITY_ENFORCED
            ORDER BY ArticleViewCount DESC NULLS LAST
            LIMIT  :safeLimit
        ];

        return toWrapperList(articles, null);
    }

    // ─────────────────────────────────────────────────────────────
    // PRIVATE HELPERS
    // ─────────────────────────────────────────────────────────────

    private static String resolveLang(String lang) {
        if (String.isBlank(lang)) return 'fr';
        return LANG_MAP.containsKey(lang) ? LANG_MAP.get(lang) : 'en_US';
    }

    private static List<ArticleWrapper> toWrapperList(
            List<KnowledgeArticleVersion> articles, String defaultCategory) {
        List<ArticleWrapper> result = new List<ArticleWrapper>();
        for (KnowledgeArticleVersion a : articles) {
            ArticleWrapper w = new ArticleWrapper();
            w.id           = a.Id;
            w.title        = a.Title;
            w.summary      = a.Summary;
            w.urlName      = a.UrlName;
            w.categoryName = a.DataCategoryName ?? defaultCategory;
            w.lastPublished = a.LastPublishedDate;
            result.add(w);
        }
        return result;
    }

    @Future
    private static void incrementViewCountAsync(Id articleId) {
        // Uses standard KAV ArticleViewCount — SF tracks automatically for
        // authenticated Knowledge, but if manual tracking is needed:
        try {
            KbManagement.PublishingService.incrementViewCount(articleId);
        } catch (Exception e) {
            // Non-blocking
        }
    }
}