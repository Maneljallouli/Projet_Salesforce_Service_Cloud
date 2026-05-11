@IsTest
private class CaseController_Test {

    @IsTest
    static void testGetMyCasesMultipleStatuses() {
        // ARRANGE : On crée plusieurs dossiers avec des statuts différents
        Id currentUserId = UserInfo.getUserId();
        List<Case> casesToInsert = new List<Case>();
        
        casesToInsert.add(new Case(Subject = 'New Case', Status = 'New', OwnerId = currentUserId));
        casesToInsert.add(new Case(Subject = 'Closed Case', Status = 'Closed', OwnerId = currentUserId));
        casesToInsert.add(new Case(Subject = 'Escalated Case', Status = 'Escalated', OwnerId = currentUserId));
        
        insert casesToInsert;

        // ACT
        Test.startTest();
        List<CaseController.CaseWrapper> result = CaseController.getMyCases();
        Test.stopTest();

        // ASSERT
        System.assertEquals(3, result.size(), 'On devrait récupérer 3 dossiers');
        
        // On vérifie que la logique CSS fonctionne pour différents statuts
        for(CaseController.CaseWrapper cw : result) {
            if(cw.Status == 'New') {
                System.assertEquals('status-new', cw.StatusClass);
            } else if(cw.Status == 'Closed') {
                System.assertEquals('status-closed', cw.StatusClass);
            } else if(cw.Status == 'Escalated') {
                System.assertEquals('status-escalated', cw.StatusClass);
            }
        }
    }

    @IsTest
    static void testGetMyCasesNoCases() {
        // ACT
        Test.startTest();
        List<CaseController.CaseWrapper> result = CaseController.getMyCases();
        Test.stopTest();

        // ASSERT
        System.assertNotEquals(null, result, 'La liste ne doit pas être null');
        System.assertEquals(0, result.size(), 'La liste doit être vide');
    }
}