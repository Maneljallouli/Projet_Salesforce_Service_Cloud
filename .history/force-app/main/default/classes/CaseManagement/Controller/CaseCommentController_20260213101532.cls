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
            this.isAction = (f.Type != 'TextPost' && f.Type != 'CommentEvent');

            // 1. Handle Details (Fixing the JSON issue from image_b1e65e)
            if (!f.FeedTrackedChanges.isEmpty()) {
                FeedTrackedChange ftc = f.FeedTrackedChanges[0];
                String field = ftc.FieldName.replace('Case.', '');
                this.body = field + ' changed from ' + ftc.OldValue + ' to ' + ftc.NewValue;
            } else if (f.Title != null && f.Title.contains('{"fu"')) {
                this.body = 'Case details were updated';
            } else if (f.Title != null && f.Title != '') {
                this.body = f.Title;
            } else {
                this.body = f.Body != null ? f.Body : 'Update recorded';
            }

            // 2. Setting Icons (Fixing PMD errors: added curly braces)
            if (f.Type == 'TrackedChange') {
                this.icon = 'standard:case_change_status';
            } else if (f.Type == 'CreateRecordEvent') {
                this.body = 'Case Created';
                this.icon = 'standard:case';
            } else {
                this.icon = 'standard:comment';
            }
        }
    }
}