public with sharing class TriggerAgentOnCaseCreation {
    @InvocableMethod(
        label='Déclencher Agent Agentforce sur Case'
        description='Ouvre une session agent et envoie le message déclencheur pour la génération de brouillon'
    )
    public static void triggerAgent(List<Id> caseIds) {
        if (caseIds == null || caseIds.isEmpty()) return;
        
        Id caseId = caseIds[0];
        
        // Construction du message pour guider l'agent
        // On lui donne l'ID pour le grounding (contexte)
        String message = 'Analyse le dossier avec l\'ID ' + caseId + ' et génère un brouillon de réponse approprié.';

        try {
            // Utilisation de la ConnectApi pour Agentforce (Service Cloud)
            // Remplace 'Service_Client_AI' par l'API Name exact de ton Agent si différent
            ConnectApi.EinsteinAgent.generateResponse('Service_Client_AI', caseId, message);
            System.debug('Agentforce sollicité avec succès pour le Case: ' + caseId);
        } catch (Exception e) {
            System.debug('Erreur lors de l\'appel Agentforce: ' + e.getMessage());
        }
    }
}