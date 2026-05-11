public class AgentforceDirectInvoker {

    public static void invoke(Id caseId) {

        Map<String, Object> inputs = new Map<String, Object>{
            'recordId'    => (String) caseId,
            'analyseIA'   => '',
            'brouillonIA' => ''
        };

        Map<String, Object> body = new Map<String, Object>{
            'inputs' => new List<Object>{ inputs }
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint(
            URL.getOrgDomainUrl().toExternalForm() +
            '/services/data/v63.0/actions/custom/flow/Agent_Update_Case_Fields'
        );
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setBody(JSON.serialize(body));
        req.setTimeout(120000);

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