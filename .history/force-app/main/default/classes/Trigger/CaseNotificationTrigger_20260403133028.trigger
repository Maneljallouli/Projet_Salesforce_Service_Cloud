trigger CaseNotificationTrigger on Case (after update) {
    List<Case_Status_Change__e> events = new List<Case_Status_Change__e>();

    for (Case c : Trigger.new) {
        Case oldCase = Trigger.oldMap.get(c.Id);

        // On vérifie le changement de statut ET la présence du Contact
        if (c.Status != oldCase.Status && c.ContactId != null) {
            events.add(new Case_Status_Change__e(
                Case_Id__c = c.Id,
                Case_Subject__c = c.Subject,
                New_Status__c = c.Status,
                Contact_Id__c = c.ContactId // Très important pour le filtrage
            ));
        }
    }

    if (!events.isEmpty()) {
        EventBus.publish(events);
        System.debug('Nombre d\'événements publiés : ' + events.size());
    }
}