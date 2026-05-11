public with sharing class CaseCommentController {
    
    @AuraEnabled(cacheable=true)
    public static List<CommentData> getCaseComments(Id caseId) {
        List<CommentData> comments = new List<CommentData>();
        try {
            // On interroge l'objet CaseComment directement
            for (CaseComment c : [
                SELECT Id, CommentBody, CreatedDate, CreatedBy.Name, IsPublished
                FROM CaseComment
                WHERE ParentId = :caseId
                WITH USER_MODE
                ORDER BY CreatedDate DESC
            ]) {
                comments.add(new CommentData(c));
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        return comments;
    }

    @AuraEnabled
    public static void postMessage(Id caseId, String message) {
        if (String.isBlank(message)) {
            return;
        }
        // Cette insertion crée un vrai commentaire visible par l'agent dans Salesforce
        insert as user new CaseComment(
            ParentId = caseId,
            CommentBody = message,
            IsPublished = true // Crucial pour que le client et l'agent voient le message
        );
    }

    public class CommentData {
        @AuraEnabled public String id;
        @AuraEnabled public String author;
        @AuraEnabled public String body;
        @AuraEnabled public DateTime createdDate;
        
        public CommentData(CaseComment c) {
            this.id = c.Id;
            this.author = c.CreatedBy.Name;
            this.body = c.CommentBody;
            this.createdDate = c.CreatedDate;
        }
    }
}