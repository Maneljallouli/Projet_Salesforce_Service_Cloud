public class EmailTemplateRenderer {
    
    @InvocableMethod(label='Render Template Content')
    public static List<String> renderTemplate(List<Request> inputs) {
        List<String> results = new List<String>();
        
        for (Request req : inputs) {
            // 1 — Récupération du Case avec tous les champs nécessaires
            Case c = [SELECT Id, CaseNumber, Contact.Name, Subcategory__c,
                             Order_number__c, Date_d_achat__c
                      FROM Case 
                      WHERE Id = :req.caseId 
                      LIMIT 1];
            
            System.debug('### Debug Subcategory: ' + c.Subcategory__c);
            
            String html = '';

            // 2 — Logique Forcée par Sous-catégorie
            // On utilise .equalsIgnoreCase pour éviter les problèmes de majuscules/minuscules
            if (c.Subcategory__c != null && c.Subcategory__c.equalsIgnoreCase('Comment faire un retour')) {
                html = 'Bonjour {{Case.Contact}},\n\n' +
                       'Merci de nous avoir contacté concernant votre demande de retour.\n' +
                       'Voici la procédure à suivre pour effectuer votre retour :\n\n' +
                       '📋 Connectez-vous à votre espace client\n' +
                       '📦 Allez dans "Mes commandes" et sélectionnez l\'article concerné\n' +
                       '🔄 Cliquez sur "Demander un retour"\n' +
                       '🖨️ Imprimez l\'étiquette de retour générée automatiquement\n' +
                       '📬 Déposez le colis dans un point relais sous 14 jours\n\n' +
                       'Commande concernée : {{Case.Order_number__c}}\n' +
                       'Délai de remboursement : 5 à 7 jours ouvrés après réception\n\n' +
                       'En cas de difficulté, notre équipe reste disponible.\n\n' +
                       'Cordialement,\n' +
                       'L\'équipe Service Client\n' +
                       'Référence dossier : #{{Case.CaseNumber}}';
            } else {
                // Si ce n'est pas la sous-catégorie "Retour", on prend le template de l'IA
                html = req.htmlBody;
            }

            if (String.isBlank(html)) {
                results.add('Erreur : Aucun contenu généré.');
                continue;
            }

            // 3 — Remplacements Manuels
            String contactName = (c.Contact != null && c.Contact.Name != null) ? c.Contact.Name : 'Cher(ère) client(e)';
            html = html.replace('{{Case.Contact}}', contactName).replace('{{{Case.Contact}}}', contactName);

            String orderDisplay = (c.Order_number__c != null) ? c.Order_number__c : 'votre commande';
            html = html.replace('{{Case.Order_number__c}}', orderDisplay).replace('{{{Case.Order_number__c}}}', orderDisplay);

            // 4 — Fusion finale (CaseNumber)
            try {
                Messaging.RenderEmailTemplateBodyResult res = 
                    Messaging.renderEmailTemplate(null, req.caseId, new List<String>{html})[0];
                results.add(res.getMergedBody());
            } catch (Exception e) {
                System.debug('### Error Rendering: ' + e.getMessage());
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