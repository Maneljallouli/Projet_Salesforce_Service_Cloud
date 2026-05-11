public without sharing class CaseController {
    
    @AuraEnabled
    public static List<CaseWrapper> getMyCases() {
        List<CaseWrapper> wrapperList = new List<CaseWrapper>();
        
        try {
            // 1. Récupérer l'ID de l'utilisateur connecté
            Id currentUserId = UserInfo.getUserId();
            
            // 2. Récupérer le ContactId (important pour les utilisateurs Community)
            User u = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
            Id userContactId = u.ContactId;
            
            // 3. Requête SOQL en mode "System" (ignore les restrictions de licence)
            // On filtre strictement sur ce qui appartient à l'utilisateur
            List<Case> cases = [SELECT Id, CaseNumber, Subject, Status, Contact.Name, CreatedDate 
                                FROM Case 
                                WHERE OwnerId = :currentUserId 
                                OR (ContactId != null AND ContactId = :userContactId)
                                OR CreatedById = :currentUserId
                                ORDER BY CreatedDate DESC];
            
            // 4. Transformation en Wrapper
            for(Case c : cases) {
                wrapperList.add(new CaseWrapper(c));
            }
            
        } catch (Exception e) {
            // Log de l'erreur pour le debug et renvoi d'une exception propre au LWC
            System.debug('Erreur CaseController: ' + e.getMessage());
            throw new AuraHandledException('Impossible de récupérer vos dossiers : ' + e.getMessage());
        }
        
        return wrapperList;
    }

    // Classe Wrapper pour formater les données pour le LWC
    public class CaseWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String CaseNumber;
        @AuraEnabled public String Subject;
        @AuraEnabled public String Status;
        @AuraEnabled public String ContactName;
        @AuraEnabled public String StatusClass;

        public CaseWrapper(Case c) {
            this.Id = c.Id;
            this.CaseNumber = c.CaseNumber;
            this.Subject = c.Subject;
            this.Status = c.Status;
            this.ContactName = c.Contact != null ? c.Contact.Name : 'N/A';
            
            // Logique de style CSS pour le statut
            if(c.Status == 'New') {
                this.StatusClass = 'status-new';
            } else if(c.Status == 'Closed') {
                this.StatusClass = 'status-closed';
            } else if(c.Status == 'Waiting Customer') {
                this.StatusClass = 'status-waiting';
            } else {
                this.StatusClass = 'status-in-progress';
            }
        }
    }
}