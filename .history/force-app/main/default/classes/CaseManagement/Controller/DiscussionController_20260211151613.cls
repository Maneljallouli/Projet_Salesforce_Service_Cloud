public with sharing class DiscussionController {

    @AuraEnabled(cacheable=true)
    public static List<FeedItem> getDiscussions() {

        Id groupId = [
            SELECT Id 
            FROM CollaborationGroup 
            WHERE Name = 'All Company'
            LIMIT 1
        ].Id;

        return [
            SELECT Id, Body, CreatedDate, CreatedBy.Name
            FROM FeedItem
            WHERE ParentId = :groupId
            ORDER BY CreatedDate DESC
            WITH USER_MODE
        ];
    }

    @AuraEnabled
    public static void postQuestion(String message) {

        if (String.isBlank(message)) {
            throw new AuraHandledException('Le message ne peut pas être vide.');
        }

        Id groupId = [
            SELECT Id 
            FROM CollaborationGroup 
            WHERE Name = 'All Company'
            LIMIT 1
        ].Id;

        FeedItem post = new FeedItem();
        post.ParentId = groupId;
        post.Body = message;

        insert post;
    }
}