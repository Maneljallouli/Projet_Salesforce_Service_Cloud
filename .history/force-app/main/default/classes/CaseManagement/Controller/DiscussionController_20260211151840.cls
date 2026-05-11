public with sharing class DiscussionController {
    
    @AuraEnabled(cacheable=true)
    public static List<FeedItem> getDiscussions(Id recordId) {
        // Si pas de recordId, on récupère l'ID du site actuel
        Id parentToUse = (recordId != null) ? recordId : Network.getNetworkId();
        
        if (parentToUse == null) return new List<FeedItem>();

        return [
            SELECT Id, Body, CreatedBy.Name, CreatedDate
            FROM FeedItem 
            WHERE ParentId = :parentToUse AND Type = 'TextPost'
            WITH USER_MODE 
            ORDER BY CreatedDate DESC
            LIMIT 20
        ];
    }

    @AuraEnabled
    public static void postQuestion(Id recordId, String message) {
        Id parentToUse = (recordId != null) ? recordId : Network.getNetworkId();
        
        if (String.isBlank(message)) throw new AuraHandledException('Message vide.');
        
        FeedItem post = new FeedItem();
        post.ParentId = parentToUse;
        post.Body = message;
        insert as user post;
    }
}