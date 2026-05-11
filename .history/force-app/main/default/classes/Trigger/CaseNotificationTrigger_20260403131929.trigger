trigger CaseNotificationTrigger on Case (after update) {
    List<Case_Status_Change__e> events = new List<Case_Status_Change__e>();

    for (Case c : Trigger.new) {
        Case oldCase = Trigger.oldMap.get(c.Id);

        if (c.Status != oldCase.Status && c.ContactId != null) {
            Case_Status_Change__e evt = new Case_Status_Change__e();
            evt.Case_Id__c      = c.Id;
            evt.Case_Subject__c = c.Subject;
            evt.New_Status__c   = c.Status;
            evt.Contact_Id__c   = c.ContactId;
            events.add(evt);
        }
    }

    if (!events.isEmpty()) {
        List<Database.SaveResult> results = EventBus.publish(events);
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug('Erreur publication event: ' + err.getMessage());
                }
            }
        }
    }
}
