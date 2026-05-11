@IsTest
private class CaseController_Test {

    @IsTest
    static void testGetMyCasesWithCases() {

        // ARRANGE
        Id currentUserId = UserInfo.getUserId();

        // Création d'un contact pour le test
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com'
        );
        insert testContact;

        // Mise à jour de l'utilisateur pour avoir un ContactId
        User u = [SELECT Id, ContactId FROM User WHERE Id = :currentUserId];
        u.ContactId = testContact.Id;
        update u;

        // Création de cases
        Case c1 = new Case(
            Subject = 'Test Case 1',
            Status = 'New',
            Origin = 'Email',
            OwnerId = currentUserId,
            ContactId = testContact.Id
        );
        insert c1;

        Case c2 = new Case(
            Subject = 'Test Case 2',
            Status = 'Closed',
            Origin = 'Phone',
            OwnerId = currentUserId
        );
        insert c2;

        // ACT
        Test.startTest();
        List<CaseController.CaseWrapper> result = CaseController.getMyCases();
        Test.stopTest();

        // ASSERT
        System.assert(result != null, 'La méthode doit retourner une liste non null');
        System.assert(result.size() >= 2, 'La liste doit contenir au moins les deux cas créés');

        // Vérifie les valeurs du premier wrapper
        CaseController.CaseWrapper cw1 = result[0];
        System.assertNotEquals(null, cw1.Id, 'L’ID du CaseWrapper ne doit pas être null');
        System.assertEquals(c1.Subject, cw1.Subject, 'Le sujet doit correspondre');
        System.assertEquals('status-new', cw1.StatusClass, 'La classe CSS doit correspondre au statut New');

        // Vérifie le deuxième wrapper
        CaseController.CaseWrapper cw2 = result[1];
        System.assertEquals('status-closed', cw2.StatusClass, 'La classe CSS doit correspondre au statut Closed');
    }

    @IsTest
    static void testGetMyCasesWithoutCases() {

        // ACT
        Test.startTest();
        List<CaseController.CaseWrapper> result = CaseController.getMyCases();
        Test.stopTest();

        // ASSERT
        System.assert(result != null, 'La méthode doit toujours retourner une liste même vide');
        System.assertEquals(0, result.size(), 'La liste doit être vide si aucun case n’existe pour l’utilisateur');
    }
}
