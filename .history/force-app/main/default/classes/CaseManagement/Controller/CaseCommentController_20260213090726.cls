public with sharing class CaseCommentController {
    @AuraEnabled(cacheable=true)
    public static List<CaseComment> getCaseComments(Id caseId) {
        return [SELECT Id, CommentBody, CreatedDate, CreatedBy.Name 
                FROM CaseComment 
                WHERE ParentId = :caseId 
                ORDER BY CreatedDate DESC];
    }
}