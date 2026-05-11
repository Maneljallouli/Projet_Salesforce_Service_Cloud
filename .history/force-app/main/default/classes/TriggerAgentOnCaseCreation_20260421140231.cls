public with sharing class TriggerAgentOnCaseCreation {

    @InvocableMethod(
        label='Trigger Agent on Case',
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

            Case c = [
                SELECT Id, CaseNumber, Contact.FirstName, Order_number__c
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            String sessionId = createSession();

            if (sessionId == null) {
                System.debug('Session not created');
                return;
            }

            String message =
                'Case analysis ' + c.CaseNumber +
                ', client=' + (c.Contact != null ? c.Contact.FirstName : '') +
                ', order=' + c.Order_number__c;

            sendMessage(sessionId, message);

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
    }

    private static String createSession() {

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:AgentforceInternal/einstein/ai-agent/v1/sessions');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody('{}');

        HttpResponse res = new Http().send(req);

        System.debug(res.getBody());

        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            Map<String, Object> json =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            return (String) json.get('sessionId');
        }

        return null;
    }

    private static void sendMessage(String sessionId, String message) {

        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            'callout:AgentforceInternal/einstein/ai-agent/v1/sessions/' +
            sessionId + '/messages'
        );
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        req.setBody(JSON.serialize(new Map<String, Object>{
            'message' => new Map<String, Object>{
                'type' => 'Text',
                'text' => message
            }
        }));

        HttpResponse res = new Http().send(req);

        System.debug('Agent response: ' + res.getBody());
    }
}