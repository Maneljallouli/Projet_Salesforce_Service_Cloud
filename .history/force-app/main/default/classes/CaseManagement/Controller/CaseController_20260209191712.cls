public with sharing class CaseController {
    @AuraEnabled
    public static List<CaseWrapper> getMyCases() {
        List<CaseWrapper> wrapperList = new List<CaseWrapper>();
        try {
            Id currentUserId = UserInfo.getUserId();
            User u = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
            
            // Requête pour vos 8 dossiers (Propriétaire, Contact ou Créateur)
            List<Case> cases = [SELECT Id, CaseNumber, Subject, Status, Contact.Name 
                                FROM Case 
                                WHERE OwnerId = :currentUserId
                                OR (ContactId = :u.ContactId AND ContactId != null)
                                OR CreatedById = :currentUserId
                                ORDER BY CreatedDate DESC];
            
            for(Case c : cases) {
                wrapperList.add(new CaseWrapper(c));
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return wrapperList;
    }

    public class CaseWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String CaseNumber;
        @AuraEnabled public String Subject;
        @AuraEnabled public String Status;
        @AuraEnabled public String ContactName;
        @AuraEnabled public String StatusClass;

        public CaseWrapper(Case c) {
            this.Id = c.Id; // ID RÉEL de la base de données
            this.CaseNumber = c.CaseNumber;
            this.Subject = c.Subject;
            this.Status = c.Status;
            this.ContactName = c.Contact != null ? c.Contact.Name : '';
            
            if(c.Status == 'New') this.StatusClass = 'status-new';
            else if(c.Status == 'Closed') this.StatusClass = 'status-closed';
            else if(c.Status == 'Waiting Customer') this.StatusClass = 'status-waiting';
            else this.StatusClass = 'status-in-progress';
        }
    }
}