trigger CaseBeforeInsertDuplicateTrigger on Case (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        // Appel de la logique de détection des doublons dans le handler
        CaseDuplicateHandler.checkForDuplicates(Trigger.new);
    }
}