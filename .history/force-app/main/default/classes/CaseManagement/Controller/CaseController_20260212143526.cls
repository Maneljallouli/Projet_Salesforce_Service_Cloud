@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseController {
    
    @AuraEnabled(cacheable=true) // Ajout de cacheable pour la performance LWC
    public static List<CaseWrapper> getMyCases() {
        List<CaseWrapper> wrapperList = new List<CaseWrapper>();
        
        try {
            Id currentUserId = UserInfo.getUserId();
            
            // On récupère l'utilisateur et son contact
            User u = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
            
            // Requête élargie : 
            // - Si je suis l'Admin, je verrai les cases dont je suis Owner.
            // - Si je suis le Client, je verrai les miens via ContactId ou CreatedBy.
            List<Case> cases = [SELECT Id, CaseNumber, Subject, Status, Contact.Name, CreatedDate 
                                FROM Case 
                                WHERE OwnerId = :currentUserId 
                                OR (ContactId != null AND ContactId = :u.ContactId)
                                OR CreatedById = :currentUserId
                                ORDER BY CreatedDate DESC 
                                LIMIT 50];
            
            for(Case c : cases) {
                wrapperList.add(new CaseWrapper(c));
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur Apex: ' + e.getMessage());
        }
        
        return wrapperList;
    }

    public class CaseWrapper {
        // ATTENTION : Ces noms doivent correspondre EXACTEMENT à votre HTML/JS
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
            
            // Logique de classe CSS
            if(c.Status == 'New') this.statusClass = 'status-new';
            else if(c.Status == 'Closed') this.statusClass = 'status-closed';
            else this.statusClass = 'status-in-progress';
        }
    }
}