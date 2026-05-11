public with sharing class CaseEmailController {

    @AuraEnabled
    public static void sendEmailDraft(String caseId, String body) {
        Case c = [
            SELECT Id, ContactId, SuppliedEmail, Subject
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        String toAddress = '';
        if (c.ContactId != null) {
            Contact contact = [SELECT Email FROM Contact WHERE Id = :c.ContactId LIMIT 1];
            toAddress = contact.Email;
        } else if (c.SuppliedEmail != null) {
            toAddress = c.SuppliedEmail;
        }

        if (String.isBlank(toAddress)) {
            throw new AuraHandledException('Aucune adresse email trouvée pour ce Case.');
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ toAddress });
        mail.setSubject('RE: ' + c.Subject);
        mail.setHtmlBody(body);
        mail.setWhatId(caseId);
        mail.setSaveAsActivity(true);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });

        update new Case(
            Id = caseId,
            Statut_Brouillon__c = 'Envoyé'
        );
    }
}