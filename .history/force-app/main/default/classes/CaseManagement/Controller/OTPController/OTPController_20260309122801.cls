public with sharing class OTPController {
    
    @AuraEnabled
    public static Boolean sendOtp(String email) {
        try {
            if (String.isBlank(email)) {
                throw new AuraHandledException('Email requis');
            }
            
            cleanupOldOtps(email);
            Contact contact = findOrCreateContact(email);
            String otpCode = generateOtpCode();
            OTP__c otp = createOtpRecord(contact.Id, otpCode, email);
            sendOtpEmail(contact, otpCode);
            
            return true;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur envoi OTP: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Id validateOtp(String email, String otpCode) {
        try {
            if (String.isBlank(email) || String.isBlank(otpCode)) {
                throw new AuraHandledException('Email et OTP requis');
            }
            
            List<OTP__c> otps = [
                SELECT Id, Contact__c, Used__c, Expiration__c 
                FROM OTP__c 
                WHERE Name = :otpCode AND Email__c = :email 
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC LIMIT 1
            ];
            
            if (otps.isEmpty()) {
                throw new AuraHandledException('Code OTP invalide ou expiré');
            }
            
            OTP__c otp = otps[0];
            if (otp.Used__c || otp.Expiration__c < System.now()) {
                throw new AuraHandledException('Code OTP invalide ou expiré');
            }
            
            updateOtpUsed(otp.Id);
            return otp.Contact__c;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur validation: ' + e.getMessage());
        }
    }
    
    // ✅ TOUTES les méthodes utilisent WITH SECURITY_ENFORCED + vérifications
    private static void cleanupOldOtps(String email) {
        if (!OTP__c.SObjectType.getDescribe().isDeletable()) {
            return; // Graceful degradation
        }
        List<OTP__c> oldOtps = [
            SELECT Id FROM OTP__c 
            WHERE Email__c = :email AND CreatedDate < :System.now().addHours(-1)
            WITH SECURITY_ENFORCED
        ];
        if (!oldOtps.isEmpty()) {
            delete oldOtps;
        }
    }
    
    private static Contact findOrCreateContact(String email) {
        if (!Contact.SObjectType.getDescribe().isAccessible()) {
            throw new AuraHandledException('Lecture Contact impossible');
        }
        
        List<Contact> contacts = [
            SELECT Id FROM Contact 
            WHERE Email = :email 
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];
        
        if (!contacts.isEmpty()) {
            return contacts[0];
        }
        return createNewContact(email);
    }
    
    private static Contact createNewContact(String email) {
        if (!Account.SObjectType.getDescribe().isCreateable()) {
            throw new AuraHandledException('Création Account impossible');
        }
        if (!Contact.SObjectType.getDescribe().isCreateable()) {
            throw new AuraHandledException('Création Contact impossible');
        }
        
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
    
    private static OTP__c createOtpRecord(Id contactId, String otpCode, String email) {
        if (!OTP__c.SObjectType.getDescribe().isCreateable()) {
            throw new AuraHandledException('Création OTP impossible');
        }
        
        OTP__c otp = new OTP__c(
            Contact__c = contactId,
            Name = otpCode,
            Expiration__c = System.now().addMinutes(5),
            Used__c = false,
            Email__c = email
        );
        insert otp;
        return otp;
    }
    
    private static void updateOtpUsed(Id otpId) {
        if (!OTP__c.SObjectType.getDescribe().isUpdateable()) {
            throw new AuraHandledException('Mise à jour OTP impossible');
        }
        OTP__c otp = new OTP__c(Id = otpId, Used__c = true);
        update otp;
    }
    
    private static String generateOtpCode() {
        return String.valueOf(Math.mod(Math.abs(Crypto.getRandomInteger()), 900000) + 100000);
    }
    
    private static void sendOtpEmail(Contact c, String otpCode) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { c.Email });
        mail.setSubject('Votre code OTP - Portail Client');
        mail.setHtmlBody('Bonjour,<br/>Votre code OTP est: <h2>' + otpCode + '</h2><br/>Valable 5 minutes.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}
