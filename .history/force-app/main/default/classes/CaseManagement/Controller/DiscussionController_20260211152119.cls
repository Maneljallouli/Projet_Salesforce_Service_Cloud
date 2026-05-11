public with sharing class DiscussionController {
    
    @AuraEnabled(cacheable=true)
    public static List<FeedItem> getDiscussions(Id recordId) {
        // Utilise l'ID du réseau (site) si aucun recordId n'est fourni
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
            throw new AuraHandledException('ID de contexte introuvable.');
        }

        try {
            // --- SOLUTION : Utilisation de FeedItem au lieu de ConnectApi ---
            FeedItem post = new FeedItem();
            post.ParentId = parentToUse; // Lie le post au record ou au site
            post.Body = message;
            
            insert as user post; 
        } catch (Exception e) {
            throw new AuraHandledException('Erreur technique : ' + e.getMessage());
        }
    }
}