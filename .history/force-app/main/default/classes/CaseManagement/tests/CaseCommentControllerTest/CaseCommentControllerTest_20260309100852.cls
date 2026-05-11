@isTest
private class CaseCommentControllerTest {

    @testSetup
    static void setup() {
        // Création d'un Case de test
        Case testCase = new Case(Subject = 'Test Case', Status = 'New');
        insert testCase;

        // Création d'un commentaire initial
        CaseComment comment = new CaseComment(
            ParentId = testCase.Id,
            CommentBody = 'Initial Comment',
            IsPublished = true
        );
        insert comment;
    }

    @isTest
    static void testGetCaseComments() {
        Case c = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        List<CaseCommentController.CommentData> comments = CaseCommentController.getCaseComments(c.Id);
        Test.stopTest();

        System.assertEquals(1, comments.size(), 'La liste des commentaires devrait contenir exactement un élément.');
        System.assertEquals('Initial Comment', comments[0].body, 'Le corps du commentaire ne correspond pas.');
    }

    @isTest
    static void testPostMessage() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        String newBody = 'New Test Comment';

        Test.startTest();
        CaseCommentController.postMessage(c.Id, newBody);
        Test.stopTest();

        List<CaseComment> comments = [SELECT CommentBody FROM CaseComment WHERE ParentId = :c.Id AND CommentBody = :newBody];
        System.assertEquals(1, comments.size(), 'Le commentaire devrait avoir été créé en base.');
        System.assertEquals(newBody, comments[0].CommentBody, 'Le texte du commentaire sauvegardé est différent.');
    }
}