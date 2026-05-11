public with sharing class CaseCommentController {
    
    @AuraEnabled(cacheable=true)
    public static List<CaseComment> getCaseComments(Id caseId) {
        return [SELECT Id, CommentBody, CreatedDate, CreatedBy.Name 
                FROM CaseComment 
                WHERE ParentId = :caseId 
                ORDER BY CreatedDate DESC];
    }

    @AuraEnabled
    public static void addCaseComment(Id caseId, String commentBody) {
        CaseComment newComment = new CaseComment();
        newComment.ParentId = caseId;
        newComment.CommentBody = commentBody;
        newComment.IsPublished = true; // Très important pour que le client le voie
        insert newComment;
    }
}