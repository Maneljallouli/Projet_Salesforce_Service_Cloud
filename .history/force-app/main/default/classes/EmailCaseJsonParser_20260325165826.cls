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
        @InvocableVariable public String errorMessage;
    }

    @InvocableMethod(label='Parse Agentforce JSON Response')
    public static List<Output> parse(List<Input> inputs) {
        List<Output> results = new List<Output>();

        for (Input i : inputs) {
            Output out = new Output();
            try {
                String raw = i.jsonResponse;

                if (String.isBlank(raw)) {
                    throw new IllegalArgumentException('Empty JSON response');
                }

                raw = raw.trim();
                raw = raw.replace('```json', '').replace('```', '').trim();
                raw = raw.replaceAll('\\u00A0', ' ');
                raw = raw.replaceAll('[\\u00A0\\u2007\\u202F]', ' ');
                raw = raw.replaceAll('(?m)^\\s+', '');  
                System.debug('RAW cleaned: ' + raw);

                Map<String,Object> parsed =
                    (Map<String,Object>) JSON.deserializeUntyped(raw);

                out.category    = (String) parsed.get('category');
                out.subcategory = (String) parsed.get('subcategory');
                out.priority    = (String) parsed.get('priority');
                out.summary     = (String) parsed.get('summary');

                if (parsed.containsKey('confidence') && parsed.get('confidence') != null) {
                    out.confidence = Decimal.valueOf(
                        String.valueOf(parsed.get('confidence'))
                    );
                }

                out.success = true;

            } catch (Exception e) {
                out.success      = false;
                out.errorMessage = e.getMessage();
                System.debug('Parse error: ' + e.getTypeName() + ' — ' + e.getMessage());
            }

            results.add(out);
        }

        return results;
    }
}