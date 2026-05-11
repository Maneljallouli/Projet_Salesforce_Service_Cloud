public with sharing class TriggerAgentOnCaseCreation {

    @InvocableMethod(
        label='Trigger Agent on Case'
        description='Appelle l\'Agentforce pour générer une réponse automatiquement'
    )
    public static void triggerAgent(List<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }
        // Appel de la méthode future pour autoriser le callout (Named Credential)
        processAgentAsync(caseIds[0]);
    }

    @future(callout=true)
    public static void processAgentAsync(Id caseId) {
        try {
            // 1. Sécurité : Vérifier l'accès aux données (Pour PMD)
            if (!Schema.sObjectType.Case.isAccessible()) {
                return;
            }

            // 2. Récupération des infos du Case
            Case c = [
                SELECT Id, CaseNumber 
                FROM Case 
                WHERE Id = :caseId 
                WITH SECURITY_ENFORCED 
                LIMIT 1
            ];

            // 3. Préparation de la requête HTTP vers Agentforce
            // On utilise le Named Credential "AgentforceInternal"
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:AgentforceInternal/einstein/ai-agent/v1/sessions');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');

            // 4. Construction du corps du message
            // On envoie exactement la phrase qui fonctionne en manuel
            Map<String, Object> messageBody = new Map<String, Object>{
                'type' => 'Text',
                'text' => 'Case analysis ' + caseId
            };
            
            Map<String, Object> payload = new Map<String, Object>{
                'message' => messageBody
            };

            req.setBody(JSON.serialize(payload));

            // 5. Envoi de l'appel
            Http http = new Http();
            HttpResponse res = http.send(req);

            // 6. Debug pour vérification dans les logs
            System.debug('Agentforce Status: ' + res.getStatusCode());
            System.debug('Agentforce Response: ' + res.getBody());

        } catch (Exception e) {
            System.debug('Erreur Apex Agentforce: ' + e.getMessage());
        }
    }
}