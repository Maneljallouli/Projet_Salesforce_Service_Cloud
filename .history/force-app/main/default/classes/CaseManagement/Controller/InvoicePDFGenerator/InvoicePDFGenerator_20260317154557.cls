/**
 * @class       InvoicePDFGenerator
 * @description Générateur de factures PDF pour les demandes SAV.
 * Version corrigée pour PMD et erreurs de schéma.
 */
public with sharing class InvoicePDFGenerator {

    @Future(callout=false)
    public static void generateAsync(Id savId) {
        try {
            generateAndStore(savId);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Erreur génération facture : ' + e.getMessage());
        }
    }

    public static Id generateAndStore(Id savId) {
        // 1. Récupération de la demande SAV (Sans Categorie__r pour éviter l'erreur)
        List<Demande_SAV__c> savList = [
            SELECT Id, Name, Contact__c,
            Contact__r.FirstName, Contact__r.LastName, Contact__r.Email,
            Contact__r.MailingCountry,
            Montant_Final__c, Statut_Paiement__c,
            Produit_Client__r.Nom_Produit__c,
            Payment_Intent_ID__c
            FROM Demande_SAV__c 
            WHERE Id = :savId 
            WITH USER_MODE 
            LIMIT 1
        ];

        if (savList.isEmpty()) {
            throw new InvoiceException('Demande SAV introuvable ou accès refusé.');
        }

        Demande_SAV__c sav = savList[0];
        Decimal finalAmount = (sav.Montant_Final__c != null) ? sav.Montant_Final__c : 0;

        // 2. Calculs financiers
        Decimal tvaRate = getTVARate(sav.Contact__r.MailingCountry);
        Decimal montantHT = (finalAmount / (1 + tvaRate / 100)).setScale(2, RoundingMode.HALF_UP);
        String statutFac = (sav.Statut_Paiement__c == 'Paye') ? 'Payee' : 'Emise';

        // 3. Gestion de la Facture_SAV__c
        List<Facture_SAV__c> existing = [
            SELECT Id, Name FROM Facture_SAV__c 
            WHERE Demande_SAV__c = :savId 
            WITH USER_MODE LIMIT 1
        ];

        Facture_SAV__c factureToSave;
        
        if (existing.isEmpty()) {
            factureToSave = new Facture_SAV__c(
                Demande_SAV__c = savId,
                Date_Emission__c = Date.today(),
                Montant_HT__c = montantHT,
                TVA_Taux__c = tvaRate,
                // Montant_TTC__c est une formule : Salesforce s'en occupe.
                Statut__c = statutFac
            );
            insert as user factureToSave;
            
            // Re-query pour avoir le Name (Auto-number)
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

        // 4. Génération et enregistrement du fichier PDF
        PageReference pdfPage = Page.InvoicePDF;
        pdfPage.getParameters().put('factureId', factureToSave.Id);
        
        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test Content');
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }

        String fileName = 'Facture_' + factureToSave.Name + '.pdf';
        ContentVersion cv = new ContentVersion(
            Title = fileName,
            PathOnClient = fileName,
            VersionData = pdfBlob,
            IsMajorVersion = true
        );
        insert as user cv;

        // Liaison du fichier à la facture
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id WITH USER_MODE].ContentDocumentId;
        insert as user new ContentDocumentLink(
            ContentDocumentId = conDocId,
            LinkedEntityId = factureToSave.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        // 5. Mise à jour finale du SAV avec le lien vers la facture
        update as user new Demande_SAV__c(
            Id = savId,
            Facture_SAV__c = factureToSave.Id
        );

        return factureToSave.Id;
    }

    private static Decimal getTVARate(String country) {
        // Logique par défaut
        return 20.0;
    }

    public class InvoiceException extends Exception {}
}