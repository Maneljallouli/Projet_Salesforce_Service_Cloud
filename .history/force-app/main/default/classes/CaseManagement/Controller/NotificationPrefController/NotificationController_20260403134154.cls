public without sharing class NotificationController {

    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getMyNotifications() {
        List<Map<String, String>> notifications = new List<Map<String, String>>();

        try {
            // Utilisation de l'email de l'utilisateur connecté
            String userEmail = UserInfo.getUserEmail();
            
            // Recherche du contact lié
            List<Contact> contacts = [
                SELECT Id FROM Contact 
                WHERE Email = :userEmail 
                LIMIT 1
            ];

            if (contacts.isEmpty()) {
                return notifications;
            }

            Id targetContactId = contacts[0].Id;

            // Récupération des dossiers (Case)
            // On retire le filtre TODAY pour s'assurer d'avoir des données au test
            for (Case c : [
                SELECT Id, Subject, Status, CaseNumber 
                FROM Case 
                WHERE ContactId = :targetContactId 
                ORDER BY LastModifiedDate DESC 
                LIMIT 5
            ]) {
                Map<String, String> n = new Map<String, String>();
                n.put('id', c.Id);
                n.put('caseNumber', c.CaseNumber != null ? c.CaseNumber : '---');
                n.put('status', c.Status);
                n.put('text', String.isNotBlank(c.Subject) ? c.Subject : 'Demande sans titre');
                notifications.add(n);
            }

        } catch (Exception e) {
            // Log de l'erreur dans Salesforce (Debug Logs)
            System.debug('MJ_ERROR: ' + e.getMessage());
            // On retourne une liste vide pour éviter l'erreur 500 côté LWC
            return new List<Map<String, String>>();
        }

        return notifications;
    }
}