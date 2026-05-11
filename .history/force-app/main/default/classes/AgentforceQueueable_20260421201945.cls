public class AgentforceQueueable implements Queueable {

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

        Id runAsUserId = (Id) Label.Agentforce_Runner_User_Id;

        AgentforceDirectInvoker.invoke(
            this.caseId,
            this.analyseIA,
            this.brouillonIA,
            runAsUserId
        );
    }
}