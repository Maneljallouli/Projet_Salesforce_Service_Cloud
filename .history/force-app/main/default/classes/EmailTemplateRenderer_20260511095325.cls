public class EmailTemplateRenderer {
    
    @InvocableMethod(label='Render Template Content')
    public static List<String> renderTemplate(List<Request> inputs) {
        List<String> results = new List<String>();
        
        for (Request req : inputs) {
            Case c = [SELECT Id, CaseNumber, Contact.Name, 
                             Order_number__c, Date_d_achat__c
                      FROM Case 
                      WHERE Id = :req.caseId 
                      LIMIT 1];
            
            String html = req.htmlBody;
            if (html == null) { 
                results.add(''); 
                continue; 
            }

            // 1 — Gestion du Contact (Cher client par défaut)
            String contactName = (c.Contact != null && c.Contact.Name != null) ? c.Contact.Name : 'Cher(ère) client(e)';
            html = html.replace('{{Case.Contact}}', contactName)
                       .replace('{{{Case.Contact}}}', contactName);

            // 2 — Gestion de l'Order Number (Optionnel)
            // Si vide, on met "votre commande" au lieu du numéro pour que la phrase reste jolie
            String orderDisplay = (c.Order_number__c != null) ? c.Order_number__c : 'votre commande';
            html = html.replace('{{Case.Order_number__c}}', orderDisplay)
                       .replace('{{{Case.Order_number__c}}}', orderDisplay);

            // 3 — Gestion de la Date d'achat (Optionnel)
            String dateDisplay = (c.Date_d_achat__c != null) ? c.Date_d_achat__c.format() : '[Date non précisée]';
            html = html.replace('{{Case.Date_d_achat__c}}', dateDisplay)
                       .replace('{{{Case.Date_d_achat__c}}}', dateDisplay);

            // 4 — Fusion finale via le moteur Salesforce
            try {
                Messaging.RenderEmailTemplateBodyResult res = 
                    Messaging.renderEmailTemplate(null, req.caseId, new List<String>{html})[0];
                results.add(res.getMergedBody());
            } catch (Exception e) {
                results.add(html); // Secours
            }
        }
        return results;
    }
    
    public class Request {
        @InvocableVariable(required=true) public String caseId;
        @InvocableVariable(required=true) public String htmlBody;
    }
}