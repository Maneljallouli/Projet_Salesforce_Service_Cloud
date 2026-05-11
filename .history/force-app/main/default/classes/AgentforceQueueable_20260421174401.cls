public class AgentforceQueueable implements Queueable {
    private Id caseId;
    
    public AgentforceQueueable(Id caseId) {
        this.caseId = caseId;
    }
    
    public void execute(QueueableContext ctx) {
        try {
            Map<String,Object> inputs = new Map<String,Object>();
            inputs.put('CaseId', caseId);
            inputs.put('userMessage', 'Analyse case ' + caseId + ' génère brouillon réponse');
            
            Flow.Interview.Run_Agentforce agentFlow = new Flow.Interview.Run_Agentforce(inputs);
            agentFlow.start();
        } catch (Exception e) {
            System.debug('AgentforceQueueable error: ' + e.getMessage());
        }
    }
}