public with sharing class TriggerAgentOnCaseCreation {

    @InvocableMethod(
        label='Déclencher Agent Agentforce sur Case'
        description='Ouvre une session Agentforce et envoie le message déclencheur'
    )
    public static void triggerAgent(List<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) return;
        processAgentAsync(caseIds[0]);
    }

    @future(callout=true)
    private static void processAgentAsync(Id caseId) {
        try {
            // Récupère les données du Case
            Case c = [
                SELECT Id, CaseNumber, Subcategory__c,
                       Contact.FirstName, Order_number__c,
                       Purchase_date__c
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            // Étape 1 — Créer une session Agentforce
            String sessionId = createAgentSession();
            if (sessionId == null) {
                System.debug('Échec création session Agentforce');
                return;
            }

            // Étape 2 — Construire le message avec toutes les données
            String message = 'Analyse et prépare automatiquement '
                + 'une réponse brouillon pour ce dossier. '
                + 'caseId=' + c.Id + ' '
                + 'subcategory=' + c.Subcategory__c + ' '
                + 'contact=' + c.Contact.FirstName + ' '
                + 'order=' + c.Order_number__c + ' '
                + 'date=' + String.valueOf(c.Purchase_date__c) + ' '
                + 'caseNumber=' + c.CaseNumber;

            // Étape 3 — Envoyer le message à l'agent
            sendMessageToAgent(sessionId, message);

        } catch (Exception e) {
            System.debug('Erreur TriggerAgent: ' + e.getMessage());
        }
    }

    // Crée une session et retourne le sessionId
    private static String createAgentSession() {
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String endpoint = baseUrl 
            + '/einstein/ai-agent/v1/sessions';

        // Body de création de session
        Map<String, Object> body = new Map<String, Object>{
            'externalSessionKey' => 'case-auto-' 
                + String.valueOf(DateTime.now().getTime()),
            'instanceConfig' => new Map<String, Object>{
                'endpoint' => baseUrl
            },
            'streamingCapabilities' => new Map<String, Object>{
                'chunkTypes' => new List<String>{'Text'}
            },
            'bypassUser' => true
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' 
            + UserInfo.getSessionId());
        req.setBody(JSON.serialize(body));
        req.setTimeout(30000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200 
            || res.getStatusCode() == 201) {
            Map<String, Object> responseMap = 
                (Map<String, Object>) JSON.deserializeUntyped(
                    res.getBody()
                );
            return (String) responseMap.get('sessionId');
        }

        System.debug('Erreur session: ' + res.getStatusCode() 
            + ' — ' + res.getBody());
        return null;
    }

    // Envoie le message à la session agent
    private static void sendMessageToAgent(
        String sessionId, 
        String message
    ) {
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String endpoint = baseUrl 
            + '/einstein/ai-agent/v1/sessions/' 
            + sessionId + '/messages';

        Map<String, Object> body = new Map<String, Object>{
            'message' => new Map<String, Object>{
                'sequenceId' => 1,
                'type'       => 'Text',
                'text'       => message
            }
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' 
            + UserInfo.getSessionId());
        req.setBody(JSON.serialize(body));
        req.setTimeout(30000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('Réponse agent: ' + res.getStatusCode() 
            + ' — ' + res.getBody());
    }
}