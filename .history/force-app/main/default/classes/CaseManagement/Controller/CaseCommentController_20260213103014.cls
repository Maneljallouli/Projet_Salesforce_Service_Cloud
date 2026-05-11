public with sharing class CaseCommentController {
    @AuraEnabled(cacheable=true)
    public static List<FeedData> getCaseHistory(Id caseId) {
        List<FeedData> history = new List<FeedData>();
        try {
            for(CaseFeed f : [SELECT Id, Body, Title, Type, CreatedDate, CreatedBy.Name,
                              (SELECT FieldName, OldValue, NewValue FROM FeedTrackedChanges)
                              FROM CaseFeed WHERE ParentId = :caseId 
                              WITH USER_MODE ORDER BY CreatedDate DESC]) {
                history.add(new FeedData(f));
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        return history;
    }

    @AuraEnabled
    public static void postMessage(Id caseId, String message) {
        if (String.isNotBlank(message)) {
            insert as user new CaseComment(ParentId = caseId, CommentBody = message, IsPublished = true);
        }
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
            this.author = f.CreatedBy != null ? f.CreatedBy.Name : 'System';
            this.createdDate = f.CreatedDate;
            this.isAction = (f.Type != 'TextPost' && f.Type != 'CommentEvent');

            // --- RESOLVING THE JSON TEXT PROBLEM ---
            if (f.FeedTrackedChanges != null && !f.FeedTrackedChanges.isEmpty()) {
                // Manually build the English phrase
                FeedTrackedChange ftc = f.FeedTrackedChanges[0];
                String field = ftc.FieldName != null ? ftc.FieldName.replace('Case.', '') : 'Status';
                this.body = field + ' updated from ' + ftc.OldValue + ' to ' + ftc.NewValue;
            } else if (f.Title != null && !f.Title.contains('{"fu"')) {
                this.body = f.Title;
            } else if (f.Body != null) {
                this.body = f.Body;
            } else {
                this.body = 'Activity recorded';
            }

            // --- SETTING THE ORANGE ICONS ---
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