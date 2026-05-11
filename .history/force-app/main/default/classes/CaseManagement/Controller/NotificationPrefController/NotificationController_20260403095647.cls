public without sharing class NotificationController {
    
    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getMyNotifications() {
        List<Map<String, String>> notifications = new List<Map<String, String>>();
        
        try {
            // Récupération de l'ID du contact lié à l'utilisateur
            User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            if (currentUser.ContactId != null) {
                // Récupération des 5 derniers dossiers (Cases)
                for (Case c : [SELECT Id, Subject, Status 
                               FROM Case 
                               WHERE ContactId = :currentUser.ContactId 
                               ORDER BY LastModifiedDate DESC LIMIT 5]) {
                    
                    Map<String, String> notif = new Map<String, String>();
                    
                    // CORRECTION ICI : Utilisation de .put() au lieu de .id, .status, etc.
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