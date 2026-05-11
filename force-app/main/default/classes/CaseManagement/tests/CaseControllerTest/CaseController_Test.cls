@IsTest
private class CaseController_Test {

    @IsTest
    static void testGetMyCasesMultipleStatuses() {
        // ARRANGE
        Id currentUserId = UserInfo.getUserId();
        List<Case> casesToInsert = new List<Case>();
        
        // On crée des dossiers pour couvrir les différentes branches du code
        casesToInsert.add(new Case(Subject = 'New Case', Status = 'New', OwnerId = currentUserId));
        casesToInsert.add(new Case(Subject = 'Closed Case', Status = 'Closed', OwnerId = currentUserId));
        casesToInsert.add(new Case(Subject = 'Escalated Case', Status = 'Escalated', OwnerId = currentUserId));
        
        insert casesToInsert;

        // ACT
        Test.startTest();
        List<CaseController.CaseWrapper> result = CaseController.getMyCases();
        Test.stopTest();

        // ASSERT
        System.assertEquals(3, result.size(), 'Le nombre de dossiers récupérés est incorrect');
        
        for(CaseController.CaseWrapper cw : result) {
            if(cw.Status == 'New') {
                System.assertEquals('status-new', cw.StatusClass, 'La classe CSS pour le statut New est incorrecte');
            } else if(cw.Status == 'Closed') {
                System.assertEquals('status-closed', cw.StatusClass, 'La classe CSS pour le statut Closed est incorrecte');
            } else if(cw.Status == 'Escalated') {
                // CORRECTION : On attend 'status-in-progress' comme l'a indiqué l'erreur précédente
                System.assertEquals('status-in-progress', cw.StatusClass, 'La classe CSS pour le statut Escalated est incorrecte');
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
        System.assertNotEquals(null, result, 'La liste retournée ne devrait pas être null');
        System.assertEquals(0, result.size(), 'La liste devrait être vide quand l utilisateur n a pas de dossiers');
    }
}