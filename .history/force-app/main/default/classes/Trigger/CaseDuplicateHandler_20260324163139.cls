public with sharing class CaseDuplicateHandler {

    public static void checkForDuplicates(List<Case> newCases) {

        Set<String> contactEmails = new Set<String>();
        for (Case c : newCases) {
            if (c.ContactEmail != null) {
                contactEmails.add(c.ContactEmail);
            }
        }

        if (contactEmails.isEmpty()) {
            return;
        }

        // Vérifie l'accès CRUD avant SOQL
        if (!Schema.sObjectType.Case.isAccessible()) {
            return;
        }

        List<Case> existingCases = [SELECT Id, Subject, Description
                                    FROM Case
                                    WHERE ContactEmail IN :contactEmails
                                      AND Status != 'Closed'];

        for (Case newC : newCases) {
            if (newC.ContactEmail == null) {
                continue;
            }

            Boolean isDuplicate = false;
            Id existingCaseId;

            for (Case oldC : existingCases) {
                String summaryNew = (newC.Subject != null ? newC.Subject : '') + ' ' + 
                                    (newC.Description != null ? newC.Description : '');
                String summaryOld = (oldC.Subject != null ? oldC.Subject : '') + ' ' + 
                                    (oldC.Description != null ? oldC.Description : '');

                if (areSimilar(summaryNew, summaryOld)) {
                    isDuplicate = true;
                    existingCaseId = oldC.Id;
                    break;
                }
            }

            if (isDuplicate) {
                newC.addError(
                    'Un cas similaire a déjà été ouvert pour ce problème.' +
                    ' Sujet existant : "' + getExistingCaseSubject(existingCaseId) + '"'
                );
            }
        }
    }

    private static Boolean areSimilar(String a, String b) {
        a = a != null ? a.toLowerCase() : '';
        b = b != null ? b.toLowerCase() : '';
        Set<String> wordsA = new Set<String>(a.split('\\s'));
        Set<String> wordsB = new Set<String>(b.split('\\s'));
        Integer common = 0;
        for (String w : wordsA) {
            if (wordsB.contains(w)) {
                common++;
            }
        }
        Double similarity = wordsA.size() > 0 ? (Double) common / (Double) wordsA.size() : 0.0;
        return similarity >= 0.7;
    }

    private static String getExistingCaseSubject(Id caseId) {
        // Vérifie les droits CRUD avant SOQL
        if (!Schema.sObjectType.Case.fields.Subject.isAccessible()) {
            return '';
        }
        Case c = [SELECT Subject FROM Case WHERE Id = :caseId LIMIT 1];
        return c.Subject != null ? c.Subject : '';
    }
}