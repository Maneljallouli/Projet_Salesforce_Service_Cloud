@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseController {
    
    @AuraEnabled
    public static List<CaseWrapper> getMyCases() {
        List<CaseWrapper> wrapperList = new List<CaseWrapper>();
        
        try {
            // L'ID de la personne connectée (Admin ou Client)
            Id currentUserId = UserInfo.getUserId();
            
            // REQUÊTE DE TEST : On cherche tout ce que l'utilisateur a créé, 
            // peu importe qui est le propriétaire actuel (Queue ou Admin).
            List<Case> cases = [SELECT Id, CaseNumber, Subject, Status, Contact.Name, CreatedDate 
                                FROM Case 
                                WHERE CreatedById = :currentUserId 
                                OR OwnerId = :currentUserId
                                ORDER BY CreatedDate DESC 
                                LIMIT 50];
            
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
            
            // Correction des accolades pour PMD
            if (c.Status == 'New') {
                this.statusClass = 'status-new';
            } else if (c.Status == 'Closed') {
                this.statusClass = 'status-closed';
            } else {
                this.statusClass = 'status-in-progress';
            }
        }
    }
}