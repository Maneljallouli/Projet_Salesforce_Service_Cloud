public without sharing class ChatController {

    // Récupère tous les commentaires d'un case
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getComments(Id caseId) {
        List<Map<String, String>> result = new List<Map<String, String>>();

        try {
            List<CaseComment> comments = [
                SELECT Id, CommentBody, CreatedById, CreatedBy.Name,
                       CreatedBy.UserType, CreatedDate, IsPublished
                FROM CaseComment
                WHERE ParentId = :caseId
                AND IsPublished = true
                ORDER BY CreatedDate ASC
                LIMIT 200
            ];

            Id currentUserId = UserInfo.getUserId();

            for (CaseComment cc : comments) {
                Map<String, String> m = new Map<String, String>();
                m.put('id',        cc.Id);
                m.put('body',      cc.CommentBody);
                m.put('authorId',  cc.CreatedById);
                m.put('authorName', cc.CreatedBy.Name);
                m.put('date',      cc.CreatedDate.format('dd/MM/yyyy HH:mm'));
                m.put('isOwn',     cc.CreatedById == currentUserId ? 'true' : 'false');

                // Distingue agent vs client
                String userType = cc.CreatedBy.UserType;
                Boolean isAgent = (userType == 'Standard' || userType == 'PowerUser');
                m.put('isAgent',   isAgent ? 'true' : 'false');
                m.put('senderLabel', isAgent ? 'Support Maison Luxe' : cc.CreatedBy.Name);

                result.add(m);
            }

        } catch (Exception e) {
            System.debug('ERREUR getComments: ' + e.getMessage());
            throw new AuraHandledException('Erreur: ' + e.getMessage());
        }

        return result;
    }

    // Envoie un nouveau commentaire
    @AuraEnabled
    public static void sendComment(Id caseId, String message) {
        try {
            if (String.isBlank(message)) {
                throw new AuraHandledException('Le message ne peut pas être vide.');
            }

            CaseComment cc = new CaseComment();
            cc.ParentId    = caseId;
            cc.CommentBody = message.trim();
            cc.IsPublished = true;
            insert cc;

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            System.debug('ERREUR sendComment: ' + e.getMessage());
            throw new AuraHandledException('Erreur: ' + e.getMessage());
        }
    }
}