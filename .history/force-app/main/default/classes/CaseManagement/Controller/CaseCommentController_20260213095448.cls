public with sharing class CaseCommentController {
    @AuraEnabled(cacheable=true)
    public static List<FeedData> getCaseHistory(Id caseId) {
        List<FeedData> history = new List<FeedData>();
        
        // On récupère les Feeds ET les changements de champs associés
        for(CaseFeed f : [SELECT Id, Body, Title, Type, CreatedDate, CreatedBy.Name,
                          (SELECT FieldName, OldValue, NewValue FROM FeedTrackedChanges)
                          FROM CaseFeed WHERE ParentId = :caseId 
                          WITH USER_MODE ORDER BY CreatedDate DESC]) {
            history.add(new FeedData(f));
        }
        return history;
    }

    @AuraEnabled
    public static void postMessage(Id caseId, String message) {
        CaseComment newComment = new CaseComment(
            ParentId = caseId,
            CommentBody = message,
            IsPublished = true // Crucial pour la visibilité client
        );
        insert as user newComment;
    }

    public class FeedData {
        @AuraEnabled public String id;
        @AuraEnabled public String author;
        @ AuraEnabled public String body;
        @AuraEnabled public String icon;
        @AuraEnabled public DateTime createdDate;

        public FeedData(CaseFeed f) {
            this.id = f.Id;
            this.author = f.CreatedBy.Name;
            this.createdDate = f.CreatedDate;
            
            if(f.Type == 'TrackedChange' && !f.FeedTrackedChanges.isEmpty()) {
                FeedTrackedChange change = f.FeedTrackedChanges[0];
                this.body = 'Statut changé : ' + change.OldValue + ' vers ' + change.NewValue;
                this.icon = 'standard:case_change_status';
            } else if(f.Type == 'CreateRecordEvent') {
                this.body = 'Requête créée';
                this.icon = 'standard:case';
            } else {
                this.body = f.Body != null ? f.Body : (f.Title != null ? f.Title : 'Mise à jour');
                this.icon = 'standard:comment';
            }
        }
    }
}