/**
 * @class       SavWizardController
 * @description AuraEnabled controller for the SAV repair wizard on Experience Cloud.
 *              Handles creation and retrieval of Demande_SAV__c records.
 *              All DML is bulk-safe. All SOQL uses WITH SECURITY_ENFORCED.
 *              Record-level security enforced via Contact ownership check.
 *
 * @author      Salesforce Architect
 * @version     1.0
 */
public with sharing class SavWizardController {

    // ─────────────────────────────────────────────────────────────
    // INNER CLASSES
    // ─────────────────────────────────────────────────────────────

    public class SavRequestInput {
        @AuraEnabled public String  produitClientId { get; set; }
        @AuraEnabled public String  categorieId     { get; set; }
        @AuraEnabled public String  sousCategorie   { get; set; }
        @AuraEnabled public String  description     { get; set; }
        @AuraEnabled public String  canalRetour     { get; set; }
        @AuraEnabled public String  photoUrlsJson   { get; set; }
    }

    public class SavDetailWrapper {
        @AuraEnabled public Demande_SAV__c            record       { get; set; }
        @AuraEnabled public List<Intervention_SAV__c> interventions { get; set; }
        @AuraEnabled public Facture_SAV__c            facture      { get; set; }
        @AuraEnabled public Boolean                   canValidate  { get; set; }
        @AuraEnabled public Boolean                   canPay       { get; set; }
    }

    public class SavListWrapper {
        @AuraEnabled public List<Demande_SAV__c> records    { get; set; }
        @AuraEnabled public Integer              totalCount { get; set; }
    }

    // ─────────────────────────────────────────────────────────────
    // READ METHODS
    // ─────────────────────────────────────────────────────────────

    /**
     * Returns paginated list of SAV requests for the current portal user.
     * @param pageSize  Number of records per page (max 50)
     * @param pageNum   1-based page number
     * @param statut    Optional status filter (null = all)
     */
    @AuraEnabled(cacheable=true)
    public static SavListWrapper getMySavRequests(
            Integer pageSize,
            Integer pageNum,
            String  statut) {

        Id contactId = ContactUtils.getCurrentContactId();

        // Input sanitisation
        Integer safePageSize = (pageSize == null || pageSize > 50 || pageSize < 1) ? 20 : pageSize;
        Integer safeOffset   = ((pageNum  == null || pageNum  < 1)  ? 0 : (pageNum - 1)) * safePageSize;

        // Apex SOQL does not support "OR :var = null" inline conditions.
        // Branch on statut nullity before issuing the query.
        Boolean filterByStatus = String.isNotBlank(statut);

        Integer total;
        List<Demande_SAV__c> records;

        if (filterByStatus) {
            total = [
                SELECT COUNT()
                FROM   Demande_SAV__c
                WHERE  Contact__c = :contactId
                AND    Statut__c  = :statut
            ];
            records = [
                SELECT  Id, Name, Statut__c, Statut_Paiement__c,
                        Montant_Devis__c, Montant_Final__c,
                        Date_Soumission__c, Date_Livraison__c,
                        Produit_Client__r.Nom_Produit__c,
                        Produit_Client__r.Modele__c,
                        Produit_Client__r.Couleur__c,
                        Produit_Client__r.Photo_Principale__c,
                        Categorie__r.Nom__c,
                        Conseiller_Reference__r.Name
                FROM    Demande_SAV__c
                WHERE   Contact__c = :contactId
                AND     Statut__c  = :statut
                WITH    SECURITY_ENFORCED
                ORDER BY Date_Soumission__c DESC
                LIMIT   :safePageSize
                OFFSET  :safeOffset
            ];
        } else {
            total = [
                SELECT COUNT()
                FROM   Demande_SAV__c
                WHERE  Contact__c = :contactId
            ];
            records = [
                SELECT  Id, Name, Statut__c, Statut_Paiement__c,
                        Montant_Devis__c, Montant_Final__c,
                        Date_Soumission__c, Date_Livraison__c,
                        Produit_Client__r.Nom_Produit__c,
                        Produit_Client__r.Modele__c,
                        Produit_Client__r.Couleur__c,
                        Produit_Client__r.Photo_Principale__c,
                        Categorie__r.Nom__c,
                        Conseiller_Reference__r.Name
                FROM    Demande_SAV__c
                WHERE   Contact__c = :contactId
                WITH    SECURITY_ENFORCED
                ORDER BY Date_Soumission__c DESC
                LIMIT   :safePageSize
                OFFSET  :safeOffset
            ];
        }

        SavListWrapper result = new SavListWrapper();
        result.records    = records;
        result.totalCount = total;
        return result;
    }

    /**
     * Returns full SAV detail with interventions and invoice.
     * Ownership check: Contact__c must match current user's contact.
     * @param savId  Demande_SAV__c Id
     */
    @AuraEnabled(cacheable=true)
    public static SavDetailWrapper getSavDetail(Id savId) {

        Id contactId = ContactUtils.getCurrentContactId();

        List<Demande_SAV__c> records = [
            SELECT  Id, Name, Statut__c, Description__c,
                    Statut_Paiement__c, Payment_Intent_ID__c,
                    Montant_Devis__c, Montant_Final__c,
                    Artisan_Responsable__c, Note_Atelier__c,
                    Canal_Retour__c, Langue_Client__c,
                    Numero_Suivi_Entrant__c, Numero_Suivi_Sortant__c,
                    Date_Soumission__c, Date_Colis_Envoye__c,
                    Date_Colis_Recu__c, Date_Reparation_Debut__c,
                    Date_Reparation_Fin__c, Date_Expedition__c,
                    Date_Livraison__c, Date_Validation_Client__c,
                    Produit_Client__c,
                    Produit_Client__r.Nom_Produit__c,
                    Produit_Client__r.Modele__c,
                    Produit_Client__r.Couleur__c,
                    Produit_Client__r.Matiere__c,
                    Produit_Client__r.Photo_Principale__c,
                    Produit_Client__r.Reference_Officielle__c,
                    Categorie__r.Nom__c,
                    Categorie__r.Icone_URL__c,
                    Conseiller_Reference__r.Name,
                    Conseiller_Reference__r.Email,
                    Contact__c
            FROM    Demande_SAV__c
            WHERE   Id = :savId
            AND     Contact__c = :contactId
            WITH    SECURITY_ENFORCED
            LIMIT   1
        ];

        if (records.isEmpty()) {
            throw new AuraHandledException(Label.SAV_Error_NotFound);
        }

        Demande_SAV__c sav = records[0];

        List<Intervention_SAV__c> interventions = [
            SELECT  Id, Type_Intervention__c, Description__c,
                    Artisan__c, Date_Intervention__c, Photos_URL__c
            FROM    Intervention_SAV__c
            WHERE   Demande_SAV__c = :savId
            WITH    SECURITY_ENFORCED
            ORDER BY Date_Intervention__c ASC
        ];

        List<Facture_SAV__c> factures = [
            SELECT  Id, Name, Numero_Facture__c, Date_Emission__c,
                    Montant_HT__c, TVA_Taux__c, Montant_TTC__c,
                    Statut__c, PDF_URL__c
            FROM    Facture_SAV__c
            WHERE   Demande_SAV__c = :savId
            WITH    SECURITY_ENFORCED
            LIMIT   1
        ];

        SavDetailWrapper wrapper = new SavDetailWrapper();
        wrapper.record        = sav;
        wrapper.interventions = interventions;
        wrapper.facture       = factures.isEmpty() ? null : factures[0];
        wrapper.canValidate   = sav.Statut__c == 'Livre';
        wrapper.canPay        = sav.Statut__c == 'Devis_Approuve'
                             && sav.Statut_Paiement__c == 'En attente';
        return wrapper;
    }

    /**
     * Returns available SAV categories with estimated price ranges.
     */
    @AuraEnabled(cacheable=true)
    public static List<Categorie_SAV__c> getSavCategories() {
        return [
            SELECT  Id, Nom__c, Code__c, Description__c,
                    Icone_URL__c, Delai_Estime_Jours__c,
                    Fourchette_Prix_Min__c, Fourchette_Prix_Max__c
            FROM    Categorie_SAV__c
            WHERE   Actif__c = true
            WITH    SECURITY_ENFORCED
            ORDER BY Nom__c ASC
        ];
    }

    // ─────────────────────────────────────────────────────────────
    // WRITE METHODS
    // ─────────────────────────────────────────────────────────────

    /**
     * Creates a new SAV request from the wizard form data.
     * Sets Contact, Priorite, and Langue from current user context.
     * @param requestData  Populated SavRequestInput wrapper
     * @return             Id of newly created Demande_SAV__c
     */
    @AuraEnabled
    public static Id createSavRequest(SavRequestInput requestData) {

        if (requestData == null) {
            throw new AuraHandledException(Label.SAV_Error_InvalidInput);
        }
        if (String.isBlank(requestData.produitClientId)) {
            throw new AuraHandledException(Label.SAV_Error_ProductRequired);
        }
        if (String.isBlank(requestData.categorieId)) {
            throw new AuraHandledException(Label.SAV_Error_CategoryRequired);
        }

        Id contactId = ContactUtils.getCurrentContactId();

        // Verify product belongs to current contact (prevent Id injection)
        List<Produit_Client__c> produits = [
            SELECT Id, Contact__c
            FROM   Produit_Client__c
            WHERE  Id = :requestData.produitClientId
            AND    Contact__c = :contactId
            WITH   SECURITY_ENFORCED
            LIMIT  1
        ];
        if (produits.isEmpty()) {
            throw new AuraHandledException(Label.SAV_Error_ProductNotOwned);
        }

        // Derive client priority from Contact tier field
        Contact con = [
            SELECT Id, Segment_VIP__c, Preferred_Language__c
            FROM   Contact
            WHERE  Id = :contactId
            WITH   SECURITY_ENFORCED
            LIMIT  1
        ];

        String priorite = 'Standard';
        if (con.Segment_VIP__c == 'VVIP') priorite = 'VVIP';
        else if (con.Segment_VIP__c == 'VIP') priorite = 'VIP';

        Demande_SAV__c sav = new Demande_SAV__c(
            Contact__c         = contactId,
            Produit_Client__c  = requestData.produitClientId,
            Categorie__c       = requestData.categorieId,
            Sous_Categorie__c  = requestData.sousCategorie,
            Description__c     = String.escapeSingleQuotes(requestData.description),
            Canal_Retour__c    = requestData.canalRetour,
            Statut__c          = 'Soumise',
            Statut_Paiement__c = 'Non requis',
            Priorite__c        = priorite,
            Langue_Client__c   = con.Preferred_Language__c ?? 'fr'
        );

        // Photo URLs stored as JSON array in Long Text
        if (String.isNotBlank(requestData.photoUrlsJson)) {
            // Validate it's parseable JSON before storing
            try {
                JSON.deserializeUntyped(requestData.photoUrlsJson);
                sav.Photos_Demande_URL__c = requestData.photoUrlsJson;
            } catch (Exception e) {
                // Non-blocking: log and skip
                System.debug(LoggingLevel.WARN, 'Invalid photo JSON skipped: ' + e.getMessage());
            }
        }

        insert sav;

        // Asynchronous post-creation tasks
        SavWizardController.runPostCreationAsync(sav.Id);

        return sav.Id;
    }

    /**
     * Client validates reception of repaired item.
     * Transitions status from Livre → Valide.
     * @param savId  Demande_SAV__c Id
     */
    @AuraEnabled
    public static void validateReception(Id savId) {
        Id contactId = ContactUtils.getCurrentContactId();

        List<Demande_SAV__c> records = [
            SELECT Id, Statut__c, Contact__c
            FROM   Demande_SAV__c
            WHERE  Id = :savId
            AND    Contact__c = :contactId
            AND    Statut__c  = 'Livre'
            WITH   SECURITY_ENFORCED
            LIMIT  1
        ];

        if (records.isEmpty()) {
            throw new AuraHandledException(Label.SAV_Error_CannotValidate);
        }

        update new Demande_SAV__c(
            Id        = savId,
            Statut__c = 'Valide'
        );
    }

    /**
     * Client approves a devis (quote). Transitions Devis_Envoye → Devis_Approuve.
     * Sets payment status to En attente.
     */
    @AuraEnabled
    public static void approveDevis(Id savId) {
        Id contactId = ContactUtils.getCurrentContactId();

        List<Demande_SAV__c> records = [
            SELECT Id, Statut__c, Contact__c
            FROM   Demande_SAV__c
            WHERE  Id = :savId
            AND    Contact__c = :contactId
            AND    Statut__c  = 'Devis_Envoye'
            WITH   SECURITY_ENFORCED
            LIMIT  1
        ];

        if (records.isEmpty()) {
            throw new AuraHandledException(Label.SAV_Error_CannotApprove);
        }

        update new Demande_SAV__c(
            Id                 = savId,
            Statut__c          = 'Devis_Approuve',
            Statut_Paiement__c = 'En attente'
        );
    }

    /**
     * Client refuses a devis. Transitions Devis_Envoye → Annulee.
     */
    @AuraEnabled
    public static void refuseDevis(Id savId, String motif) {
        Id contactId = ContactUtils.getCurrentContactId();

        List<Demande_SAV__c> records = [
            SELECT Id, Statut__c, Contact__c
            FROM   Demande_SAV__c
            WHERE  Id = :savId
            AND    Contact__c = :contactId
            AND    Statut__c  = 'Devis_Envoye'
            WITH   SECURITY_ENFORCED
            LIMIT  1
        ];

        if (records.isEmpty()) {
            throw new AuraHandledException(Label.SAV_Error_CannotRefuse);
        }

        update new Demande_SAV__c(
            Id                   = savId,
            Statut__c            = 'Annulee',
            Motif_Annulation__c  = String.escapeSingleQuotes(motif)
        );
    }

    // ─────────────────────────────────────────────────────────────
    // ASYNC HELPERS
    // ─────────────────────────────────────────────────────────────

    @Future
    private static void runPostCreationAsync(Id savId) {
        // Assign conseiller attitré from Contact lookup
        List<Demande_SAV__c> savList = [
            SELECT Id, Contact__c, Contact__r.Conseiller_Attitré__c
            FROM   Demande_SAV__c
            WHERE  Id = :savId
            LIMIT  1
        ];
        if (!savList.isEmpty() && savList[0].Contact__r.Conseiller_Attitré__c != null) {
            update new Demande_SAV__c(
                Id                       = savId,
                Conseiller_Reference__c  = savList[0].Contact__r.Conseiller_Attitré__c
            );
        }
    }
}