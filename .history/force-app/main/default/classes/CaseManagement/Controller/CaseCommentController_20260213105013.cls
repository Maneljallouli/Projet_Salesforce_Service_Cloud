public with sharing class CaseCommentController {

    // On déplace la Map au niveau supérieur pour corriger l'erreur 'static'
    private static final Map<String, Schema.SObjectField> CASE_FIELDS = 
        Schema.SObjectType.Case.fields.getMap();

    @AuraEnabled(cacheable=true)
    public static List<FeedData> getCaseHistory(Id caseId) {
        List<FeedData> history = new List<FeedData>();
        try {
            for (CaseFeed f : [
                SELECT Id, Body, Title, Type, CreatedDate, CreatedBy.Name,
                       (SELECT FieldName, OldValue, NewValue FROM FeedTrackedChanges)
                FROM CaseFeed
                WHERE ParentId = :caseId
                WITH USER_MODE
                ORDER BY CreatedDate DESC
            ]) {
                history.add(new FeedData(f));
            }
        } catch (Exception e) {
            System.debug('CaseCommentController error: ' + e.getMessage());
        }
        return history;
    }

    @AuraEnabled
    public static void postMessage(Id caseId, String message) {
        if (String.isNotBlank(message)) {
            insert as user new CaseComment(
                ParentId = caseId,
                CommentBody = message,
                IsPublished = true
            );
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

            // --- PRIORITÉ 1 : Changements de champs (Tracked Changes) ---
            if (f.FeedTrackedChanges != null && !f.FeedTrackedChanges.isEmpty()) {
                this.body = formatChanges(f.FeedTrackedChanges);
                this.icon = 'standard:case_change_status';
            } 
            // --- PRIORITÉ 2 : Création du ticket ---
            else if (f.Type == 'CreateRecordEvent') {
                this.body = 'Case Created';
                this.icon = 'standard:case';
            } 
            // --- PRIORITÉ 3 : Messages et Titres propres ---
            else {
                this.body = cleanMessage(f);
                this.icon = 'standard:comment';
            }
        }

        private String formatChanges(List<FeedTrackedChange> ftcList) {
            List<String> changeStrings = new List<String>();
            for (FeedTrackedChange ftc : ftcList) {
                String fieldApi = ftc.FieldName != null ? ftc.FieldName.replace('Case.', '') : 'Field';
                
                // On récupère les labels (ex: "New" au lieu de "1")
                String oldV = resolveLabel(fieldApi, String.valueOf(ftc.OldValue));
                String newV = resolveLabel(fieldApi, String.valueOf(ftc.NewValue));

                // On évite d'afficher "updated from — to —"
                if (oldV != '—' || newV != '—') {
                    changeStrings.add(fieldApi + ' updated: ' + oldV + ' to ' + newV);
                }
            }
            return changeStrings.isEmpty() ? 'Case details updated' : String.join(changeStrings, ' • ');
        }

        private String cleanMessage(CaseFeed f) {
            // On vérifie le Body en premier
            if (String.isNotBlank(f.Body)) {
                return f.Body;
            } 
            // On utilise le titre seulement s'il ne contient pas de JSON technique
            if (String.isNotBlank(f.Title) && !f.Title.contains('{"fu"')) {
                return f.Title;
            }
            return 'Activity recorded';
        }

        private String resolveLabel(String fieldApi, String val) {
            if (val == null || val == 'null') return '—';
            
            if (CASE_FIELDS.containsKey(fieldApi)) {
                Schema.DescribeFieldResult dfr = CASE_FIELDS.get(fieldApi).getDescribe();
                if (dfr.getType() == Schema.DisplayType.Picklist) {
                    for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                        if (pe.getValue() == val) return pe.getLabel();
                    }
                }
            }
            return val;
        }
    }
}