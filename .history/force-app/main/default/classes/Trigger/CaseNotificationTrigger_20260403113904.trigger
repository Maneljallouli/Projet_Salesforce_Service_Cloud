trigger CaseNotificationTrigger on Case (after update) {
    // Liste pour traiter les cases modifiés si besoin
    for (Case c : Trigger.new) {
        Case oldCase = Trigger.oldMap.get(c.Id);
        
        // On vérifie si le statut a changé
        if (c.Status != oldCase.Status) {
            System.debug('Statut mis à jour pour le Case: ' + c.CaseNumber);
            // Ici, le simple fait que le record soit 'Updated' 
            // permet à ton LWC (via Apex) de voir le changement.
        }
    }
}