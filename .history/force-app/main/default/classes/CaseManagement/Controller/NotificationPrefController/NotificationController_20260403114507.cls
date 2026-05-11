public without sharing class NotificationController {
    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getMyNotifications() {
        List<Map<String, String>> notifications = new List<Map<String, String>>();
        
        // TEST FORCE : On prend les 5 derniers dossiers modifiés aujourd'hui 
        // SANS FILTRER par utilisateur pour voir si le composant s'affiche
        for (Case c : [SELECT Id, Subject, Status FROM Case 
                       WHERE LastModifiedDate = TODAY 
                       ORDER BY LastModifiedDate DESC LIMIT 5]) {
            
            Map<String, String> n = new Map<String, String>();
            n.put('id', c.Id);
            n.put('status', 'TEST : ' + c.Status);
            n.put('text', 'Dossier : ' + c.Subject);
            notifications.add(n);
        }
        return notifications;
    }
}