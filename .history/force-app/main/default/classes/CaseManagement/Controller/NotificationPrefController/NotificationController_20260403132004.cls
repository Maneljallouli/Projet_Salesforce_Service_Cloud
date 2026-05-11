public without sharing class NotificationController {

    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getMyNotifications() {
        List<Map<String, String>> notifications = new List<Map<String, String>>();

        Id userId = UserInfo.getUserId();

        List<User> users = [
            SELECT ContactId FROM User WHERE Id = :userId LIMIT 1
        ];

        if (users.isEmpty() || users[0].ContactId == null) {
            return notifications;
        }

        Id contactId = users[0].ContactId;

        for (Case c : [
            SELECT Id, Subject, Status, CaseNumber
            FROM Case
            WHERE ContactId = :contactId
            AND LastModifiedDate = TODAY
            ORDER BY LastModifiedDate DESC
            LIMIT 10
        ]) {
            Map<String, String> n = new Map<String, String>();
            n.put('id', c.Id);
            n.put('caseNumber', c.CaseNumber);
            n.put('status', c.Status);
            n.put('text', c.Subject != null ? c.Subject : 'Dossier sans titre');
            notifications.add(n);
        }

        return notifications;
    }
}