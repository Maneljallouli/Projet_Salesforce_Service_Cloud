public without sharing class SavCaseController {

    /**
     * MÉTHODE UTILITAIRE PRIVÉE
     * Récupère le ContactId de l'utilisateur connecté (centralisé)
     */
    private static Id getConnectedContactId() {
        Id userId = UserInfo.getUserId();
        User u = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1];
        return u.ContactId;
    }

    /**
     * RÉCUPÉRATION DES INFOS PROFIL (Pour le Header LWC)
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getMyContactInfo() {
        Id contactId = getConnectedContactId();
        
        // Si l'utilisateur est un Admin sans contact, on renvoie des valeurs par défaut
        if (contactId == null) {
            return new Map<String, String>{
                'firstName' => 'Admin',
                'lastName'  => UserInfo.getLastName(),
                'email'     => UserInfo.getUserEmail(),
                'city'      => 'Sfax', // Valeur par défaut ou vide
                'phone'     => ''
            };
        }

        Contact c = [
            SELECT FirstName, LastName, Email, Phone, MobilePhone, MailingCity, MailingCountry 
            FROM Contact 
            WHERE Id = :contactId 
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
     * LISTE DES CASES (Page Accueil & Mes Demandes)
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
            
            // Assignation automatique
            if (contactId != null) {
                newCase.ContactId = contactId;
            }

            newCase.Status = 'New';
            newCase.Origin = 'Web';

            // Ton bloc de gestion des règles d'assignation (conservé)
            List<AssignmentRule> rules = [
                SELECT Id FROM AssignmentRule 
                WHERE SobjectType = 'Case' AND Active = true 
                LIMIT 1
            ];

            if (!rules.isEmpty()) {
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = rules[0].Id;
                newCase.setOptions(dmlOpts);
            }

            // Insertion sécurisée en USER_MODE
            Database.SaveResult sr = Database.insert(newCase, AccessLevel.USER_MODE);

            Case c = [SELECT CaseNumber FROM Case WHERE Id = :sr.getId() WITH USER_MODE];
            return c.CaseNumber;
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur : ' + e.getMessage());
        }
    }

    /**
     * DÉTAIL D'UNE DEMANDE
     */
    @AuraEnabled(cacheable=true)
    public static Case getCaseById(Id caseId) {
        if (caseId == null) return null;
        
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