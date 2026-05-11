public class AgentforceQueueableInvoker {
    @InvocableMethod(label='Queue Agentforce' description='Déclenche Agentforce async')
    public static void invokeQueueable(List<Id> caseIds) {
        if (!caseIds.isEmpty()) {
            System.enqueueJob(new AgentforceQueueable(caseIds[0]));
        }
    }
}