@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseController {
    
    @AuraEnabled
    public static List<CaseWrapper> getMyCases() {
        List<CaseWrapper> wrapperList = new List<CaseWrapper>();
        
        try {
            Id currentUserId = UserInfo.getUserId();
            
            // 1. Récupérer le ContactId de l'utilisateur connecté
            User u = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
            
            // 2. Requête SOQL : On cherche par ContactId ou par Créateur
            // Important : Le client externe voit ses cases car il est lié au Contact
            List<Case> cases = [SELECT Id, CaseNumber, Subject, Status, Contact.Name, CreatedDate 
                                FROM Case 
                                WHERE (ContactId != null AND ContactId = :u.ContactId)
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
            
            // Respect des accolades pour PMD
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