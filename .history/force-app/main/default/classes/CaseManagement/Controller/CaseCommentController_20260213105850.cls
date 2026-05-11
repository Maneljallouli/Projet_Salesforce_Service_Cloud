public with sharing class CaseCommentController {
    @AuraEnabled(cacheable=true)
    public static List<CommentData> getCaseComments(Id caseId) {
        List<CommentData> comments = new List<CommentData>();
        try {
            // On récupère uniquement les commentaires réels
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

    public class CommentData {
        @AuraEnabled public String id;
        @AuraEnabled public String author;
        @AuraEnabled public String body;
        @AuraEnabled public DateTime createdDate;
        
        public CommentData(CaseComment c) {
            this.id = c.Id;
            this.author = c.CreatedBy.Name; // Nom de l'agent ou du client
            this.body = c.CommentBody;      // Le texte de l'échange
            this.createdDate = c.CreatedDate;
        }
    }
}