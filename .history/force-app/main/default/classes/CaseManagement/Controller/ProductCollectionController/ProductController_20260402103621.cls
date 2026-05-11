@AuraEnabled(cacheable=true)
public static List<Product__c> getMyProducts() {
    // 1. On récupère l'utilisateur
    User u = [SELECT ContactId, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    
    // 2. TEST DE DEBUG : On affiche TOUT sans filtre pour voir si les produits existent
    // Si cela affiche les sacs, c'est que ton filtre 'WHERE Contact__c = ...' est le coupable
    return [SELECT Id, Name, Description__c, Price__c, Image_URL__c, Collection__c 
            FROM Product__c 
            WHERE Is_Active__c = true]; 
}