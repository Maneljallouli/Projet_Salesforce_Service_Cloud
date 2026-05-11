@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseController {
    
    @AuraEnabled
    public static List<CaseWrapper> getMyCases() {
        List<CaseWrapper> wrapperList = new List<CaseWrapper>();
        
        try {
            // Récupère l'ID de l'utilisateur qui appelle le code (dynamique)
            Id userId = UserInfo.getUserId();
            
            // Récupère le contact lié à cet utilisateur spécifique
            User currentUser = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1];
            
            // REQUÊTE DYNAMIQUE : On cherche les cases liés à ce contact OU créés par cet ID
            List<Case> cases = [SELECT Id, CaseNumber, Subject, Status, Contact.Name, CreatedDate 
                                FROM Case 
                                WHERE (ContactId != null AND ContactId = :currentUser.ContactId)
                                OR CreatedById = :userId
                                ORDER BY CreatedDate DESC];
            
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
            
            // Gestion dynamique des classes CSS
            if (c.Status == 'New') { this.statusClass = 'status-new'; }
            else if (c.Status == 'Closed') { this.statusClass = 'status-closed'; }
            else { this.statusClass = 'status-in-progress'; }
        }
    }
}