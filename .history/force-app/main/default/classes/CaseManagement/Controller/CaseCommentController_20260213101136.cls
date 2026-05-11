public with sharing class CaseCommentController {
    @AuraEnabled(cacheable=true)
    public static List<FeedData> getCaseHistory(Id caseId) {
        List<FeedData> history = new List<FeedData>();
        
        // Querying CaseFeed for Title (Actions) and Body (Comments)
        for(CaseFeed f : [SELECT Id, Body, Title, Type, CreatedDate, CreatedBy.Name 
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
            IsPublished = true
        );
        insert as user newComment;
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
            
            // Fixed PMD: Using curly braces for all if/else statements
            if (f.Title != null && f.Title != '') {
                this.body = f.Title; 
            } else if (f.Body != null && f.Body != '') {
                this.body = f.Body;
            } else {
                this.body = 'System update';
            }

            // Setting Icons based on Type
            if (f.Type == 'TrackedChange') {
                this.icon = 'standard:case_change_status';
            } else if (f.Type == 'CreateRecordEvent') {
                this.icon = 'standard:case';
            } else {
                this.icon = 'standard:comment';
            }
        }
    }
}