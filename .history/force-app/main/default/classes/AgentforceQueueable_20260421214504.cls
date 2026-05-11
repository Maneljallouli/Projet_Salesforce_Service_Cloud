public class AgentforceQueueable implements Queueable, Database.AllowsCallouts {

    private Id caseId;
    private String flowSessionId;

    public AgentforceQueueable(Id caseId, String flowSessionId) {
        this.caseId        = caseId;
        this.flowSessionId = flowSessionId;
    }

    public void execute(QueueableContext ctx) {
        AgentforceDirectInvoker.invoke(this.caseId, this.flowSessionId);
    }
}