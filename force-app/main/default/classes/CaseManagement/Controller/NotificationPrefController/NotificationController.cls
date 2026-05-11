public without sharing class NotificationController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getMyNotifications() {
        List<Map<String, String>> result = new List<Map<String, String>>();

        try {
            Id userId = UserInfo.getUserId();

            // Retourne TOUTES les notifs (lues + non lues) pour l'historique
            List<User_Notification__c> notifs = [
                SELECT Id, Case__c, Case__r.CaseNumber, Case__r.Subject,
                       Message__c, Status__c, Is_Read__c, CreatedDate
                FROM User_Notification__c
                WHERE User__c = :userId
                ORDER BY CreatedDate DESC
                LIMIT 50
            ];

            for (User_Notification__c n : notifs) {
                Map<String, String> m = new Map<String, String>();
                m.put('id',         n.Id);
                m.put('caseId',     n.Case__c);
                m.put('caseNumber', n.Case__r.CaseNumber != null ? n.Case__r.CaseNumber : 'N/A');
                m.put('status',     n.Status__c  != null ? n.Status__c  : '');
                m.put('message',    n.Message__c != null ? n.Message__c : '');
                m.put('isRead',     n.Is_Read__c ? 'true' : 'false');
                m.put('date',       n.CreatedDate.format('dd/MM/yyyy HH:mm'));
                result.add(m);
            }

        } catch (Exception e) {
            System.debug('ERREUR: ' + e.getMessage());
            throw new AuraHandledException('Erreur: ' + e.getMessage());
        }

        return result;
    }

    @AuraEnabled
    public static void markAllAsRead() {
        try {
            Id userId = UserInfo.getUserId();

            List<User_Notification__c> notifs = [
                SELECT Id, Is_Read__c
                FROM User_Notification__c
                WHERE User__c = :userId
                AND Is_Read__c = false
            ];

            for (User_Notification__c n : notifs) {
                n.Is_Read__c = true;
            }

            if (!notifs.isEmpty()) {
                update notifs;
            }

        } catch (Exception e) {
            System.debug('ERREUR markAllAsRead: ' + e.getMessage());
            throw new AuraHandledException('Erreur: ' + e.getMessage());
        }
    }
}