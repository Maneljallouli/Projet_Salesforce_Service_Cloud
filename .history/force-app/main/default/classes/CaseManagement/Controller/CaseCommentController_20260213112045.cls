public with sharing class CaseCommentController {
    @AuraEnabled(cacheable=true)
    public static List<CommentData> getCaseComments(Id caseId) {
        List<CommentData> comments = new List<CommentData>();
        try {
            // On récupère le corps du message et la date exacte
            for (CaseComment c : [
                SELECT Id, CommentBody, CreatedDate, CreatedBy.Name
                FROM CaseComment
                WHERE ParentId = :caseId AND IsPublished = true
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
        if (String.isNotBlank(message)) {
            insert as user new CaseComment(
                ParentId = caseId, 
                CommentBody = message, 
                IsPublished = true
            );
        }
    }

    public class CommentData {
        @AuraEnabled public String id;
        @AuraEnabled public String author;
        @AuraEnabled public String body;
        @AuraEnabled public DateTime createdDate; // Champ pour la date et l'heure
        
        public CommentData(CaseComment c) {
            this.id = c.Id;
            this.author = c.CreatedBy.Name;
            this.body = c.CommentBody;
            this.createdDate = c.CreatedDate;
        }
    }
}