public without sharing class ChatController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getComments(Id caseId) {

        // Vérification CRUD
        if (!Schema.sObjectType.CaseComment.isAccessible()) {
            throw new AuraHandledException('Accès refusé aux commentaires.');
        }

        List<Map<String, String>> result = new List<Map<String, String>>();

        try {
            List<CaseComment> comments = [
                SELECT Id,
                       CommentBody,
                       CreatedById,
                       CreatedBy.Name,
                       CreatedDate,
                       IsPublished
                FROM CaseComment
                WHERE ParentId = :caseId
                AND IsPublished = true
                ORDER BY CreatedDate ASC
                LIMIT 200
            ];

            // Récupérer les IDs des auteurs
            Set<Id> userIds = new Set<Id>();
            for (CaseComment cc : comments) {
                if (cc.CreatedById != null) {
                    userIds.add(cc.CreatedById);
                }
            }

            // Map UserId -> User
            Map<Id, User> usersById = new Map<Id, User>();

            if (!userIds.isEmpty() && Schema.sObjectType.User.isAccessible()) {
                usersById = new Map<Id, User>([
                    SELECT Id, UserType
                    FROM User
                    WHERE Id IN :userIds
                ]);
            }

            Id currentUserId = UserInfo.getUserId();

            for (CaseComment cc : comments) {

                Map<String, String> m = new Map<String, String>();

                m.put('id', cc.Id);
                m.put('body', cc.CommentBody);
                m.put('authorId', cc.CreatedById);
                m.put('authorName', cc.CreatedBy.Name);
                m.put('date', cc.CreatedDate.format('dd/MM/yyyy HH:mm'));
                m.put('isOwn', String.valueOf(cc.CreatedById == currentUserId));

                // Déterminer si c'est un agent
                String userType = null;
                if (usersById.containsKey(cc.CreatedById)) {
                    userType = usersById.get(cc.CreatedById).UserType;
                }

                Boolean isAgent = (
                    userType == 'Standard' ||
                    userType == 'PowerUser'
                );

                m.put('isAgent', String.valueOf(isAgent));
                m.put(
                    'senderLabel',
                    isAgent ? 'Support Maison Luxe' : cc.CreatedBy.Name
                );

                result.add(m);
            }

            return result;

        } catch (Exception e) {
            throw new AuraHandledException('Erreur getComments : ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void sendComment(Id caseId, String message) {

        // Vérification CRUD
        if (!Schema.sObjectType.CaseComment.isCreateable()) {
            throw new AuraHandledException('Vous ne pouvez pas créer de commentaire.');
        }

        try {
            if (String.isBlank(message)) {
                throw new AuraHandledException('Le message ne peut pas être vide.');
            }

            CaseComment cc = new CaseComment(
                ParentId = caseId,
                CommentBody = message.trim(),
                IsPublished = true
            );

            insert cc;

        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Erreur sendComment : ' + e.getMessage());
        }
    }
}