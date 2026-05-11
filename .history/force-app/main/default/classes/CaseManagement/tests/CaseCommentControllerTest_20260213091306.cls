@isTest
private class CaseCommentControllerTest {
    
    @testSetup
    static void setup() {
        // Création d'une requête de test
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
        List<CaseComment> comments = CaseCommentController.getCaseComments(c.Id);
        Test.stopTest();
        
        Assert.areEqual(1, comments.size(), 'On devrait avoir 1 commentaire');
        Assert.areEqual('Initial Comment', comments[0].CommentBody);
    }

    @isTest
    static void testAddCaseComment() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        String newBody = 'New Test Comment';
        
        Test.startTest();
        CaseCommentController.addCaseComment(c.Id, newBody);
        Test.stopTest();
        
        List<CaseComment> comments = [SELECT Id FROM CaseComment WHERE CommentBody = :newBody];
        Assert.areEqual(1, comments.size(), 'Le commentaire aurait dû être inséré');
    }
}