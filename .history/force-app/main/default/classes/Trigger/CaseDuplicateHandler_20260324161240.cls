public with sharing class CaseDuplicateHandler {

    public static void checkForDuplicates(List<Case> newCases) {
        if (newCases.isEmpty()) {
            return;
        }
        Set<Id> contactIds = collectContactIds(newCases);
        if (contactIds.isEmpty()) {
            return;
        }

        List<Case> existingCases = fetchOpenCases(contactIds);
        markDuplicates(newCases, existingCases);
    }

    private static Set<Id> collectContactIds(List<Case> cases) {
        Set<Id> contactIds = new Set<Id>();
        for (Case c : cases) {
            if (c.ContactId != null) {
                contactIds.add(c.ContactId);
            }
        }
        return contactIds;
    }

    private static List<Case> fetchOpenCases(Set<Id> contactIds) {
        if (!Schema.sObjectType.Case.isAccessible()) {
            return new List<Case>();
        }
        return [SELECT Id, Subject, Description, ContactId, Status
                FROM Case
                WHERE ContactId IN :contactIds
                AND Status != 'Closed'];
    }

    private static void markDuplicates(List<Case> newCases, List<Case> existingCases) {
        for (Case newCase : newCases) {
            for (Case exist : existingCases) {
                if (isSimilar(newCase.Subject, exist.Subject)) {
                    if (Schema.sObjectType.Case.isUpdateable()) {
                        newCase.addError('Un cas similaire existe déjà pour ce client.');
                    }
                }
            }
        }
    }

    private static Boolean isSimilar(String s1, String s2) {
        if (s1 == null || s2 == null) {
            return false;
        }
        return computeSimilarity(s1, s2) >= 0.7;
    }

    private static Double computeSimilarity(String s1, String s2) {
        Set<String> words1 = new Set<String>(s1.toLowerCase().split('\\s+'));
        Set<String> words2 = new Set<String>(s2.toLowerCase().split('\\s+'));
        Integer common = 0;
        for (String w : words1) {
            if (words2.contains(w)) {
                common++;
            }
        }
        Integer total = Math.max(words1.size(), words2.size());
        return total > 0 ? ((Double) common / total) : 0.0;
    }
}