public with sharing class CaseCommentController {

    @AuraEnabled(cacheable=true)
    public static List<FeedData> getCaseHistory(Id caseId) {
        List<FeedData> history = new List<FeedData>();
        try {
            // Requête ciblée sur les types de messages humains uniquement
            // TextPost = Messages du fil / CommentEvent = Commentaires de la requête
            for (CaseFeed f : [
                SELECT Id, Body, Type, CreatedDate, CreatedBy.Name
                FROM CaseFeed
                WHERE ParentId = :caseId 
                AND (Type = 'TextPost' OR Type = 'CommentEvent')
                WITH USER_MODE
                ORDER BY CreatedDate DESC
            ]) {
                history.add(new FeedData(f));
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        return history;
    }

    @AuraEnabled
    public static void postMessage(Id caseId, String message) {
        if (String.isBlank(message)) {
            return;
        }
        
        // Insertion d'un commentaire officiel visible par le client et l'agent
        insert as user new CaseComment(
            ParentId = caseId,
            CommentBody = message,
            IsPublished = true
        );
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
            this.body = f.Body;
            this.icon = 'standard:comment';
            this.isAction = false; 
        }
    }
}