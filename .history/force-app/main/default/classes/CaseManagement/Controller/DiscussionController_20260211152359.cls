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
            // SOLUTION 1 : ConnectApi (recommandée) - corrige l'erreur de signature
            ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
            input.subjectId = parentToUse;
            input.feedElementType = ConnectApi.FeedElementType.FeedItem;
            
            ConnectApi.MessageBodyInput bodyInput = new ConnectApi.MessageBodyInput();
            bodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            
            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
            textSegment.text = message;
            
            bodyInput.messageSegments.add(textSegment);
            input.body = bodyInput;
            
            ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), input);
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur technique : ' + e.getMessage());
        }
    }
}
