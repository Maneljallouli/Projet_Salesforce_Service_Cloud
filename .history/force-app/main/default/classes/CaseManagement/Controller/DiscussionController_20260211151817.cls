public with sharing class DiscussionController {

    // =============================
    // Récupérer les discussions
    // =============================
    @AuraEnabled(cacheable=true)
    public static List<FeedItem> getDiscussions() {

        // 🔐 Sécurité : accès lecture FeedItem
        if (!Schema.sObjectType.FeedItem.isAccessible()) {
            return new List<FeedItem>();
        }

        // 🔐 Sécurité : accès lecture CollaborationGroup
        if (!Schema.sObjectType.CollaborationGroup.isAccessible()) {
            return new List<FeedItem>();
        }

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

    // =============================
    // Publier une question
    // =============================
    @AuraEnabled
    public static void postQuestion(String message) {

        if (String.isBlank(message)) {
            throw new AuraHandledException('Le message ne peut pas être vide.');
        }

        // 🔐 Sécurité : création FeedItem
        if (!Schema.sObjectType.FeedItem.isCreateable()) {
            throw new AuraHandledException('Permission insuffisante pour publier un message.');
        }

        // 🔐 Sécurité : lecture CollaborationGroup
        if (!Schema.sObjectType.CollaborationGroup.isAccessible()) {
            throw new AuraHandledException('Accès au groupe de discussion refusé.');
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
