/**
 * @class       ProductCollectionController
 * @description Contrôleur Aura pour la collection de produits client (Produit_Client__c).
 * Version 1.2 - Fix déploiement (Fields, Metadata, Utils)
 */
public with sharing class ProductCollectionController {

    // ─── CLASSES INTERNES ──────────────────────────────────────────

    public class ProductInput {
        @AuraEnabled public String nomProduit          { get; set; }
        @AuraEnabled public String referenceOfficielle { get; set; }
        @AuraEnabled public String modele               { get; set; }
        @AuraEnabled public String couleur              { get; set; }
        @AuraEnabled public String matiere              { get; set; }
        @AuraEnabled public String canalAchat           { get; set; }
        @AuraEnabled public Date   dateAcquisition      { get; set; }
        @AuraEnabled public String annee                { get; set; }
        @AuraEnabled public String nfcTagId            { get; set; }
    }

    public class PassportWrapper {
        @AuraEnabled public Produit_Client__c    product       { get; set; }
        @AuraEnabled public List<Demande_SAV__c>  savHistory    { get; set; }
        @AuraEnabled public Integer               savCount      { get; set; }
        @AuraEnabled public Boolean               isCertified   { get; set; }
    }

    // ─── MÉTHODES DE LECTURE ───────────────────────────────────────

    @AuraEnabled(cacheable=true)
    public static List<Produit_Client__c> getMyProducts() {
        Id contactId = getInternalContactId();

        return [
            SELECT  Id, Nom_Produit__c, Reference_Officielle__c,
                    Modele__c, Couleur__c, Matiere__c,
                    Date_Acquisition__c, Canal_Achat__c,
                    Annee_Fabrication__c, Statut_Certificat__c, NFC_Tag_ID__c
            FROM    Produit_Client__c
            WHERE   Contact__c = :contactId
            WITH    USER_MODE
            ORDER BY Date_Acquisition__c DESC NULLS LAST
        ];
    }

    @AuraEnabled(cacheable=true)
    public static PassportWrapper getProductPassport(Id productId) {
        Id contactId = getInternalContactId();

        List<Produit_Client__c> products = [
            SELECT  Id, Nom_Produit__c, Reference_Officielle__c,
                    Modele__c, Couleur__c, Matiere__c,
                    Date_Acquisition__c, Canal_Achat__c,
                    Annee_Fabrication__c, Statut_Certificat__c, 
                    NFC_Tag_ID__c, Contact__c
            FROM    Produit_Client__c
            WHERE   Id = :productId AND Contact__c = :contactId
            WITH    USER_MODE
            LIMIT   1
        ];

        if (products.isEmpty()) {
            throw new AuraHandledException('Produit introuvable.');
        }

        List<Demande_SAV__c> savHistory = [
            SELECT  Id, Name, Statut__c, Date_Soumission__c, Montant_Final__c
            FROM    Demande_SAV__c
            WHERE   Produit_Client__c = :productId
            WITH    USER_MODE
            ORDER BY Date_Soumission__c DESC
            LIMIT   10
        ];

        PassportWrapper wrapper  = new PassportWrapper();
        wrapper.product          = products[0];
        wrapper.savHistory       = savHistory;
        wrapper.savCount         = savHistory.size();
        wrapper.isCertified      = products[0].Statut_Certificat__c == 'Certifié';
        return wrapper;
    }

    // ─── MÉTHODES D'ÉCRITURE ───────────────────────────────────────

    @AuraEnabled
    public static Id addProduct(ProductInput productData) {
        if (productData == null || String.isBlank(productData.nomProduit)) {
            throw new AuraHandledException('Le nom du produit est requis.');
        }

        Id contactId = getInternalContactId();

        Integer annee = null;
        if (String.isNotBlank(productData.annee)) {
            try { annee = Integer.valueOf(productData.annee); } catch (Exception e) {}
        }

        Produit_Client__c p = new Produit_Client__c(
            Contact__c              = contactId,
            Nom_Produit__c          = productData.nomProduit,
            Reference_Officielle__c = productData.referenceOfficielle,
            Modele__c               = productData.modele,
            Couleur__c              = productData.couleur,
            Matiere__c              = productData.matiere,
            Canal_Achat__c          = productData.canalAchat,
            Date_Acquisition__c     = productData.dateAcquisition,
            Annee_Fabrication__c    = annee,
            NFC_Tag_ID__c           = productData.nfcTagId,
            Statut_Certificat__c    = 'En attente'
        );

        insert as user p;
        return p.Id;
    }

    @AuraEnabled
    public static void removeProduct(Id productId) {
        Id contactId = getInternalContactId();

        // Vérification de propriété
        List<Produit_Client__c> owned = [SELECT Id FROM Produit_Client__c WHERE Id = :productId AND Contact__c = :contactId WITH USER_MODE];
        if (owned.isEmpty()) { throw new AuraHandledException('Action non autorisée.'); }

        // Vérification SAV actif
        Integer activeSav = [SELECT COUNT() FROM Demande_SAV__c WHERE Produit_Client__c = :productId AND Statut__c NOT IN ('Cloture', 'Annulee') WITH USER_MODE];
        if (activeSav > 0) { throw new AuraHandledException('Impossible de supprimer un produit avec un SAV en cours.'); }

        delete as user owned[0];
    }

    // ─── HELPERS ───────────────────────────────────────────────────

    private static Id getInternalContactId() {
        User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE];
        if (u.ContactId == null) {
            throw new AuraHandledException('Utilisateur non lié à un contact.');
        }
        return u.ContactId;
    }
}