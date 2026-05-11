public without sharing class NotificationController {
    
    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getMyNotifications() {
        List<Map<String, String>> notifications = new List<Map<String, String>>();
        
        try {
            // 1. Récupérer l'utilisateur courant et son contact
            User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            if (u.ContactId != null) {
                // 2. On récupère les dossiers modifiés AUJOURD'HUI
                // C'est ici qu'on capte l'action de l'agent/flow
                for (Case c : [SELECT Id, Subject, Status, LastModifiedDate 
                               FROM Case 
                               WHERE ContactId = :u.ContactId 
                               AND LastModifiedDate = TODAY 
                               ORDER BY LastModifiedDate DESC LIMIT 5]) {
                    
                    Map<String, String> n = new Map<String, String>();
                    n.put('id', c.Id);
                    
                    // On construit le message dynamiquement
                    // C'est ce qui apparaîtra dans ta cloche
                    n.put('status', 'Mise à jour : ' + c.Status);
                    n.put('text', 'Votre demande concernant "' + c.Subject + '" a été actualisée par nos équipes.');
                    
                    notifications.add(n);
                }
            }
        } catch (Exception e) {
            System.debug('Erreur Apex Notification: ' + e.getMessage());
        }
        
        return notifications;
    }
}