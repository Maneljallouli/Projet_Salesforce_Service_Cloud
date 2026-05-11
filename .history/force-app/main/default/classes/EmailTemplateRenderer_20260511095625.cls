public class EmailTemplateRenderer {
    
    @InvocableMethod(label='Render Template Content')
    public static List<String> renderTemplate(List<Request> inputs) {
        List<String> results = new List<String>();
        
        for (Request req : inputs) {
            // 1 — Récupération des données du Case (Ajout de Subcategory__c)
            Case c = [SELECT Id, CaseNumber, Contact.Name, Subcategory__c,
                             Order_number__c, Date_d_achat__c
                      FROM Case 
                      WHERE Id = :req.caseId 
                      LIMIT 1];
            
            String html;

            // 2 — Logique de "Force Content" basée sur la sous-catégorie
            if (c.Subcategory__c == 'Comment faire un retour') {
                html = 'Bonjour {{Case.Contact}},<br/>' +
                       'Merci de nous avoir contacté concernant votre demande de retour.<br/>' +
                       'Voici la procédure à suivre pour effectuer votre retour :<br/><br/>' +
                       '📋 Connectez-vous à votre espace client<br/>' +
                       '📦 Allez dans "Mes commandes" et sélectionnez l\'article concerné<br/>' +
                       '🔄 Cliquez sur "Demander un retour"<br/>' +
                       '🖨️ Imprimez l\'étiquette de retour générée automatiquement<br/>' +
                       '📬 Déposez le colis dans un point relais sous 14 jours<br/><br/>' +
                       'Commande concernée : {{Case.Order_number__c}}<br/>' +
                       'Délai de remboursement : 5 à 7 jours ouvrés après réception<br/><br/>' +
                       'En cas de difficulté, notre équipe reste disponible.<br/>' +
                       'Cordialement,<br/>' +
                       'L\'équipe Service Client<br/>' +
                       'Référence dossier : #{{Case.CaseNumber}}';
            } else {
                html = req.htmlBody;
            }

            if (html == null) { results.add(''); continue; }

            // 3 — Remplacements dynamiques
            
            // Contact
            String contactName = (c.Contact != null && c.Contact.Name != null) ? c.Contact.Name : 'Cher(ère) client(e)';
            html = html.replace('{{Case.Contact}}', contactName).replace('{{{Case.Contact}}}', contactName);

            // Order Number (Optionnel)
            String orderDisplay = (c.Order_number__c != null) ? c.Order_number__c : 'votre commande';
            html = html.replace('{{Case.Order_number__c}}', orderDisplay).replace('{{{Case.Order_number__c}}}', orderDisplay);

            // Date d'achat
            String dateDisplay = (c.Date_d_achat__c != null) ? c.Date_d_achat__c.format() : '[Date non précisée]';
            html = html.replace('{{Case.Date_d_achat__c}}', dateDisplay).replace('{{{Case.Date_d_achat__c}}}', dateDisplay);

            // 4 — Fusion finale pour le CaseNumber et formatage propre
            try {
                Messaging.RenderEmailTemplateBodyResult res = 
                    Messaging.renderEmailTemplate(null, req.caseId, new List<String>{html})[0];
                results.add(res.getMergedBody());
            } catch (Exception e) {
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