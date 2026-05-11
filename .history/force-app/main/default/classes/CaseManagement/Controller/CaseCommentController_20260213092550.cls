public with sharing class CaseCommentController {
    
    @AuraEnabled(cacheable=true)
    public static List<CaseComment> getCaseComments(Id caseId) {
        // Correction : On s'assure que la requête est propre et bien formatée
        return [
            SELECT Id, CommentBody, CreatedDate, CreatedBy.Name 
            FROM CaseComment 
            WHERE ParentId = :caseId 
            AND IsPublished = true 
            WITH USER_MODE 
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static void addCaseComment(Id caseId, String commentBody) {
        CaseComment newComment = new CaseComment();
        newComment.ParentId = caseId;
        newComment.CommentBody = commentBody;
        newComment.IsPublished = true; // Pour que ce soit visible sur le portail
        
        insert as user newComment;
    }
}