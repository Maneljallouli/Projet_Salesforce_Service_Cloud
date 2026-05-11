/**
 * @class       ProductCollectionController
 * @description Contrôleur pour la gestion des produits clients et du passeport numérique.
 * Version 1.3 - Fix PMD (Empty Catch) & Security
 */
public with sharing class ProductCollectionController {

    // ─── CLASSES INTERNES (Wrappers) ───────────────────────────────

    public class ProductInput {
        @AuraEnabled public String nomProduit           { get; set; }
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
        wrapper.isCertified      = (products[0].Statut_Certificat__c == 'Certifié');
        return wrapper;
    }

    // ─── MÉTHODES D'ÉCRITURE ───────────────────────────────────────

    @AuraEnabled
    public static Id addProduct(ProductInput productData) {
        if (productData == null || String.isBlank(productData.nomProduit)) {
            throw new AuraHandledException('Le nom du produit est requis.');
        }

        Id contactId = getInternalContactId();
        Integer anneeInt = null;

        // FIX PMD : Remplissage du catch block
        if (String.isNotBlank(productData.annee)) {
            try { 
                anneeInt = Integer.valueOf(productData.annee); 
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Format d\'année invalide : ' + productData.annee);
            }
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
            Annee_Fabrication__c    = anneeInt,
            NFC_Tag_ID__c           = productData.nfcTagId,
            Statut_Certificat__c    = 'En attente'
        );

        insert as user p;
        return p.Id;
    }

    @AuraEnabled
    public static void removeProduct(Id productId) {
        Id contactId = getInternalContactId();

        // Sécurité : Vérifier que le produit appartient bien au contact
        List<Produit_Client__c> owned = [
            SELECT Id FROM Produit_Client__c 
            WHERE Id = :productId AND Contact__c = :contactId 
            WITH USER_MODE
        ];
        
        if (owned.isEmpty()) { 
            throw new AuraHandledException('Action non autorisée : Vous n\'êtes pas le propriétaire.'); 
        }

        // Sécurité : Vérifier s'il y a des dossiers SAV actifs
        List<String> activeStatuses = new List<String>{'Cloture', 'Annulee'};
        Integer activeSav = [
            SELECT COUNT() FROM Demande_SAV__c 
            WHERE Produit_Client__c = :productId AND Statut__c NOT IN :activeStatuses
            WITH USER_MODE
        ];

        if (activeSav > 0) { 
            throw new AuraHandledException('Suppression impossible : Une demande SAV est actuellement en cours pour ce produit.'); 
        }

        delete as user owned[0];
    }

    // ─── HELPERS ───────────────────────────────────────────────────

    private static Id getInternalContactId() {
        User u = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE];
        if (u.ContactId == null) {
            throw new AuraHandledException('Erreur : Votre utilisateur n\'est pas lié à un compte client (Contact).');
        }
        return u.ContactId;
    }
}