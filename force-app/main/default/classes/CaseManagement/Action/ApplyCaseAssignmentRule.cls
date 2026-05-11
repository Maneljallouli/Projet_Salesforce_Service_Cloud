public with sharing class ApplyCaseAssignmentRule {
    @InvocableMethod(label='Apply Case Assignment Rule' description='Applique la règle active par défaut')
    public static void applyRules(List<Id> caseIds){
        List<Case> casesToUpdate = [SELECT Id FROM Case WHERE Id IN :caseIds];
        for(Case c : casesToUpdate){
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;
            c.setOptions(dmo);
        }
        update casesToUpdate;
    }
}