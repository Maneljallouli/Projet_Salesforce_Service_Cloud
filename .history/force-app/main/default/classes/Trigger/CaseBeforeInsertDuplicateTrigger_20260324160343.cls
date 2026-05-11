trigger CaseBeforeInsertDuplicateTrigger on Case (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        CaseDuplicateHandler.checkForDuplicates(Trigger.new);
    }
}