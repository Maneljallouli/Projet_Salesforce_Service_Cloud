public with sharing class CaseController {
    @AuraEnabled
    public static List<CaseWrapper> getMyCases() {
        List<CaseWrapper> wrapperList = new List<CaseWrapper>();
        try {
            // Récupérer l'utilisateur courant et son ContactId
            Id currentUserId = UserInfo.getUserId();
            User u = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];

            if(u.ContactId == null) {
                // Si l'utilisateur n'a pas de Contact lié, retourner une liste vide
                return wrapperList;
            }

            // Requête : tous les Cases liés au Contact de l'utilisateur
            List<Case> cases = [
                SELECT Id, CaseNumber, Subject, Status, Contact.Name
                FROM Case
                WHERE ContactId = :u.ContactId
                ORDER BY CreatedDate DESC
            ];

            // Créer les wrappers pour l'affichage
            for(Case c : cases) {
                wrapperList.add(new CaseWrapper(c));
            }
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la récupération des Cases : ' + e.getMessage());
        }
        return wrapperList;
    }

    // Wrapper pour exposer les champs au Lightning Component / Aura
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
            this.ContactName = c.Contact != null ? c.Contact.Name : '';

            // Classe CSS pour le status
            if(c.Status == 'New') this.StatusClass = 'status-new';
            else if(c.Status == 'Closed') this.StatusClass = 'status-closed';
            else if(c.Status == 'Waiting Customer') this.StatusClass = 'status-waiting';
            else this.StatusClass = 'status-in-progress';
        }
    }
}
