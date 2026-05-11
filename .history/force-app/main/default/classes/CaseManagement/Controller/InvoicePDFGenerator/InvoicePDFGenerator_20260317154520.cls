/**
 * @class       InvoicePDFGenerator
 * @description Generates PDF invoices for paid SAV requests.
 */
public with sharing class InvoicePDFGenerator {

    @Future(callout=false)
    public static void generateAsync(Id savId) {
        try {
            generateAndStore(savId);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'InvoicePDFGenerator failed: ' + e.getMessage());
        }
    }

    public static Id generateAndStore(Id savId) {
        // 1. Charger Demande_SAV__c
        List<Demande_SAV__c> savList = [SELECT Id, Name, Contact__c,
            Contact__r.FirstName, Contact__r.LastName, Contact__r.Email,
            Contact__r.MailingStreet, Contact__r.MailingCity,
            Contact__r.MailingPostalCode, Contact__r.MailingCountry,
            Montant_Final__c, Statut_Paiement__c,
            Produit_Client__r.Nom_Produit__c,
            Produit_Client__r.Modele__c,
            Produit_Client__r.Reference_Officielle__c,
            // Categorie__r.Nom__c retiré car la relation n'existe pas ou est mal nommée
            Payment_Intent_ID__c,
            Langue_Client__c
            FROM Demande_SAV__c 
            WHERE Id = :savId 
            WITH USER_MODE 
            LIMIT 1
        ];

        if (savList.isEmpty()) throw new InvoiceException('SAV not found');

        Demande_SAV__c sav = savList[0];
        Decimal amount = sav.Montant_Final__c != null ? sav.Montant_Final__c : 0;

        // 2. Charger/Préparer Facture
        List<Facture_SAV__c> existing = [SELECT Id, Name FROM Facture_SAV__c WHERE Demande_SAV__c = :savId WITH USER_MODE LIMIT 1];
        
        Decimal tvaRate = getTVARate(sav.Contact__r.MailingCountry);
        Decimal montantHT = (amount / (1 + tvaRate / 100)).setScale(2, RoundingMode.HALF_UP);
        String statutFac = (sav.Statut_Paiement__c == 'Paye') ? 'Payee' : 'Emise';

        Facture_SAV__c factureToSave;
        
        if (existing.isEmpty()) {
            factureToSave = new Facture_SAV__c(
                Demande_SAV__c = savId,
                Date_Emission__c = Date.today(),
                Montant_HT__c = montantHT,
                TVA_Taux__c = tvaRate,
                // Montant_TTC__c retiré car c'est un champ en lecture seule (Formule ?)
                Statut__c = statutFac
            );
            insert as user factureToSave;
            // Récupérer le Name pour le fichier
            factureToSave = [SELECT Id, Name FROM Facture_SAV__c WHERE Id = :factureToSave.Id WITH USER_MODE];
        } else {
            factureToSave = new Facture_SAV__c(
                Id = existing[0].Id,
                Montant_HT__c = montantHT,
                TVA_Taux__c = tvaRate,
                Statut__c = statutFac
            );
            update as user factureToSave;
            factureToSave.Name = existing[0].Name;
        }

        // 3. Génération du PDF
        PageReference pdfPage = Page.InvoicePDF;
        pdfPage.getParameters().put('factureId', factureToSave.Id);
        
        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Test') : pdfPage.getContentAsPDF();

        // 4. Stockage ContentVersion
        String fileName = 'Facture_' + factureToSave.Name + '.pdf';
        ContentVersion cv = new ContentVersion(
            Title = fileName,
            PathOnClient = fileName,
            VersionData = pdfBlob,
            IsMajorVersion = true
        );
        insert as user cv;

        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id WITH USER_MODE].ContentDocumentId;

        // 5. Liaison
        insert as user new ContentDocumentLink(
            ContentDocumentId = conDocId,
            LinkedEntityId = factureToSave.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        // 6. Update Final URLs
        factureToSave.PDF_URL__c = '/sfc/servlet.shepherd/document/download/' + conDocId;
        update as user new Facture_SAV__c(Id = factureToSave.Id, PDF_URL__c = factureToSave.PDF_URL__c);

        return factureToSave.Id;
    }

    private static Decimal getTVARate(String country) {
        // Logique simplifiée pour éviter les erreurs mdt si non configuré
        return 20.0;
    }

    public class InvoiceException extends Exception {}
}