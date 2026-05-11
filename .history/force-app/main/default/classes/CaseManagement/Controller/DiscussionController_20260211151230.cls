public with sharing class DiscussionController {

    @AuraEnabled(cacheable=true)
    public static List<ConnectApi.FeedElement> getDiscussions() {

        Id communityId = Network.getNetworkId();
        Id userId = UserInfo.getUserId();

        ConnectApi.FeedElementPage feed =
            ConnectApi.ChatterFeeds.getFeedElementsFromFeed(
                communityId,
                ConnectApi.FeedType.News,
                userId
            );

        return feed.elements;
    }

    @AuraEnabled
    public static void postQuestion(String message) {

        if (String.isBlank(message)) {
            throw new AuraHandledException('Le message ne peut pas être vide.');
        }

        Id communityId = Network.getNetworkId();
        Id userId = UserInfo.getUserId();

        // Segment texte
        ConnectApi.TextSegmentInput textSeg = new ConnectApi.TextSegmentInput();
        textSeg.text = message;

        // Corps du message
        ConnectApi.MessageBodyInput body = new ConnectApi.MessageBodyInput();
        body.messageSegments = new List<ConnectApi.MessageSegmentInput>{ textSeg };

        // Élément de feed
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = body;

        // ✅ MÉTHODE CORRECTE
        ConnectApi.ChatterFeeds.postFeedElement(
            communityId,
            ConnectApi.FeedType.News,
            userId,
            input
        );
    }
}
