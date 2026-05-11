@IsTest
private class CaseController_Test {

    @IsTest
    static void testGetMyCasesSuccess() {

        // ARRANGE
        // On récupère l'ID de l'utilisateur courant de manière propre
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
        // Utilisation du préfixe CaseController pour accéder à la classe interne Wrapper
        List<CaseController.CaseWrapper> result = CaseController.getMyCases();
        Test.stopTest();

        // ASSERT
        System.assert(
            result.size() > 0,
            'La liste des cases doit contenir au moins un élément'
        );

        // On utilise ici aussi le type complet
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
        // Correction de la signature de l'assertion si nécessaire
        System.assertNotEquals(
            null,
            result,
            'La méthode doit toujours retourner une liste'
        );
    }
}