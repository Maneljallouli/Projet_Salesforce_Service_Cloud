public without sharing class NotificationController {

    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getMyNotifications() {
        List<Map<String, String>> notifications = new List<Map<String, String>>();

        try {
            Id userId = UserInfo.getUserId();

            System.debug('=== LUX NOTIF DEBUG ===');
            System.debug('UserId: ' + userId);
            System.debug('UserType: ' + UserInfo.getUserType());

            List<User> users = [
                SELECT Id, ContactId, UserType
                FROM User
                WHERE Id = :userId
                LIMIT 1
            ];

            System.debug('User: ' + users);

            if (users.isEmpty() || users[0].ContactId == null) {
                System.debug('Aucun ContactId trouvé pour cet utilisateur');
                return notifications;
            }

            Id contactId = users[0].ContactId;
            System.debug('ContactId: ' + contactId);

            List<Case> cases = [
                SELECT Id, Subject, Status, CaseNumber, LastModifiedDate
                FROM Case
                WHERE ContactId = :contactId
                ORDER BY LastModifiedDate DESC
                LIMIT 10
            ];

            System.debug('Cases trouvés: ' + cases.size());

            for (Case c : cases) {
                Map<String, String> n = new Map<String, String>();
                n.put('id', c.Id);
                n.put('caseNumber', c.CaseNumber != null ? c.CaseNumber : 'N/A');
                n.put('status', c.Status != null ? c.Status : 'Inconnu');
                n.put('text', c.Subject != null ? c.Subject : 'Dossier sans titre');
                notifications.add(n);
            }

        } catch (Exception e) {
            System.debug('ERREUR: ' + e.getMessage() + ' | ' + e.getStackTraceString());
            throw new AuraHandledException('Erreur: ' + e.getMessage());
        }

        return notifications;
    }
}