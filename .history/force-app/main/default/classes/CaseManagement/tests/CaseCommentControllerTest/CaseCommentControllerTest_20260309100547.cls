@isTest
private class CaseCommentControllerTest {
    
    @testSetup
    static void setup() {
        Case testCase = new Case(Subject = 'Test Case', Status = 'New');
        insert testCase;

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
        // Corrigé : type List<CommentData>
        List<CaseCommentController.CommentData> comments = CaseCommentController.getCaseComments(c.Id);
        Test.stopTest();

        System.assertEquals(1, comments.size(), 'La liste des commentaires devrait contenir exactement un élément.');
        System.assertEquals('Initial Comment', comments[0].CommentBody, 'Le corps du commentaire ne correspond pas.');
    }

    @isTest
    static void testAddCaseComment() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        String newBody = 'New Test Comment';

        Test.startTest();
        CaseComment cc = CaseCommentController.addCaseComment(c.Id, newBody);
        Test.stopTest();

        System.assertNotEquals(null, cc.Id, 'Le commentaire devrait être inséré en base.');
        System.assertEquals(newBody, cc.CommentBody, 'Le texte du commentaire sauvegardé est différent.');
    }
}