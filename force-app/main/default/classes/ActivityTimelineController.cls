public without sharing class ActivityTimelineController {
    @AuraEnabled
    public static List<RecordActivity> getAllActivities(String recordId) {
        List<RecordActivity> allActivities = new List<RecordActivity>();
        for (Account account : [SELECT Id, Name,
                                    (SELECT Id,Subject,Description,CreatedDate,TaskSubtype FROM Tasks),
                                    (SELECT Id,Subject,Description,CreatedDate FROM Events),
                                    (SELECT Id,Subject,TextBody,CreatedDate FROM Emails)
                                FROM Account WHERE Id = :recordId]) {
            for (Task task: account.Tasks) {
                RecordActivity recordActivity = new RecordActivity();
                recordActivity.actId = task.Id;
                recordActivity.icon = task.TaskSubtype?.equalsIgnoreCase('call') ? 'standard:log_a_call' : 'standard:task';
                recordActivity.title = task.Subject;
                recordActivity.description = task.Description;
                recordActivity.createdDate = task.CreatedDate;
                allActivities.add(recordActivity);
            }
            for (Event event: account.Events) {
                RecordActivity recordActivity = new RecordActivity();
                recordActivity.actId = event.Id;
                recordActivity.icon = 'standard:event';
                recordActivity.title = event.Subject;
                recordActivity.description = event.Description;
                recordActivity.createdDate = event.CreatedDate;
                allActivities.add(recordActivity);
            }
            for (EmailMessage em: account.Emails) {
                RecordActivity recordActivity = new RecordActivity();
                recordActivity.actId = em.Id;
                recordActivity.icon = 'standard:email';
                recordActivity.title = em.Subject;
                recordActivity.description = em.TextBody;
                recordActivity.createdDate = em.CreatedDate;
                allActivities.add(recordActivity);
            }
        }
        return allActivities;
    }

    public class RecordActivity {
        @AuraEnabled public String actId {get; set;}
        @AuraEnabled public String icon {get; set;}
        @AuraEnabled public String title {get; set;}
        @AuraEnabled public String description {get; set;}
        @AuraEnabled public Datetime createdDate {get; set;}
    }
}