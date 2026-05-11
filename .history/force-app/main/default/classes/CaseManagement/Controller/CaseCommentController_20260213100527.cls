public with sharing class CaseCommentController {
    @AuraEnabled(cacheable=true)
    public static List<FeedData> getCaseHistory(Id caseId) {
        List<FeedData> history = new List<FeedData>();
        
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
        insert as user new CaseComment(ParentId = caseId, CommentBody = message, IsPublished = true);
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
                // Extraction du changement précis
                FeedTrackedChange c = f.FeedTrackedChanges[0];
                String fieldLabel = c.FieldName.contains('Status') ? 'Statut' : c.FieldName;
                // C'est ici que l'on construit le texte : "Statut : New vers Waiting Customer"
                this.body = fieldLabel + ' : ' + c.OldValue + ' → ' + c.NewValue;
                this.icon = 'standard:case_change_status';
            } else if(f.Type == 'CreateRecordEvent') {
                this.body = 'La requête a été créée.';
                this.icon = 'standard:case';
            } else {
                // Pour les commentaires réels de l'agent
                this.body = f.Body != null ? f.Body : (f.Title != null ? f.Title : 'Mise à jour du dossier');
                this.icon = 'standard:comment';
            }
        }
    }
}