public class EmailTemplateRenderer {

    @InvocableMethod(label='Render Template Content')
    public static List<String> renderTemplate(List<Request> inputs) {
        List<String> results = new List<String>();

        for (Request req : inputs) {

            Case c = [
                SELECT Id, CaseNumber,
                       Contact.FirstName, Contact.Name,
                       Order_number__c,
                       Date_d_achat__c
                FROM Case
                WHERE Id = :req.caseId
                LIMIT 1
            ];

            String templateName = req.templateName != null
                ? req.templateName.toLowerCase() : '';

            String body = '';

            // ─── SUIVI DE COMMANDE ────────────────────────────────────
            if (templateName.contains('shipping') ||
                templateName.contains('suivi') ||
                templateName.contains('delayed') ||
                templateName.contains('delivery')) {

                body  = 'Bonjour ' + contactName(c) + ',\n\n';
                body += 'Merci de nous avoir contacté. Nous avons bien reçu ';
                body += 'votre demande concernant le suivi de votre commande.\n\n';
                body += 'Voici les informations relatives à votre commande :\n\n';
                body += '📦 Numéro de commande : ' + val(c.Order_number__c) + '\n';
                body += '📅 Date de commande : '   + formatDate(c.Date_d_achat__c) + '\n';
                body += '🚚 Statut : En cours de livraison\n\n';
                body += 'N\'hésitez pas à nous recontacter si vous avez d\'autres questions.\n\n';
                body += 'Cordialement,\nL\'équipe Service Client\n';
                body += 'Référence dossier : #' + val(c.CaseNumber);
            }

            // ─── RETOUR ───────────────────────────────────────────────
            else if (templateName.contains('return') ||
                     templateName.contains('retour')) {

                body  = 'Bonjour ' + contactName(c) + ',\n\n';
                body += 'Merci de nous avoir contacté concernant votre demande de retour.\n\n';
                body += 'Voici la procédure à suivre pour effectuer votre retour :\n\n';
                body += '1. 📋 Connectez-vous à votre espace client\n';
                body += '2. 📦 Allez dans "Mes commandes" et sélectionnez l\'article concerné\n';
                body += '3. 🔄 Cliquez sur "Demander un retour"\n';
                body += '4. 🖨️ Imprimez l\'étiquette de retour générée automatiquement\n';
                body += '5. 📬 Déposez le colis dans un point relais sous 14 jours\n\n';
                body += 'Commande concernée : ' + val(c.Order_number__c) + '\n';
                body += 'Délai de remboursement : 5 à 7 jours ouvrés après réception\n\n';
                body += 'En cas de difficulté, notre équipe reste disponible.\n\n';
                body += 'Cordialement,\nL\'équipe Service Client\n';
                body += 'Référence dossier : #' + val(c.CaseNumber);
            }

            // ─── FALLBACK ─────────────────────────────────────────────
            else {
                body  = 'Bonjour ' + contactName(c) + ',\n\n';
                body += 'Merci de nous avoir contacté.\n\n';
                body += 'Notre équipe va traiter votre demande dans les plus brefs délais.\n\n';
                body += 'Cordialement,\nL\'équipe Service Client\n';
                body += 'Référence dossier : #' + val(c.CaseNumber);
            }

            results.add(body);
        }

        return results;
    }

    // ─── UTILS ────────────────────────────────────────────────────────

    private static String contactName(Case c) {
        if (c.Contact != null && String.isNotBlank(c.Contact.FirstName))
            return c.Contact.FirstName;
        if (c.Contact != null && String.isNotBlank(c.Contact.Name))
            return c.Contact.Name;
        return 'Client';
    }

    private static String val(Object o) {
        return o != null ? String.valueOf(o) : 'N/A';
    }

    private static String formatDate(Date d) {
        if (d == null) return 'N/A';
        return d.day() + '/' + d.month() + '/' + d.year();
    }

    // ─── CLASSES ──────────────────────────────────────────────────────

    public class Request {
        @InvocableVariable(required=true)  public String caseId;
        @InvocableVariable(required=true)  public String templateName;
        @InvocableVariable(required=false) public String htmlBody;
    }
}