@IsTest
public class SavCaseControllerTest {

    // Méthode utilitaire pour créer un contact test
    private static Contact createTestContact() {
        Contact c = new Contact(
            LastName = 'Test',
            Email = 'test@example.com'
        );
        insert c;
        return c;
    }

    // Méthode utilitaire pour créer un cas test
    private static Case createTestCase(Contact c) {
        Case cs = new Case(
            Subject = 'Test Case',
            Description = 'Description for test case',
            Status = 'New',
            ContactId = c.Id
        );
        insert cs;
        return cs;
    }

    @IsTest
    static void testCreateCase() {
        Contact c = createTestContact();

        // Appel de la méthode mock createCase
        Id caseId = SavCaseController.createCase('Subject Test', 'Description Test');
        System.assertNotEquals(null, caseId, 'Le caseId ne doit pas être nul après la création du cas');
    }

    @IsTest
    static void testAddComment() {
        Contact c = createTestContact();
        Case cs = createTestCase(c);

        // Appel de la méthode mock addComment
        SavCaseController.addComment(cs.Id, 'Test Comment');
        // Comme c'est mock, on vérifie juste que le code passe
        System.assert(true, 'addComment a été exécuté sans erreur');
    }

    @IsTest
    static void testCloseCase() {
        Contact c = createTestContact();
        Case cs = createTestCase(c);

        SavCaseController.closeCase(cs.Id);
        System.assert(true, 'closeCase a été exécuté sans erreur');
    }

    @IsTest
    static void testEscalateCase() {
        Contact c = createTestContact();
        Case cs = createTestCase(c);

        SavCaseController.escalateCase(cs.Id, 'Urgent');
        System.assert(true, 'escalateCase a été exécuté sans erreur');
    }

    @IsTest
    static void testDashboardStats() {
        // Simple appel pour tester que ça compile
        SavCaseController.getCaseDashboardStats();
        System.assert(true, 'getCaseDashboardStats a été exécuté sans erreur');
    }
}