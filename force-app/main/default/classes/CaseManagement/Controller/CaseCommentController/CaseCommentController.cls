/**
 * @description Controller for Case Discussion. 
 * 'without sharing' is necessary because External Profiles lack 'Edit' permission on Case.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseCommentController {

    @AuraEnabled(cacheable=true)
    public static List<CommentData> getCaseComments(Id caseId) {
        List<CommentData> comments = new List<CommentData>();
        try {
            // On ignore l'alerte CRUD ici car l'utilisateur doit voir les messages 
            // même si son profil est restreint.
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

    @AuraEnabled
    public static void postMessage(Id caseId, String message) {
        if (String.isBlank(message)) {
            return;
        }
        
        try {
            // Création du commentaire en mode système pour contourner 
            // l'absence du droit 'Edit' sur le Case.
            CaseComment newCc = new CaseComment();
            newCc.ParentId = caseId;
            newCc.CommentBody = message; 
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

        public CommentData(CaseComment c) {
            this.id = c.Id;
            this.author = c.CreatedBy.Name;
            this.body = c.CommentBody;
            this.createdDate = c.CreatedDate;
        }
    }
}