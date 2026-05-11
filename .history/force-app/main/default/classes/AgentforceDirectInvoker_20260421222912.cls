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
            'callout:AgentforceInternal' +
            '/services/data/v63.0/actions/custom/flow/Agent_Update_Case_Fields'
        );
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(body));
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('STATUS: ' + res.getStatusCode());
        System.debug('FULL BODY: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            // Parse outputValues
            List<Object> results = (List<Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> result = (Map<String, Object>) results[0];
            Map<String, Object> outputValues = (Map<String, Object>) result.get('outputValues');
            System.debug('OUTPUT KEYS: ' + outputValues.keySet());
            System.debug('brouillonIA: ' + outputValues.get('brouillonIA'));
            System.debug('analyseIA: ' + outputValues.get('analyseIA'));
        }
    }
}