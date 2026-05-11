public with sharing class TriggerAgentOnCaseCreation {
    @InvocableMethod(
        label='Déclencher Agent Agentforce sur Case'
        description='Ouvre une session agent et envoie le message déclencheur pour la génération de brouillon'
    )
    public static void triggerAgent(List<Id> caseIds) {
        // Correction PMD : Utilisation des accolades
        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }
        
        Id caseId = caseIds[0];
        
        // Message d'instruction pour l'agent
        String message = 'Analyse le dossier avec l\'ID ' + caseId + ' et génère un brouillon de réponse approprié.';

        try {
            // Utilisation de EinsteinBotRuntime (plus largement supporté pour déclencher les agents)
            // 'Service_Client_AI' est l'API Name de ton Agent
            ConnectApi.EinsteinBotExternalSessionInput sessionInput = new ConnectApi.EinsteinBotExternalSessionInput();
            
            // On envoie le message de manière synchrone pour forcer l'exécution
            ConnectApi.EinsteinBotOutput response = ConnectApi.EinsteinBotRuntime.sendSynchronousMessage(
                'Service_Client_AI', 
                null, // null crée une nouvelle session
                message
            );
            
            System.debug('Agentforce sollicité avec succès pour le Case: ' + caseId);
        } catch (Exception e) {
            System.debug('Erreur lors de l\'appel Agentforce: ' + e.getMessage());
        }
    }
}