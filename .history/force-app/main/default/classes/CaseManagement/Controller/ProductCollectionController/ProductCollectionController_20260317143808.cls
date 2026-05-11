/**
 * @class       ProductCollectionController
 * @description AuraEnabled controller for the client product collection
 *              (Produit_Client__c) on Experience Cloud.
 *              Handles CRUD for owned products and digital product passport.
 *
 * @author      Salesforce Architect
 * @version     1.0
 */
public with sharing class ProductCollectionController {

    // ─────────────────────────────────────────────────────────────
    // INNER CLASSES
    // ─────────────────────────────────────────────────────────────

    public class ProductInput {
        @AuraEnabled public String nomProduit          { get; set; }
        @AuraEnabled public String referenceOfficielle { get; set; }
        @AuraEnabled public String modele              { get; set; }
        @AuraEnabled public String couleur             { get; set; }
        @AuraEnabled public String matiere             { get; set; }
        @AuraEnabled public String canalAchat          { get; set; }
        @AuraEnabled public Date   dateAcquisition     { get; set; }
        @AuraEnabled public String annee               { get; set; }
        @AuraEnabled public String photoPrincipaleUrl  { get; set; }
        @AuraEnabled public String nfcTagId            { get; set; }
    }

    public class PassportWrapper {
        @AuraEnabled public Produit_Client__c     product       { get; set; }
        @AuraEnabled public List<Demande_SAV__c>  savHistory    { get; set; }
        @AuraEnabled public Integer               savCount      { get; set; }
        @AuraEnabled public Boolean               isCertified   { get; set; }
        @AuraEnabled public String                certificateUrl { get; set; }
    }

    // ─────────────────────────────────────────────────────────────
    // READ METHODS
    // ─────────────────────────────────────────────────────────────

    /**
     * Returns all products owned by the current portal user.
     */
    @AuraEnabled(cacheable=true)
    public static List<Produit_Client__c> getMyProducts() {
        Id contactId = ContactUtils.getCurrentContactId();

        return [
            SELECT  Id, Nom_Produit__c, Reference_Officielle__c,
                    Modele__c, Couleur__c, Matiere__c,
                    Date_Acquisition__c, Canal_Achat__c,
                    Annee_Fabrication__c, Photo_Principale__c,
                    Statut_Certificat__c, NFC_Tag_ID__c,
                    (SELECT COUNT_DISTINCT(Id) total
                     FROM   Demandes_SAV__r
                     WHERE  Statut__c != 'Annulee')
            FROM    Produit_Client__c
            WHERE   Contact__c = :contactId
            WITH    SECURITY_ENFORCED
            ORDER BY Date_Acquisition__c DESC NULLS LAST
        ];
    }

    /**
     * Returns full product passport including SAV history.
     * @param productId  Produit_Client__c Id
     */
    @AuraEnabled(cacheable=true)
    public static PassportWrapper getProductPassport(Id productId) {
        Id contactId = ContactUtils.getCurrentContactId();

        List<Produit_Client__c> products = [
            SELECT  Id, Nom_Produit__c, Reference_Officielle__c,
                    Modele__c, Couleur__c, Matiere__c,
                    Date_Acquisition__c, Canal_Achat__c,
                    Annee_Fabrication__c, Photo_Principale__c,
                    Statut_Certificat__c, NFC_Tag_ID__c,
                    Contact__c
            FROM    Produit_Client__c
            WHERE   Id = :productId
            AND     Contact__c = :contactId
            WITH    SECURITY_ENFORCED
            LIMIT   1
        ];

        if (products.isEmpty()) {
            throw new AuraHandledException(Label.Product_Error_NotFound);
        }

        Produit_Client__c product = products[0];

        List<Demande_SAV__c> savHistory = [
            SELECT  Id, Name, Statut__c, Categorie__r.Nom__c,
                    Date_Soumission__c, Date_Validation_Client__c,
                    Montant_Final__c, Artisan_Responsable__c
            FROM    Demande_SAV__c
            WHERE   Produit_Client__c = :productId
            WITH    SECURITY_ENFORCED
            ORDER BY Date_Soumission__c DESC
            LIMIT   20
        ];

        PassportWrapper wrapper  = new PassportWrapper();
        wrapper.product          = product;
        wrapper.savHistory       = savHistory;
        wrapper.savCount         = savHistory.size();
        wrapper.isCertified      = product.Statut_Certificat__c == 'Certifié';
        wrapper.certificateUrl   = wrapper.isCertified
            ? buildCertificateUrl(product.Reference_Officielle__c) : null;
        return wrapper;
    }

    /**
     * Resolves a product by NFC Tag ID (phygital tap-to-open).
     * @param nfcTagId  NFC chip identifier scanned by the client device
     * @return          Produit_Client__c Id or null if not found / not owned
     */
    @AuraEnabled(cacheable=false)
    public static Id resolveProductByNfc(String nfcTagId) {
        if (String.isBlank(nfcTagId)) return null;
        Id contactId = ContactUtils.getCurrentContactId();

        List<Produit_Client__c> matches = [
            SELECT Id
            FROM   Produit_Client__c
            WHERE  NFC_Tag_ID__c = :nfcTagId
            AND    Contact__c    = :contactId
            WITH   SECURITY_ENFORCED
            LIMIT  1
        ];
        return matches.isEmpty() ? null : matches[0].Id;
    }

    // ─────────────────────────────────────────────────────────────
    // WRITE METHODS
    // ─────────────────────────────────────────────────────────────

    /**
     * Adds a new product to the client's collection.
     * Reference_Officielle__c uniqueness checked per-contact (not globally).
     * @param productData  Populated ProductInput wrapper
     * @return             Id of newly created Produit_Client__c
     */
    @AuraEnabled
    public static Id addProduct(ProductInput productData) {
        if (productData == null) {
            throw new AuraHandledException(Label.Product_Error_InvalidInput);
        }
        if (String.isBlank(productData.nomProduit)) {
            throw new AuraHandledException(Label.Product_Error_NameRequired);
        }

        Id contactId = ContactUtils.getCurrentContactId();

        // Check duplicate reference for this contact
        if (String.isNotBlank(productData.referenceOfficielle)) {
            Integer existingCount = [
                SELECT COUNT()
                FROM   Produit_Client__c
                WHERE  Reference_Officielle__c = :productData.referenceOfficielle
                AND    Contact__c = :contactId
            ];
            if (existingCount > 0) {
                throw new AuraHandledException(Label.Product_Error_DuplicateRef);
            }
        }

        Integer annee = null;
        if (String.isNotBlank(productData.annee)) {
            try { annee = Integer.valueOf(productData.annee); }
            catch (Exception e) { /* ignore non-numeric */ }
        }

        Produit_Client__c p = new Produit_Client__c(
            Contact__c              = contactId,
            Nom_Produit__c          = String.escapeSingleQuotes(productData.nomProduit),
            Reference_Officielle__c = productData.referenceOfficielle,
            Modele__c               = productData.modele,
            Couleur__c              = productData.couleur,
            Matiere__c              = productData.matiere,
            Canal_Achat__c          = productData.canalAchat,
            Date_Acquisition__c     = productData.dateAcquisition,
            Annee_Fabrication__c    = annee,
            Photo_Principale__c     = productData.photoPrincipaleUrl,
            NFC_Tag_ID__c           = productData.nfcTagId,
            Statut_Certificat__c    = 'En attente'
        );

        insert p;
        return p.Id;
    }

    /**
     * Updates an existing product. Ownership verified.
     */
    @AuraEnabled
    public static void updateProduct(Id productId, ProductInput productData) {
        if (productData == null || productId == null) {
            throw new AuraHandledException(Label.Product_Error_InvalidInput);
        }

        Id contactId = ContactUtils.getCurrentContactId();

        List<Produit_Client__c> owned = [
            SELECT Id FROM Produit_Client__c
            WHERE  Id = :productId AND Contact__c = :contactId
            WITH   SECURITY_ENFORCED LIMIT 1
        ];
        if (owned.isEmpty()) {
            throw new AuraHandledException(Label.Product_Error_NotFound);
        }

        Integer annee = null;
        if (String.isNotBlank(productData.annee)) {
            try { annee = Integer.valueOf(productData.annee); }
            catch (Exception e) { /* ignore */ }
        }

        update new Produit_Client__c(
            Id                   = productId,
            Nom_Produit__c       = String.escapeSingleQuotes(productData.nomProduit),
            Modele__c            = productData.modele,
            Couleur__c           = productData.couleur,
            Matiere__c           = productData.matiere,
            Canal_Achat__c       = productData.canalAchat,
            Date_Acquisition__c  = productData.dateAcquisition,
            Annee_Fabrication__c = annee,
            Photo_Principale__c  = productData.photoPrincipaleUrl
        );
    }

    /**
     * Soft-delete: marks product as inactive (does not cascade to SAV records).
     */
    @AuraEnabled
    public static void removeProduct(Id productId) {
        Id contactId = ContactUtils.getCurrentContactId();

        List<Produit_Client__c> owned = [
            SELECT Id FROM Produit_Client__c
            WHERE  Id = :productId AND Contact__c = :contactId
            WITH   SECURITY_ENFORCED LIMIT 1
        ];
        if (owned.isEmpty()) {
            throw new AuraHandledException(Label.Product_Error_NotFound);
        }

        // Prevent removal if active SAV exists
        Integer activeSav = [
            SELECT COUNT() FROM Demande_SAV__c
            WHERE  Produit_Client__c = :productId
            AND    Statut__c NOT IN ('Cloture', 'Annulee', 'Valide')
        ];
        if (activeSav > 0) {
            throw new AuraHandledException(Label.Product_Error_ActiveSav);
        }

        update new Produit_Client__c(
            Id      = productId,
            Actif__c = false
        );
    }

    // ─────────────────────────────────────────────────────────────
    // PRIVATE HELPERS
    // ─────────────────────────────────────────────────────────────

    private static String buildCertificateUrl(String reference) {
        if (String.isBlank(reference)) return null;
        String baseUrl = [
            SELECT Value__c FROM Portal_Config__mdt
            WHERE  DeveloperName = 'Certificate_Base_URL' LIMIT 1
        ].Value__c;
        return baseUrl + '?ref=' + EncodingUtil.urlEncode(reference, 'UTF-8');
    }
}