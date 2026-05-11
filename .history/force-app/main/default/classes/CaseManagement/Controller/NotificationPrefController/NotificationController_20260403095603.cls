public without sharing class NotificationController {
    
    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getMyNotifications() {
        List<Map<String, String>> notifications = new List<Map<String, String>>();
        
        try {
            // On récupère l'ID du contact lié à l'utilisateur actuel
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            if (currentUser.ContactId != null) {
                // On récupère les 5 derniers Cases modifiés pour ce contact
                for (Case c : [SELECT Id, Subject, Status, LastModifiedDate 
                               FROM Case 
                               WHERE ContactId = :currentUser.ContactId 
                               ORDER BY LastModifiedDate DESC LIMIT 5]) {
                    
                    Map<String, String> notif = new Map<String, String>();
                    notif.id = c.Id;
                    notif.status = 'Mise à jour : ' + c.Status;
                    notif.text = 'Votre demande "' + c.Subject + '" a été actualisée.';
                    notifications.add(notif);
                }
            }
        } catch (Exception e) {
            System.debug('Erreur Notif: ' + e.getMessage());
        }
        
        return notifications;
    }
}