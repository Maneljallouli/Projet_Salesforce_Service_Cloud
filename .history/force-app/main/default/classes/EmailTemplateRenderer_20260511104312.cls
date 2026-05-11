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

            String body = req.htmlBody != null ? req.htmlBody : '';

            // ─── Remplacement des variables ───────────────────────────
            String contactName = '';
            if (c.Contact != null && String.isNotBlank(c.Contact.FirstName)) {
                contactName = c.Contact.FirstName;
            } else if (c.Contact != null && String.isNotBlank(c.Contact.Name)) {
                contactName = c.Contact.Name;
            } else {
                contactName = 'Client';
            }

            String orderNumber = c.Order_number__c != null
                ? c.Order_number__c : 'N/A';

            String dateAchat = c.Date_d_achat__c != null
                ? c.Date_d_achat__c.day() + '/'
                + c.Date_d_achat__c.month() + '/'
                + c.Date_d_achat__c.year()
                : 'N/A';

            String caseNumber = c.CaseNumber != null ? c.CaseNumber : '';

            // ─── Remplacements ────────────────────────────────────────
            body = body.replace('{{Case.Contact}}',          contactName);
            body = body.replace('{{Case.Order_number__c}}',  orderNumber);
            body = body.replace('{{Case.Date_d_achat__c}}',  dateAchat);
            body = body.replace('{{Case.CaseNumber}}',       caseNumber);

            // ─── Nettoyage HTML → texte lisible ──────────────────────
            body = body.replace('<br />',  '\n');
            body = body.replace('<br/>',   '\n');
            body = body.replace('<br>',    '\n');
            body = body.replace('</p>',   '\n');
            body = body.replace('</li>',  '\n');
            body = body.replace('</ol>',  '\n');
            body = body.replace('</ul>',  '\n');
            body = body.replace('<strong>', '');
            body = body.replace('</strong>','');
            body = body.replace('&nbsp;',  ' ');
            body = body.replaceAll('<[^>]+>', '');
            body = body.replaceAll('(?m)^\\s+', '');
            body = body.replaceAll('\n{3,}', '\n\n').trim();

            results.add(body);
        }

        return results;
    }

    public class Request {
        @InvocableVariable(required=true)  public String caseId;
        @InvocableVariable(required=true)  public String htmlBody;
    }
}