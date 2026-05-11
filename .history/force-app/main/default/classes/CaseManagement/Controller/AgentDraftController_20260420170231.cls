public with sharing class AgentDraftController {
    
    @AuraEnabled(cacheable=false)
    public static Map<String, String> getDraft(String caseId) {
        Case c = [SELECT Reponse_Brouillon__c FROM Case WHERE Id = :caseId LIMIT 1];
        return new Map<String, String>{
            'body' => c.Reponse_Brouillon__c
        };
    }

    @AuraEnabled
    public static void triggerAgent(String caseId) {
        // Optionnel : on vide le champ avant de lancer pour être sûr que le LWC détecte le changement
        update new Case(Id = caseId, Reponse_Brouillon__c = '');
        
        Map<String, Object> params = new Map<String, Object>{ 'recordId' => caseId };
        Flow.Interview.createInterview('Agent_Update_Case_Fields', params).start();
    }

    @AuraEnabled
    public static void sendEmail(String caseId, String body) {
        Case c = [SELECT ContactId FROM Case WHERE Id = :caseId LIMIT 1];
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(c.ContactId);
        mail.setHtmlBody(body);
        mail.setSubject('Réponse à votre demande');
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        // On peut marquer le Case comme fermé ou ajouter un flag ici si besoin
    }
}