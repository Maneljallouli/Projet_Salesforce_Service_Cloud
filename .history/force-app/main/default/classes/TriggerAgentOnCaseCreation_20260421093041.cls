public with sharing class TriggerAgentOnCaseCreation {
    @InvocableMethod(
        label='Déclencher Agent Agentforce sur Case'
        description='Déclenche l’agent de manière asynchrone'
    )
    public static void triggerAgent(List<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }
        
        // On appelle le futur pour éviter les erreurs de session
        processAgentAsync(caseIds[0]);
    }

    @future(callout=true)
    private static void processAgentAsync(Id caseId) {
        try {
            // Au lieu de ConnectApi qui plante, on utilise l'appel système 
            // pour réveiller l'Agent via une instruction simple.
            String agentApiName = 'Service_Client_AI';
            String message = 'Génère le brouillon pour le ticket ' + caseId;
            
            // Cette méthode est plus ancienne et souvent plus stable
            ConnectApi.ChatterMessages.sendMessage(message, caseId);
            
            System.debug('Signal envoyé à l\'agent pour le Case: ' + caseId);
        } catch (Exception e) {
            System.debug('Erreur: ' + e.getMessage());
        }
    }
}