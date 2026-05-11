public with sharing class DiscussionController {

    @AuraEnabled(cacheable=true)
    public static List<ConnectApi.FeedElement> getDiscussions() {
        ConnectApi.FeedType feedType = ConnectApi.FeedType.Record;
        Id communityId = Network.getNetworkId();

        return ConnectApi.ChatterFeeds.getFeedElementsFromFeed(
            communityId,
            ConnectApi.FeedType.News,
            null
        ).elements;
    }

    @AuraEnabled
    public static void postQuestion(String message) {
        if (String.isBlank(message)) {
            throw new AuraHandledException('Le message ne peut pas être vide.');
        }

        Id communityId = Network.getNetworkId();

        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = new ConnectApi.MessageBodyInput();
        input.body.messageSegments = new List<ConnectApi.MessageSegmentInput>{
            new ConnectApi.TextSegmentInput(message)
        };

        ConnectApi.ChatterFeeds.postFeedItem(
            communityId,
            ConnectApi.FeedType.News,
            null,
            input
        );
    }
}
