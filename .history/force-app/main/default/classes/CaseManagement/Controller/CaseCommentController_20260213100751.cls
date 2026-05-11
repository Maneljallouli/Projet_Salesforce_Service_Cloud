public with sharing class CaseCommentController {
    @AuraEnabled(cacheable=true)
    public static List<FeedData> getCaseHistory(Id caseId) {
        List<FeedData> history = new List<FeedData>();
        
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
        insert as user new CaseComment(ParentId = caseId, CommentBody = message, IsPublished = true);
    }

    public class FeedData {
        @AuraEnabled public String id;
        @AuraEnabled public String author;
        @AuraEnabled public String body;
        @AuraEnabled public String icon;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public Boolean isAction;

        public FeedData(CaseFeed f) {
            this.id = f.Id;
            this.author = f.CreatedBy.Name;
            this.createdDate = f.CreatedDate;
            this.isAction = (f.Type == 'TrackedChange' || f.Type == 'CreateRecordEvent');
            
            if(f.Type == 'TrackedChange' && !f.FeedTrackedChanges.isEmpty()) {
                FeedTrackedChange c = f.FeedTrackedChanges[0];
                // Deep extraction of field updates (English)
                String fieldName = c.FieldName.capitalize();
                this.body = fieldName + ' changed from ' + c.OldValue + ' to ' + c.NewValue;
                this.icon = 'standard:case_change_status';
            } else if(f.Type == 'CreateRecordEvent') {
                this.body = 'Case created';
                this.icon = 'standard:case';
            } else {
                // Agent or Client comments
                this.body = f.Body != null ? f.Body : (f.Title != null ? f.Title : 'Case update');
                this.icon = 'standard:comment';
            }
        }
    }
}