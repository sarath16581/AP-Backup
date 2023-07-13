public without sharing class ActivityTimelineController {
    public static final String LOG_CALL_SUBTYPE_ICON = 'standard:log_a_call';
    public static final String TASK_SUBTYPE_ICON = 'standard:task';

    @AuraEnabled
    public static List<RecordActivity> getAllActivities(String recordId, String sObjectName) {
        recordId = String.escapeSingleQuotes(recordId);
        sObjectName = String.escapeSingleQuotes(sObjectName);

        Map<Id,Task> tasks = TasksSelector.newInstance().selectByWhatId(new Set<Id>{recordId});
        Map<Id,Event> events = EventsSelector.newInstance().selectByWhatId(new Set<Id>{recordId});
        List<EmailMessage> emails = EmailMessagesSelector.newInstance(EmailMessage.CreatedDate, 'DESC').selectByRelatedToIds(new Set<Id>{recordId});

        List<RecordActivity> allActivities = new List<RecordActivity>();
        for (Task task : tasks.values()) {
            RecordActivity recordActivity = new RecordActivity();
            recordActivity.actId = task.Id;
            recordActivity.icon = task.TaskSubtype?.equalsIgnoreCase('call') ? LOG_CALL_SUBTYPE_ICON : TASK_SUBTYPE_ICON; // log a call and regular tasks are identical apart from TaskSubtype values
            recordActivity.title = task.Subject;
            recordActivity.type = task.Type;
            recordActivity.category = task.Category__c;
            recordActivity.description = task.Description;
            recordActivity.createdDate = task.CreatedDate;
            allActivities.add(recordActivity);
        }

        for (Event event : events.values()) {
            RecordActivity recordActivity = new RecordActivity();
            recordActivity.actId = event.Id;
            recordActivity.icon = 'standard:event';
            recordActivity.title = event.Subject;
            recordActivity.description = event.Description;
            recordActivity.createdDate = event.CreatedDate;
            allActivities.add(recordActivity);
        }

        for (EmailMessage em : emails) {
            RecordActivity recordActivity = new RecordActivity();
            recordActivity.actId = em.Id;
            recordActivity.icon = 'standard:email';
            recordActivity.title = em.Subject;
            recordActivity.type = 'Email';
            recordActivity.description = em.TextBody;
            recordActivity.htmlBody = em.HtmlBody;
            recordActivity.createdDate = em.CreatedDate;
            allActivities.add(recordActivity);
        }

        return allActivities;
    }

    public class RecordActivity {
        @AuraEnabled public String actId {get; set;}
        @AuraEnabled public String icon {get; set;}
        @AuraEnabled public String title {get; set;}
        @AuraEnabled public String type {get; set;}
        @AuraEnabled public String category {get; set;}
        @AuraEnabled public String description {get; set;}
        @AuraEnabled public Datetime createdDate {get; set;}
        @AuraEnabled public String htmlBody {get; set;}
    }
}