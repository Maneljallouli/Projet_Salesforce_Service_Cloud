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

            // Logic to clean the technical JSON from your screenshot
            if (!f.FeedTrackedChanges.isEmpty()) {
                FeedTrackedChange ftc = f.FeedTrackedChanges[0];
                this.body = formatFieldName(ftc.FieldName) + ' changed from ' + ftc.OldValue + ' to ' + ftc.NewValue;
                this.icon = 'standard:case_change_status';
            } else if (f.Title != null && f.Title.contains('{"fu"')) {
                // If the Title is technical JSON, we simplify it
                this.body = 'Case details updated';
                this.icon = 'standard:case_change_status';
            } else if (f.Title != null && f.Title != '') {
                this.body = f.Title;
                this.icon = 'standard:case_change_status';
            } else {
                this.body = f.Body != null ? f.Body : 'Update recorded';
                this.icon = 'standard:comment';
            }

            if (f.Type == 'CreateRecordEvent') {
                this.body = 'Case Created';
                this.icon = 'standard:case';
            }
        }

        private String formatFieldName(String name) {
            if (name == null) return 'Field';
            String cleanName = name.replace('Case.', '');
            return cleanName.substring(0, 1).toUpperCase() + cleanName.substring(1);
        }
    }
}