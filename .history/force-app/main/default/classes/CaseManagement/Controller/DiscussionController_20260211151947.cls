public with sharing class DiscussionController {
    
    @AuraEnabled(cacheable=true)
    public static List<FeedItem> getDiscussions(Id recordId) {
        // Détermination du ParentId (Record ou Network)
        Id parentToUse = (recordId != null) ? recordId : Network.getNetworkId();
        
        if (parentToUse == null) {
            return new List<FeedItem>();
        }

        return [
            SELECT Id, Body, CreatedBy.Name, CreatedDate,
                   (SELECT Id, CommentBody, CreatedBy.Name, CreatedDate FROM FeedComments)
            FROM FeedItem 
            WHERE ParentId = :parentToUse 
            AND Type = 'TextPost'
            WITH USER_MODE 
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }

    @AuraEnabled
    public static void postQuestion(Id recordId, String message) {
        if (String.isBlank(message)) {
            throw new AuraHandledException('Le message ne peut pas être vide.');
        }

        Id parentToUse = (recordId != null) ? recordId : Network.getNetworkId();
        
        if (parentToUse == null) {
            throw new AuraHandledException('Impossible de trouver un contexte pour publier (Network ID manquant).');
        }

        try {
            // Utilisation de FeedItem pour plus de simplicité et éviter les erreurs ConnectApi
            FeedItem post = new FeedItem();
            post.ParentId = parentToUse;
            post.Body = message;
            // "insert as user" assure que les permissions du client sont respectées
            insert as user post;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la publication : ' + e.getMessage());
        }
    }
}