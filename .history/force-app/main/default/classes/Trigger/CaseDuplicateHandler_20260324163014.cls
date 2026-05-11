public without sharing class CaseDuplicateHandler {

    public static void checkForDuplicates(List<Case> newCases) {

        // Collecte les emails des contacts des nouveaux cas
        Set<String> contactEmails = new Set<String>();
        for (Case c : newCases) {
            if (c.ContactEmail != null) {
                contactEmails.add(c.ContactEmail);
            }
        }

        if (contactEmails.isEmpty()) return;

        // Récupère les cases existants des mêmes contacts
        List<Case> existingCases = [
            SELECT Id, Subject, Description
            FROM Case
            WHERE ContactEmail IN :contactEmails
              AND Status != 'Closed'
        ];

        for (Case newC : newCases) {

            if (newC.ContactEmail == null) continue;

            Boolean isDuplicate = false;
            Id existingCaseId;

            for (Case oldC : existingCases) {

                // Comparaison sur le sujet exact ou résumé IA similaire (ici simple contains)
                String summaryNew = newC.Subject + ' ' + newC.Description;
                String summaryOld = oldC.Subject + ' ' + oldC.Description;

                // Comparaison de similarité simple (à améliorer)
                if (areSimilar(summaryNew, summaryOld)) {
                    isDuplicate = true;
                    existingCaseId = oldC.Id;
                    break;
                }
            }

            if (isDuplicate) {
                // Bloquer l'insertion
                newC.addError(
                    'Un cas similaire a déjà été ouvert pour ce problème.' +
                    ' Sujet existant : "' + getExistingCaseSubject(existingCaseId) + '"'
                );
            }
        }
    }

    // Méthode simple de comparaison (à remplacer par algo plus avancé si besoin)
    private static Boolean areSimilar(String a, String b) {
        a = a != null ? a.toLowerCase() : '';
        b = b != null ? b.toLowerCase() : '';
        Integer minLength = Math.min(a.length(), b.length());

        if (minLength == 0) return false;

        // Si plus de 70% des mots sont communs
        Set<String> wordsA = new Set<String>(a.split('\\s'));
        Set<String> wordsB = new Set<String>(b.split('\\s'));
        Integer common = 0;
        for (String w : wordsA) {
            if (wordsB.contains(w)) common++;
        }

        Double similarity = (Double) common / (Double) wordsA.size();
        return similarity >= 0.7;
    }

    private static String getExistingCaseSubject(Id caseId) {
        Case c = [SELECT Subject FROM Case WHERE Id = :caseId LIMIT 1];
        return c.Subject != null ? c.Subject : '';
    }
}