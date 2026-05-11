public with sharing class CaseCommentController {
    @AuraEnabled(cacheable=true)
    public static List<FeedData> getCaseHistory(Id caseId) {
        List<FeedData> history = new List<FeedData>();
        // Querying for both the Feed and the child Tracked Changes
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

            // --- FIX FOR THE "JSON" PROBLEM ---
            if (!f.FeedTrackedChanges.isEmpty()) {
                FeedTrackedChange ftc = f.FeedTrackedChanges[0];
                String fieldName = ftc.FieldName.replace('Case.', '');
                // Manually building the English sentence to avoid JSON text
                this.body = fieldName + ' updated from ' + String.valueOf(ftc.OldValue) + ' to ' + String.valueOf(ftc.NewValue);
            } else if (f.Title != null && !f.Title.contains('{"fu"')) {
                this.body = f.Title;
            } else if (f.Body != null && f.Body != '') {
                this.body = f.Body;
            } else {
                this.body = 'Case updated';
            }

            // --- FIX FOR PMD BRACE ERRORS & ICONS ---
            if (f.Type == 'TrackedChange') {
                this.icon = 'standard:case_change_status';
            } else if (f.Type == 'CreateRecordEvent') {
                this.body = 'Case Created'; // English
                this.icon = 'standard:case';
            } else {
                this.icon = 'standard:comment';
            }
        }
    }
}