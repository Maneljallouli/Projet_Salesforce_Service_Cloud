trigger CaseBeforeInsertDuplicateTrigger on Case (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        // Appel du handler, pas de logique ici
        CaseDuplicateHandler.checkForDuplicates(Trigger.new);
    }
}