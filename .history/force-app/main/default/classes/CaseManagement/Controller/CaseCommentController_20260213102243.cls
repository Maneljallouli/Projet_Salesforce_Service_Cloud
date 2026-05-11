public with sharing class CaseCommentController {
    @AuraEnabled(cacheable=true)
    public static List<FeedData> getCaseHistory(Id caseId) {
        List<FeedData> history = new List<FeedData>();
        try {
            // Extraction des données avec gestion du mode utilisateur
            for(CaseFeed f : [SELECT Id, Body, Title, Type, CreatedDate, CreatedBy.Name,
                              (SELECT FieldName, OldValue, NewValue FROM FeedTrackedChanges)
                              FROM CaseFeed WHERE ParentId = :caseId 
                              WITH USER_MODE ORDER BY CreatedDate DESC]) {
                history.add(new FeedData(f));
            }
        } catch (Exception e) {
            // Permet de voir l'erreur dans les logs sans bloquer le composant
            System.debug('Error: ' + e.getMessage());
        }
        return history;
    }

    @AuraEnabled
    public static void postMessage(Id caseId, String message) {
        if (String.isNotBlank(message)) {
            insert as user new CaseComment(ParentId = caseId, CommentBody = message, IsPublished = true);
        }
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
            this.author = f.CreatedBy != null ? f.CreatedBy.Name : 'System';
            this.createdDate = f.CreatedDate;
            this.isAction = (f.Type != 'TextPost' && f.Type != 'CommentEvent');

            // --- GESTION DU CORPS DU MESSAGE (POUR ÉVITER LE JSON) ---
            if (f.FeedTrackedChanges != null && !f.FeedTrackedChanges.isEmpty()) {
                // Traduction manuelle pour obtenir : "Status updated from New to Waiting Customer"
                FeedTrackedChange ftc = f.FeedTrackedChanges[0];
                String field = ftc.FieldName != null ? ftc.FieldName.replace('Case.', '') : 'Field';
                this.body = field + ' updated from ' + ftc.OldValue + ' to ' + ftc.NewValue;
            } else if (String.isNotBlank(f.Title) && !f.Title.contains('{"fu"')) {
                // On utilise le titre seulement s'il n'est pas technique
                this.body = f.Title;
            } else if (String.isNotBlank(f.Body)) {
                this.body = f.Body;
            } else {
                this.body = 'Activity recorded';
            }

            // --- GESTION DES ICÔNES (AVEC ACCOLADES POUR PMD) ---
            if (f.Type == 'TrackedChange') {
                this.icon = 'standard:case_change_status';
            } else if (f.Type == 'CreateRecordEvent') {
                this.body = 'Case Created';
                this.icon = 'standard:case';
            } else {
                this.icon = 'standard:comment';
            }
        }
    }
}