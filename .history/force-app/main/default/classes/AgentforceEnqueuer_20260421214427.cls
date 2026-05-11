public class AgentforceEnqueuer {

    @InvocableMethod(
        label='Enqueue Agentforce Job'
        description='Enqueue Agentforce action with admin user context'
    )
    public static void enqueue(List<EnqueueRequest> requests) {
        // Capture le Session ID dans le contexte Flow (valide)
        String sessionId = UserInfo.getSessionId();
        
        for (EnqueueRequest r : requests) {
            System.enqueueJob(new AgentforceQueueable(r.caseId, sessionId));
        }
    }

    public class EnqueueRequest {
        @InvocableVariable(required=true)
        public Id caseId;
    }
}