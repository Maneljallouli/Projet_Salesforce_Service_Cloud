public class AgentforceDirectInvoker {

    public static void invoke(Id caseId, String flowSessionId) {

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
        req.setHeader('Authorization', 'Bearer ' + flowSessionId);
        req.setBody(JSON.serialize(body));
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('STATUS: ' + res.getStatusCode());
        System.debug('BODY: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            // Parse la réponse
            List<Object> results = (List<Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> result = (Map<String, Object>) results[0];
            Map<String, Object> outputValues = (Map<String, Object>) result.get('outputValues');

            if (outputValues != null) {
                String brouillonIA = (String) outputValues.get('brouillonIA');
                String analyseIA   = (String) outputValues.get('analyseIA');

                System.debug('brouillonIA: ' + brouillonIA);
                System.debug('analyseIA: '   + analyseIA);

                // Met à jour le Case directement
                if (String.isNotBlank(brouillonIA) || String.isNotBlank(analyseIA)) {
                    Case c = new Case(Id = caseId);
                    c.Reponse_Brouillon__c = brouillonIA;
                    c.Analyse_IA__c        = analyseIA;
                    update c;
                    System.debug('✅ Case updated successfully: ' + caseId);
                } else {
                    System.debug('⚠️ outputValues are empty - Agent did not generate content');
                }
            }
        } else {
            System.debug('❌ Agentforce action failed - Status: ' + res.getStatusCode());
            System.debug('Response body: ' + res.getBody());
        }
    }
}