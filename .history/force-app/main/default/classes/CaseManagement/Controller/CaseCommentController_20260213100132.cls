public with sharing class CaseCommentController {
    @AuraEnabled(cacheable=true)
    public static List<FeedData> getCaseHistory(Id caseId) {
        List<FeedData> history = new List<FeedData>();
        
        // On récupère tout le flux (TrackedChanges pour les actions, TextPost pour les commentaires)
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
        // Crée un commentaire public que l'agent verra dans sa console
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
            this.isAction = (f.Type == 'TrackedChange' || f.Type == 'CreateRecordEvent');
            
            if(f.Type == 'TrackedChange' && !f.FeedTrackedChanges.isEmpty()) {
                FeedTrackedChange c = f.FeedTrackedChanges[0];
                // Traduction dynamique des noms de champs techniques
                String field = c.FieldName.contains('Status') ? 'Statut' : c.FieldName;
                this.body = field + ' mis à jour : ' + c.OldValue + ' → ' + c.NewValue;
                this.icon = 'standard:case_change_status';
            } else if(f.Type == 'CreateRecordEvent') {
                this.body = 'Ouverture de la requête';
                this.icon = 'standard:case';
            } else {
                // C'est un commentaire ou un post Chatter
                this.body = f.Body != null ? f.Body : (f.Title != null ? f.Title : 'Mise à jour du dossier');
                this.icon = 'standard:comment';
            }
        }
    }
}