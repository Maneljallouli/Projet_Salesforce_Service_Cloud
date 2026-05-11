@IsTest
private class ApplyCaseAssignmentRule_Test {

    @IsTest
    static void testApplyRulesSuccess() {

        // ARRANGE
        Case c = new Case(
            Subject = 'Test Assignment Rule',
            Status = 'New',
            Origin = 'Phone'
        );
        insert c;

        // ACT
        Test.startTest();
        ApplyCaseAssignmentRule.applyRules(
            new List<Id>{ c.Id }
        );
        Test.stopTest();

        // ASSERT
        Case result = [
            SELECT OwnerId
            FROM Case
            WHERE Id = :c.Id
        ];

        System.assertNotEquals(
            null,
            result.OwnerId,
            'Le propriétaire du Case doit être défini par la règle'
        );
    }
}
