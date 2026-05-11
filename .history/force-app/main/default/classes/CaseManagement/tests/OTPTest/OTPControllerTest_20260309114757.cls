@IsTest
public class OTPControllerTest {

    private static Contact createTestContact(String email) {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = email,
            AccountId = acc.Id,
            Type__c = 'Client' 
        );
        insert c;
        return c;
    }

    @IsTest
    static void testSendOtpNewContact() {
        Test.startTest();
        Boolean result = OTPController.sendOtp('newuser@example.com');
        Test.stopTest();
        
        System.assert(result, 'L\'OTP aurait dû être envoyé avec succès pour un nouvel utilisateur.');
        
        Contact c = [SELECT Id, Email FROM Contact WHERE Email = 'newuser@example.com' LIMIT 1];
        System.assertNotEquals(null, c, 'Un nouveau contact aurait dû être créé en base de données.');
        
        OTP__c otpRec = [SELECT Id, Contact__c, Used__c FROM OTP__c WHERE Contact__c = :c.Id LIMIT 1];
        System.assertEquals(false, otpRec.Used__c, 'Le nouvel OTP créé ne devrait pas être marqué comme utilisé.');
    }

    @IsTest
    static void testSendOtpExistingContact() {
        Contact c = createTestContact('existing@example.com');

        Test.startTest();
        Boolean result = OTPController.sendOtp('existing@example.com');
        Test.stopTest();

        System.assert(result, 'L\'OTP aurait dû être envoyé pour un contact existant.');

        OTP__c otpRec = [SELECT Id, Contact__c, Used__c FROM OTP__c WHERE Contact__c = :c.Id ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals(c.Id, otpRec.Contact__c, 'L\'OTP généré doit être lié à l\'ID du contact existant.');
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

        System.assertEquals(c.Id, returnedId, 'La validation de l\'OTP aurait dû retourner l\'ID du contact correspondant.');

        OTP__c updatedOtp = [SELECT Used__c FROM OTP__c WHERE Id = :otpRec.Id];
        System.assertEquals(true, updatedOtp.Used__c, 'L\'OTP devrait être marqué comme utilisé (Used__c = true) après une validation réussie.');
    }

    @IsTest
    static void testValidateOtpExpired() {
        Contact c = createTestContact('expired@example.com');

        OTP__c otpRec = new OTP__c(
            Contact__c = c.Id,
            Name = '654321',
            Expiration__c = System.now().addMinutes(-5), 
            Used__c = false
        );
        insert otpRec;

        Test.startTest();
        try {
            OTPController.validateOtp(c.Email, otpRec.Name);
            System.assert(false, 'Une AuraHandledException aurait dû être levée pour un code OTP expiré.');
        } catch (AuraHandledException e) {
            // Respect de PMD : On ajoute un message même pour confirmer un succès attendu
            System.assert(true, 'L\'exception AuraHandledException a été correctement capturée pour l\'expiration.');
        } catch (Exception e) {
            System.assert(false, 'Une exception de type AuraHandledException était attendue, mais a reçu : ' + e.getTypeName());
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
            Used__c = true 
        );
        insert otpRec;

        Test.startTest();
        try {
            OTPController.validateOtp(c.Email, otpRec.Name);
            System.assert(false, 'Une AuraHandledException aurait dû être levée pour un code OTP déjà utilisé.');
        } catch (AuraHandledException e) {
            System.assert(true, 'L\'exception AuraHandledException a été correctement capturée pour un code déjà utilisé.');
        } catch (Exception e) {
            System.assert(false, 'Une exception de type AuraHandledException était attendue, mais a reçu : ' + e.getTypeName());
        }
        Test.stopTest();
    }
}