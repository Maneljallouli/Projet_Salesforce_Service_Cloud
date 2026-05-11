public without sharing class NotificationController {

    @AuraEnabled(cacheable=false)
    public static List<Map<String, String>> getMyNotifications() {
        List<Map<String, String>> notifications = new List<Map<String, String>>();

        try {
            // ÉTAPE 1 : On récupère l'email de l'utilisateur courant
            String userEmail = UserInfo.getUserEmail();
            
            // ÉTAPE 2 : On cherche le contact lié à cet email
            // On utilise Contact directement pour être plus précis
            List<Contact> contacts = [
                SELECT Id FROM Contact 
                WHERE Email = :userEmail 
                LIMIT 1
            ];

            if (contacts.isEmpty()) {
                System.debug('MJ_LOG: Aucun contact trouvé pour l\'email ' + userEmail);
                return notifications;
            }

            Id targetContactId = contacts[0].Id;

            // ÉTAPE 3 : Requête sécurisée sur les Cases
            // On récupère les 5 derniers dossiers modifiés (peu importe la date)
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
            // Si une erreur arrive, on la logue mais on ne crash pas le LWC (évite la 500)
            System.debug('MJ_ERROR: ' + e.getMessage() + ' à la ligne ' + e.getLineNumber());
        }

        return notifications;
    }
}