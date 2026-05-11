public with sharing class CaseCommentController {
    @AuraEnabled(cacheable=true)
    public static List<FeedData> getCaseHistory(Id caseId) {
        List<FeedData> history = new List<FeedData>();
        
        // On récupère le fil d'actualité ET les changements de champs détaillés
        for(CaseFeed f : [SELECT Id, Body, Title, Type, CreatedDate, CreatedBy.Name,
                          (SELECT FieldName, OldValue, NewValue FROM FeedTrackedChanges)
                          FROM CaseFeed WHERE ParentId = :caseId 
                          WITH USER_MODE ORDER BY CreatedDate DESC]) {
            history.add(new FeedData(f));
        }
        return history;
    }

    @AuraEnabled
    public static void postMessage(Id caseId, String message) {
        CaseComment newComment = new CaseComment(
            ParentId = caseId, 
            CommentBody = message, 
            IsPublished = true
        );
        insert as user newComment;
    }

    public class FeedData {
        @AuraEnabled public String id;
        @AuraEnabled public String author;
        @AuraEnabled public String body;
        @AuraEnabled public String icon;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public Boolean isAction;

        public FeedData(CaseFeed f) {
            this.id = f.Id;
            this.author = f.CreatedBy.Name;
            this.createdDate = f.CreatedDate;
            this.isAction = (f.Type != 'TextPost' && f.Type != 'CommentEvent');
            
            // LOGIQUE DE DÉTAILS : Priorité absolue aux changements de champs
            if (!f.FeedTrackedChanges.isEmpty()) {
                FeedTrackedChange ftc = f.FeedTrackedChanges[0];
                String fieldName = ftc.FieldName.replace('Case.', '');
                // On construit manuellement la phrase en Anglais
                this.body = fieldName + ' updated: ' + String.valueOf(ftc.OldValue) + ' to ' + String.valueOf(ftc.NewValue);
                this.icon = 'standard:case_change_status';
            } else if (f.Title != null && f.Title != '') {
                this.body = f.Title;
                this.icon = 'standard:case_change_status';
            } else if (f.Body != null && f.Body != '') {
                this.body = f.Body;
                this.icon = 'standard:comment';
            } else {
                this.body = 'Case Update';
                this.icon = 'standard:case';
            }

            // Correction spécifique pour l'icône de création
            if (f.Type == 'CreateRecordEvent') {
                this.body = 'Case Created';
                this.icon = 'standard:case';
            }
        }
    }
}