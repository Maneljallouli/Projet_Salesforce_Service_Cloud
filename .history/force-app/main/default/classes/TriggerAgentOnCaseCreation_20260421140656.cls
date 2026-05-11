public with sharing class TriggerAgentOnCaseCreation {

    @InvocableMethod(
        label='Trigger Agent on Case'
        description='Calls Agentforce when Case is created'
    )
    public static void triggerAgent(List<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }
        process(caseIds[0]);
    }

    @future(callout=true)
    private static void process(Id caseId) {
        try {
            // Sécurisation CRUD/FLS pour PMD
            if (!Schema.sObjectType.Case.isAccessible()) {
                return;
            }

            Case c = [
                SELECT Id, CaseNumber, Contact.FirstName, Order_number__c
                FROM Case
                WHERE Id = :caseId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            String sessionId = createSession();

            if (sessionId == null) {
                System.debug('Session not created');
                return;
            }

            String clientName = (c.Contact != null && c.Contact.FirstName != null) ? c.Contact.FirstName : '';
            String orderNum = (c.Order_number__c != null) ? c.Order_number__c : '';

            String message = 'Case analysis ' + c.CaseNumber + 
                             ', client=' + clientName + 
                             ', order=' + orderNum;

            sendMessage(sessionId, message);

        } catch (Exception e) {
            System.debug('Error in process: ' + e.getMessage());
        }
    }

    private static String createSession() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AgentforceInternal/einstein/ai-agent/v1/sessions');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{}');

        Http h = new Http();
        HttpResponse res = h.send(req);

        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) jsonMap.get('sessionId');
        }
        return null;
    }

    private static void sendMessage(String sessionId, String message) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AgentforceInternal/einstein/ai-agent/v1/sessions/' + sessionId + '/messages');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        // Correction de la syntaxe Map (utilisation de : au lieu de =>)
        Map<String, Object> messageBody = new Map<String, Object>{
            'type' => 'Text',
            'text' => message
        };
        
        Map<String, Object> payload = new Map<String, Object>{
            'message' => messageBody
        };

        req.setBody(JSON.serialize(payload));

        Http h = new Http();
        HttpResponse res = h.send(req);
        System.debug('Agent response: ' + res.getBody());
    }
}