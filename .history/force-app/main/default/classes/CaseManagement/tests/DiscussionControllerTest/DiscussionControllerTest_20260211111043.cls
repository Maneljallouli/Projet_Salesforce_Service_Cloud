@isTest
private class DiscussionControllerTest {
    
    @isTest
    static void testDiscussionFlow() {
        // Création de données de test
        Account acc = new Account(Name = 'Luxury Test Account');
        insert acc;

        Test.startTest();
        DiscussionController.postQuestion(acc.Id, 'Quelle est la durée de garantie ?');
        List<FeedItem> results = DiscussionController.getDiscussions(acc.Id);
        Test.stopTest();

        // Ajout du message de diagnostic (3ème paramètre)
        System.assertEquals(1, results.size(), 'La liste des discussions devrait contenir exactement 1 élément après insertion.');
        System.assertEquals('Quelle est la durée de garantie ?', results[0].Body, 'Le corps du message récupéré ne correspond pas au message inséré.');
    }
}