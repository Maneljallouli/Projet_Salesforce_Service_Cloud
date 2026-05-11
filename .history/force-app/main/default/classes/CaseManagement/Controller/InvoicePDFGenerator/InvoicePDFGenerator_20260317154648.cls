public with sharing class InvoicePDFGenerator {

    @Future(callout=false)
    public static void generateAsync(Id savId) {
        try {
            generateAndStore(savId);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Erreur : ' + e.getMessage());
        }
    }

    public static Id generateAndStore(Id savId) {
        // 1. Requête sans la relation Categorie__r qui pose problème
        List<Demande_SAV__c> savList = [
            SELECT Id, Name, Contact__c,
            Contact__r.FirstName, Contact__r.LastName, Contact__r.Email,
            Contact__r.MailingCountry,
            Montant_Final__c, Statut_Paiement__c
            FROM Demande_SAV__c 
            WHERE Id = :savId 
            WITH USER_MODE 
            LIMIT 1
        ];

        if (savList.isEmpty()) {
            throw new InvoiceException('SAV introuvable.');
        }

        Demande_SAV__c sav = savList[0];
        Decimal montantTotal = (sav.Montant_Final__c != null) ? sav.Montant_Final__c : 0;

        // 2. Calculs
        Decimal tvaRate = 20.0; // Valeur par défaut
        Decimal montantHT = (montantTotal / (1 + tvaRate / 100)).setScale(2, RoundingMode.HALF_UP);

        // 3. Gestion de la Facture
        List<Facture_SAV__c> existing = [
            SELECT Id, Name FROM Facture_SAV__c 
            WHERE Demande_SAV__c = :savId 
            WITH USER_MODE LIMIT 1
        ];

        Facture_SAV__c facture;
        
        if (existing.isEmpty()) {
            facture = new Facture_SAV__c(
                Demande_SAV__c = savId,
                Date_Emission__c = Date.today(),
                Montant_HT__c = montantHT,
                TVA_Taux__c = tvaRate,
                // On ne mentionne PAS Montant_TTC__c ici car c'est une formule
                Statut__c = 'Emise'
            );
            insert as user facture;
            
            // Re-query pour récupérer le Name auto-généré
            facture = [SELECT Id, Name FROM Facture_SAV__c WHERE Id = :facture.Id WITH USER_MODE];
        } else {
            facture = existing[0];
            update as user new Facture_SAV__c(
                Id = facture.Id,
                Montant_HT__c = montantHT,
                TVA_Taux__c = tvaRate
            );
        }

        // 4. Génération PDF (Logique simplifiée pour compilation)
        PageReference pdfPage = Page.InvoicePDF;
        pdfPage.getParameters().put('id', facture.Id);
        
        if (!Test.isRunningTest()) {
            Blob pdfBlob = pdfPage.getContentAsPDF();
            ContentVersion cv = new ContentVersion(
                Title = 'Facture_' + facture.Name,
                PathOnClient = 'Facture_' + facture.Name + '.pdf',
                VersionData = pdfBlob
            );
            insert as user cv;
        }

        return facture.Id;
    }

    public class InvoiceException extends Exception {}
}