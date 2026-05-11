@IsTest
public class OTPControllerTest {

    // Méthode pour créer un Contact de test
    private static Contact createTestContact(String email) {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = email,
            AccountId = acc.Id,
            Type__c = 'Client' // Champ obligatoire ajouté
        );
        insert c;
        return c;
    }

    @IsTest
    static void testSendOtpNewContact() {
        Test.startTest();
        
        Boolean result = OTPController.sendOtp('newuser@example.com');
        
        System.assert(result, 'L\'OTP doit être envoyé');
        
        Contact c = [SELECT Id, Email FROM Contact WHERE Email = 'newuser@example.com' LIMIT 1];
        System.assertNotEquals(null, c, 'Un nouveau contact doit être créé');
        
        OTP__c otpRec = [SELECT Id, Contact__c, Used__c FROM OTP__c WHERE Contact__c = :c.Id LIMIT 1];
        System.assertEquals(false, otpRec.Used__c, 'OTP doit être non utilisé');
        
        Test.stopTest();
    }

    @IsTest
    static void testSendOtpExistingContact() {
        Contact c = createTestContact('existing@example.com');

        Test.startTest();
        Boolean result = OTPController.sendOtp('existing@example.com');
        Test.stopTest();

        System.assert(result, 'L\'OTP doit être envoyé pour un contact existant');

        OTP__c otpRec = [SELECT Id, Contact__c, Used__c FROM OTP__c WHERE Contact__c = :c.Id ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(c.Id, otpRec.Contact__c, 'L\'OTP doit être lié au contact existant');
    }

    @IsTest
    static void testValidateOtpSuccess() {
        Contact c = createTestContact('validate@example.com');

        OTP__c otpRec = new OTP__c(
            Contact__c = c.Id,
            Name = '123456',
            Expiration__c = System.now().addMinutes(10),
            Used__c = false
        );
        insert otpRec;

        Test.startTest();
        Id returnedId = OTPController.validateOtp(c.Email, otpRec.Name);
        Test.stopTest();

        System.assertEquals(c.Id, returnedId, 'La validation doit retourner l\'Id du contact');

        OTP__c updatedOtp = [SELECT Used__c FROM OTP__c WHERE Id = :otpRec.Id];
        System.assertEquals(true, updatedOtp.Used__c, 'L\'OTP doit être marqué comme utilisé après validation');
    }

    @IsTest
    static void testValidateOtpExpired() {
        Contact c = createTestContact('expired@example.com');

        OTP__c otpRec = new OTP__c(
            Contact__c = c.Id,
            Name = '654321',
            Expiration__c = System.now().addMinutes(-5), // déjà expiré
            Used__c = false
        );
        insert otpRec;

        Test.startTest();
        try {
            OTPController.validateOtp(c.Email, otpRec.Name);
            System.assert(false, 'Une exception doit être levée pour un OTP expiré');
        } catch (AuraHandledException e) {
            // ✅ Vérification adaptée : on teste que le message contient la chaîne attendue
            System.assert(e.getMessage().contains('OTP expiré'), 'Message attendu : OTP expiré');
        }
        Test.stopTest();
    }

    @IsTest
    static void testValidateOtpUsed() {
        Contact c = createTestContact('used@example.com');

        OTP__c otpRec = new OTP__c(
            Contact__c = c.Id,
            Name = '111111',
            Expiration__c = System.now().addMinutes(10),
            Used__c = true // déjà utilisé
        );
        insert otpRec;

        Test.startTest();
        try {
            OTPController.validateOtp(c.Email, otpRec.Name);
            System.assert(false, 'Une exception doit être levée pour un OTP déjà utilisé');
        } catch (AuraHandledException e) {
            // ✅ Vérification adaptée : on teste que le message contient la chaîne attendue
            System.assert(e.getMessage().contains('OTP déjà utilisé'), 'Message attendu : OTP déjà utilisé');
        }
        Test.stopTest();
    }
}