public class AgentforceDirectInvoker {

    public static void invoke(Id caseId) {
        
        // Étape 1 — Créer une session
        String sessionId = createSession();
        if (sessionId == null) {
            System.debug('❌ Failed to create Agent session for Case: ' + caseId);
            return;
        }
        System.debug('✅ Session created: ' + sessionId);

        // Étape 2 — Envoyer le message avec le Case ID
        Boolean sent = sendMessage(sessionId, (String) caseId);
        if (!sent) {
            System.debug('❌ Failed to send message for Case: ' + caseId);
            closeSession(sessionId);
            return;
        }
        System.debug('✅ Message sent for Case: ' + caseId);

        // Étape 3 — Fermer la session
        closeSession(sessionId);
        System.debug('✅ Session closed for Case: ' + caseId);
    }

    // Crée une session Agent
    private static String createSession() {
        Map<String, Object> body = new Map<String, Object>{
            'agentId' => 'Service_Client_AI'
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Agentforce_Runtime/v63.0/sessions');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(body));
        req.setTimeout(120000);

        HttpResponse res = new Http().send(req);
        System.debug('Create Session STATUS: ' + res.getStatusCode());
        System.debug('Create Session BODY: ' + res.getBody());

        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            Map<String, Object> parsed = 
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) parsed.get('sessionId');
        }
        return null;
    }

    // Envoie le message avec le Case ID
    private static Boolean sendMessage(String sessionId, String caseId) {
        Map<String, Object> body = new Map<String, Object>{
            'message' => 'Traite automatiquement le Case ID: ' + caseId,
            'variables' => new Map<String, Object>{
                'recordId' => caseId
            }
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Agentforce_Runtime/v63.0/sessions/' + sessionId + '/messages');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(body));
        req.setTimeout(120000);

        HttpResponse res = new Http().send(req);
        System.debug('Send Message STATUS: ' + res.getStatusCode());
        System.debug('Send Message BODY: ' + res.getBody());

        return res.getStatusCode() == 200 || res.getStatusCode() == 201;
    }

    // Ferme la session
    private static void closeSession(String sessionId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Agentforce_Runtime/v63.0/sessions/' + sessionId);
        req.setMethod('DELETE');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);

        HttpResponse res = new Http().send(req);
        System.debug('Close Session STATUS: ' + res.getStatusCode());
    }
}