public with sharing class EmailCaseAgentforceAnalyzer {

    // Classe pour les entrées
    public class Input {
        @InvocableVariable(required=true)
        public Id caseId;
    }

    // Classe pour les sorties
    public class Output {
        @InvocableVariable public String category;
        @InvocableVariable public String subcategory;
        @InvocableVariable public String priority;
        @InvocableVariable public String summary;
        @InvocableVariable public Decimal confidence;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(label='Analyze Case with Agentforce')
    public static List<Output> analyze(List<Input> inputs) {
        List<Output> results = new List<Output>();
        List<Case> casesToUpdate = new List<Case>();

        for (Input i : inputs) {
            Output out = callAgentforce(i.caseId);
            results.add(out);

            if (out.success) {
                Case c = new Case(Id = i.caseId);
                updateCaseFields(c, out);
                casesToUpdate.add(c);
            }
        }

        if (!casesToUpdate.isEmpty()) {
            try {
                update casesToUpdate;
            } catch (DmlException e) {
                for (Output o : results) {
                    o.success = false;
                    o.errorMessage = e.getMessage();
                }
            }
        }

        return results;
    }

    // Appel à Agentforce
    private static Output callAgentforce(Id caseId) {
        Output out = new Output();
        try {
            ConnectApi.EinsteinPromptTemplateGenerationsInput req =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            req.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            req.additionalConfig.applicationName = 'EmailCaseAgentforceAnalyzer';
            req.isPreview = false;

            Map<String, ConnectApi.WrappedValue> params = new Map<String, ConnectApi.WrappedValue>();
            ConnectApi.WrappedValue val = new ConnectApi.WrappedValue();
            val.value = caseId;
            params.put('$Input:Case', val);
            req.inputParams = params;

            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation resp =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                    'Email_Case_Analyzer',
                    req
                );

            String raw = resp.generations[0].text.trim();
            raw = raw.replace('```json','').replace('```','').trim();
            Map<String,Object> parsed = (Map<String,Object>) JSON.deserializeUntyped(raw);

            out.category    = (String) parsed.get('category');
            out.subcategory = (String) parsed.get('subcategory');
            out.priority    = (String) parsed.get('priority');
            out.summary     = (String) parsed.get('summary');
            out.confidence  = (Decimal) parsed.get('confidence');
            out.success     = true;

        } catch (Exception e) {
            out.success = false;
            out.errorMessage = e.getMessage();
        }
        return out;
    }

    // Mise à jour des champs Case
    private static void updateCaseFields(Case c, Output out) {
        Map<String, Object> values = new Map<String, Object>{
            'Category__c'    => out.category,
            'Subcategory__c' => out.subcategory,
            'Priority'       => out.priority,
            'Description'    => out.summary
        };

        for (String fieldName : values.keySet()) {
            if (values.get(fieldName) != null) {
                c.put(fieldName, values.get(fieldName));
            }
        }
    }
}