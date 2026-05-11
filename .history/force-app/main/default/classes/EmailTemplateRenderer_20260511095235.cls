public class EmailTemplateRenderer {
    
    @InvocableMethod(label='Render Template Content')
    public static List<String> renderTemplate(List<Request> inputs) {
        List<String> results = new List<String>();
        
        for (Request req : inputs) {
            // 1 — On récupère les données avec sécurité
            Case c = [SELECT Id, CaseNumber, Contact.Name, 
                             Order_number__c, Date_d_achat__c
                      FROM Case 
                      WHERE Id = :req.caseId 
                      LIMIT 1];
            
            String html = req.htmlBody;
            if (html == null) {
                results.add('Erreur : Corps du template vide.');
                continue;
            }

            // 2 — Remplacements manuels (Case Sensitive & Null Check)
            
            // Contact
            String contactName = (c.Contact != null && c.Contact.Name != null) ? c.Contact.Name : 'Cher(ère) client(e)';
            html = html.replace('{{Case.Contact}}', contactName)
                       .replace('{{{Case.Contact}}}', contactName);

            // Order Number
            String orderNum = (c.Order_number__c != null) ? c.Order_number__c : '[Non renseigné]';
            html = html.replace('{{Case.Order_number__c}}', orderNum)
                       .replace('{{{Case.Order_number__c}}}', orderNum);

            // Date d'achat
            String dateAchat = (c.Date_d_achat__c != null) ? 
                               c.Date_d_achat__c.format() : '[Non renseignée]';
            html = html.replace('{{Case.Date_d_achat__c}}', dateAchat)
                       .replace('{{{Case.Date_d_achat__c}}}', dateAchat);

            // 3 — Fusion finale (CaseNumber est géré ici nativement par Salesforce)
            try {
                Messaging.RenderEmailTemplateBodyResult res = 
                    Messaging.renderEmailTemplate(null, req.caseId, new List<String>{html})[0];
                results.add(res.getMergedBody());
            } catch (Exception e) {
                // Si la fusion standard échoue, on renvoie quand même le HTML déjà partiellement rempli
                results.add(html);
            }
        }
        return results;
    }
    
    public class Request {
        @InvocableVariable(required=true) public String caseId;
        @InvocableVariable(required=true) public String htmlBody;
    }
}