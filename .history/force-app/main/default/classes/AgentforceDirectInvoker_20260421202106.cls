public class AgentforceDirectInvoker {

    public static void invoke(
        Id caseId,
        String analyseIA,
        String brouillonIA,
        Id runAsUserId
    ) {
        List<AgentUpdateCaseFieldsInput> inputs = new List<AgentUpdateCaseFieldsInput>();

        AgentUpdateCaseFieldsInput input = new AgentUpdateCaseFieldsInput();
        input.analyseIAInstructions   = analyseIA;
        input.brouillonIAInstructions = brouillonIA;
        input.recordIdInstructions    = caseId;

        inputs.add(input);

        List<AgentUpdateCaseFieldsOutput> outputs = AgentUpdateCaseFields.execute(inputs);

        if (outputs != null && !outputs.isEmpty()) {
            AgentUpdateCaseFieldsOutput output = outputs[0];
            if (!output.isSuccess) {
                System.debug('❌ Agentforce action failed for Case: ' + caseId);
            } else {
                System.debug('✅ Agentforce action succeeded for Case: ' + caseId);
            }
        }
    }
}