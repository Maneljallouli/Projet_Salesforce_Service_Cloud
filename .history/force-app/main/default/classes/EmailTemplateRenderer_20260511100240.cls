public class EmailTemplateRenderer {
    @InvocableMethod(label='Render Template Content')
    public static List<String> renderTemplate(List<Request> inputs) {
        List<String> results = new List<String>();
        for (Request req : inputs) {
            // Version simplifiée : On teste si l'Apex répond au moins quelque chose
            Case c = [SELECT Id, CaseNumber, Contact.Name, Subcategory__c FROM Case WHERE Id = :req.caseId LIMIT 1];
            
            String monTexte = 'Bonjour ' + (c.Contact.Name != null ? c.Contact.Name : 'Client') + ',\n\n';
            monTexte += 'Ceci est un test pour le dossier #' + c.CaseNumber + '.\n';
            monTexte += 'Sous-catégorie détectée : ' + c.Subcategory__c;
            
            results.add(monTexte);
        }
        return results;
    }
    public class Request {
        @InvocableVariable(required=true) public String caseId;
        @InvocableVariable(required=true) public String htmlBody;
    }
}