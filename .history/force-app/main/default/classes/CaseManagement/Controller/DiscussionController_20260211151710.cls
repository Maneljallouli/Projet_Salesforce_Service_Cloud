public with sharing class DiscussionController {

    // 🔹 Récupération des discussions
    @AuraEnabled(cacheable=true)
    public static List<FeedItem> getDiscussions() {

        // ⚠️ Remplace le nom si besoin
        CollaborationGroup group = [
            SELECT Id
            FROM CollaborationGroup
            WHERE Name = 'All Company'
            LIMIT 1
        ];

        return [
            SELECT Id,
                   Body,
                   CreatedDate,
                   CreatedBy.Name
            FROM FeedItem
            WHERE ParentId = :group.Id
            ORDER BY CreatedDate DESC
        ];
    }

    // 🔹 Publication d’une question
    @AuraEnabled
    public static void postQuestion(String message) {

        if (String.isBlank(message)) {
            throw new AuraHandledException('Le message ne peut pas être vide.');
        }

        CollaborationGroup group = [
            SELECT Id
            FROM CollaborationGroup
            WHERE Name = 'All Company'
            LIMIT 1
        ];

        FeedItem post = new FeedItem();
        post.ParentId = group.Id;
        post.Body = message;

        insert post;
    }
}
