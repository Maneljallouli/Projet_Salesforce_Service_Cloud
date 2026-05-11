/**
 * @description Classe pour gérer les échanges entre agent et client via CaseComment.
 * "without sharing" est crucial ici car votre profil client n'a pas le droit "Edit" sur Case.
 */
public without sharing class CaseCommentController {

    @AuraEnabled(cacheable=true)
    public static List<CommentData> getCaseComments(Id caseId) {
        List<CommentData> comments = new List<CommentData>();
        try {
            // Requête sur CaseComment uniquement (pas de pollution technique)
            // IsPublished = true garantit que les messages sont visibles par le client
            for (CaseComment c : [
                SELECT Id, CommentBody, CreatedDate, CreatedBy.Name
                FROM CaseComment
                WHERE ParentId = :caseId 
                AND IsPublished = true
                ORDER BY CreatedDate DESC
            ]) {
                comments.add(new CommentData(c));
            }
        } catch (Exception e) {
            // En cas d'erreur, on renvoie une exception lisible par le LWC
            throw new AuraHandledException('Erreur lors de la récupération des commentaires : ' + e.getMessage());
        }
        return comments;
    }

    @AuraEnabled
    public static void postMessage(Id caseId, String message) {
        // Sécurité de base : ne pas envoyer de message vide
        if (String.isBlank(message)) {
            return;
        }
        
        try {
            // Création du commentaire en mode système (contourne les restrictions du profil)
            CaseComment newCc = new CaseComment();
            newCc.ParentId = caseId;
            newCc.CommentBody = message; // Le texte saisi par l'utilisateur
            newCc.IsPublished = true;    // Rendre le message visible pour les deux parties
            
            insert newCc;
            
        } catch (Exception e) {
            // Log de l'erreur et renvoi au composant LWC
            System.debug('Erreur insertion CaseComment: ' + e.getMessage());
            throw new AuraHandledException('Impossible d\'envoyer le message : ' + e.getMessage());
        }
    }

    /**
     * Wrapper class pour structurer les données envoyées au LWC
     */
    public class CommentData {
        @AuraEnabled public String id;
        @AuraEnabled public String author;
        @AuraEnabled public String body;
        @AuraEnabled public DateTime createdDate;

        public CommentData(CaseComment c) {
            this.id = c.Id;
            this.author = c.CreatedBy.Name; // Nom de Manel ou de l'agent
            this.body = c.CommentBody;      // Le message pur
            this.createdDate = c.CreatedDate; // Date et heure pour votre affichage
        }
    }
}