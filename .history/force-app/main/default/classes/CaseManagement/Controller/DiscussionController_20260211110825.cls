public with sharing class DiscussionController {
    
    @AuraEnabled(cacheable=true)
    public static List<SObject> getDiscussions(Id recordId) {
        // Sécurisation de la requête SOQL
        String query = 'SELECT Id, Body, CreatedBy.Name, CreatedDate, ' +
                       '(SELECT Id, CommentBody, CreatedBy.Name, CreatedDate FROM FeedComments) ' +
                       'FROM FeedItem WHERE ParentId = :recordId ORDER BY CreatedDate DESC';
        
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, Database.query(query));
        return decision.getRecords();
    }

    @AuraEnabled
    public static void postQuestion(Id recordId, String message) {
        FeedItem post = new FeedItem();
        post.ParentId = recordId;
        post.Body = message;

        // Vérification CRUD avant insertion
        if (Schema.sObjectType.FeedItem.isCreateable()) {
            insert post;
        } else {
            throw new AuraHandledException('Permissions insuffisantes pour publier.');
        }
    }
}