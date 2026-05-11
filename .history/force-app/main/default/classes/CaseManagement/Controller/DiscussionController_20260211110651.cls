public with sharing class DiscussionController {
    
    // Récupérer les questions liées à un article (ou globales)
    @AuraEnabled(cacheable=true)
    public static List<FeedItem> getDiscussions(Id recordId) {
        return [SELECT Id, Body, CreatedBy.Name, CreatedDate, 
                       (SELECT Id, CommentBody, CreatedBy.Name, CreatedDate FROM FeedComments) 
                FROM FeedItem 
                WHERE ParentId = :recordId 
                ORDER BY CreatedDate DESC];
    }

    // Créer une nouvelle question
    @AuraEnabled
    public static void postQuestion(Id recordId, String message) {
        FeedItem post = new FeedItem();
        post.ParentId = recordId;
        post.Body = message;
        insert post;
    }
}