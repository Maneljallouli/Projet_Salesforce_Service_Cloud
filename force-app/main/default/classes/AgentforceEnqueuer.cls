public class AgentforceEnqueuer {

    @InvocableMethod(
        label='Enqueue Agentforce Job'
        description='Enqueue Agentforce action with admin user context'
    )
    public static void enqueue(List<EnqueueRequest> requests) {
        if (!requests.isEmpty()) {
            System.enqueueJob(
                new AgentforceQueueable(requests[0].caseId)
            );
        }
    }

    public class EnqueueRequest {
        @InvocableVariable(required=true)
        public Id caseId;
    }
}