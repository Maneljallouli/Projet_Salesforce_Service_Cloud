@IsTest
private class CaseController_Test {

    @IsTest
    static void testGetMyCases_success() {

        // ARRANGE
        User u = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];

        Case c = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Email',
            OwnerId = u.Id
        );
        insert c;

        // ACT
        Test.startTest();
        List<CaseWrapper> result = CaseController.getMyCases();
        Test.stopTest();

        // ASSERT
        System.assert(
            result.size() > 0,
            'La liste des cases ne doit pas être vide'
        );

        CaseWrapper cw = result[0];
        System.assertEquals('New', cw.Status);
        System.assertEquals('status-new', cw.StatusClass);
        System.assertNotEquals(null, cw.Id);
    }

    @IsTest
    static void testGetMyCases_noCases() {

        // ACT
        Test.startTest();
        List<CaseWrapper> result = CaseController.getMyCases();
        Test.stopTest();

        // ASSERT
        System.assertNotEquals(null, result);
    }
}
