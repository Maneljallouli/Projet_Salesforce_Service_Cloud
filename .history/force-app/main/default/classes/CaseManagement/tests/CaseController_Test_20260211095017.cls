@IsTest
private class CaseController_Test {

    @IsTest
    static void testGetMyCasesSuccess() {

        // ARRANGE
        Id currentUserId = UserInfo.getUserId();

        Case c = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Email',
            OwnerId = currentUserId
        );
        insert c;

        // ACT
        Test.startTest();
        // Correction : On précise que CaseWrapper appartient à CaseController
        List<CaseController.CaseWrapper> result = CaseController.getMyCases();
        Test.stopTest();

        // ASSERT
        System.assert(
            result.size() > 0,
            'La liste des cases doit contenir au moins un élément'
        );

        // Correction : Ici aussi, on utilise le type complet
        CaseController.CaseWrapper cw = result[0];

        System.assertEquals(
            'New',
            cw.Status,
            'Le statut du Case doit être New'
        );

        System.assertEquals(
            'status-new',
            cw.StatusClass,
            'La classe CSS doit correspondre au statut New'
        );

        System.assertNotEquals(
            null,
            cw.Id,
            'L’ID du Case ne doit pas être null'
        );
    }

    @IsTest
    static void testGetMyCasesNoCases() {

        // ACT
        Test.startTest();
        List<CaseController.CaseWrapper> result = CaseController.getMyCases();
        Test.stopTest();

        // ASSERT
        // Correction de la signature pour comparer la liste au null
        System.assertNotEquals(
            null,
            result,
            'La méthode doit toujours retourner une liste'
        );
    }
}