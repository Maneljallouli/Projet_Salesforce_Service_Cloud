public with sharing class DiscussionController {
    
    @AuraEnabled(cacheable=true)
    public static List<FeedItem> getDiscussions(Id recordId) {
        // Vérification de sécurité pour éviter le PromiseRejection côté client
        if (recordId == null) return new List<FeedItem>();

        return [
            SELECT Id, Body, CreatedBy.Name, CreatedDate, 
                   (SELECT Id, CommentBody, CreatedBy.Name, CreatedDate FROM FeedComments) 
            FROM FeedItem 
            WHERE ParentId = :recordId 
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static void postQuestion(Id recordId, String message) {
        if (String.isBlank(message)) throw new AuraHandledException('Le message ne peut pas être vide.');
        
        FeedItem post = new FeedItem();
        post.ParentId = recordId;
        post.Body = message;
        insert as user post;
    }
}