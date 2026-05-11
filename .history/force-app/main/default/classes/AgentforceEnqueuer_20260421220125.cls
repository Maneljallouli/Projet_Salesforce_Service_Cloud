public class AgentforceEnqueuer {

    @InvocableMethod(
        label='Enqueue Agentforce Job'
        description='Enqueue Agentforce action with admin user context'
    )
    public static void enqueue(List<EnqueueRequest> requests) {
        if (!requests.isEmpty()) {
            EnqueueRequest r = requests[0];
            // Utilise le sessionId passé depuis le Flow parent
            // Si null, tente UserInfo (fallback)
            String sid = String.isNotBlank(r.sessionId) 
                ? r.sessionId 
                : UserInfo.getSessionId();
            System.enqueueJob(new AgentforceQueueable(r.caseId, sid));
        }
    }

    public class EnqueueRequest {
        @InvocableVariable(required=true)
        public Id caseId;

        @InvocableVariable(required=false)
        public String sessionId;
    }
}