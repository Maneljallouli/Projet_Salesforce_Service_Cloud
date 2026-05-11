public with sharing class CaseCommentController {
    
    @AuraEnabled(cacheable=true)
    public static List<FeedData> getCaseHistory(Id caseId) {
        List<FeedData> history = new List<FeedData>();
        
        // On récupère le flux Chatter (Posts, Changements de statut, etc.)
        List<CaseFeed> feeds = [
            SELECT Id, Body, Title, Type, CreatedDate, CreatedBy.Name,
                   (SELECT OldValue, NewValue, FieldName FROM FeedTrackedChanges)
            FROM CaseFeed
            WHERE ParentId = :caseId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ];

        for(CaseFeed f : feeds) {
            history.add(new FeedData(f));
        }
        return history;
    }

    // Classe wrapper pour formater proprement les données pour le LWC
    public class FeedData {
        @AuraEnabled public String id;
        @AuraEnabled public String author;
        @AuraEnabled public String body;
        @AuraEnabled public String type;
        @AuraEnabled public DateTime createdDate;

        public FeedData(CaseFeed f) {
            this.id = f.Id;
            this.author = f.CreatedBy.Name;
            this.createdDate = f.CreatedDate;
            
            if(f.Type == 'TrackedChange' && !f.FeedTrackedChanges.isEmpty()) {
                this.body = 'A modifié le champ ' + f.FeedTrackedChanges[0].FieldName;
            } else {
                this.body = f.Body != null ? f.Body : f.Title;
            }
        }
    }
}