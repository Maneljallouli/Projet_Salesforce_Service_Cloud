@AuraEnabled(cacheable=true)
public static List<CaseComment> getCaseComments(Id caseId) {
    return [SELECT Id, CommentBody, CreatedDate, CreatedBy.Name 
            FROM CaseComment 
            WHERE ParentId = :caseId 
            AND IsPublished = true  /* Force l'affichage des messages publics */
            WITH USER_MODE
            ORDER BY CreatedDate DESC];
}