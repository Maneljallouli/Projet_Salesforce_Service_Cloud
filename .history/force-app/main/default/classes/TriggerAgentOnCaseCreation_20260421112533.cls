public with sharing class TriggerAgentOnCaseCreation {

    @InvocableMethod(
        label='Déclencher Agent Agentforce sur Case'
        description='Ouvre une session Agentforce et envoie le message déclencheur'
    )
    public static void triggerAgent(List<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }
        processAgentAsync(caseIds[0]);
    }

    @future(callout=true)
    private static void processAgentAsync(Id caseId) {
        try {
            if (!Schema.sObjectType.Case.isAccessible()) {
                System.debug('Accès refusé à Case');
                return;
            }

            Case c = [
                SELECT Id, CaseNumber, Subcategory__c,
                       Contact.FirstName, Order_number__c,
                       Date_d_achat__c
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            String sessionId = createAgentSession();
            if (sessionId == null) {
                System.debug('❌ Échec création session');
                return;
            }

            // 🔥 MESSAGE CORRIGÉ (TRÈS IMPORTANT)
            String message = 'Appelle l’action Agent_Update_Case_Fields avec les données suivantes : '
                + 'recordId=' + c.Id + ', '
                + 'analyseIA=Analyse automatique du dossier, '
                + 'brouillonIA=Bonjour ' + c.Contact.FirstName + ', '
                + 'merci pour votre message. '
                + 'Numéro de commande : ' + c.Order_number__c + ', '
                + 'Date : ' + String.valueOf(c.Date_d_achat__c) + ', '
                + 'Référence : ' + c.CaseNumber;

            sendMessageToAgent(sessionId, message);

        } catch (Exception e) {
            System.debug('❌ Erreur TriggerAgent: ' + e.getMessage());
        }
    }

    private static String createAgentSession() {
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();

        Map<String, Object> body = new Map<String, Object>{
            'externalSessionKey' => 'case-auto-' + DateTime.now().getTime(),
            'instanceConfig' => new Map<String, Object>{
                'endpoint' => baseUrl
            },
            'streamingCapabilities' => new Map<String, Object>{
                'chunkTypes' => new List<String>{ 'Text' }
            },
            'bypassUser' => true
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
            Map<String, Object> responseMap =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) responseMap.get('sessionId');
        }

        System.debug('❌ Erreur session: ' + res.getStatusCode() + ' — ' + res.getBody());
        return null;
    }

    private static void sendMessageToAgent(String sessionId, String message) {

        Map<String, Object> body = new Map<String, Object>{
            'message' => new Map<String, Object>{
                'sequenceId' => 1,
                'type'       => 'Text',
                'text'       => message
            }
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AgentforceInternal/einstein/ai-agent/v1/sessions/'
            + sessionId + '/messages');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(body));
        req.setTimeout(30000);

        HttpResponse res = new Http().send(req);

        System.debug('🤖 AGENT RESPONSE: ' + res.getStatusCode() + ' — ' + res.getBody());
    }
}