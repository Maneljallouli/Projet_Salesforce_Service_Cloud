public class AgentforceEnqueuer {

    @InvocableMethod(
        label='Enqueue Agentforce Job'
        description='Enqueue Agentforce action with admin user context'
    )
    public static void enqueue(List<EnqueueRequest> requests) {
        for (EnqueueRequest r : requests) {
            System.enqueueJob(new AgentforceQueueable(r.caseId));
        }
    }

    public class EnqueueRequest {
        @InvocableVariable(required=true)
        public Id caseId;
    }
}