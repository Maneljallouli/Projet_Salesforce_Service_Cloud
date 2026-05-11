trigger CaseNotificationTrigger on Case (after update) {
    List<Case_Status_Change__e> events   = new List<Case_Status_Change__e>();
    List<User_Notification__c>  notifs   = new List<User_Notification__c>();

    for (Case c : Trigger.new) {
        Case oldCase = Trigger.oldMap.get(c.Id);

        if (c.Status != oldCase.Status && c.ContactId != null) {

            // Trouver le User lié au Contact
            List<User> users = [
                SELECT Id FROM User
                WHERE ContactId = :c.ContactId
                AND IsActive = true
                LIMIT 1
            ];

            if (!users.isEmpty()) {
                // Construire le message selon le statut
                String msg = '';
                if (c.Status == 'New') {
                    msg = 'Votre demande « ' + c.Subject + ' » a bien été reçue et est en attente de traitement.';
                } else if (c.Status == 'In Progress') {
                    msg = 'Votre demande « ' + c.Subject + ' » est en cours de traitement par notre équipe.';
                } else if (c.Status == 'Waiting Customer') {
                    msg = 'Votre demande « ' + c.Subject + ' » nécessite votre retour. Merci de nous répondre.';
                } else if (c.Status == 'Resolved') {
                    msg = 'Votre demande « ' + c.Subject + ' » a été résolue. N\'hésitez pas à nous contacter si besoin.';
                } else if (c.Status == 'Closed') {
                    msg = 'Votre demande « ' + c.Subject + ' » a été clôturée. Merci de votre confiance.';
                } else {
                    msg = 'Votre demande « ' + c.Subject + ' » a été mise à jour. Statut actuel : ' + c.Status + '.';
                }

                // Créer l'enregistrement notification
                User_Notification__c notif = new User_Notification__c();
                notif.Case__c    = c.Id;
                notif.User__c    = users[0].Id;
                notif.Message__c = msg;
                notif.Status__c  = c.Status;
                notif.Is_Read__c = false;
                notifs.add(notif);

                // Publier le Platform Event pour temps réel
                Case_Status_Change__e evt = new Case_Status_Change__e();
                evt.Case_Id__c      = c.Id;
                evt.Case_Subject__c = c.Subject;
                evt.New_Status__c   = c.Status;
                evt.Contact_Id__c   = c.ContactId;
                events.add(evt);
            }
        }
    }

    if (!notifs.isEmpty()) {
        insert notifs;
    }

    if (!events.isEmpty()) {
        EventBus.publish(events);
    }
}
