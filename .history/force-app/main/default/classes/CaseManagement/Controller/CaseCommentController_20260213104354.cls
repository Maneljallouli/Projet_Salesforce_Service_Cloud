public with sharing class CaseCommentController {

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
        if (String.isBlank(message)) {
            return;
        }
        insert as user new CaseComment(
            ParentId = caseId,
            CommentBody = message,
            IsPublished = true
        );
    }

    // ===================== DTO CLASS =====================

    public class FeedData {
        @AuraEnabled public String id;
        @AuraEnabled public String author;
        @AuraEnabled public String body;
        @AuraEnabled public String icon;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public Boolean isAction;

        // CORRECTION ICI : Le type doit être SObjectField
        private static final Map<String, Schema.SObjectField> FIELD_MAP = 
            Schema.SObjectType.Case.fields.getMap();

        public FeedData(CaseFeed f) {
            this.id = f.Id;
            this.author = f.CreatedBy != null ? f.CreatedBy.Name : 'System';
            this.createdDate = f.CreatedDate;
            this.isAction = (f.Type != 'TextPost' && f.Type != 'CommentEvent');

            if (f.FeedTrackedChanges != null && !f.FeedTrackedChanges.isEmpty()) {
                buildTrackedChanges(f);
            } else if (f.Type == 'CreateRecordEvent') {
                this.body = 'Case Created';
                this.icon = 'standard:case';
            } else {
                buildMessage(f);
            }
        }

        private void buildTrackedChanges(CaseFeed f) {
            List<String> changes = new List<String>();
            for (FeedTrackedChange ftc : f.FeedTrackedChanges) {
                String fieldApi = ftc.FieldName != null ? ftc.FieldName.replace('Case.', '') : 'Field';
                
                String oldVal = normalize(ftc.OldValue);
                String newVal = normalize(ftc.NewValue);

                // Résolution des labels pour Status, Priority, etc.
                oldVal = resolvePicklistLabel(fieldApi, oldVal);
                newVal = resolvePicklistLabel(fieldApi, newVal);

                changes.add(fieldApi + ' updated from ' + oldVal + ' to ' + newVal);
            }
            this.body = String.join(changes, ' • ');
            this.icon = 'standard:case_change_status';
        }

        private void buildMessage(CaseFeed f) {
            if (String.isNotBlank(f.Body)) {
                this.body = f.Body;
            } else if (String.isNotBlank(f.Title) && !f.Title.contains('{"fu"')) {
                this.body = f.Title;
            } else {
                this.body = 'Activity recorded';
            }
            this.icon = 'standard:comment';
        }

        private static String normalize(Object value) {
            return value == null ? '—' : String.valueOf(value);
        }

        private static String resolvePicklistLabel(String fieldApi, String value) {
            // Utilisation correcte de la Map de champs
            if (!FIELD_MAP.containsKey(fieldApi)) {
                return value;
            }

            Schema.DescribeFieldResult dfr = FIELD_MAP.get(fieldApi).getDescribe();

            if (dfr.getType() != Schema.DisplayType.Picklist && 
                dfr.getType() != Schema.DisplayType.MultiPicklist) {
                return value;
            }

            for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                if (pe.getValue() == value) {
                    return pe.getLabel(); // Retourne "Nouveau" au lieu de "1"
                }
            }
            return value;
        }
    }
}