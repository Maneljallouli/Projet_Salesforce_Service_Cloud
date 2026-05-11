public with sharing class DiscussionController {
    
    @AuraEnabled(cacheable=true)
    public static List<FeedItem> getDiscussions(Id recordId) {
        // Vérification explicite des droits de lecture (CRUD/FLS) pour PMD
        if (!Schema.sObjectType.FeedItem.isAccessible() || 
            !Schema.sObjectType.FeedItem.fields.Body.isAccessible() ||
            !Schema.sObjectType.FeedComment.isAccessible()) {
            throw new AuraHandledException('Accès refusé aux discussions.');
        }

        // Utilisation de WITH USER_MODE pour la sécurité native
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
        // Vérification avant insertion
        if (Schema.sObjectType.FeedItem.isCreateable() && 
            Schema.sObjectType.FeedItem.fields.Body.isCreateable()) {
            
            FeedItem post = new FeedItem();
            post.ParentId = recordId;
            post.Body = message;
            insert as user post; // Insertion en mode utilisateur
        } else {
            throw new AuraHandledException('Vous n\'avez pas la permission de publier.');
        }
    }
}