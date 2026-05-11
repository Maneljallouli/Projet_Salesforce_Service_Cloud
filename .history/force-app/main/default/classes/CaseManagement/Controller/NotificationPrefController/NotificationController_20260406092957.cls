public without sharing class NotificationController {

    // Récupère uniquement les notifications NON LUES
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getMyNotifications() {
        List<Map<String, String>> result = new List<Map<String, String>>();

        try {
            Id userId = UserInfo.getUserId();

            List<User_Notification__c> notifs = [
                SELECT Id, Case__c, Case__r.CaseNumber, Message__c, Status__c, Is_Read__c, CreatedDate
                FROM User_Notification__c
                WHERE User__c = :userId
                AND Is_Read__c = false
                ORDER BY CreatedDate DESC
                LIMIT 20
            ];

            for (User_Notification__c n : notifs) {
                Map<String, String> m = new Map<String, String>();
                m.put('id', n.Id);
                m.put('caseId', n.Case__c);
                m.put('caseNumber', n.Case__r.CaseNumber != null ? n.Case__r.CaseNumber : 'N/A');
                m.put('status', n.Status__c != null ? n.Status__c : '');
                m.put('message', n.Message__c != null ? n.Message__c : '');
                result.add(m);
            }

        } catch (Exception e) {
            System.debug('ERREUR getMyNotifications: ' + e.getMessage());
            throw new AuraHandledException('Erreur: ' + e.getMessage());
        }

        return result;
    }

    // Marque toutes les notifications comme lues
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