public with sharing class CaseController {
    @AuraEnabled
    public static List<CaseWrapper> getMyCases() {
        List<CaseWrapper> wrapperList = new List<CaseWrapper>();
        try {
            // Vérifier que l'utilisateur a accès à l'objet Case
            if(!Schema.sObjectType.Case.isAccessible()) {
                throw new AuraHandledException('Vous n’avez pas accès aux Cases.');
            }

            // Récupérer l'utilisateur courant et son ContactId
            Id currentUserId = UserInfo.getUserId();
            User currentUser = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];

            if(currentUser.ContactId == null) {
                // Pas de contact lié => retourner vide
                return wrapperList;
            }

            // Vérifier que l'utilisateur a le droit de lire les Cases
            if(!Schema.sObjectType.Case.fields.Id.isAccessible() ||
               !Schema.sObjectType.Case.fields.Subject.isAccessible() ||
               !Schema.sObjectType.Case.fields.Status.isAccessible()) {
                throw new AuraHandledException('Accès aux champs Case refusé.');
            }

            // Requête sécurisée pour récupérer les Cases liés au contact
            List<Case> cases = [
                SELECT Id, CaseNumber, Subject, Status, Contact.Name
                FROM Case
                WHERE ContactId = :currentUser.ContactId
                ORDER BY CreatedDate DESC
            ];

            for(Case c : cases) {
                wrapperList.add(new CaseWrapper(c));
            }
        } catch(Exception e) {
            throw new AuraHandledException('Erreur lors de la récupération des Cases : ' + e.getMessage());
        }
        return wrapperList;
    }

    // Wrapper Apex pour exposer les champs au Lightning Component / Aura
    public class CaseWrapper {
        @AuraEnabled public String idRecord;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String subject;
        @AuraEnabled public String status;
        @AuraEnabled public String contactName;
        @AuraEnabled public String statusClass;

        public CaseWrapper(Case c) {
            this.idRecord = c.Id;
            this.caseNumber = c.CaseNumber;
            this.subject = c.Subject;
            this.status = c.Status;
            this.contactName = (c.Contact != null) ? c.Contact.Name : '';

            if(c.Status == 'New') {
                this.statusClass = 'status-new';
            } else if(c.Status == 'Closed') {
                this.statusClass = 'status-closed';
            } else if(c.Status == 'Waiting Customer') {
                this.statusClass = 'status-waiting';
            } else {
                this.statusClass = 'status-in-progress';
            }
        }
    }
}
