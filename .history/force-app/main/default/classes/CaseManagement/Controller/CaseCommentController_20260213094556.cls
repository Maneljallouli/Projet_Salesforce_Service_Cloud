public with sharing class CaseCommentController {
    @AuraEnabled(cacheable=true)
    public static List<FeedData> getCaseHistory(Id caseId) {
        List<FeedData> history = new List<FeedData>();
        for(CaseFeed f : [SELECT Id, Body, Title, Type, CreatedDate, CreatedBy.Name 
                          FROM CaseFeed WHERE ParentId = :caseId 
                          WITH USER_MODE ORDER BY CreatedDate DESC]) {
            history.add(new FeedData(f));
        }
        return history;
    }

    public class FeedData {
        @AuraEnabled public String id;
        @AuraEnabled public String author;
        @AuraEnabled public String body;
        @AuraEnabled public String icon;
        @AuraEnabled public DateTime createdDate;

        public FeedData(CaseFeed f) {
            this.id = f.Id;
            this.author = f.CreatedBy.Name;
            this.createdDate = f.CreatedDate;
            // On choisit l'icône et le texte selon le type
            if(f.Type == 'TrackedChange') {
                this.body = f.Title; // "Statut changé" ou "Record updated"
                this.icon = 'standard:record';
            } else if(f.Type == 'CreateRecordEvent') {
                this.body = 'Requête créée';
                this.icon = 'standard:case';
            } else {
                this.body = f.Body != null ? f.Body : 'Mise à jour système';
                this.icon = 'standard:post';
            }
        }
    }
}