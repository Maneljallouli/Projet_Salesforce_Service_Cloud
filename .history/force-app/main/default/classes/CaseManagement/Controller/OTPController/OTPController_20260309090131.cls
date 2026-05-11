public with sharing class OTPController {

    // Méthode pour envoyer OTP et créer Contact/Account si nécessaire
    @AuraEnabled
    public static Boolean sendOtp(String email) {
        if (String.isBlank(email)) {
            throw new AuraHandledException('Email requis');
        }

        // Vérifier accès lecture Contact
        if (!Schema.sObjectType.Contact.isAccessible()) {
            throw new AuraHandledException('Permission lecture Contact manquante');
        }

        List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE Email = :email LIMIT 1];
        Contact c;
        Account a;

        if (contacts.isEmpty()) {
            // Vérifier permission création Account
            if (!Schema.sObjectType.Account.isCreateable()) {
                throw new AuraHandledException('Permission création Account manquante');
            }
            a = new Account(Name = 'Prospect - ' + email);
            insert a;

            // Vérifier permission création Contact
            if (!Schema.sObjectType.Contact.isCreateable()) {
                throw new AuraHandledException('Permission création Contact manquante');
            }
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
        if (otpCode.length() < 6) {
            otpCode = otpCode.leftPad(6, '0');
        }

        // Vérifier permission création OTP__c
        if (!Schema.sObjectType.OTP__c.isCreateable()) {
            throw new AuraHandledException('Permission création OTP manquante');
        }
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
        mail.setPlainTextBody('Voici votre code OTP : ' + otpCode + ' (valide 10 minutes)');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        return true;
    }

    // Méthode pour valider OTP
    @AuraEnabled
    public static Id validateOtp(String email, String otpCode) {
        if (String.isBlank(email) || String.isBlank(otpCode)) {
            throw new AuraHandledException('Email et OTP requis');
        }

        // Vérifier accès lecture Contact
        if (!Schema.sObjectType.Contact.isAccessible()) {
            throw new AuraHandledException('Permission lecture Contact manquante');
        }
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = :email LIMIT 1];
        if (contacts.isEmpty()) {
            throw new AuraHandledException('Contact introuvable');
        }

        Contact c = contacts[0];

        // Vérifier accès lecture OTP__c
        if (!Schema.sObjectType.OTP__c.isAccessible()) {
            throw new AuraHandledException('Permission lecture OTP manquante');
        }
        List<OTP__c> otps = [SELECT Id, Expiration__c, Used__c
                              FROM OTP__c
                              WHERE Contact__c = :c.Id AND OTP_Code__c = :otpCode
                              ORDER BY CreatedDate DESC
                              LIMIT 1];
        if (otps.isEmpty()) {
            throw new AuraHandledException('OTP invalide');
        }

        OTP__c otpRec = otps[0];

        if (otpRec.Used__c) {
            throw new AuraHandledException('OTP déjà utilisé');
        }

        if (otpRec.Expiration__c < System.now()) {
            throw new AuraHandledException('OTP expiré');
        }

        // Vérifier permission update OTP__c
        if (!Schema.sObjectType.OTP__c.isUpdateable()) {
            throw new AuraHandledException('Permission mise à jour OTP manquante');
        }
        otpRec.Used__c = true;
        update otpRec;

        return c.Id;
    }
}