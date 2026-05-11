@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseController {
    
    @AuraEnabled(cacheable=true)
    public static List<CaseWrapper> getMyCases() {
        List<CaseWrapper> wrapperList = new List<CaseWrapper>();
        
        try {
            Id currentUserId = UserInfo.getUserId();
            User u = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
            Id userContactId = u.ContactId;
            
            // Requête robuste pour Admin et Client
            List<Case> cases = [SELECT Id, CaseNumber, Subject, Status, Contact.Name, CreatedDate 
                                FROM Case 
                                WHERE OwnerId = :currentUserId 
                                OR (ContactId != null AND ContactId = :userContactId)
                                OR CreatedById = :currentUserId
                                ORDER BY CreatedDate DESC 
                                LIMIT 100];
            
            for(Case c : cases) {
                wrapperList.add(new CaseWrapper(c));
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
        
        return wrapperList;
    }

    public class CaseWrapper {
        @AuraEnabled public String caseId;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String subject;
        @AuraEnabled public String status;
        @AuraEnabled public String contactName;
        @AuraEnabled public String statusClass;

        public CaseWrapper(Case c) {
            this.caseId = c.Id;
            this.caseNumber = c.CaseNumber;
            this.subject = c.Subject;
            this.status = c.Status;
            this.contactName = (c.Contact != null) ? c.Contact.Name : 'N/A';
            
            // Correction PMD : Utilisation systématique des accolades { }
            if (c.Status == 'New') {
                this.statusClass = 'status-new';
            } else if (c.Status == 'Closed') {
                this.statusClass = 'status-closed';
            } else if (c.Status == 'Waiting Customer') {
                this.statusClass = 'status-waiting';
            } else {
                this.statusClass = 'status-in-progress';
            }
        }
    }
}