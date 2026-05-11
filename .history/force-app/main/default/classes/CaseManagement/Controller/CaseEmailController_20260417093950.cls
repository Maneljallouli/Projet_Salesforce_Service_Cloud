public with sharing class CaseEmailController {

    @AuraEnabled
    public static void sendEmailDraft(String caseId, String body) {

        // 🔒 Vérification accès lecture Case
        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new AuraHandledException('Accès refusé à Case');
        }

        // 🔎 Récupération du Case
        Case c = [
            SELECT Id, ContactId, SuppliedEmail, Subject
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        String toAddress = '';

        // 🔎 Si Contact lié
        if (c.ContactId != null) {

            // 🔒 Vérification accès Contact
            if (!Schema.sObjectType.Contact.isAccessible()) {
                throw new AuraHandledException('Accès refusé à Contact');
            }

            Contact contact = [
                SELECT Email 
                FROM Contact 
                WHERE Id = :c.ContactId 
                LIMIT 1
            ];

            toAddress = contact.Email;

        } 
        // 🔎 Sinon email saisi manuellement
        else if (c.SuppliedEmail != null) {
            toAddress = c.SuppliedEmail;
        }

        // ❌ Aucun email trouvé
        if (String.isBlank(toAddress)) {
            throw new AuraHandledException('Aucune adresse email trouvée pour ce Case.');
        }

        // 📧 Création email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ toAddress });
        mail.setSubject('RE: ' + c.Subject);
        mail.setHtmlBody(body);
        mail.setWhatId(caseId);
        mail.setSaveAsActivity(true);

        // 🚀 Envoi
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });

        // 🔒 Vérification permission UPDATE
        if (Schema.sObjectType.Case.isUpdateable()) {

            update new Case(
                Id = caseId,
                Statut_du_brouillon__c = 'Approuvé' // ✅ valeur valide
            );
        }
    }
}