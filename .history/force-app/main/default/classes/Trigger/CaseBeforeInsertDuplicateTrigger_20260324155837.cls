trigger CaseBeforeInsertDuplicateTrigger on Case (before insert) {

    // Méthode utilitaire pour calculer la similarité textuelle
    Decimal similarity(String text1, String text2) {
        if (String.isBlank(text1) || String.isBlank(text2)) return 0;
        Set<String> words1 = new Set<String>(text1.toLowerCase().split('\\s+'));
        Set<String> words2 = new Set<String>(text2.toLowerCase().split('\\s+'));
        Set<String> intersection = new Set<String>();
        intersection.addAll(words1);
        intersection.retainAll(words2);
        return (words1.size() > 0) ? (Decimal)intersection.size() / words1.size() : 0;
    }

    // 1. Collecter les ContactId des nouveaux cases Email
    Set<Id> contactIds = new Set<Id>();
    for (Case c : Trigger.new) {
        if (c.Origin == 'Email' && c.ContactId != null) {
            contactIds.add(c.ContactId);
        }
    }

    if (!contactIds.isEmpty()) {

        // 2. Récupérer les cases récents pour ces contacts (dernier mois)
        Map<Id, List<Case>> recentCasesMap = new Map<Id, List<Case>>();
        for (Case oldCase : [
            SELECT Id, CaseNumber, Subject, Description
            FROM Case
            WHERE ContactId IN :contactIds
              AND CreatedDate = LAST_N_DAYS:30
              AND Origin = 'Email'
        ]) {
            if (!recentCasesMap.containsKey(oldCase.ContactId)) {
                recentCasesMap.put(oldCase.ContactId, new List<Case>());
            }
            recentCasesMap.get(oldCase.ContactId).add(oldCase);
        }

        // 3. Vérifier chaque nouveau Case contre les anciens
        for (Case newCase : Trigger.new) {
            if (recentCasesMap.containsKey(newCase.ContactId)) {
                for (Case oldCase : recentCasesMap.get(newCase.ContactId)) {
                    Decimal score = similarity(
                        newCase.Subject + ' ' + newCase.Description,
                        oldCase.Subject + ' ' + oldCase.Description
                    );
                    if (score >= 0.8) { // seuil configurable
                        newCase.addError('Un cas similaire existe déjà : ' + oldCase.CaseNumber);
                    }
                }
            }
        }
    }
}