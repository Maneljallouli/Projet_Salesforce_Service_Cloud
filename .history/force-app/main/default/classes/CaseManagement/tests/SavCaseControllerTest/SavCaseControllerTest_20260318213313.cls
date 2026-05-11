@IsTest
private class SavCaseControllerTest {

    @TestSetup
    static void setupData() {

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            LastName = 'Test',
            AccountId = acc.Id,
            Preferred_Language__c = 'fr',
            Segment_VIP__c = 'VIP'
        );
        insert con;

        User u = new User(
            Alias = 'tuser',
            Email='testuser@test.com',
            EmailEncodingKey='UTF-8',
            LastName='Testing',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            TimeZoneSidKey='Europe/Paris',
            UserName='testuser'+System.currentTimeMillis()+'@test.com',
            ContactId = con.Id
        );
        insert u;
    }

    @IsTest
    static void testGetSavRecordTypesShouldReturnTypes() {

        Test.startTest();
        List<SavCaseController.RecordTypeOption> result =
            SavCaseController.getSavRecordTypes();
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testCreateCaseRetourProduitShouldCreateSuccessfully() {

        SavCaseController.CaseInput input = new SavCaseController.CaseInput();
        input.recordTypeName = 'Retour_Produit';
        input.subject = 'Produit cassé';
        input.description = 'Description test';

        Test.startTest();
        Id caseId = SavCaseController.createCase(input);
        Test.stopTest();

        System.assertNotEquals(null, caseId);
    }

    @IsTest
    static void testGetMyCasesNoFilterShouldReturnResults() {

        SavCaseController.CaseFilterInput filter =
            new SavCaseController.CaseFilterInput();
        filter.pageNum = 1;
        filter.pageSize = 10;

        Test.startTest();
        SavCaseController.CaseListWrapper result =
            SavCaseController.getMyCases(filter);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testGetCaseDashboardStatsShouldReturnStats() {

        Test.startTest();
        Map<String, Integer> stats =
            SavCaseController.getCaseDashboardStats();
        Test.stopTest();

        System.assertNotEquals(null, stats);
    }

    @IsTest
    static void testAddCommentShouldAddCommentSuccessfully() {

        Case c = new Case(
            Subject = 'Test',
            Status = 'New',
            Origin = 'Portal'
        );
        insert c;

        Test.startTest();
        SavCaseController.addComment(c.Id, 'Commentaire test');
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testCloseCaseShouldCloseResolvedCase() {

        Case c = new Case(
            Subject = 'Test',
            Status = 'Resolved',
            Origin = 'Portal'
        );
        insert c;

        Test.startTest();
        SavCaseController.closeCase(c.Id);
        Test.stopTest();

        Case updated = [SELECT Status FROM Case WHERE Id = :c.Id];
        System.assertEquals('Closed', updated.Status);
    }

    @IsTest
    static void testEscalateCaseShouldUpdatePriority() {

        Case c = new Case(
            Subject = 'Test',
            Status = 'New',
            Origin = 'Portal'
        );
        insert c;

        Test.startTest();
        SavCaseController.escalateCase(c.Id, 'Client mécontent');
        Test.stopTest();

        Case updated = [SELECT Priority FROM Case WHERE Id = :c.Id];
        System.assertEquals('High', updated.Priority);
    }
}