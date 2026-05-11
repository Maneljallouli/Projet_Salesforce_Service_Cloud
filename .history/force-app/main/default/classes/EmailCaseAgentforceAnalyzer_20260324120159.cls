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

        Map<Id, Case> casesMap = getCasesMap(inputs);

        for (Input i : inputs) {
            Output out = new Output();
            try {
                Case caseRecord = casesMap.get(i.caseId);
                if (caseRecord == null) {
                    out.success = false;
                    out.errorMessage = 'Case not found';
                    results.add(out);
                    continue;
                }

                Map<String, Object> parsed = callEinstein(caseRecord);

                mapParsedToOutput(parsed, out);

                Case c = mapOutputToCase(out, i.caseId);
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

    // -------------------- Méthodes auxiliaires --------------------

    private static Map<Id, Case> getCasesMap(List<Input> inputs) {
        Set<Id> caseIds = new Set<Id>();
        for (Input i : inputs) {
            caseIds.add(i.caseId);
        }

        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new SecurityException('User does not have access to Case object');
        }

        return new Map<Id, Case>(
            [SELECT Id, Subject, Description, Category__c, Subcategory__c, Priority
             FROM Case
             WHERE Id IN :caseIds]
        );
    }

    private static Map<String, Object> callEinstein(Case caseRecord) {
        ConnectApi.EinsteinPromptTemplateGenerationsInput req =
            new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        req.additionalConfig =
            new ConnectApi.EinsteinLlmAdditionalConfigInput();
        req.additionalConfig.applicationName = 'EmailCaseAgentforceAnalyzer';
        req.isPreview = false;

        Map<String, ConnectApi.WrappedValue> params =
            new Map<String, ConnectApi.WrappedValue>();
        ConnectApi.WrappedValue val = new ConnectApi.WrappedValue();
        val.value = caseRecord;
        params.put('Input:Case', val);
        req.inputParams = params;

        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation resp =
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                'Email_Case_Analyzer',
                req
            );

        String raw = resp.generations[0].text.trim();
        raw = raw.replace('```json','').replace('```','').trim();

        return (Map<String,Object>) JSON.deserializeUntyped(raw);
    }

    private static void mapParsedToOutput(Map<String,Object> parsed, Output out) {
        out.category    = (String) parsed.get('category');
        out.subcategory = (String) parsed.get('subcategory');
        out.priority    = (String) parsed.get('priority');
        out.summary     = (String) parsed.get('summary');
        out.confidence  = (Decimal) parsed.get('confidence');
        out.success     = true;
    }

    private static Case mapOutputToCase(Output out, Id caseId) {
        Case c = new Case(Id = caseId);
        if (out.category != null) {
            c.Category__c = out.category;
        }
        if (out.subcategory != null) {
            c.Subcategory__c = out.subcategory;
        }
        if (out.priority != null) {
            c.Priority = out.priority;
        }
        if (out.summary != null) {
            c.Description = out.summary;
        }
        return c;
    }

    private static void updateCases(List<Case> casesToUpdate) {
        if (casesToUpdate.isEmpty()) {
            return;
        }
        if (!Schema.sObjectType.Case.isUpdateable()) {
            return;
        }
        try {
            update casesToUpdate;
        } catch (DmlException e) {
            System.debug('DML Error: ' + e.getMessage());
        }
    }
}