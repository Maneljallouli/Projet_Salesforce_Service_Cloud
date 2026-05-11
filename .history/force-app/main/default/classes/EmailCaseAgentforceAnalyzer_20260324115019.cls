public with sharing class EmailCaseAgentforceAnalyzer {

    public class Input {
        @InvocableVariable(required=true)
        public Id caseId;
    }

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
            Output out = new Output();
            try {
                ConnectApi.EinsteinPromptTemplateGenerationsInput req =
                    new ConnectApi.EinsteinPromptTemplateGenerationsInput();
                req.additionalConfig =
                    new ConnectApi.EinsteinLlmAdditionalConfigInput();
                req.additionalConfig.applicationName = 'EmailCaseAgentforceAnalyzer';
                req.isPreview = false;

                Map<String, ConnectApi.WrappedValue> params =
                    new Map<String, ConnectApi.WrappedValue>();
                ConnectApi.WrappedValue val = new ConnectApi.WrappedValue();
                val.value = i.caseId;
                params.put('Input:Case', val); // ✅ corrigé
                req.inputParams = params;

                ConnectApi.EinsteinPromptTemplateGenerationsRepresentation resp =
                    ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                        'Email_Case_Analyzer',
                        req
                    );

                String raw = resp.generations[0].text.trim();
                raw = raw.replace('```json','').replace('```','').trim();

                Map<String,Object> parsed =
                    (Map<String,Object>) JSON.deserializeUntyped(raw);

                out.category    = (String)  parsed.get('category');
                out.subcategory = (String)  parsed.get('subcategory');
                out.priority    = (String)  parsed.get('priority');
                out.summary     = (String)  parsed.get('summary');
                out.confidence  = (Decimal) parsed.get('confidence');
                out.success     = true;

                // ✅ Mapping correct des champs
                Case c = new Case(Id = i.caseId);
                if (out.category    != null) c.Category__c    = out.category;
                if (out.subcategory != null) c.Subcategory__c = out.subcategory;
                if (out.priority    != null) c.Priority       = out.priority;
                if (out.summary     != null) c.Description    = out.summary;
                casesToUpdate.add(c);

            } catch (Exception e) {
                out.success      = false;
                out.errorMessage = e.getMessage();
                System.debug('Error: ' + e.getMessage());
            }
            results.add(out);
        }

        updateCases(casesToUpdate);
        return results;
    }

    private static void updateCases(List<Case> casesToUpdate) {
        if (casesToUpdate.isEmpty()) return;
        if (!Schema.sObjectType.Case.isUpdateable()) return;
        try {
            update casesToUpdate;
        } catch (DmlException e) {
            System.debug('DML Error: ' + e.getMessage());
        }
    }
}