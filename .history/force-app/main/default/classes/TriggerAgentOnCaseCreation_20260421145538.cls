public with sharing class TriggerAgentOnCaseCreation {

    @InvocableMethod(
        label='Trigger Agent on Case'
        description='Appelle l\'Agentforce et écrit le statut dans le Case'
    )
    public static void triggerAgent(List<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }
        processAgentAsync(caseIds[0]);
    }

    @future(callout=true)
    public static void processAgentAsync(Id caseId) {
        try {
            // 1. Correction de l'URL de l'instance (Remplacer getSalesforceBaseUrl)
            String instanceUrl = Url.getOrgDomainUrl().toExternalForm();
            
            // 2. Préparation de la requête
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:AgentforceInternal/services/data/v62.0/einstein/ai-agent/v1/sessions');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');

            // 3. Corps du message
            Map<String, Object> messageMap = new Map<String, Object>{
                'type' => 'Text',
                'text' => 'Case analysis ' + caseId
            };
            
            Map<String, Object> payload = new Map<String, Object>{
                'message' => messageMap
            };

            req.setBody(JSON.serialize(payload));

            // 4. Envoi de l'appel
            Http http = new Http();
            HttpResponse res = http.send(req);

            // 5. MISE À JOUR DU CASE (Correction PMD & Sécurité)
            // On vérifie si l'utilisateur a le droit de modifier le champ
            if (Schema.sObjectType.Case.fields.Reponse_Brouillon__c.isUpdateable()) {
                Case c = new Case(Id = caseId);
                if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    c.Reponse_Brouillon__c = 'Appel réussi (200). L\'agent traite la demande...';
                } else {
                    c.Reponse_Brouillon__c = 'Erreur API: ' + res.getStatusCode() + ' | Message: ' + res.getBody();
                }
                update c;
            }

        } catch (Exception e) {
            System.debug('Erreur critique Apex: ' + e.getMessage());
            logErrorToCase(caseId, e.getMessage());
        }
    }

    // Méthode utilitaire pour éviter les blocs catch vides (PMD Violation)
    private static void logErrorToCase(Id caseId, String errorMessage) {
        try {
            if (Schema.sObjectType.Case.fields.Reponse_Brouillon__c.isUpdateable()) {
                update new Case(Id = caseId, Reponse_Brouillon__c = 'Erreur Apex: ' + errorMessage);
            }
        } catch (Exception ex) {
            System.debug('Impossible d\'écrire l\'erreur sur le Case: ' + ex.getMessage());
        }
    }
}