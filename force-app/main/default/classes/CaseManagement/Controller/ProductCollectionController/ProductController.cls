@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductController {

    @AuraEnabled(cacheable=true)
    public static List<Product__c> getMyProducts() {
        try {
            // 1. Récupérer l'utilisateur courant (Id de session)
            User u = [SELECT ContactId, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id targetCid = u.ContactId;

            // 2. LOGIQUE DE SECOURS : Si ContactId est vide, on cherche par l'Email
            if (targetCid == null) {
                List<Contact> conList = [SELECT Id FROM Contact WHERE Email = :u.Email LIMIT 1];
                if (!conList.isEmpty()) {
                    targetCid = conList[0].Id;
                }
            }

            // 3. Si on n'a toujours rien, on s'arrête ici
            if (targetCid == null) {
                return new List<Product__c>();
            }

            // 4. Requête finale filtrée sur ton champ Master-Detail 'Contact__c'
            return [
                SELECT Id, Name, Description__c, Price__c, Image_URL__c, Collection__c
                FROM Product__c
                WHERE Contact__c = :targetCid
                AND Is_Active__c = true
                ORDER BY Name ASC
            ];

        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getCollections() {
        List<String> cols = new List<String>{'All'};
        try {
            User u = [SELECT ContactId, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id cid = u.ContactId;

            if (cid == null) {
                List<Contact> conList = [SELECT Id FROM Contact WHERE Email = :u.Email LIMIT 1];
                if (!conList.isEmpty()) cid = conList[0].Id;
            }

            if (cid != null) {
                for (AggregateResult ar : [
                    SELECT Collection__c col FROM Product__c 
                    WHERE Contact__c = :cid AND Is_Active__c = true 
                    GROUP BY Collection__c
                ]) {
                    String s = (String) ar.get('col');
                    if (String.isNotBlank(s)) cols.add(s);
                }
            }
        } catch (Exception e) {
            return cols;
        }
        return cols;
    }
}