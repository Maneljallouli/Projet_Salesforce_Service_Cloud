/**
 * @class       InvoicePDFGenerator
 * @description Generates PDF invoices for paid SAV requests.
 * CRUD/FLS-safe using USER_MODE, PMD-clean.
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
        // ── 1. Charger Demande_SAV__c en USER_MODE (Gère l'accessibilité CRUD/FLS)
        List<Demande_SAV__c> savList = [SELECT Id, Name, Contact__c,
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
            WITH USER_MODE 
            LIMIT 1
        ];

        if (savList.isEmpty()) {
            throw new InvoiceException('SAV not found or insufficient permissions: ' + savId);
        }

        Demande_SAV__c sav = savList[0];

        if (sav.Montant_Final__c == null || sav.Montant_Final__c <= 0) {
            throw new InvoiceException('Cannot invoice: amount is zero or null');
        }

        // ── 2. Charger Facture existante en USER_MODE
        List<Facture_SAV__c> existing = [SELECT Id, PDF_URL__c, Name
            FROM Facture_SAV__c 
            WHERE Demande_SAV__c = :savId 
            WITH USER_MODE 
            LIMIT 1
        ];

        Facture_SAV__c facture;
        Boolean isNew = existing.isEmpty();

        Decimal tvaRate = getTVARate(sav.Contact__r.MailingCountry);
        Decimal montantHT = (sav.Montant_Final__c / (1 + tvaRate / 100)).setScale(2, RoundingMode.HALF_UP);
        Decimal montantTTC = sav.Montant_Final__c.setScale(2, RoundingMode.HALF_UP);
        String statutFac = (sav.Statut_Paiement__c == 'Paye') ? 'Payee' : 'Emise';

        // ── 3. Création ou mise à jour Facture en USER_MODE
        if (isNew) {
            facture = new Facture_SAV__c(
                Demande_SAV__c = savId,
                Date_Emission__c = Date.today(),
                Montant_HT__c = montantHT,
                TVA_Taux__c = tvaRate,
                Montant_TTC__c = montantTTC,
                Statut__c = statutFac
            );
            insert as user facture;
            
            // Récupérer le Name généré (Auto-number) pour le nom du fichier PDF
            facture = [SELECT Id, Name FROM Facture_SAV__c WHERE Id = :facture.Id WITH USER_MODE];
        } else {
            facture = existing[0];
            Facture_SAV__c toUpdate = new Facture_SAV__c(
                Id = facture.Id,
                Montant_HT__c = montantHT,
                TVA_Taux__c = tvaRate,
                Montant_TTC__c = montantTTC,
                Statut__c = statutFac
            );
            update as user toUpdate;
        }

        // ── 4. Générer PDF
        PageReference pdfPage = Page.InvoicePDF;
        pdfPage.getParameters().put('factureId', facture.Id);
        pdfPage.getParameters().put('savId', savId);

        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('PDF_TEST_CONTENT_' + facture.Id);
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }

        // ── 5. Stocker PDF en USER_MODE
        String fileName = 'Facture_' + facture.Name + '_' + sav.Name + '.pdf';
        ContentVersion cv = new ContentVersion(
            Title = fileName,
            PathOnClient = fileName,
            VersionData = pdfBlob,
            ContentLocation = 'S',
            IsMajorVersion = true
        );
        insert as user cv;

        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id WITH USER_MODE LIMIT 1];

        // ── 6. Lier ContentDocument en USER_MODE
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = facture.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert as user cdl;

        // ── 7. Mettre à jour URL de la facture en USER_MODE
        Facture_SAV__c updateFactureUrl = new Facture_SAV__c(
            Id = facture.Id, 
            PDF_URL__c = System.URL.getOrgDomainUrl().toExternalForm() + '/sfc/servlet.shepherd/document/download/' + cv.ContentDocumentId
        );
        update as user updateFactureUrl;

        // ── 8. Lier Facture à SAV en USER_MODE
        Demande_SAV__c updateSav = new Demande_SAV__c(
            Id = savId, 
            Facture_SAV__c = facture.Id
        );
        update as user updateSav;

        return facture.Id;
    }

    @AuraEnabled(cacheable=true)
    public static String getInvoiceDownloadUrl(Id savId) {
        Id contactId = ContactUtils.getCurrentContactId();

        List<Facture_SAV__c> factures = [SELECT PDF_URL__c
            FROM Facture_SAV__c
            WHERE Demande_SAV__c = :savId AND Demande_SAV__r.Contact__c = :contactId
            WITH USER_MODE
            LIMIT 1
        ];

        if (factures.isEmpty() || String.isBlank(factures[0].PDF_URL__c)) {
            throw new AuraHandledException(Label.Invoice_Error_NotFound);
        }

        return factures[0].PDF_URL__c;
    }

    private static Decimal getTVARate(String billingCountry) {
        if (String.isBlank(billingCountry)) {
            return 20.0;
        }

        List<TVA_Config__mdt> rates = [SELECT TVA_Rate__c FROM TVA_Config__mdt WHERE Country_Code__c = :billingCountry WITH USER_MODE LIMIT 1];
        if (!rates.isEmpty()) { return rates[0].TVA_Rate__c; }
        return 20.0;
    }

    public class InvoiceException extends Exception {}
}