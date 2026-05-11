public with sharing class DiscussionController {
    
    @AuraEnabled(cacheable=true)
    public static List<FeedItem> getDiscussions(Id recordId) {
        // Si on est sur une page sans recordId, on utilise l'ID du Réseau (Site)
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
            throw new AuraHandledException('Contexte introuvable (Network ID manquant).');
        }

        try {
            // Remplacement de ConnectApi par FeedItem standard
            FeedItem post = new FeedItem();
            post.ParentId = parentToUse;
            post.Body = message;
            
            // "insert as user" respecte les permissions de ton profil client
            insert as user post;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }
}