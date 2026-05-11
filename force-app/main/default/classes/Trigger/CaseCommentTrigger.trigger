trigger CaseCommentTrigger on CaseComment (after insert) {

    List<Case_Message__e> events = new List<Case_Message__e>();

    for (CaseComment cc : Trigger.new) {
        if (cc.ParentId != null) {
            events.add(
                new Case_Message__e(
                    Case_Id__c = cc.ParentId
                )
            );
        }
    }

    if (!events.isEmpty()) {
        EventBus.publish(events);
    }
}