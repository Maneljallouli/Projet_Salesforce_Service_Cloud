public with sharing class CaseCommentController {
    private static final Map<String, Schema.SObjectField> CASE_FIELDS = 
        Schema.SObjectType.Case.fields.getMap();

    @AuraEnabled(cacheable=true)
    public static List<FeedData> getCaseHistory(Id caseId) {
        List<FeedData> history = new List<FeedData>();
        try {
            for (CaseFeed f : [
                SELECT Id, Body, Title, Type, CreatedDate, CreatedBy.Name,
                       (SELECT FieldName, OldValue, NewValue FROM FeedTrackedChanges)
                FROM CaseFeed WHERE ParentId = :caseId WITH USER_MODE ORDER BY CreatedDate DESC
            ]) {
                history.add(new FeedData(f));
            }
        } catch (Exception e) {
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

            // --- FORCE LE NETTOYAGE ICI ---
            // Si on a des changements de champs, on les utilise en PRIORITÉ ABSOLUE
            if (f.FeedTrackedChanges != null && !f.FeedTrackedChanges.isEmpty()) {
                this.body = formatChanges(f.FeedTrackedChanges);
                this.icon = 'standard:case_change_status';
            } 
            // Si c'est du JSON technique dans le titre, on le remplace par du texte propre
            else if (String.isNotBlank(f.Title) && f.Title.contains('{"fu"')) {
                this.body = 'Case details updated';
                this.icon = 'standard:case_change_status';
            }
            else if (f.Type == 'CreateRecordEvent') {
                this.body = 'Case Created';
                this.icon = 'standard:case';
            } 
            else {
                this.body = String.isNotBlank(f.Body) ? f.Body : (String.isNotBlank(f.Title) ? f.Title : 'Update recorded');
                this.icon = 'standard:comment';
            }
        }

        private String formatChanges(List<FeedTrackedChange> ftcList) {
            List<String> results = new List<String>();
            for (FeedTrackedChange ftc : ftcList) {
                String field = ftc.FieldName.replace('Case.', '');
                String oldV = resolveLabel(field, String.valueOf(ftc.OldValue));
                String newV = resolveLabel(field, String.valueOf(ftc.NewValue));
                
                // On ne garde que les vrais changements
                if (oldV != '—' || newV != '—') {
                    results.add(field + ': ' + oldV + ' to ' + newV);
                }
            }
            return results.isEmpty() ? 'Case updated' : String.join(results, ' • ');
        }

        private String resolveLabel(String field, String val) {
            if (val == null || val == 'null' || val == '') return '—';
            if (CASE_FIELDS.containsKey(field)) {
                Schema.DescribeFieldResult d = CASE_FIELDS.get(field).getDescribe();
                if (d.getType() == Schema.DisplayType.Picklist) {
                    for (Schema.PicklistEntry pe : d.getPicklistValues()) {
                        if (pe.getValue() == val) return pe.getLabel();
                    }
                }
            }
            return val;
        }
    }
}