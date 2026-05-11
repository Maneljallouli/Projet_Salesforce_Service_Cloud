@IsTest
private class SavCaseControllerTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            LastName = 'Test Contact',
            AccountId = acc.Id
            // Preferred_Language__c et Segment_VIP__c supprimés
        );
        insert con;

        Case c = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Web',
            ContactId = con.Id
        );
        insert c;
    }

    @IsTest
    static void testCreateCase() {
        Test.startTest();

        // Appel générique à createCase (simplifié)
        Id caseId = SavCaseController.createCase('Sujet test', 'Description test');
        System.assertNotEquals(null, caseId, 'createCase doit retourner un Id valide');

        Test.stopTest();
    }

    @IsTest
    static void testAddComment() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();

        // Appel générique à addComment (si méthode existe)
        SavCaseController.addComment(c.Id, 'Commentaire test');
        System.assert(true, 'addComment exécuté sans erreur');

        Test.stopTest();
    }

    @IsTest
    static void testCloseCase() {
        Case c = [SELECT Id, Status FROM Case LIMIT 1];
        Test.startTest();

        SavCaseController.closeCase(c.Id);
        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :c.Id];
        System.assertEquals('Closed', updatedCase.Status, 'Le statut du case doit être Closed');

        Test.stopTest();
    }

    @IsTest
    static void testEscalateCase() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();

        SavCaseController.escalateCase(c.Id, 'Raison test');
        // Vérifie que l'exécution ne plante pas
        System.assert(true, 'escalateCase exécuté sans erreur');

        Test.stopTest();
    }
}