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
    public static void sendEmail(String caseId, String body, String toAddress, String ccAddress, String subject) {
        // On récupère toujours le ContactId pour le lier à l'activité de l'email
        Case c = [SELECT ContactId FROM Case WHERE Id = :caseId LIMIT 1];
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        // Configuration des destinataires
        mail.setToAddresses(new List<String>{ toAddress });
        
        if (String.isNotBlank(ccAddress)) {
            mail.setCcAddresses(new List<String>{ ccAddress });
        }
        
        // Configuration du contenu
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        
        // Optionnel : Lie l'email au contact et au Case dans l'historique
        if (c.ContactId != null) {
            mail.setTargetObjectId(c.ContactId);
        }
        mail.setWhatId(caseId); 
        mail.setSaveAsActivity(true); // Pour que l'email apparaisse dans la timeline "Activity"
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }
}