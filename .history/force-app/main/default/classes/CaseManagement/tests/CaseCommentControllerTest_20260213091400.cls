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
        
        // Correction : Ajout du 3ème paramètre (le message d'erreur)
        Assert.areEqual(1, comments.size(), 'La liste des commentaires devrait contenir exactement un élément.');
        Assert.areEqual('Initial Comment', comments[0].CommentBody, 'Le corps du commentaire récupéré ne correspond pas à celui inséré en setup.');
    }

    @isTest
    static void testAddCaseComment() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        String newBody = 'New Test Comment';
        
        Test.startTest();
        CaseCommentController.addCaseComment(c.Id, newBody);
        Test.stopTest();
        
        List<CaseComment> comments = [SELECT Id FROM CaseComment WHERE CommentBody = :newBody];
        // Correction : Ajout du 3ème paramètre
        Assert.areEqual(1, comments.size(), 'Le commentaire devrait avoir été créé avec succès en base de données.');
        Assert.areEqual(newBody, comments[0].CommentBody, 'Le texte du commentaire sauvegardé est différent du texte envoyé.');
    }
}