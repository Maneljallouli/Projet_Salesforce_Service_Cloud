public without sharing class NotificationController {
    
    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getMyNotifications() {
        List<Map<String, String>> notifications = new List<Map<String, String>>();
        
        try {
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            if (currentUser.ContactId != null) {
                // On ajoute "AND LastModifiedDate = TODAY" pour ne capter que l'action récente du Flow
                for (Case c : [SELECT Id, Subject, Status 
                               FROM Case 
                               WHERE ContactId = :currentUser.ContactId 
                               AND LastModifiedDate = TODAY 
                               ORDER BY LastModifiedDate DESC LIMIT 5]) {
                    
                    Map<String, String> notif = new Map<String, String>();
                    notif.put('id', c.Id);
                    notif.put('status', 'Mise à jour : ' + c.Status);
                    notif.put('text', 'Votre demande "' + c.Subject + '" a été actualisée.');
                    
                    notifications.add(notif);
                }
            }
        } catch (Exception e) {
            System.debug('Erreur Notif: ' + e.getMessage());
        }
        
        return notifications;
    }
}