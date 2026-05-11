public class CaseDuplicateHandler {

    public static void checkForDuplicates(List<Case> newCases) {
        Set<String> contactIds = new Set<String>();

        for (Case c : newCases) {
            if (c.ContactId != null) {
                contactIds.add(c.ContactId);
            }
        }

        if (!contactIds.isEmpty()) {
            List<Case> existingCases = [
                SELECT Id, Subject, Description, ContactId, CaseNumber
                FROM Case
                WHERE ContactId IN :contactIds
                AND Status != 'Closed'
            ];

            for (Case newCase : newCases) {
                for (Case oldCase : existingCases) {
                    // Calcul de similarité entre les emails / sujets
                    Decimal similarity = calculateSimilarity(
                        newCase.Subject + ' ' + newCase.Description,
                        oldCase.Subject + ' ' + oldCase.Description
                    );

                    if (similarity > 0.8) {
                        newCase.addError(
                            'Un cas similaire existe déjà : ' + oldCase.CaseNumber
                        );
                    }
                }
            }
        }
    }

    // Méthode simple pour calculer la similarité textuelle (placeholder)
    public static Decimal calculateSimilarity(String text1, String text2) {
        if (text1 == null || text2 == null) {
            return 0;
        }
        text1 = text1.toLowerCase().trim();
        text2 = text2.toLowerCase().trim();

        Set<String> words1 = new Set<String>();
        Set<String> words2 = new Set<String>();

        words1.addAll(text1.split('\\s+'));
        words2.addAll(text2.split('\\s+'));

        Set<String> intersection = new Set<String>();
        intersection.addAll(words1);
        intersection.retainAll(words2);

        if (words1.size() + words2.size() == 0) {
            return 0;
        }

        return (2.0 * intersection.size()) / (words1.size() + words2.size());
    }
}