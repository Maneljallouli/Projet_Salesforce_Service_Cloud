public without sharing class ChatController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getComments(Id caseId) {

        if (caseId == null) {
            throw new AuraHandledException('CaseId manquant.');
        }

        List<Map<String, String>> result = new List<Map<String, String>>();

        try {
            List<CaseComment> comments = [
                SELECT Id,
                       CommentBody,
                       CreatedDate,
                       CreatedById,
                       CreatedBy.Name
                FROM CaseComment
                WHERE ParentId = :caseId
                AND IsPublished = true
                ORDER BY CreatedDate ASC
                LIMIT 200
            ];

            Id currentUserId = UserInfo.getUserId();
            // Récupération de la TimeZone de l'utilisateur pour corriger l'heure
            String userTimeZone = UserInfo.getTimeZone().getID();

            for (CaseComment cc : comments) {
                Map<String, String> row = new Map<String, String>();
                Boolean isOwn = (cc.CreatedById == currentUserId);

                row.put('id', cc.Id);
                row.put('body', cc.CommentBody);
                row.put('authorId', cc.CreatedById);
                row.put('authorName', cc.CreatedBy.Name);
                
                // CORRECTION 1 : Heure locale (ex: Tunisie GMT+1)
                row.put('date', cc.CreatedDate.format('dd/MM/yyyy HH:mm', userTimeZone));
                
                row.put('isOwn', String.valueOf(isOwn));

                // CORRECTION 2 : Nom de l'agent pour les messages reçus
                if (isOwn) {
                    row.put('senderLabel', cc.CreatedBy.Name);
                } else {
                    row.put('senderLabel', 'Agent Support');
                }

                result.add(row);
            }

            return result;

        } catch (Exception e) {
            throw new AuraHandledException('Erreur getComments : ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void sendComment(Id caseId, String message) {
        if (caseId == null) {
            throw new AuraHandledException('L’identifiant de la requête est introuvable.');
        }
        if (String.isBlank(message)) {
            throw new AuraHandledException('Le message ne peut pas être vide.');
        }

        try {
            CaseComment commentToInsert = new CaseComment(
                ParentId = caseId,
                CommentBody = message.trim(),
                IsPublished = true
            );
            insert commentToInsert;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur sendComment : ' + e.getMessage());
        }
    }
}