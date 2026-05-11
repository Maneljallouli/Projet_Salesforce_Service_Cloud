public without sharing class SavCaseController {

    /**
     * MÉTHODE UTILITAIRE PRIVÉE
     * Récupère le ContactId de l'utilisateur connecté.
     * Corrigé : Utilisation de USER_MODE pour la sécurité SOQL.
     */
    private static Id getConnectedContactId() {
        Id userId = UserInfo.getUserId();
        // PMD Fix: Validation CRUD via WITH USER_MODE
        User u = [SELECT ContactId FROM User WHERE Id = :userId WITH USER_MODE LIMIT 1];
        return u.ContactId;
    }

    /**
     * RÉCUPÉRATION DES INFOS PROFIL
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getMyContactInfo() {
        Id contactId = getConnectedContactId();
        
        if (contactId == null) {
            return new Map<String, String>{
                'firstName' => 'Admin',
                'lastName'  => UserInfo.getLastName(),
                'email'     => UserInfo.getUserEmail(),
                'city'      => '',
                'phone'     => ''
            };
        }

        // PMD Fix: WITH USER_MODE pour valider les droits de lecture du Contact
        Contact c = [
            SELECT FirstName, LastName, Email, Phone, MobilePhone, MailingCity, MailingCountry 
            FROM Contact 
            WHERE Id = :contactId 
            WITH USER_MODE
            LIMIT 1
        ];

        return new Map<String, String>{
            'firstName' => (c.FirstName != null ? c.FirstName : ''),
            'lastName'  => (c.LastName != null ? c.LastName : ''),
            'email'     => (c.Email != null ? c.Email : ''),
            'phone'     => (c.Phone != null ? c.Phone : (c.MobilePhone != null ? c.MobilePhone : '')),
            'city'      => (c.MailingCity != null ? c.MailingCity : '')
        };
    }

    /**
     * LISTE DES CASES
     */
    @AuraEnabled(cacheable=false)
    public static List<Case> getMyCases() {
        Id contactId = getConnectedContactId();

        if (contactId == null) {
            return new List<Case>();
        }

        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate, Category__c
            FROM Case
            WHERE ContactId = :contactId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
    }

    /**
     * CRÉATION D'UNE DEMANDE
     */
    @AuraEnabled
    public static String createCase(Case newCase) {
        try {
            Id contactId = getConnectedContactId();
            
            if (contactId != null) {
                newCase.ContactId = contactId;
            }

            newCase.Status = 'New';
            newCase.Origin = 'Web';

            // Gestion des règles d'assignation
            List<AssignmentRule> rules = [
                SELECT Id FROM AssignmentRule 
                WHERE SobjectType = 'Case' AND Active = true 
                WITH USER_MODE 
                LIMIT 1
            ];

            if (!rules.isEmpty()) {
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = rules[0].Id;
                newCase.setOptions(dmlOpts);
            }

            // PMD Fix: Insertion via AccessLevel.USER_MODE pour valider les droits DML
            Database.SaveResult sr = Database.insert(newCase, AccessLevel.USER_MODE);

            Case c = [SELECT CaseNumber FROM Case WHERE Id = :sr.getId() WITH USER_MODE];
            return c.CaseNumber;
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }

    /**
     * DÉTAIL D'UNE DEMANDE
     * PMD Fix: Ajout d'accolades sur le if
     */
    @AuraEnabled(cacheable=true)
    public static Case getCaseById(Id caseId) {
        if (caseId == null) {
            return null;
        }
        
        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, Origin, Description, 
                   Category__c, Subcategory__c, Order_number__c, Client_segment__c
            FROM Case
            WHERE Id = :caseId
            WITH USER_MODE
            LIMIT 1
        ];
    }
}