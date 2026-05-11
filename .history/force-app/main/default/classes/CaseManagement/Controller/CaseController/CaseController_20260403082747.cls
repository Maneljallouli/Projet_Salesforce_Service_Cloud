@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseController {

    @AuraEnabled(cacheable=true)
    public static List<Case> getMyCases() {
        try {
            // 1. Récupérer l'email de l'utilisateur connecté
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            String userEmail = currentUser.Email;

            // 2. Trouver le contact qui a cet email
            // On utilise une liste pour éviter une exception si aucun contact n'est trouvé
            List<Contact> relatedContacts = [SELECT Id FROM Contact WHERE Email = :userEmail LIMIT 1];

            if (relatedContacts.isEmpty()) {
                System.debug('@@@ Aucun contact trouvé pour l\'email : ' + userEmail);
                return new List<Case>();
            }

            Id targetContactId = relatedContacts[0].Id;

            // 3. Retourner les cases de ce contact
            return [
                SELECT Id, CaseNumber, Subject, Status, Priority, Category__c, CreatedDate
                FROM Case
                WHERE ContactId = :targetContactId
                ORDER BY CreatedDate DESC
                LIMIT 100
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Erreur récupération : ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Id createCase(CaseRequest req) {
        try {
            // Même logique pour la création
            User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Contact ctc = [SELECT Id FROM Contact WHERE Email = :currentUser.Email LIMIT 1];

            Case c = new Case();
            c.Subject = req.subject;
            c.Description = req.description;
            c.Category__c = req.category;
            c.Subcategory__c = req.subcategory;
            c.Client_Segment__c = req.clientSegment;
            c.ContactId = ctc.Id;
            c.Origin = 'Web';
            insert c;
            
            return c.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur création : ' + e.getMessage());
        }
    }
    
    // N'oublie pas d'inclure ta classe CaseRequest ici...
}