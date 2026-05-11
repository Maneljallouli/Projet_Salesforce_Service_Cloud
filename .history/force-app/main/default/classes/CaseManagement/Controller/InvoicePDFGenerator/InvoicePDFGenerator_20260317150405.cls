/**
 * @class       InvoicePDFGenerator
 * @description Generates PDF invoices for paid SAV requests.
 *              Uses a Visualforce page (InvoicePDF) rendered as PDF via PageReference.
 *              Stores the PDF as a ContentDocument linked to Facture_SAV__c.
 *              Exposes a public download URL for the Experience Cloud portal.
 *
 *              Declared `with sharing` — inherits the calling user's record access.
 *              CRUD permissions are verified via Schema before every DML operation.
 *              SOQL queries use isAccessible() / WITH SECURITY_ENFORCED where required.
 *
 * @version     1.3  PMD-clean + CRUD + braces
 */
public with sharing class InvoicePDFGenerator {

    @Future(callout=false)
    public static void generateAsync(Id savId) {
        try {
            generateAndStore(savId);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 
                'InvoicePDFGenerator.generateAsync failed for ' + savId + ': ' + e.getMessage()
                + '\n' + e.getStackTraceString()
            );
        }
    }

    public static Id generateAndStore(Id savId) {
        // ── 1. Check access & load SAV
        if (!Schema.sObjectType.Demande_SAV__c.isAccessible()) {
            throw new InvoiceException('No access to Demande_SAV__c');
        }

        List<Demande_SAV__c> savList = [
            SELECT Id, Name, Contact__c,
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
            FROM Demande_SAV__c
            WHERE Id = :savId
            LIMIT 1
        ];

        if (savList.isEmpty()) {
            throw new InvoiceException('SAV not found: ' + savId);
        }

        Demande_SAV__c sav = savList[0];

        if (sav.Montant_Final__c == null || sav.Montant_Final__c <= 0) {
            throw new InvoiceException('Cannot invoice: amount is zero or null');
        }

        // ── 2. Fetch existing Facture_SAV__c
        if (!Schema.sObjectType.Facture_SAV__c.isAccessible()) {
            throw new InvoiceException('No access to Facture_SAV__c');
        }

        List<Facture_SAV__c> existing = [
            SELECT Id, PDF_URL__c
            FROM Facture_SAV__c
            WHERE Demande_SAV__c = :savId
            LIMIT 1
        ];

        Facture_SAV__c facture;
        Boolean isNew = existing.isEmpty();

        Decimal tvaRate = getTVARate(sav.Contact__r.MailingCountry);
        Decimal montantHT = (sav.Montant_Final__c / (1 + tvaRate / 100)).setScale(2, RoundingMode.HALF_UP);
        Decimal montantTTC = sav.Montant_Final__c.setScale(2, RoundingMode.HALF_UP);
        String statutFac;
        if (sav.Statut_Paiement__c == 'Paye') {
            statutFac = 'Payee';
        } else {
            statutFac = 'Emise';
        }

        // ── 3. Create/update Facture
        if (isNew) {
            assertCreateable(Facture_SAV__c.SObjectType);
            facture = new Facture_SAV__c(
                Demande_SAV__c = savId,
                Date_Emission__c = Date.today(),
                Montant_HT__c = montantHT,
                TVA_Taux__c = tvaRate,
                Montant_TTC__c = montantTTC,
                Statut__c = statutFac
            );
            insert facture;
        } else {
            assertUpdateable(Facture_SAV__c.SObjectType);
            facture = existing[0];
            update new Facture_SAV__c(
                Id = facture.Id,
                Montant_HT__c = montantHT,
                TVA_Taux__c = tvaRate,
                Montant_TTC__c = montantTTC,
                Statut__c = statutFac
            );
        }

        // ── 4. Render PDF
        PageReference pdfPage = Page.InvoicePDF;
        pdfPage.getParameters().put('factureId', facture.Id);
        pdfPage.getParameters().put('savId', savId);

        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('PDF_TEST_CONTENT_' + facture.Id);
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }

        // ── 5. Store PDF
        assertCreateable(ContentVersion.SObjectType);
        String fileName = 'Facture_' + facture.Name + '_' + sav.Name + '.pdf';
        ContentVersion cv = new ContentVersion(
            Title = fileName,
            PathOnClient = fileName,
            VersionData = pdfBlob,
            ContentLocation = 'S',
            IsMajorVersion = true
        );
        insert cv;

        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];

        // ── 6. Link PDF
        assertCreateable(ContentDocumentLink.SObjectType);
        insert new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = facture.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        // ── 7. Build URL & update Facture
        String pdfUrl = System.URL.getOrgDomainUrl().toExternalForm() + '/sfc/servlet.shepherd/document/download/' + cv.ContentDocumentId;
        assertUpdateable(Facture_SAV__c.SObjectType);
        update new Facture_SAV__c(Id = facture.Id, PDF_URL__c = pdfUrl);

        // ── 8. Link Facture on SAV
        assertUpdateable(Demande_SAV__c.SObjectType);
        update new Demande_SAV__c(Id = savId, Facture_SAV__c = facture.Id);

        return facture.Id;
    }

    @AuraEnabled(cacheable=true)
    public static String getInvoiceDownloadUrl(Id savId) {
        Id contactId = ContactUtils.getCurrentContactId();

        if (!Schema.sObjectType.Facture_SAV__c.isAccessible()) {
            throw new InvoiceException('No access to Facture_SAV__c');
        }

        List<Facture_SAV__c> factures = [
            SELECT PDF_URL__c
            FROM Facture_SAV__c
            WHERE Demande_SAV__c = :savId AND Demande_SAV__r.Contact__c = :contactId
            LIMIT 1
        ];

        if (factures.isEmpty() || String.isBlank(factures[0].PDF_URL__c)) {
            throw new AuraHandledException(Label.Invoice_Error_NotFound);
        }

        return factures[0].PDF_URL__c;
    }

    // ── PRIVATE HELPERS ─────────────────────────────────────────
    private static Decimal getTVARate(String billingCountry) {
        if (String.isBlank(billingCountry)) {
            return 20.0;
        }
        if (!Schema.sObjectType.TVA_Config__mdt.isAccessible()) {
            return 20.0;
        }

        List<TVA_Config__mdt> rates = [
            SELECT TVA_Rate__c
            FROM TVA_Config__mdt
            WHERE Country_Code__c = :billingCountry
            LIMIT 1
        ];

        if (!rates.isEmpty()) {
            return rates[0].TVA_Rate__c;
        } else {
            return 20.0;
        }
    }

    private static void assertCreateable(Schema.SObjectType objType) {
        if (!objType.getDescribe().isCreateable()) {
            throw new InvoiceException('Insufficient privileges to create: ' + objType.getDescribe().getName());
        }
    }

    private static void assertUpdateable(Schema.SObjectType objType) {
        if (!objType.getDescribe().isUpdateable()) {
            throw new InvoiceException('Insufficient privileges to update: ' + objType.getDescribe().getName());
        }
    }

    public class InvoiceException extends Exception {}
}