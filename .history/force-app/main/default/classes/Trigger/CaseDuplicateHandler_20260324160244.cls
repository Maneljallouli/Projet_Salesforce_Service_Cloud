public with sharing class CaseDuplicateHandler {

    public static void checkForDuplicates(List<Case> newCases) {
        // 1. Récupérer les contacts
        Set<Id> contactIds = new Set<Id>();
        for (Case c : newCases) {
            if (c.Origin == 'Email' && c.ContactId != null) {
                contactIds.add(c.ContactId);
            }
        }
        if (contactIds.isEmpty()) return;

        // 2. Vérifier les permissions CRUD
        if (!Schema.sObjectType.Case.isAccessible()) return;

        // 3. Récupérer les cases récents
        List<Case> recentCases = [
            SELECT Id, Subject, Description, ContactId
            FROM Case
            WHERE ContactId IN :contactIds
              AND CreatedDate = LAST_N_DAYS:30
              AND Origin = 'Email'
        ];

        // 4. Comparer les textes pour trouver doublons
        for (Case newCase : newCases) {
            for (Case oldCase : recentCases) {
                if (oldCase.ContactId == newCase.ContactId &&
                    calculateSimilarity(newCase.Subject + newCase.Description,
                                        oldCase.Subject + oldCase.Description) > 0.8) {
                    newCase.addError('Un cas similaire existe déjà : ' + oldCase.CaseNumber);
                }
            }
        }
    }

    private static Decimal calculateSimilarity(String text1, String text2) {
        // simple: proportion de mots communs
        Set<String> words1 = new Set<String>(text1.toLowerCase().split('\\s+'));
        Set<String> words2 = new Set<String>(text2.toLowerCase().split('\\s+'));
        Set<String> intersection = new Set<String>();
        intersection.addAll(words1);
        intersection.retainAll(words2);
        return (words1.size() > 0) ? (Decimal)intersection.size() / words1.size() : 0;
    }
}