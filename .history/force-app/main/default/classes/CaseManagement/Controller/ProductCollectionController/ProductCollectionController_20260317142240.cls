public with sharing class ProductCollectionController {

  @AuraEnabled(cacheable=true)
  public static List<Produit_Client__c> getMyCollection() {
    return [SELECT Id, Nom_Produit__c, Reference_Officielle__c,
                   Date_Acquisition__c, Canal_Achat__c, Modele__c,
                   Couleur__c, Matiere__c, Photo_Principale__c,
                   Statut_Certificat__c, Annee_Fabrication__c
            FROM Produit_Client__c
            WHERE Contact__c = :getContactId()
            WITH SECURITY_ENFORCED
            ORDER BY Date_Acquisition__c DESC];
  }

  @AuraEnabled
  public static Id addProduct(Map<String,Object> productData) {
    Produit_Client__c p = new Produit_Client__c(
      Contact__c = getContactId(),
      Nom_Produit__c = (String)productData.get('nom'),
      Modele__c = (String)productData.get('modele'),
      Date_Acquisition__c = Date.valueOf((String)productData.get('dateAcquisition')),
      Canal_Achat__c = (String)productData.get('canal'),
      Statut_Certificat__c = 'En attente'
    );
    insert p;
    return p.Id;
  }

  private static Id getContactId() { /* même méthode */ }
}