public without sharing class SavCaseController {

    @AuraEnabled
    public static String createCase(Case newCase) {
        try {
            // 1. Récupération de l'ID de l'utilisateur qui remplit le formulaire
            Id userId = UserInfo.getUserId();
            
            // 2. Récupération du ContactId lié à cet utilisateur
            // On utilise "without sharing" pour passer outre les restrictions de visibilité sur l'objet User
            User currentUser = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1];

            // 3. Assignation CRITIQUE : On lie le Case au Contact
            if (currentUser.ContactId != null) {
                newCase.ContactId = currentUser.ContactId;
            } else {
                // Optionnel : Log ou erreur si l'utilisateur n'est pas un utilisateur portail
                System.debug('Attention : L\'utilisateur n\'a pas de ContactId associé.');
            }

            // Valeurs par défaut pour Maison MJ
            newCase.Status = 'New';
            newCase.Origin = 'Web';

            // 4. Application des règles d'assignation
            List<AssignmentRule> rules = [
                SELECT Id 
                FROM AssignmentRule 
                WHERE SobjectType = 'Case' AND Active = true 
                LIMIT 1
            ];

            if (!rules.isEmpty()) {
                Database.DMLOptions dmlOpts = new Database.DMLOptions();
                dmlOpts.assignmentRuleHeader.assignmentRuleId = rules[0].Id;
                newCase.setOptions(dmlOpts);
            }

            // Insertion en mode USER_MODE pour la sécurité
            Database.SaveResult sr = Database.insert(newCase, AccessLevel.USER_MODE);

            // Récupération du numéro de dossier pour l'affichage final
            Case c = [SELECT CaseNumber FROM Case WHERE Id = :sr.getId() WITH USER_MODE];
            return c.CaseNumber;
            
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la création : ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<Case> getMyCases() {
        Id userId = UserInfo.getUserId();
        User u = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1];

        if (u.ContactId == null) {
            return new List<Case>();
        }

        return [
            SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate, Category__c
            FROM Case
            WHERE ContactId = :u.ContactId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ];
    }
}