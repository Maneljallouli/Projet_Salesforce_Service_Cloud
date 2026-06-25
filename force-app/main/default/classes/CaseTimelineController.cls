public with sharing class CaseTimelineController {

    public class TimelineItem {
        @AuraEnabled public String title;
        @AuraEnabled public String description;
        @AuraEnabled public String dateLabel;
        @AuraEnabled public String state;
    }

    @AuraEnabled(cacheable=true)
    public static List<TimelineItem> getTimeline(Id caseId) {
        if (caseId == null) {
            return new List<TimelineItem>();
        }

        Case c = [
            SELECT Id, CaseNumber, Subject, Status, CreatedDate, LastModifiedDate, ClosedDate
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        List<TimelineItem> items = new List<TimelineItem>();

        items.add(makeItem(
            'Demande créée',
            'Votre dossier #' + c.CaseNumber + ' a été enregistré.',
            c.CreatedDate,
            'completed'
        ));

        List<CaseHistory> histories = [
            SELECT CreatedDate, OldValue, NewValue
            FROM CaseHistory
            WHERE CaseId = :caseId
            AND Field = 'Status'
            ORDER BY CreatedDate ASC
        ];

        for (CaseHistory h : histories) {
            String oldValue = h.OldValue == null ? '' : String.valueOf(h.OldValue);
            String newValue = h.NewValue == null ? '' : String.valueOf(h.NewValue);

            items.add(makeItem(
                'Statut mis à jour',
                oldValue + ' → ' + newValue,
                h.CreatedDate,
                'completed'
            ));
        }

        if (isClosedStatus(c.Status)) {
            items.add(makeItem(
                'Dossier clôturé',
                'Votre demande est désormais clôturée.',
                c.ClosedDate != null ? c.ClosedDate : c.LastModifiedDate,
                'completed'
            ));
        } else {
            items.add(makeItem(
                'Statut actuel : ' + c.Status,
                'Notre équipe suit actuellement votre dossier.',
                c.LastModifiedDate,
                'current'
            ));

            TimelineItem nextStep = new TimelineItem();
            nextStep.title = 'Prochaine étape';
            nextStep.description = 'Vous recevrez une notification dès qu’une nouvelle action sera effectuée.';
            nextStep.dateLabel = '';
            nextStep.state = 'upcoming';
            items.add(nextStep);
        }

        return items;
    }

    private static TimelineItem makeItem(String title, String description, Datetime dt, String state) {
        TimelineItem item = new TimelineItem();
        item.title = title;
        item.description = description;
        item.dateLabel = dt == null ? '' : dt.format('dd MMM yyyy, HH:mm');
        item.state = state;
        return item;
    }

    private static Boolean isClosedStatus(String statusValue) {
        if (String.isBlank(statusValue)) {
            return false;
        }

        String s = statusValue.toLowerCase();

        return s.contains('closed') ||
               s.contains('clot') ||
               s.contains('résolu') ||
               s.contains('resolu') ||
               s.contains('resolved');
    }
}