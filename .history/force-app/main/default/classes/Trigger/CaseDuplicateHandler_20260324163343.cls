public with sharing class CaseDuplicateHandler {

    public static void checkForDuplicates(List<Case> newCases) {
        Set<String> contactEmails = collectContactEmails(newCases);
        if (contactEmails.isEmpty()) return;

        List<Case> existingCases = fetchExistingCases(contactEmails);

        for (Case c : newCases) {
            processDuplicateCheck(c, existingCases);
        }
    }

    // Collecte les emails valides
    private static Set<String> collectContactEmails(List<Case> cases) {
        Set<String> emails = new Set<String>();
        for (Case c : cases) {
            if (c.ContactEmail != null) {
                emails.add(c.ContactEmail);
            }
        }
        return emails;
    }

    // Récupère les cas existants pour ces emails
    private static List<Case> fetchExistingCases(Set<String> emails) {
        if (!Schema.sObjectType.Case.isAccessible()) return new List<Case>();
        return [SELECT Id, Subject, Description
                FROM Case
                WHERE ContactEmail IN :emails
                  AND Status != 'Closed'];
    }

    // Vérifie si un cas est un doublon et ajoute un message d'erreur si besoin
    private static void processDuplicateCheck(Case newC, List<Case> existingCases) {
        if (newC.ContactEmail == null) return;

        for (Case oldC : existingCases) {
            if (isSimilar(newC, oldC)) {
                newC.addError(
                    'Un cas similaire a déjà été ouvert pour ce problème. ' +
                    'Sujet existant : "' + safeGetSubject(oldC.Id) + '"'
                );
                break;
            }
        }
    }

    // Compare deux cas pour détecter un doublon
    private static Boolean isSimilar(Case a, Case b) {
        String textA = (a.Subject != null ? a.Subject : '') + ' ' + (a.Description != null ? a.Description : '');
        String textB = (b.Subject != null ? b.Subject : '') + ' ' + (b.Description != null ? b.Description : '');
        return computeSimilarity(textA, textB) >= 0.7;
    }

    // Calcul simplifié de similarité
    private static Double computeSimilarity(String a, String b) {
        a = a.toLowerCase();
        b = b.toLowerCase();
        Set<String> wordsA = new Set<String>(a.split('\\s'));
        Set<String> wordsB = new Set<String>(b.split('\\s'));
        Integer common = 0;
        for (String w : wordsA) {
            if (wordsB.contains(w)) common++;
        }
        return wordsA.size() > 0 ? (Double)common / (Double)wordsA.size() : 0.0;
    }

    // Récupère le sujet d'un cas existant de manière sécurisée
    private static String safeGetSubject(Id caseId) {
        if (!Schema.sObjectType.Case.fields.Subject.isAccessible()) return '';
        Case c = [SELECT Subject FROM Case WHERE Id = :caseId LIMIT 1];
        return c.Subject != null ? c.Subject : '';
    }
}