public with sharing class CaseController {

    @AuraEnabled
    public static List<CaseWrapper> getMyCases() {
        List<CaseWrapper> wrapperList = new List<CaseWrapper>();

        try {
            // Vérifier l'accès CRUD sur User et Case
            if(!Schema.sObjectType.User.isAccessible()) {
                throw new AuraHandledException('Vous n’avez pas accès à l’objet User.');
            }

            if(!Schema.sObjectType.Case.isAccessible()) {
                throw new AuraHandledException('Vous n’avez pas accès à l’objet Case.');
            }

            if(!Schema.sObjectType.User.fields.ContactId.isAccessible()) {
                throw new AuraHandledException('Vous n’avez pas accès au champ ContactId.');
            }

            if(!Schema.sObjectType.Case.fields.Id.isAccessible() ||
               !Schema.sObjectType.Case.fields.Subject.isAccessible() ||
               !Schema.sObjectType.Case.fields.Status.isAccessible() ||
               !Schema.sObjectType.Case.fields.CaseNumber.isAccessible() ||
               !Schema.sObjectType.Case.fields.ContactId.isAccessible()) {
                throw new AuraHandledException('Accès aux champs Case refusé.');
            }

            // Récupérer l'utilisateur courant et son ContactId
            Id currentUserId = UserInfo.getUserId();
            User currentUser = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];

            if(currentUser.ContactId == null) {
                // Aucun Contact lié => retourner liste vide
                return wrapperList;
            }

            // Récupérer tous les Cases liés au Contact
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

    // Wrapper Apex exposé aux Lightning Components / Aura
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
