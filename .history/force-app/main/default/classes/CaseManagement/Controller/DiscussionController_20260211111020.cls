public with sharing class DiscussionController {
    
    @AuraEnabled(cacheable=true)
    public static List<FeedItem> getDiscussions(Id recordId) {
        // Utilisation du binding direct [:recordId] pour éviter l'injection SOQL
        List<FeedItem> discussions = [
            SELECT Id, Body, CreatedBy.Name, CreatedDate, 
                   (SELECT Id, CommentBody, CreatedBy.Name, CreatedDate FROM FeedComments) 
            FROM FeedItem 
            WHERE ParentId = :recordId 
            ORDER BY CreatedDate DESC
        ];

        // Sécurisation CRUD/FLS
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, discussions);
        return (List<FeedItem>) decision.getRecords();
    }

    @AuraEnabled
    public static void postQuestion(Id recordId, String message) {
        if (Schema.sObjectType.FeedItem.isCreateable()) {
            FeedItem post = new FeedItem();
            post.ParentId = recordId;
            post.Body = message;
            insert post;
        } else {
            throw new AuraHandledException('Permissions de publication insuffisantes.');
        }
    }
}