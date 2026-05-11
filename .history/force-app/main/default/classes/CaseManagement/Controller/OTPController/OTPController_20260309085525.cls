public with sharing class OTPController {

    // Méthode pour envoyer OTP
    @AuraEnabled
    public static Boolean sendOtp(String email) {
        if(String.isBlank(email)) {
            throw new AuraHandledException('Email requis');
        }

        // Vérifier si le Contact existe
        Contact c;
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE Email = :email LIMIT 1];

        if(contacts.isEmpty()) {
            // Créer un Account fictif
            Account a = new Account(Name = 'Prospect - ' + email);
            insert a;

            // Créer le Contact
            c = new Contact(
                FirstName = 'Nouveau',
                LastName = 'Client',
                Email = email,
                AccountId = a.Id
            );
            insert c;
        } else {
            c = contacts[0];
        }

        // Générer OTP
        String otpCode = String.valueOf(Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000));
        if(otpCode.length() < 6) {
            otpCode = otpCode.leftPad(6, '0');
        }

        // Stocker OTP dans l'objet OTP__c
        OTP__c otpRecord = new OTP__c(
            Contact__c = c.Id,
            OTP_Code__c = otpCode,
            Expiration__c = System.now().addMinutes(10),
            Used__c = false
        );
        insert otpRecord;

        // Envoyer email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { email });
        mail.setSubject('Votre code OTP');
        mail.setPlainTextBody('Voici votre code OTP : ' + otpCode + ' (valide 10 min)');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        return true;
    }

    // Méthode pour valider OTP
    @AuraEnabled
    public static Id validateOtp(String email, String otpCode) {
        if(String.isBlank(email) || String.isBlank(otpCode)) {
            throw new AuraHandledException('Email et OTP requis');
        }

        // Récupérer le Contact
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = :email LIMIT 1];
        if(contacts.isEmpty()) {
            throw new AuraHandledException('Contact introuvable');
        }
        Contact c = contacts[0];

        // Vérifier OTP
        List<OTP__c> otps = [SELECT Id, Expiration__c, Used__c 
                              FROM OTP__c 
                              WHERE Contact__c = :c.Id AND OTP_Code__c = :otpCode 
                              ORDER BY CreatedDate DESC LIMIT 1];

        if(otps.isEmpty()) {
            throw new AuraHandledException('OTP invalide');
        }

        OTP__c otpRec = otps[0];

        if(otpRec.Used__c) {
            throw new AuraHandledException('OTP déjà utilisé');
        }

        if(otpRec.Expiration__c < System.now()) {
            throw new AuraHandledException('OTP expiré');
        }

        // Marquer OTP comme utilisé
        otpRec.Used__c = true;
        update otpRec;

        return c.Id;
    }
}