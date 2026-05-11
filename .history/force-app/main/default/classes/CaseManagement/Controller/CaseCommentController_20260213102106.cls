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
            System.debug('Error fetching feed: ' + e.getMessage());
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
            this.author = f.CreatedBy.Name;
            this.createdDate = f.CreatedDate;
            this.isAction = (f.Type != 'TextPost' && f.Type != 'CommentEvent');

            // --- DETECTING AND FIXING THE DETAILS ---
            if (f.FeedTrackedChanges != null && !f.FeedTrackedChanges.isEmpty()) {
                // This is where we get "Status: New to Waiting Customer"
                FeedTrackedChange ftc = f.FeedTrackedChanges[0];
                String field = ftc.FieldName != null ? ftc.FieldName.replace('Case.', '') : 'Field';
                this.body = field + ' updated from ' + ftc.OldValue + ' to ' + ftc.NewValue;
                this.icon = 'standard:case_change_status';
            } else if (f.Title != null && !f.Title.contains('{"fu"')) {
                // Use the Title only if it's NOT technical JSON
                this.body = f.Title;
                this.icon = 'standard:case_change_status';
            } else if (f.Body != null) {
                this.body = f.Body;
                this.icon = 'standard:comment';
            } else {
                this.body = 'Case update recorded';
                this.icon = 'standard:case';
            }

            // --- FIXING ICONS WITH BRACES (PMD) ---
            if (f.Type == 'CreateRecordEvent') {
                this.body = 'Case Created';
                this.icon = 'standard:case';
            }
        }
    }
}