public class EmailTemplateRenderer {
    
    @InvocableMethod(label='Render Template Content')
    public static List<String> renderTemplate(List<Request> inputs) {
        List<String> results = new List<String>();
        
        for (Request req : inputs) {
            // 1 — Récupération des données spécifiques du Case
            Case c = [SELECT Id, CaseNumber, Contact.Name, 
                             Order_number__c, Date_d_achat__c
                      FROM Case 
                      WHERE Id = :req.caseId 
                      LIMIT 1];
            
            String html = req.htmlBody;

            // 2 — Remplacement manuel des champs personnalisés
            // Note : On utilise .replace() pour gérer les balises {{ }} ou {{{ }}}
            
            // Gestion du Contact (Prénom/Nom)
            String contactName = (c.Contact.Name != null) ? c.Contact.Name : 'Cher(ère) client(e)';
            html = html.replace('{{Case.Contact}}', contactName);
            html = html.replace('{{{Case.Contact}}}', contactName);

            // Gestion du Numéro de commande
            String orderNum = (c.Order_number__c != null) ? c.Order_number__c : '[Non renseigné]';
            html = html.replace('{{Case.Order_number__c}}', orderNum);
            html = html.replace('{{{Case.Order_number__c}}}', orderNum);

            // Gestion de la Date d'achat (Formatage JJ/MM/AAAA)
            String dateAchat = (c.Date_d_achat__c != null) ? 
                               c.Date_d_achat__c.format() : '[Non renseignée]';
            html = html.replace('{{Case.Date_d_achat__c}}', dateAchat);
            html = html.replace('{{{Case.Date_d_achat__c}}}', dateAchat);

            // 3 — Utilisation de la méthode standard pour les champs de base (comme CaseNumber)
            // Cela gère aussi les éventuels merge fields restants proprement.
            Messaging.RenderEmailTemplateBodyResult res = 
                Messaging.renderEmailTemplate(null, req.caseId, new List<String>{html})[0];
            
            results.add(res.getMergedBody());
        }
        return results;
    }
    
    public class Request {
        @InvocableVariable(required=true) public String caseId;
        @InvocableVariable(required=true) public String htmlBody;
    }
}