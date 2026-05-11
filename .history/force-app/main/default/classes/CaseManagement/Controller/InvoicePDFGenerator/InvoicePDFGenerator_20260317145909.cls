/**
 * @class       InvoicePDFGenerator
 * @description Generates PDF invoices for paid SAV requests.
 *              Uses a Visualforce page (InvoicePDF) rendered as PDF via PageReference.
 *              Stores the PDF as a ContentDocument linked to Facture_SAV__c.
 *              Exposes a public download URL for the Experience Cloud portal.
 *
 *              Declared `with sharing` — inherits the calling user's record access.
 *              CRUD permissions are verified via Schema before every DML operation.
 *              SOQL queries use WITH SECURITY_ENFORCED where the object is user-facing;
 *              internal objects (ContentVersion, ContentDocumentLink) are system-managed
 *              and verified via Schema.sObjectType checks.
 *
 *              Async entry point: generateAsync(savId) — called post-payment.
 *              Sync entry point:  generateAndStore(savId) — for Flow/direct calls.
 *
 * @author      Salesforce Architect
 * @version     1.1  PMD-clean
 */
public with sharing class InvoicePDFGenerator {

    // ─────────────────────────────────────────────────────────────
    // PUBLIC ENTRY POINTS
    // ─────────────────────────────────────────────────────────────

    /**
     * Async invocation — called after payment confirmation.
     * @param savId  Demande_SAV__c Id
     */
    @Future(callout=false)
    public static void generateAsync(Id savId) {
        try {
            generateAndStore(savId);
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'InvoicePDFGenerator.generateAsync failed for ' + savId
                + ': ' + e.getMessage() + '\n' + e.getStackTraceString()
            );
        }
    }

    /**
     * Synchronous generation. Creates Facture_SAV__c if not existing,
     * renders the PDF, stores it as ContentVersion, links to Facture.
     * @param savId  Demande_SAV__c Id
     * @return       Facture_SAV__c Id
     */
    public static Id generateAndStore(Id savId) {

        // ── 1. Load SAV data ─────────────────────────────────────
        // WITH SECURITY_ENFORCED enforces FLS — satisfies PMD ApexCRUDViolation
        // for SELECT operations on Demande_SAV__c.
        List<Demande_SAV__c> savList = [
            SELECT  Id, Name, Contact__c,
                    Contact__r.FirstName, Contact__r.LastName,
                    Contact__r.Email,
                    Contact__r.MailingStreet, Contact__r.MailingCity,
                    Contact__r.MailingPostalCode, Contact__r.MailingCountry,
                    Montant_Final__c, Statut_Paiement__c,
                    Produit_Client__r.Nom_Produit__c,
                    Produit_Client__r.Modele__c,
                    Produit_Client__r.Reference_Officielle__c,
                    Categorie__r.Nom__c,
                    Payment_Intent_ID__c,
                    Langue_Client__c
            FROM    Demande_SAV__c
            WHERE   Id = :savId
            WITH    SECURITY_ENFORCED
            LIMIT   1
        ];

        if (savList.isEmpty()) {
            throw new InvoiceException('SAV not found: ' + savId);
        }

        Demande_SAV__c sav = savList[0];

        if (sav.Montant_Final__c == null || sav.Montant_Final__c <= 0) {
            throw new InvoiceException('Cannot invoice: amount is zero or null');
        }

        // ── 2. Check for existing Facture_SAV__c ─────────────────
        List<Facture_SAV__c> existing = [
            SELECT Id, PDF_URL__c
            FROM   Facture_SAV__c
            WHERE  Demande_SAV__c = :savId
            WITH   SECURITY_ENFORCED
            LIMIT  1
        ];

        Facture_SAV__c facture;
        Boolean isNew = existing.isEmpty();

        Decimal tvaRate    = getTVARate(sav.Contact__r.MailingCountry);
        Decimal montantHT  = (sav.Montant_Final__c / (1 + tvaRate / 100))
                                 .setScale(2, RoundingMode.HALF_UP);
        Decimal montantTTC = sav.Montant_Final__c.setScale(2, RoundingMode.HALF_UP);
        String  statutFac  = sav.Statut_Paiement__c == 'Paye' ? 'Payee' : 'Emise';

        if (isNew) {
            // assertCreateable called immediately before INSERT — PMD traces this.
            assertCreateable(Facture_SAV__c.SObjectType);
            facture = new Facture_SAV__c(
                Demande_SAV__c   = savId,
                Date_Emission__c = Date.today(),
                Montant_HT__c    = montantHT,
                TVA_Taux__c      = tvaRate,
                Montant_TTC__c   = montantTTC,
                Statut__c        = statutFac
            );
            insert facture;
        } else {
            // assertUpdateable called immediately before UPDATE — PMD traces this.
            assertUpdateable(Facture_SAV__c.SObjectType);
            facture = existing[0];
            update new Facture_SAV__c(
                Id             = facture.Id,
                Montant_HT__c  = montantHT,
                TVA_Taux__c    = tvaRate,
                Montant_TTC__c = montantTTC,
                Statut__c      = statutFac
            );
        }

        // ── 3. Render PDF via Visualforce page ───────────────────
        PageReference pdfPage = Page.InvoicePDF;
        pdfPage.getParameters().put('factureId', facture.Id);
        pdfPage.getParameters().put('savId',     savId);

        Blob pdfBlob;
        if (Test.isRunningTest()) {
            // PageReference.getContentAsPDF() is unavailable in test context
            pdfBlob = Blob.valueOf('PDF_TEST_CONTENT_' + facture.Id);
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }

        // ── 4. Store as ContentVersion ───────────────────────────
        String fileName = 'Facture_' + facture.Name + '_' + sav.Name + '.pdf';

        assertCreateable(ContentVersion.SObjectType);
        ContentVersion cv = new ContentVersion(
            Title           = fileName,
            PathOnClient    = fileName,
            VersionData     = pdfBlob,
            ContentLocation = 'S',   // Salesforce-managed storage
            IsMajorVersion  = true
        );
        insert cv;

        // Reload to obtain system-assigned ContentDocumentId
        cv = [
            SELECT ContentDocumentId
            FROM   ContentVersion
            WHERE  Id = :cv.Id
            WITH   SECURITY_ENFORCED
            LIMIT  1
        ];

        // ── 5. Link ContentDocument to Facture ───────────────────
        assertCreateable(ContentDocumentLink.SObjectType);
        insert new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId    = facture.Id,
            ShareType         = 'V',        // Viewer
            Visibility        = 'AllUsers'
        );

        // ── 6. Build public download URL ─────────────────────────
        String pdfUrl = System.URL.getOrgDomainUrl().toExternalForm()
            + '/sfc/servlet.shepherd/document/download/'
            + cv.ContentDocumentId;

        // ── 7. Update Facture with PDF URL ───────────────────────
        assertUpdateable(Facture_SAV__c.SObjectType);
        update new Facture_SAV__c(
            Id         = facture.Id,
            PDF_URL__c = pdfUrl
        );

        // ── 8. Link Facture on SAV for quick portal access ───────
        assertUpdateable(Demande_SAV__c.SObjectType);
        update new Demande_SAV__c(
            Id             = savId,
            Facture_SAV__c = facture.Id
        );

        return facture.Id;
    }

    // ─────────────────────────────────────────────────────────────
    // AURA EXPOSED — For portal invoice download button
    // ─────────────────────────────────────────────────────────────

    /**
     * Returns download URL for the invoice PDF.
     * Verifies ownership before returning URL.
     */
    @AuraEnabled(cacheable=true)
    public static String getInvoiceDownloadUrl(Id savId) {
        Id contactId = ContactUtils.getCurrentContactId();

        List<Facture_SAV__c> factures = [
            SELECT PDF_URL__c
            FROM   Facture_SAV__c
            WHERE  Demande_SAV__c            = :savId
            AND    Demande_SAV__r.Contact__c = :contactId
            WITH   SECURITY_ENFORCED
            LIMIT  1
        ];

        if (factures.isEmpty() || String.isBlank(factures[0].PDF_URL__c)) {
            throw new AuraHandledException(Label.Invoice_Error_NotFound);
        }

        return factures[0].PDF_URL__c;
    }

    // ─────────────────────────────────────────────────────────────
    // PRIVATE HELPERS
    // ─────────────────────────────────────────────────────────────

    /**
     * Returns applicable TVA rate based on billing country.
     * Extendable via TVA_Config__mdt Custom Metadata for multi-country support.
     */
    private static Decimal getTVARate(String billingCountry) {
        if (String.isBlank(billingCountry)) {
            return 20.0;
        }

        List<TVA_Config__mdt> rates = [
            SELECT TVA_Rate__c
            FROM   TVA_Config__mdt
            WHERE  Country_Code__c = :billingCountry
            LIMIT  1
        ];

        return rates.isEmpty() ? 20.0 : rates[0].TVA_Rate__c;
    }

    /**
     * Throws InvoiceException if the running user cannot CREATE on the given SObjectType.
     *
     * Called immediately before every INSERT so PMD's data-flow analysis can trace
     * the permission check to the adjacent DML statement. PMD requires the check
     * to appear in the same method scope as the DML — this helper satisfies that
     * requirement because PMD follows method calls one level deep.
     *
     * Satisfies: PMD rule Security-ApexCRUDViolation for INSERT operations.
     */
    private static void assertCreateable(Schema.SObjectType objType) {
        if (!objType.getDescribe().isCreateable()) {
            throw new InvoiceException(
                'Insufficient privileges to create: ' + objType.getDescribe().getName()
            );
        }
    }

    /**
     * Throws InvoiceException if the running user cannot UPDATE on the given SObjectType.
     *
     * Called immediately before every UPDATE.
     * Satisfies: PMD rule Security-ApexCRUDViolation for UPDATE operations.
     */
    private static void assertUpdateable(Schema.SObjectType objType) {
        if (!objType.getDescribe().isUpdateable()) {
            throw new InvoiceException(
                'Insufficient privileges to update: ' + objType.getDescribe().getName()
            );
        }
    }

    // ─────────────────────────────────────────────────────────────
    // CUSTOM EXCEPTION
    // ─────────────────────────────────────────────────────────────

    public class InvoiceException extends Exception {}
}