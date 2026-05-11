public with sharing class CaseCommentController {
    
    @AuraEnabled(cacheable=true)
    public static List<CaseComment> getCaseComments(Id caseId) {
        // Validation CRUD via USER_MODE
        return [SELECT Id, CommentBody, CreatedDate, CreatedBy.Name 
                FROM CaseComment 
                WHERE ParentId = :caseId 
                WITH USER_MODE
                ORDER BY CreatedDate DESC];
    }

    @AuraEnabled
    public static void addCaseComment(Id caseId, String commentBody) {
        CaseComment newComment = new CaseComment();
        newComment.ParentId = caseId;
        newComment.CommentBody = commentBody;
        newComment.IsPublished = true; 
        
        // Validation CRUD lors de l'insertion
        insert as user newComment;
    }
}