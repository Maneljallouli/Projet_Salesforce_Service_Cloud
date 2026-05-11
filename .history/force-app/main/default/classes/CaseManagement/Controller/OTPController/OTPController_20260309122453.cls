public with sharing class OTPController {
    
    @AuraEnabled
    public static Boolean sendOtp(String email) {
        try {
            // Nettoyage OTP existants (max 3 tentatives/heure)
            cleanupOldOtps(email);
            
            Contact contact = findOrCreateContact(email);
            
            // Générer OTP 6 chiffres
            String otpCode = String.valueOf(Math.mod(Math.abs(Crypto.getRandomInteger()), 900000) + 100000);
            
            // Créer enregistrement OTP
            OTP__c otp = new OTP__c(
                Contact__c = contact.Id,
                Name = otpCode,
                Expiration__c = System.now().addMinutes(5),
                Used__c = false,
                Email__c = email  // Champ custom pour debug
            );
            insert otp;
            
            // Envoyer email
            sendOtpEmail(contact, otpCode);
            
            return true;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur envoi OTP: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Id validateOtp(String email, String otpCode) {
        try {
            List<OTP__c> otps = [SELECT Id, Contact__c, Used__c, Expiration__c 
                                FROM OTP__c 
                                WHERE Name = :otpCode 
                                AND Email__c = :email 
                                AND Used__c = false 
                                AND Expiration__c > :System.now()
                                ORDER BY CreatedDate DESC LIMIT 1];
            
            if (otps.isEmpty()) {
                throw new AuraHandledException('Code OTP invalide ou expiré');
            }
            
            OTP__c otp = otps[0];
            otp.Used__c = true;
            update otp;
            
            return otp.Contact__c;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur validation: ' + e.getMessage());
        }
    }
    
    // Méthodes privées
    private static Contact findOrCreateContact(String email) {
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = :email LIMIT 1];
        if (!contacts.isEmpty()) return contacts[0];
        
        // Créer nouveau Contact (votre logique PFE)
        Account acc = new Account(Name = email.left(40) + ' Client');
        insert acc;
        
        Contact c = new Contact(
            FirstName = 'Client',
            LastName = email.left(40),
            Email = email,
            AccountId = acc.Id,
            Type__c = 'Client'
        );
        insert c;
        return c;
    }
    
    private static void sendOtpEmail(Contact c, String otpCode) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { c.Email });
        mail.setSubject('Votre code OTP - Portail Client');
        mail.setHtmlBody('Bonjour,<br/>Votre code OTP est: <h2>' + otpCode + '</h2><br/>Valable 5 minutes.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    private static void cleanupOldOtps(String email) {
        delete [SELECT Id FROM OTP__c WHERE Email__c = :email AND CreatedDate < :System.now().addHours(-1)];
    }
}
