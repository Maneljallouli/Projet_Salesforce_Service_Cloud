public class AgentforceQueueable implements Queueable, Database.AllowsCallouts {

    private Id caseId;

    public AgentforceQueueable(Id caseId) {
        this.caseId = caseId;
    }

    public void execute(QueueableContext ctx) {
        AgentforceDirectInvoker.invoke(this.caseId);
    }
}