@isTest
private class DiscussionControllerTest {
    
    @isTest
    static void testDiscussionFlow() {
        // 1. Création d'un compte pour servir de ParentId
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Test.startTest();
        // 2. Test de l'insertion
        DiscussionController.postQuestion(acc.Id, 'Ma question de test ?');
        
        // 3. Test de la récupération
        List<SObject> results = DiscussionController.getDiscussions(acc.Id);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Il devrait y avoir une discussion');
        FeedItem fi = (FeedItem)results[0];
        System.assertEquals('Ma question de test ?', fi.Body);
    }
}