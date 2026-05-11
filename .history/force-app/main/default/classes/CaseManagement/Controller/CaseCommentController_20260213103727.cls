public class FeedData {

    @AuraEnabled public String id;
    @AuraEnabled public String author;
    @AuraEnabled public String body;
    @AuraEnabled public String icon;
    @AuraEnabled public DateTime createdDate;
    @AuraEnabled public Boolean isAction;

    private static final Map<String, Schema.DescribeFieldResult> CASE_FIELDS =
        Schema.SObjectType.Case.fields.getMap();

    public FeedData(CaseFeed f) {
        this.id = f.Id;
        this.author = resolveAuthor(f);
        this.createdDate = f.CreatedDate;
        this.isAction = isActionEvent(f);

        if (hasTrackedChanges(f)) {
            buildTrackedChangeBody(f);
        } else if (isCreateEvent(f)) {
            buildCreateBody();
        } else {
            buildMessageBody(f);
        }
    }

    // ================= PRIVATE HELPERS =================

    private static String resolveAuthor(CaseFeed f) {
        return f.CreatedBy != null ? f.CreatedBy.Name : 'System';
    }

    private static Boolean isActionEvent(CaseFeed f) {
        return f.Type != 'TextPost' && f.Type != 'CommentEvent';
    }

    private static Boolean hasTrackedChanges(CaseFeed f) {
        return f.FeedTrackedChanges != null && !f.FeedTrackedChanges.isEmpty();
    }

    private static Boolean isCreateEvent(CaseFeed f) {
        return f.Type == 'CreateRecordEvent';
    }

    private void buildTrackedChangeBody(CaseFeed f) {

        List<String> changes = new List<String>();

        for (FeedTrackedChange ftc : f.FeedTrackedChanges) {
            changes.add(formatTrackedChange(ftc));
        }

        this.body = String.join(changes, ' • ');
        this.icon = 'standard:case_change_status';
    }

    private String formatTrackedChange(FeedTrackedChange ftc) {

        String fieldApi = ftc.FieldName != null
            ? ftc.FieldName.replace('Case.', '')
            : 'Field';

        String oldVal = normalizeValue(ftc.OldValue);
        String newVal = normalizeValue(ftc.NewValue);

        if (CASE_FIELDS.containsKey(fieldApi)) {
            oldVal = resolvePicklistLabel(fieldApi, oldVal);
            newVal = resolvePicklistLabel(fieldApi, newVal);
        }

        return fieldApi + ' updated from ' + oldVal + ' to ' + newVal;
    }

    private static String normalizeValue(Object val) {
        return val == null ? '—' : String.valueOf(val);
    }

    private static String resolvePicklistLabel(String fieldApi, String value) {

        Schema.DescribeFieldResult dfr = CASE_FIELDS.get(fieldApi);

        if (dfr == null) {
            return value;
        }

        if (dfr.getType() != Schema.DisplayType.Picklist &&
            dfr.getType() != Schema.DisplayType.MultiPicklist) {
            return value;
        }

        for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
            if (pe.getValue() == value) {
                return pe.getLabel();
            }
        }

        return value;
    }

    private void buildCreateBody() {
        this.body = 'Case Created';
        this.icon = 'standard:case';
    }

    private void buildMessageBody(CaseFeed f) {

        if (String.isNotBlank(f.Body)) {
            this.body = f.Body;
        } else if (String.isNotBlank(f.Title) && !f.Title.contains('{"fu"')) {
            this.body = f.Title;
        } else {
            this.body = 'Activity recorded';
        }

        this.icon = 'standard:comment';
    }
}
