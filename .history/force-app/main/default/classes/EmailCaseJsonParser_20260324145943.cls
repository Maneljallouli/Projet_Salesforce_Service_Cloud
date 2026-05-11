public class EmailCaseJsonParser {

    public class Input {
        @InvocableVariable(required=true)
        public String jsonResponse;
    }

    public class Output {
        @InvocableVariable public String category;
        @InvocableVariable public String subcategory;
        @InvocableVariable public String priority;
        @InvocableVariable public String summary;
        @InvocableVariable public Decimal confidence;
        @InvocableVariable public Boolean success;
    }

    @InvocableMethod(label='Parse Agentforce JSON Response')
    public static List<Output> parse(List<Input> inputs) {

        List<Output> results = new List<Output>();

        for (Input i : inputs) {

            Output out = new Output();

            try {

                String raw = i.jsonResponse;

                if (String.isBlank(raw)) {
                    throw new AuraHandledException('Empty JSON response');
                }

                // 🔥 Nettoyage ULTRA IMPORTANT
                raw = raw.trim();
                raw = raw.replace('```json', '');
                raw = raw.replace('```', '');

                // 🔥 enlever caractères invisibles
                raw = raw.replace('\n', '');
                raw = raw.replace('\r', '');
                raw = raw.replace('\t', '');

                // 🔥 sécuriser JSON (très important)
                Integer start = raw.indexOf('{');
                Integer end   = raw.lastIndexOf('}');

                if (start == -1 || end == -1) {
                    throw new AuraHandledException('Invalid JSON format');
                }

                raw = raw.substring(start, end + 1);

                System.debug('CLEAN JSON => ' + raw);

                Map<String,Object> parsed =
                    (Map<String,Object>) JSON.deserializeUntyped(raw);

                out.category    = (String) parsed.get('category');
                out.subcategory = (String) parsed.get('subcategory');
                out.priority    = (String) parsed.get('priority');
                out.summary     = (String) parsed.get('summary');

                if (parsed.containsKey('confidence') && parsed.get('confidence') != null) {
                    out.confidence = Decimal.valueOf(String.valueOf(parsed.get('confidence')));
                }

                out.success = true;

            } catch (Exception e) {

                out.success = false;
                System.debug('❌ PARSE ERROR: ' + e.getMessage());
                System.debug('❌ RAW INPUT: ' + i.jsonResponse);

            }

            results.add(out);
        }

        return results;
    }
}