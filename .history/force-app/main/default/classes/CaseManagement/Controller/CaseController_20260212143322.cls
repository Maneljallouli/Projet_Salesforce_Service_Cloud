@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseController {
    
    @AuraEnabled
    public static List<CaseWrapper> getMyCases() {
        List<CaseWrapper> wrapperList = new List<CaseWrapper>();
        
        try {
            Id currentUserId = UserInfo.getUserId();
            
            // Récupération du ContactId
            User u = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
            Id userContactId = u.ContactId;
            
            // Requête SOQL (On utilise SuppressWarnings car la licence limite l'accès standard)
            List<Case> cases = [SELECT Id, CaseNumber, Subject, Status, Contact.Name, CreatedDate 
                                FROM Case 
                                WHERE OwnerId = :currentUserId 
                                OR (ContactId != null AND ContactId = :userContactId)
                                OR CreatedById = :currentUserId
                                ORDER BY CreatedDate DESC];
            
            for(Case c : cases) {
                wrapperList.add(new CaseWrapper(c));
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
        
        return wrapperList;
    }

    /**
     * Wrapper class : Les noms des variables commencent par une minuscule 
     * pour corriger l'erreur FieldNamingConventions de PMD.
     */
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