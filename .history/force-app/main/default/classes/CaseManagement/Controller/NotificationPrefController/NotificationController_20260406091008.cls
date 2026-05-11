public without sharing class NotificationController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getMyNotifications() {
        List<Map<String, String>> notifications = new List<Map<String, String>>();

        try {
            Id userId = UserInfo.getUserId();

            List<User> users = [
                SELECT Id, ContactId
                FROM User
                WHERE Id = :userId
                LIMIT 1
            ];

            if (users.isEmpty() || users[0].ContactId == null) {
                return notifications;
            }

            Id contactId = users[0].ContactId;

            for (Case c : [
                SELECT Id, Subject, Status, CaseNumber, LastModifiedDate
                FROM Case
                WHERE ContactId = :contactId
                ORDER BY LastModifiedDate DESC
                LIMIT 10
            ]) {
                Map<String, String> n = new Map<String, String>();
                n.put('id', c.Id);
                n.put('caseNumber', c.CaseNumber != null ? c.CaseNumber : 'N/A');
                n.put('status', c.Status != null ? c.Status : 'Inconnu');
                n.put('text', c.Subject != null ? c.Subject : 'Dossier sans titre');
                notifications.add(n);
            }

        } catch (Exception e) {
            System.debug('ERREUR: ' + e.getMessage());
            throw new AuraHandledException('Erreur: ' + e.getMessage());
        }

        return notifications;
    }
}