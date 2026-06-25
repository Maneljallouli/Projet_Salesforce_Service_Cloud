@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseCommentController {

    @AuraEnabled(cacheable=true)
    public static List<CommentData> getCaseComments(Id caseId) {
        List<CommentData> comments = new List<CommentData>();
        try {
            // Récupère les UserType des créateurs pour distinguer interne vs portail
            List<CaseComment> rawComments = [
                SELECT Id, CommentBody, CreatedDate, CreatedById, CreatedBy.Name
                FROM CaseComment
                WHERE ParentId = :caseId 
                AND IsPublished = true
                ORDER BY CreatedDate DESC
            ];

            Set<Id> creatorIds = new Set<Id>();
            for (CaseComment c : rawComments) {
                creatorIds.add(c.CreatedById);
            }

            Map<Id, User> usersMap = new Map<Id, User>([
                SELECT Id, UserType
                FROM User
                WHERE Id IN :creatorIds
            ]);

            for (CaseComment c : rawComments) {
                User creator = usersMap.get(c.CreatedById);
                // UserType = 'Standard' → agent interne (Service Cloud)
                // UserType = 'CspLitePortal', 'PowerCustomerSuccess', 'CustomerSuccess' → portail
                Boolean isInternal = (creator != null && creator.UserType == 'Standard');
                comments.add(new CommentData(c, isInternal));
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
        @AuraEnabled public Boolean isClient;

        public CommentData(CaseComment c, Boolean isInternal) {
            this.id = c.Id;
            this.author = c.CreatedBy.Name;
            this.body = c.CommentBody;
            this.createdDate = c.CreatedDate;
            // isClient = true → bulle droite (portail)
            // isClient = false → bulle gauche (agent Service Cloud)
            this.isClient = !isInternal;
        }
    }
}