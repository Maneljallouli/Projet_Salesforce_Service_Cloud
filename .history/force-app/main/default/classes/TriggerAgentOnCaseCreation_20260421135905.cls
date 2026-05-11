public with sharing class TriggerAgentOnCaseCreation {

    @InvocableMethod(
        label='Déclencher Agent Agentforce sur Case',
        description='Crée une session Agentforce et envoie un message au LLM'
    )
    public static void triggerAgent(List<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) return;

        for (Id caseId : caseIds) {
            processAgentAsync(caseId);
        }
    }

    @future(callout=true)
    private static void processAgentAsync(Id caseId) {
        try {

            Case c = [
                SELECT Id, CaseNumber, Subcategory__c,
                       Contact.FirstName, Order_number__c,
                       Date_d_achat__c
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            String sessionId = createAgentSession(c.Id);
            if (sessionId == null) {
                System.debug('❌ Session Agent non créée');
                return;
            }

            String message =
                'Analyse ce Case et exécute Agent_Update_Case_Fields. ' +
                'Données: ' +
                'recordId=' + c.Id + ', ' +
                'client=' + (c.Contact != null ? c.Contact.FirstName : 'inconnu') + ', ' +
                'commande=' + c.Order_number__c + ', ' +
                'date=' + String.valueOf(c.Date_d_achat__c) + ', ' +
                'caseNumber=' + c.CaseNumber + ', ' +
                'objectif=Générer analyse + brouillon réponse client';

            sendMessageToAgent(sessionId, message);

        } catch (Exception e) {
            System.debug('❌ Erreur Agent: ' + e.getMessage());
        }
    }

    private static String createAgentSession(Id caseId) {

        Map<String, Object> body = new Map<String, Object>{
            'externalSessionKey' => 'case-' + caseId + '-' + DateTime.now().getTime(),

            // 🔥 structure simplifiée (plus compatible Agentforce)
            'variables' => new Map<String, Object>{
                'caseId' => caseId
            }
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AgentforceInternal/einstein/ai-agent/v1/sessions');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(body));
        req.setTimeout(30000);

        HttpResponse res = new Http().send(req);

        System.debug('🧠 SESSION RESPONSE: ' + res.getBody());

        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            Map<String, Object> json =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            return (String) json.get('sessionId');
        }

        System.debug('❌ Session error: ' + res.getStatusCode() + ' - ' + res.getBody());
        return null;
    }

    private static void sendMessageToAgent(String sessionId, String message) {

        Map<String, Object> body = new Map<String, Object>{
            'message' => new Map<String, Object>{
                'type' => 'Text',
                'text' => message
            }
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            'callout:AgentforceInternal/einstein/ai-agent/v1/sessions/' +
            sessionId + '/messages'
        );
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(body));
        req.setTimeout(30000);

        HttpResponse res = new Http().send(req);

        System.debug('🤖 AGENT RESPONSE: ' + res.getStatusCode());
        System.debug(res.getBody());
    }
}