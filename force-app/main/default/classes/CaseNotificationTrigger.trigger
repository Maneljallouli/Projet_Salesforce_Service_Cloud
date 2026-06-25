trigger CaseNotificationTrigger on Case (after insert, after update) {

    Set<Id> contactIds = new Set<Id>();
    for (Case c : Trigger.new) {
        if (c.ContactId != null) {
            contactIds.add(c.ContactId);
        }
    }

    Map<Id, Id> contactToUserMap = new Map<Id, Id>();
    if (!contactIds.isEmpty()) {
        for (User u : [SELECT Id, ContactId FROM User WHERE ContactId IN :contactIds]) {
            contactToUserMap.put(u.ContactId, u.Id);
        }
    }

    List<User_Notification__c> notifsToInsert = new List<User_Notification__c>();
    List<Case_Status_Change__e> eventsToPublish = new List<Case_Status_Change__e>();

    for (Case c : Trigger.new) {
        Id portalUserId = contactToUserMap.get(c.ContactId);
        if (portalUserId == null) {
            continue; // pas d'utilisateur portail associé à ce contact
        }

        Boolean shouldNotify = false;
        String message = '';

        if (Trigger.isInsert) {
            shouldNotify = true;
            message = 'Votre demande #' + c.CaseNumber + ' a bien été créée et assignée à notre équipe.';
        } else if (Trigger.isUpdate) {
            Case oldCase = Trigger.oldMap.get(c.Id);
            if (c.Status != oldCase.Status) {
                shouldNotify = true;
                message = 'Le statut de votre demande #' + c.CaseNumber + ' est passé à : ' + c.Status;
            }
        }

        if (shouldNotify) {
            notifsToInsert.add(new User_Notification__c(
                User__c = portalUserId,
                Case__c = c.Id,
                Message__c = message,
                Status__c = c.Status,
                Is_Read__c = false
            ));

            eventsToPublish.add(new Case_Status_Change__e(
                Case_Id__c     = String.valueOf(c.Id),
                Case_Subject__c = c.Subject,
                Contact_Id__c  = String.valueOf(c.ContactId),
                New_Status__c  = c.Status
            ));
        }
    }

    if (!notifsToInsert.isEmpty()) {
        Database.insert(notifsToInsert, AccessLevel.SYSTEM_MODE);
    }

    if (!eventsToPublish.isEmpty()) {
        EventBus.publish(eventsToPublish);
    }
}