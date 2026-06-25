@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseCommentController {

    @AuraEnabled(cacheable=true)
    public static List<CommentData> getCaseComments(Id caseId) {
        List<CommentData> comments = new List<CommentData>();
        try {
            for (CaseComment c : [
                SELECT Id, CommentBody, CreatedDate, CreatedBy.Name
                FROM CaseComment
                WHERE ParentId = :caseId 
                AND IsPublished = true
                ORDER BY CreatedDate DESC
            ]) {
                comments.add(new CommentData(c));
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving comments: ' + e.getMessage());
        }
        return comments;
    }

    // Appelée depuis le portail (client)
    @AuraEnabled
    public static void postMessage(Id caseId, String message) {
        if (String.isBlank(message)) return;
        try {
            CaseComment newCc = new CaseComment();
            newCc.ParentId = caseId;
            newCc.CommentBody = message;
            newCc.IsPublished = true;
            insert newCc;
        } catch (Exception e) {
            throw new AuraHandledException('Cannot send message: ' + e.getMessage());
        }
    }

    // Appelée depuis Service Cloud (agent)
    @AuraEnabled
    public static void postSupportMessage(Id caseId, String message) {
        if (String.isBlank(message)) return;
        try {
            CaseComment newCc = new CaseComment();
            newCc.ParentId = caseId;
            newCc.CommentBody = '[SUPPORT]' + message;
            newCc.IsPublished = true;
            insert newCc;
        } catch (Exception e) {
            throw new AuraHandledException('Cannot send message: ' + e.getMessage());
        }
    }

    public class CommentData {
        @AuraEnabled public String id;
        @AuraEnabled public String author;
        @AuraEnabled public String body;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public Boolean isClient;

        public CommentData(CaseComment c) {
            this.id = c.Id;
            this.isClient = !c.CommentBody.startsWith('[SUPPORT]');
            this.body = c.CommentBody.startsWith('[SUPPORT]')
                ? c.CommentBody.removeStart('[SUPPORT]')
                : c.CommentBody;
            this.author = this.isClient ? c.CreatedBy.Name : 'Support Client';
            this.createdDate = c.CreatedDate;
        }
    }
}