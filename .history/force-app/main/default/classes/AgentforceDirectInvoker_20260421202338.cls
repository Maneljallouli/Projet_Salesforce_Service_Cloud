public class AgentforceDirectInvoker {

    public static void invoke(
        Id caseId,
        String analyseIA,
        String brouillonIA
    ) {
        Map<String, Object> inputs = new Map<String, Object>{
            'analyseIAInstructions'   => analyseIA,
            'brouillonIAInstructions' => brouillonIA,
            'recordIdInstructions'    => (String) caseId
        };

        Map<String, Object> body = new Map<String, Object>{
            'inputs' => new List<Object>{ inputs }
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            URL.getOrgDomainUrl().toExternalForm() +
            '/services/data/v63.0/actions/custom/agentAction/Agent_Update_Case_Fields_179AW00000025q1'
        );
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setBody(JSON.serialize(body));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            System.debug('✅ Agentforce action succeeded for Case: ' + caseId);
        } else {
            System.debug('❌ Agentforce action failed - Status: ' + res.getStatusCode());
            System.debug('Response body: ' + res.getBody());
        }
    }
}