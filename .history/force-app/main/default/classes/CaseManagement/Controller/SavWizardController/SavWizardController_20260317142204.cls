public with sharing class SavWizardController {

  @AuraEnabled(cacheable=true)
  public static List<Produit_Client__c> getMyProducts() { ... }

  @AuraEnabled(cacheable=true)
  public static List<Categorie_SAV__c> getSavCategories() { ... }

  @AuraEnabled
  public static Id createSavRequest(Map<String,Object> requestData) { ... }

  @AuraEnabled(cacheable=true)
  public static Demande_SAV__c getSavDetail(Id savId) { ... }

  @AuraEnabled(cacheable=true)
  public static List<Demande_SAV__c> getMySavRequests() { ... }

  @AuraEnabled
  public static void validateDevis(Id savId, Boolean approved) { ... }

  private static Id getContactId() {
    User u = [SELECT ContactId FROM User
              WHERE Id = :UserInfo.getUserId() LIMIT 1];
    if(u.ContactId == null)
      throw new AuraHandledException('Contact introuvable');
    return u.ContactId;
  }
}