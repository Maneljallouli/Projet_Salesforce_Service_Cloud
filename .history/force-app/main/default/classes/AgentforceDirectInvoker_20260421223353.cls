public class AgentforceDirectInvoker {

    public static void invoke(Id caseId) {

        // Étape 1 — Appel initial pour récupérer les données du Case
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

        HttpResponse res = new Http().send(req);
        System.debug('STATUS: ' + res.getStatusCode());

        if (res.getStatusCode() != 200) {
            System.debug('❌ Step 1 failed: ' + res.getBody());
            return;
        }

        // Parse les outputs
        List<Object> results = (List<Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> result = (Map<String, Object>) results[0];
        Map<String, Object> outputValues = (Map<String, Object>) result.get('outputValues');

        String vTemplateBody     = (String) outputValues.get('vTemplateBody');
        String vSubcategory      = (String) outputValues.get('vSubcategory');
        String vContactFirstName = (String) outputValues.get('vContactFirstName');
        String vOrderNumber      = (String) outputValues.get('vOrderNumber');
        String vCaseNumber       = (String) outputValues.get('vCaseNumber');
        String vDateAchat        = (String) outputValues.get('vDateAchat');

        System.debug('vTemplateBody: ' + vTemplateBody);
        System.debug('vSubcategory: '  + vSubcategory);

        // Étape 2 — Générer brouillonIA via Einstein LLM
        String brouillonIA = generateBrouillon(
            vTemplateBody, vContactFirstName, vOrderNumber, vCaseNumber, vDateAchat
        );
        System.debug('brouillonIA generated: ' + brouillonIA);

        // Étape 3 — Réécrire sur le Case avec brouillonIA rempli
        Map<String, Object> inputs2 = new Map<String, Object>{
            'recordId'    => (String) caseId,
            'analyseIA'   => vSubcategory,
            'brouillonIA' => brouillonIA
        };

        Map<String, Object> body2 = new Map<String, Object>{
            'inputs' => new List<Object>{ inputs2 }
        };

        HttpRequest req2 = new HttpRequest();
        req2.setEndpoint(
            'callout:AgentforceInternal' +
            '/services/data/v63.0/actions/custom/flow/Agent_Update_Case_Fields'
        );
        req2.setMethod('POST');
        req2.setHeader('Content-Type', 'application/json');
        req2.setBody(JSON.serialize(body2));
        req2.setTimeout(120000);

        HttpResponse res2 = new Http().send(req2);
        System.debug('Step 3 STATUS: ' + res2.getStatusCode());
        System.debug('Step 3 BODY: '   + res2.getBody());

        if (res2.getStatusCode() == 200) {
            System.debug('✅ Case updated successfully: ' + caseId);
        } else {
            System.debug('❌ Step 3 failed: ' + res2.getBody());
        }
    }

    private static String generateBrouillon(
        String templateBody,
        String firstName,
        String orderNumber,
        String caseNumber,
        String dateAchat
    ) {
        if (String.isBlank(templateBody)) return '';

        // Remplacement des variables de fusion
        String result = templateBody;
        result = result.replace('{{Case.Contact}}',              firstName   != null ? firstName   : '');
        result = result.replace('{{Case.Order_number__c}}',      orderNumber != null ? orderNumber : '');
        result = result.replace('{{Case.CaseNumber}}',           caseNumber  != null ? caseNumber  : '');
        result = result.replace('{{Case.Date_d_achat__c}}',      dateAchat   != null ? dateAchat   : '');

        return result;
    }
}