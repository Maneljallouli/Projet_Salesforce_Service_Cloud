public with sharing class CaseDuplicateHandler {

    public static void checkForDuplicates(List<Case> newCases) {
        if (newCases.isEmpty()) return;

        // Collecter ContactIds des nouveaux cas
        Set<Id> contactIds = new Set<Id>();
        for (Case c : newCases) {
            if (c.ContactId != null) {
                contactIds.add(c.ContactId);
            }
        }

        if (contactIds.isEmpty()) return;

        // Vérifier que l'utilisateur peut lire Case
        if (!Schema.sObjectType.Case.isAccessible()) return;

        // Récupérer les cases existants ouverts pour ces contacts
        List<Case> existingCases = [
            SELECT Id, Subject, Description, ContactId, Status
            FROM Case
            WHERE ContactId IN :contactIds
            AND Status != 'Closed'
        ];

        for (Case newCase : newCases) {
            for (Case exist : existingCases) {
                // Comparaison basique : si le sujet est similaire ou description proche
                if (isSimilar(newCase, exist)) {
                    // Vérifier updateable avant addError
                    if (Schema.sObjectType.Case.isUpdateable()) {
                        newCase.addError('Un cas similaire existe déjà pour ce client.');
                    }
                }
            }
        }
    }

    private static Boolean isSimilar(Case a, Case b) {
        // Comparaison simplifiée, peut être améliorée avec une librairie de similarité
        if (a.Subject != null && b.Subject != null) {
            Double similarity = stringSimilarity(a.Subject, b.Subject);
            return similarity >= 0.7;
        }
        return false;
    }

    private static Double stringSimilarity(String s1, String s2) {
        // Méthode très simple : proportion de mots communs
        Set<String> words1 = new Set<String>(s1.toLowerCase().split('\\s+'));
        Set<String> words2 = new Set<String>(s2.toLowerCase().split('\\s+'));
        Integer common = 0;
        for (String w : words1) if (words2.contains(w)) common++;
        Integer total = Math.max(words1.size(), words2.size());
        return total > 0 ? ((Double) common / total) : 0.0;
    }
}