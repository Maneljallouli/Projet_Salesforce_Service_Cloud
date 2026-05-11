public without sharing class NotificationController {

    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getMyNotifications() {
        List<Map<String, String>> notifications = new List<Map<String, String>>();

        try {
            // Recherche de l'utilisateur par son Email de session
            String userEmail = UserInfo.getUserEmail();
            
            List<User> users = [
                SELECT ContactId 
                FROM User 
                WHERE Email = :userEmail 
                AND IsActive = true 
                LIMIT 1
            ];

            if (users.isEmpty() || users[0].ContactId == null) {
                System.debug('MJ_LOG: Aucun Contact trouvé pour l\'email : ' + userEmail);
                return notifications;
            }

            Id contactId = users[0].ContactId;

            // Requête sur les Cases liés à ce Contact
            // Note: J'ai retiré LastModifiedDate = TODAY pour être sûr que tu voies quelque chose au premier test
            for (Case c : [
                SELECT Id, Subject, Status, CaseNumber 
                FROM Case 
                WHERE ContactId = :contactId 
                ORDER BY LastModifiedDate DESC 
                LIMIT 5
            ]) {
                Map<String, String> n = new Map<String, String>();
                n.put('id', c.Id);
                n.put('caseNumber', c.CaseNumber);
                n.put('status', c.Status);
                n.put('text', String.isNotBlank(c.Subject) ? c.Subject : 'Demande sans objet');
                notifications.add(n);
            }

        } catch (Exception e) {
            System.debug('MJ_ERROR: ' + e.getMessage());
            // On ne jette pas d'erreur pour éviter la 500 dans le LWC
        }

        return notifications;
    }
}