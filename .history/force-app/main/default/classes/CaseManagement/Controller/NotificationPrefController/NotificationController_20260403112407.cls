public without sharing class NotificationController {
    
    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getMyNotifications() {
        List<Map<String, String>> notifications = new List<Map<String, String>>();
        
        try {
            // 1. On identifie l'utilisateur actuel
            Id userId = UserInfo.getUserId();
            
            // 2. On récupère les notifications de l'utilisateur via une table système
            // Note: On filtre sur les notifications créées aujourd'hui
            for (ExternalNotification notif : [SELECT Id, Title, Body, CreatedDate 
                                              FROM ExternalNotification 
                                              WHERE UserId = :userId 
                                              AND CreatedDate = TODAY 
                                              ORDER BY CreatedDate DESC LIMIT 5]) {
                
                Map<String, String> n = new Map<String, String>();
                n.put('id', notif.Id);
                n.put('status', notif.Title); // Récupère le titre du Flow
                n.put('text', notif.Body);    // Récupère le corps du message du Flow
                notifications.add(n);
            }
        } catch (Exception e) {
            // Si l'objet ExternalNotification n'est pas activé, on se rabat sur les Cases récents
            return getFallbackNotifications();
        }
        
        return notifications;
    }

    // Méthode de secours si le système de notifications est restrictif
    private static List<Map<String, String>> getFallbackNotifications() {
        List<Map<String, String>> fallbacks = new List<Map<String, String>>();
        User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        for (Case c : [SELECT Id, Subject, Status FROM Case 
                       WHERE ContactId = :u.ContactId AND LastModifiedDate = TODAY 
                       ORDER BY LastModifiedDate DESC LIMIT 5]) {
            Map<String, String> n = new Map<String, String>();
            n.put('id', c.Id);
            n.put('status', 'Mise à jour : ' + c.Status);
            n.put('text', 'Votre demande "' + c.Subject + '" a été actualisée.');
            fallbacks.add(n);
        }
        return fallbacks;
    }
}