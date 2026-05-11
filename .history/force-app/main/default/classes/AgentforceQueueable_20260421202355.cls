public class AgentforceQueueable implements Queueable, Database.AllowsCallouts {

    private Id caseId;
    private String channel;
    private String analyseIA;
    private String brouillonIA;

    public AgentforceQueueable(Id caseId, String channel, String analyseIA, String brouillonIA) {
        this.caseId      = caseId;
        this.channel     = channel;
        this.analyseIA   = analyseIA;
        this.brouillonIA = brouillonIA;
    }

    public void execute(QueueableContext ctx) {
        AgentforceDirectInvoker.invoke(
            this.caseId,
            this.analyseIA,
            this.brouillonIA
        );
    }
}