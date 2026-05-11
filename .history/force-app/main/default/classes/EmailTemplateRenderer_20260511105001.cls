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

            // ─── Remplacements manuels (champs custom non gérés par Salesforce) ───
            String contactName = '';
            if (c.Contact != null && String.isNotBlank(c.Contact.FirstName)) {
                contactName = c.Contact.FirstName;
            } else if (c.Contact != null && String.isNotBlank(c.Contact.Name)) {
                contactName = c.Contact.Name;
            } else {
                contactName = 'Client';
            }

            String orderNum = String.isNotBlank(c.Order_number__c)
                ? c.Order_number__c : '[Non renseigné]';

            String dateAchat = c.Date_d_achat__c != null
                ? c.Date_d_achat__c.format() : '[Non renseignée]';

            html = html.replace('{{Case.Contact}}',         contactName);
            html = html.replace('{{{Case.Contact}}}',       contactName);
            html = html.replace('{{Case.Order_number__c}}', orderNum);
            html = html.replace('{{{Case.Order_number__c}}}', orderNum);
            html = html.replace('{{Case.Date_d_achat__c}}', dateAchat);
            html = html.replace('{{{Case.Date_d_achat__c}}}', dateAchat);

            // ─── renderEmailTemplate gère CaseNumber et autres champs standard ───
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
                // Fallback : retourner le HTML avec remplacements manuels uniquement
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