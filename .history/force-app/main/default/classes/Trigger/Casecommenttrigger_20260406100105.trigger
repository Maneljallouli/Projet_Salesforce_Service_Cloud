trigger CaseCommentTrigger on CaseComment (after insert) {
    List<Case_Message__e> events = new List<Case_Message__e>();

    for (CaseComment cc : Trigger.new) {
        Case_Message__e evt = new Case_Message__e();
        evt.Case_Id__c = cc.ParentId;
        events.add(evt);
    }

    if (!events.isEmpty()) {
        EventBus.publish(events);
    }
}
