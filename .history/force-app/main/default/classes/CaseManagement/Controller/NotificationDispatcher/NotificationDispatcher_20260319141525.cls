public with sharing class NotificationDispatcher {

    /*
     * ==============================
     * DTO (Wrapper pour éviter les paramètres excessifs)
     * ==============================
     */
    public class NotificationRequest {
        public Id caseId;
        public String subject;
        public String message;
        public Id recipientId;
        public String type;
        public Boolean sendEmail;
        public Boolean sendCustomNotif;
    }

    /*
     * ==============================
     * ENTRY POINT
     * ==============================
     */
    public static void dispatch(NotificationRequest request) {

        if (request == null) {
            return;
        }

        validateRequest(request);

        if (request.sendEmail == true) {
            sendEmailNotification(request);
        }

        if (request.sendCustomNotif == true) {
            sendCustomNotification(request);
        }
    }

    /*
     * ==============================
     * VALIDATION
     * ==============================
     */
    private static void validateRequest(NotificationRequest request) {

        if (request.caseId == null) {
            throw new AuraHandledException('CaseId is required');
        }

        if (String.isBlank(request.subject)) {
            throw new AuraHandledException('Subject is required');
        }

        if (String.isBlank(request.message)) {
            throw new AuraHandledException('Message is required');
        }

        if (request.recipientId == null) {
            throw new AuraHandledException('RecipientId is required');
        }
    }

    /*
     * ==============================
     * EMAIL NOTIFICATION
     * ==============================
     */
    private static void sendEmailNotification(NotificationRequest request) {

        if (!Schema.sObjectType.Messaging.SingleEmailMessage.isAccessible()) {
            return;
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        email.setTargetObjectId(request.recipientId);
        email.setSubject(request.subject);
        email.setPlainTextBody(request.message);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }

    /*
     * ==============================
     * CUSTOM NOTIFICATION
     * ==============================
     */
    private static void sendCustomNotification(NotificationRequest request) {

        if (!Schema.sObjectType.CustomNotificationType.isAccessible()) {
            return;
        }

        Id notificationTypeId = getNotificationTypeId(request.type);

        if (notificationTypeId == null) {
            return;
        }

        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        notification.setTitle(request.subject);
        notification.setBody(request.message);
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetId(request.caseId);

        notification.send(new Set<Id>{ request.recipientId });
    }

    /*
     * ==============================
     * HELPER: GET NOTIFICATION TYPE
     * ==============================
     */
    private static Id getNotificationTypeId(String developerName) {

        if (String.isBlank(developerName)) {
            return null;
        }

        if (!Schema.sObjectType.CustomNotificationType.isAccessible()) {
            return null;
        }

        List<CustomNotificationType> types = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = :developerName
            LIMIT 1
        ];

        if (!types.isEmpty()) {
            return types[0].Id;
        }

        return null;
    }
}