public class AgentforceEnqueuer {

    @InvocableMethod(
        label='Enqueue Agentforce Job'
        description='Enqueue Agentforce action with admin user context'
    )
    public static void enqueue(List<EnqueueRequest> requests) {
        for (EnqueueRequest r : requests) {
            System.enqueueJob(
                new AgentforceQueueable(
                    r.caseId,
                    r.channel,
                    r.analyseIA,
                    r.brouillonIA
                )
            );
        }
    }

    public class EnqueueRequest {
        @InvocableVariable(required=true)
        public Id caseId;

        @InvocableVariable(required=true)
        public String channel;

        @InvocableVariable(required=false)
        public String analyseIA;

        @InvocableVariable(required=false)
        public String brouillonIA;
    }
}