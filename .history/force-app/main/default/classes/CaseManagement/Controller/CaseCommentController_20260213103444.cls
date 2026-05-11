public FeedData(CaseFeed f) {
    this.id = f.Id;
    this.author = f.CreatedBy != null ? f.CreatedBy.Name : 'System';
    this.createdDate = f.CreatedDate;
    this.isAction = (f.Type != 'TextPost' && f.Type != 'CommentEvent');

    // ===== CASE FIELD METADATA (for picklists) =====
    Map<String, Schema.DescribeFieldResult> caseFields =
        Schema.SObjectType.Case.fields.getMap();

    // ===== TRACKED CHANGES =====
    if (f.FeedTrackedChanges != null && !f.FeedTrackedChanges.isEmpty()) {

        List<String> changes = new List<String>();

        for (FeedTrackedChange ftc : f.FeedTrackedChanges) {

            String fieldApi = ftc.FieldName != null
                ? ftc.FieldName.replace('Case.', '')
                : 'Field';

            String oldVal = String.valueOf(ftc.OldValue);
            String newVal = String.valueOf(ftc.NewValue);

            if (oldVal == 'null') oldVal = '—';
            if (newVal == 'null') newVal = '—';

            // ===== PICKLIST LABEL RESOLUTION =====
            if (caseFields.containsKey(fieldApi)) {
                Schema.DescribeFieldResult dfr = caseFields.get(fieldApi);

                if (dfr.getType() == Schema.DisplayType.Picklist ||
                    dfr.getType() == Schema.DisplayType.MultiPicklist) {

                    Map<String, String> pickMap = new Map<String, String>();
                    for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                        pickMap.put(pe.getValue(), pe.getLabel());
                    }

                    if (pickMap.containsKey(oldVal)) oldVal = pickMap.get(oldVal);
                    if (pickMap.containsKey(newVal)) newVal = pickMap.get(newVal);
                }
            }

            changes.add(
                fieldApi + ' updated from ' + oldVal + ' to ' + newVal
            );
        }

        this.body = String.join(changes, ' • ');
        this.icon = 'standard:case_change_status';
        return;
    }

    // ===== CREATE EVENT =====
    if (f.Type == 'CreateRecordEvent') {
        this.body = 'Case Created';
        this.icon = 'standard:case';
        return;
    }

    // ===== CLEAN TEXT POSTS =====
    if (String.isNotBlank(f.Body)) {
        this.body = f.Body;
    } else if (String.isNotBlank(f.Title) && !f.Title.contains('{"fu"')) {
        this.body = f.Title;
    } else {
        this.body = 'Activity recorded';
    }

    this.icon = 'standard:comment';
}
