public with sharing class CaseDuplicateHandler {

    public static void checkForDuplicates(List<Case> newCases) {
        Set<String> contactEmails = collectContactEmails(newCases);
        if (contactEmails.isEmpty()) {
            return;
        }

        List<Case> existingCases = fetchExistingCases(contactEmails);

        for (Case c : newCases) {
            processDuplicateCheck(c, existingCases);
        }
    }

    private static Set<String> collectContactEmails(List<Case> cases) {
        Set<String> emails = new Set<String>();
        for (Case c : cases) {
            if (c.ContactEmail != null) {
                emails.add(c.ContactEmail);
            }
        }
        return emails;
    }

    private static List<Case> fetchExistingCases(Set<String> emails) {
        if (!Schema.sObjectType.Case.isAccessible()) {
            return new List<Case>();
        }

        return [SELECT Id, Subject, Description
                FROM Case
                WHERE ContactEmail IN :emails
                  AND Status != 'Closed'];
    }

    private static void processDuplicateCheck(Case newC, List<Case> existingCases) {
        if (newC.ContactEmail == null) {
            return;
        }

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

    private static Boolean isSimilar(Case a, Case b) {
        String textA = (a.Subject != null ? a.Subject : '') + ' ' + (a.Description != null ? a.Description : '');
        String textB = (b.Subject != null ? b.Subject : '') + ' ' + (b.Description != null ? b.Description : '');
        return computeSimilarity(textA, textB) >= 0.7;
    }

    private static Double computeSimilarity(String a, String b) {
        a = a.toLowerCase();
        b = b.toLowerCase();
        Set<String> wordsA = new Set<String>(a.split('\\s'));
        Set<String> wordsB = new Set<String>(b.split('\\s'));
        Integer common = 0;
        for (String w : wordsA) {
            if (wordsB.contains(w)) {
                common++;
            }
        }
        if (wordsA.size() > 0) {
            return (Double)common / (Double)wordsA.size();
        } else {
            return 0.0;
        }
    }

    private static String safeGetSubject(Id caseId) {
        if (!Schema.sObjectType.Case.fields.Subject.isAccessible()) {
            return '';
        }

        Case c = [SELECT Subject FROM Case WHERE Id = :caseId LIMIT 1];
        if (c.Subject != null) {
            return c.Subject;
        } else {
            return '';
        }
    }
}