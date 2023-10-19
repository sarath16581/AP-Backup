/***
 * @author Steve L.
 * @date 2023-07-15
 * @group Tests
 * @tag Selector
 * @tag SObjects that can be part of Related To field
 * @domain Core
 * @description Test Class covering EventSelector
 * @changelog
 * 2023-07-15- Steve L - Created
 */
public without sharing class ActivityTimelineController {
	public static final String LOG_CALL_SUBTYPE_ICON = 'standard:log_a_call';
	public static final String TASK_SUBTYPE_ICON = 'standard:task';
	public static final String EMAIL_SUBTYPE_ICON = 'standard:email';
	public static final String CALL_SUBTYPE = 'Call';
	public static final String EMAIL_SUBTYPE = 'Email';
	public static final String EVENT_SUBTYPE = 'Event';

	/**
	 * @param recordId the object's record Id
	 * @param sObjectName the api name of the SObject
	 * @param recordLimit used in the LIMIT clause
	 * @param offsetLimit used in the OFFSET clause
	 *
	 * @return RecordActivity an object that merged Task/Event/Email
	 */
	@AuraEnabled
	public static List<RecordActivity> getAllActivities(String recordId, String sObjectName, Integer recordLimit, Integer offsetLimit) {
		recordId = String.escapeSingleQuotes(recordId);
		sObjectName = String.escapeSingleQuotes(sObjectName);

		Set<SObjectField> taskFieldOverrides = getTaskFieldOverrides();
		Map<Id,Task> tasks = TasksSelector.newInstance(recordLimit,offsetLimit,'CreatedDate','DESC',taskFieldOverrides).selectByWhatId(new Set<Id>{recordId},new Set<Object>{TasksSelector.Options.WITH_OWNER,TasksSelector.Options.WITH_CONTACT}, true);


		Set<SObjectField> eventFieldOverrides = getEventFieldOverrides();
		Map<Id,Event> events = EventsSelector.newInstance(recordLimit, offsetLimit, eventFieldOverrides).selectByWhatId(new Set<Id>{recordId},new Set<Object>{EventsSelector.Options.WITH_OWNER,EventsSelector.Options.WITH_CONTACT}, true);


		List<RecordActivity> allActivities = new List<RecordActivity>();

		for (Task task : tasks.values()) {
			if (task.IsDeleted) {
				continue;
			}
			RecordActivity recordActivity = new RecordActivity();
			recordActivity.actId = task.Id;
			if (!String.isEmpty(task.TaskSubtype)) {
				recordActivity.icon = task.TaskSubtype.equalsIgnoreCase(CALL_SUBTYPE) ? LOG_CALL_SUBTYPE_ICON : TASK_SUBTYPE_ICON; // log a call and regular tasks are identical apart from TaskSubtype values
			}
			recordActivity.title = task.Subject;
			recordActivity.type = task.Type;
			recordActivity.subType = task.TaskSubtype; // this covers: email, task, call
			if (task.Type.equalsIgnoreCase(EMAIL_SUBTYPE)) {
				recordActivity.icon = EMAIL_SUBTYPE_ICON;
			}
			recordActivity.category = task.Category__c;
			recordActivity.description = task.Description;
			recordActivity.createdDate = task.CreatedDate;
			recordActivity.assignedToName = task.Owner.Name;
			recordActivity.dueDate = task.ActivityDate;
			recordActivity.status = task.Status;
			recordActivity.priority = task.Priority;
			recordActivity.relatedToName = task.Who.Name;
			allActivities.add(recordActivity);
		}

		for (Event event : events.values()) {
			if (event.IsDeleted) {
				continue;
			}
			RecordActivity recordActivity = new RecordActivity();
			recordActivity.actId = event.Id;
			recordActivity.icon = 'standard:event';
			recordActivity.title = event.Subject;
			recordActivity.subType = EVENT_SUBTYPE;
			recordActivity.description = event.Description;
			recordActivity.createdDate = event.CreatedDate;
			recordActivity.startDate = event.StartDateTime;
			recordActivity.endDate = event.EndDateTime;
			recordActivity.status = event.Status__c;
			recordActivity.type = event.Type;
			recordActivity.relatedToName = event.Who.Name;
			allActivities.add(recordActivity);
		}

		return allActivities;
	}

	@TestVisible
	private static Set<SObjectField> getTaskFieldOverrides() {
		return new Set<SObjectField>{Task.Id, Task.IsDeleted, Task.IsArchived, Task.TaskSubtype,Task.Subject,Task.Category__c,Task.Description,Task.Type,Task.CreatedDate,Task.ActivityDate,Task.Status,Task.Priority};
	}

	@TestVisible
	private static Set<SObjectField> getEventFieldOverrides() {
		return new Set<SObjectField>{Event.Id, Event.IsDeleted, Event.IsArchived, Event.StartDateTime,Event.Subject,Event.Category__c,Event.Description,Event.Type,Event.CreatedDate,Event.ActivityDate,Event.EndDateTime,Event.Status__c};
	}

	public class RecordActivity {
		@AuraEnabled public String actId {get; set;}
		@AuraEnabled public String icon {get; set;}
		@AuraEnabled public String title {get; set;}
		@AuraEnabled public String type {get; set;}
		@AuraEnabled public String subType {get; set;}
		@AuraEnabled public String category {get; set;}
		@AuraEnabled public String description {get; set;}
		@AuraEnabled public Datetime createdDate {get; set;}
		@AuraEnabled public String assignedToName {get; set;}
		@AuraEnabled public Date dueDate {get; set;}
		@AuraEnabled public String status {get; set;}
		@AuraEnabled public String priority {get; set;}
		@AuraEnabled public String relatedToName {get; set;}
		@AuraEnabled public Datetime startDate {get; set;}
		@AuraEnabled public Datetime endDate {get; set;}
	}
}