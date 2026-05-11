@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CaseController {
    
    @AuraEnabled(cacheable=true)
    public static List<CaseWrapper> getMyCases() {
        List<CaseWrapper> wrapperList = new List<CaseWrapper>();
        
        try {
            // Récupère l'ID de l'utilisateur connecté (Bilel ou Admin)
            Id currentUserId = UserInfo.getUserId();
            
            // 1. Récupère le ContactId associé à cet utilisateur
            User u = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
            Id userContactId = u.ContactId;
            
            // 2. Requête dynamique : on cherche par ContactId ou par Créateur
            // Même si le Case appartient à une Queue (Service Client), le ContactId reste lié à l'utilisateur
            List<Case> cases = [SELECT Id, CaseNumber, Subject, Status, Contact.Name, CreatedDate 
                                FROM Case 
                                WHERE (ContactId != null AND ContactId = :userContactId)
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
            this.contactName = (c.Contact != null) ? c.Contact.Name : '-';
            
            // Logique de couleur pour le badge (PMD compliant avec accolades)
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