public class EmailTemplateRenderer {

    @InvocableMethod(label='Render Template Content')
    public static List<String> renderTemplate(List<Request> inputs) {
        List<String> results = new List<String>();

        for (Request req : inputs) {

            Case c = [
                SELECT Id, CaseNumber, ContactId,
                       Contact.Name, Contact.FirstName,
                       Order_number__c, Date_d_achat__c
                FROM Case
                WHERE Id = :req.caseId
                LIMIT 1
            ];

            String html = req.htmlBody != null ? req.htmlBody : '';

            // ─── Contact ──────────────────────────────────────────────
            String contactName = '';
            if (c.Contact != null && String.isNotBlank(c.Contact.FirstName)) {
                contactName = c.Contact.FirstName;
            } else if (c.Contact != null && String.isNotBlank(c.Contact.Name)) {
                contactName = c.Contact.Name;
            } else {
                contactName = 'Client';
            }

            String orderNum  = c.Order_number__c != null ? c.Order_number__c : '';
            String dateAchat = c.Date_d_achat__c != null ? c.Date_d_achat__c.format() : '';
            String caseNum   = c.CaseNumber != null ? c.CaseNumber : '';

            // ─── Détection du type de template ───────────────────────
            Boolean isSuivi  = html.contains('suivi de votre commande') ||
                               html.contains('En cours de livraison');
            Boolean isRetour = html.contains('procédure') && 
                               html.contains('retour');

            // ─── FIX 1 : SUIVI — informations manquantes ─────────────
            if (isSuivi) {
                Boolean missingOrder = String.isBlank(orderNum);
                Boolean missingDate  = String.isBlank(dateAchat);

                if (missingOrder || missingDate) {
                    // Remplace le bloc infos par une demande au client
                    String missing = '';
                    if (missingOrder) missing += '- votre numéro de commande\n';
                    if (missingDate)  missing += '- la date de votre achat\n';

                    String demandeInfo =
                        '<p>Afin de vous aider au mieux, pourriez-vous nous communiquer :</p>' +
                        '<ul>' +
                        (missingOrder ? '<li>📦 Votre numéro de commande</li>' : '') +
                        (missingDate  ? '<li>📅 La date de votre achat</li>'   : '') +
                        '</ul>' +
                        '<p>Dès réception de ces informations, nous traiterons ' +
                        'votre demande dans les plus brefs délais.</p>';

                    // Remplace le bloc liste des infos commande
                    html = html.replaceAll(
                        '(?s)<ul>.*?🚚.*?</ul>',
                        demandeInfo
                    );
                } else {
                    html = html.replace('{{Case.Order_number__c}}', orderNum);
                    html = html.replace('{{Case.Date_d_achat__c}}', dateAchat);
                }
            }

            // ─── FIX 2 : RETOUR — masquer ligne commande si vide ─────
            if (isRetour) {
                if (String.isBlank(orderNum)) {
                    // Supprime la ligne "Commande concernée"
                    html = html.replaceAll(
                        '(?s)<p><strong>Commande concern.*?</p>',
                        ''
                    );
                } else {
                    html = html.replace('{{Case.Order_number__c}}', orderNum);
                }
            }

            // ─── Remplacements communs ────────────────────────────────
            html = html.replace('{{Case.Contact}}',         contactName);
            html = html.replace('{{{Case.Contact}}}',       contactName);
            html = html.replace('{{Case.Order_number__c}}', orderNum);
            html = html.replace('{{Case.Date_d_achat__c}}', dateAchat);
            html = html.replace('{{Case.CaseNumber}}',      caseNum);
            html = html.replace('{{{Case.CaseNumber}}}',    caseNum);

            // ─── renderEmailTemplate pour les merge fields restants ───
            try {
                Messaging.RenderEmailTemplateBodyResult res =
                    Messaging.renderEmailTemplate(
                        c.ContactId,
                        req.caseId,
                        new List<String>{ html }
                    )[0];

                String merged = res.getMergedBody();
                results.add(String.isNotBlank(merged) ? merged : html);

            } catch (Exception e) {
                System.debug('⚠️ renderEmailTemplate error: ' + e.getMessage());
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