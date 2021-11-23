/**
 * Domain Modules should NEVER be called directly. Domain modules should only ever be called from a domain class
 *
 * This has been a port of parts of the StarTrack Case Automation process builder. It deals with the following nodes:
 * 1. Delivery Case Priority Assignment (1. Update Case Priority. 2. Update All Related Task's Priority)
 * 2. Case Priority Changed (Update All Related Task's Priority)
 * @author Raman Raj Saxena
 * @date 2021-06-22
 * @channel Module
 * @domain StarTrack
 * @changelog
 */

public inherited sharing class StarTrackSupportCasePriorityModule extends ApplicationDomain.Module {
	public static StarTrackSupportCasePriorityModule newInstance() {
		return (StarTrackSupportCasePriorityModule) Application.Utilities.newInstance(
			StarTrackSupportCasePriorityModule.class
		);
	}

	// Setup which triggers this module should respond to
	public StarTrackSupportCasePriorityModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate().enableAfterInsert().enableAfterUpdate();
	}

	// Get record type if for *Delivery Enquiry* record type on case
	public static Id deliveryEnquiryRecordTypeId {
		get {
			if (deliveryEnquiryRecordTypeId == null) {
				deliveryEnquiryRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{ 'StarTrack_PUD_Enquiry' }).values()[0].Id;
			}
			return deliveryEnquiryRecordTypeId;
		}
		private set;
	}
	/**
	 * Called when a new Case is being inserted to update the case priority.
	 */
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			if (!records.isEmpty()) {
				System.debug('StarTrackSupportCasePriorityModule:onBeforeInsert');
				// ensures the correct Priority field is set for StarTrack cases
				updateCasePriority((List<Case>) records, null);
			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis

			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackSupportCasePriorityModule.class.getName(), 'onBeforeInsert', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * Called when a new Case is being updated to update the case priority.
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			if (!records.isEmpty()) {
				System.debug('StarTrackSupportCasePriorityModule:onBeforeUpdate');
				// ensures the correct Priority field is set for StarTrack cases
				updateCasePriority((List<Case>) records, (Map<Id, Case>) existingRecords);
			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackSupportCasePriorityModule.class.getName(), 'onBeforeUpdate', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * Updates case priority
	 */
	public void updateCasePriority(List<Case> records, Map<Id, Case> existingRecords) {
		Boolean isInsert = (existingRecords == null);
		// Grab cases for which priority needs to be updated
		List<Case> deliveryPriortyCases = new List<Case>();
		Set<Id> articleIds = new Set<Id>();

		for (Case record : records) {
			// Get old case if it is update
			Case oldCase = !isInsert ? existingRecords.get(record.Id) : null;

			if (record.RecordTypeId != deliveryEnquiryRecordTypeId && record.ArticleTest__c != null && 
				(isInsert || (!isInsert && record.ArticleTest__c != oldCase.ArticleTest__c && !'Closed'.equalsIgnoreCase(record.Status))) &&
				(isInsert || record.Priority == oldCase.Priority )) {
				
				articleIds.add(record.ArticleTest__c);
				deliveryPriortyCases.add(record);
			}
		}
		if (!deliveryPriortyCases.isEmpty()) {
			// Grab articles where article is udpated on cases or case is new
			Map<Id, Article__c> articles = ArticlesSelector.newInstance(0, new Set<SObjectField>{ Article__c.Id, Article__c.Product_Group__c }).selectById(articleIds);

			// Case priorities which doesn't require update
			Set<String> validNextFlightPriorities = new Set<String>{ 'High', 'Urgent', 'Critical' };

			for (Case c : deliveryPriortyCases) {
				// only update the consignment next flight cases that require updating
				if ('Next Flight'.equalsIgnoreCase(articles.get(c.ArticleTest__c).Product_Group__c) && !validNextFlightPriorities.contains(c.Priority)) {
					
					c.Priority = 'High';
				}
			}
		}
	}

	/**
	 * Called after when a new Case is being inserted to udpate priority on task.
	 */
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			if (!records.isEmpty()) {
				System.debug('StarTrackSupportCasePriorityModule:onAfterInsert');
				// ensures the correct Priority field is set for StarTrack case's tasks
				updateDeliveryCaseTaskPriority((List<Case>) records, null, uow);
			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackSupportCasePriorityModule.class.getName(), 'onAfterInsert', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
	 * Called after when a Case is being updated to udpate priority on task.
	 */
	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			if (!records.isEmpty()) {
				System.debug('StarTrackSupportCasePriorityModule:onAfterUpdate');
				// ensures the correct Priority field is set for StarTrack case's tasks
				updateTaskPriority((List<Case>) records, (Map<Id, Case>) existingRecords, uow);
				updateDeliveryCaseTaskPriority((List<Case>) records, (Map<Id, Case>) existingRecords, uow);
			}
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackSupportCasePriorityModule.class.getName(), 'onAfterUpdate', StarTrack_Constants.CASE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
		Update task's priority for case if priority changes on case
	 */
	public void updateTaskPriority(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow) {
		// get a list records that were changed for easy access
		Map<Id, Set<SObjectField>> changedRecords = getIsChanged(records, existingRecords, new Set<SObjectField>{ Case.RecordTypeId, Case.Priority, Case.ArticleTest__c }
		);

		Map<Id, String> casePriorities = new Map<Id, String>();
		// loop through our records to figure out what actions need to be taken
		for (Case c : (List<Case>) records) {
			// Get changed fields for the current record
			Set<SObjectField> changedFields = changedRecords.get(c.Id);
			if (changedFields != null && !changedFields.isEmpty()) {
				if (changedFields.contains(Case.Priority) && !String.isEmpty(c.Priority)) {
					// priority was changed so we need to update
					casePriorities.put(c.Id, c.Priority);
				}
			}
		}

		if (!casePriorities.isEmpty()) {
			// keep the task priorities in sync with the case priorities
			Set<String> taskIgnoreStatuses = new Set<String>{ 'Completed', 'Finished', 'Rejected' };
			Map<Id, Task> tasks = TasksSelector.newInstance().selectByWhatId(casePriorities.keySet());
			List<Task> tasksUpdated = new List<Task>();
			for (Task t : tasks.values()) {
				// only update the tasks that require updating
				if (!taskIgnoreStatuses.contains(t.Status) && !casePriorities.get(t.WhatId).equalsIgnoreCase(t.Priority)) {
					
					t.Priority = casePriorities.get(t.WhatId);
					tasksUpdated.add(t);
				}
			}
			uow.registerDirty(tasksUpdated);
		}
	}

	/**
		Update task priority for Delivery Enquiry record type cases
	 */
	public void updateDeliveryCaseTaskPriority(List<Case> records, Map<Id, Case> existingRecords, ApplicationUnitOfWork uow) {
		Boolean isInsert = (existingRecords == null || existingRecords.isEmpty());
		Map<Id, Case> deliveryPriortyCases = new Map<Id, Case>();
		Set<Id> articleIds = new Set<Id>();
		// get a list records that were changed for easy access
		Map<Id, Set<SObjectField>> changedRecords = new Map<Id, Set<SObjectField>>();
		if (!isInsert) {
			changedRecords = getIsChanged(records, existingRecords, new Set<SObjectField>{ Case.RecordTypeId, Case.Priority, Case.ArticleTest__c });
		}

		for (Case record : records) {
			// Get changed fields for the current record
			Set<SObjectField> changedFields = changedRecords.get(record.Id);

			if (record.RecordTypeId == deliveryEnquiryRecordTypeId && record.ArticleTest__c != null &&
				(isInsert || (changedFields != null && changedFields.contains(Case.ArticleTest__c) && !'Closed'.equalsIgnoreCase(record.Status))) &&
				(changedFields == null || !changedFields.contains(Case.Priority))) {
				
				articleIds.add(record.ArticleTest__c);
				deliveryPriortyCases.put(record.ID, record);
			}
		}
		if (!deliveryPriortyCases.isEmpty()) {
			// keep the task priorities in sync with the case priorities
			Map<Id, Article__c> articles = ArticlesSelector.newInstance(0, new Set<SObjectField>{ Article__c.Id, Article__c.Product_Group__c }).selectById(articleIds);
			Set<String> validNextFlightPriorities = new Set<String>{ 'Urgent', 'Critical' };
			Set<String> taskIgnoreStatuses = new Set<String>{ 'Completed', 'Finished', 'Rejected' };
			Map<Id, Task> tasks = TasksSelector.newInstance().selectByWhatId(deliveryPriortyCases.keySet());
			List<Task> tasksUpdated = new List<Task>();
			for (Task t : tasks.values()) {
				Case c = deliveryPriortyCases.get(t.WhatId);
				// only update the tasks that require updating
				if (!taskIgnoreStatuses.contains(t.Status)) {
					if ('Next Flight'.equalsIgnoreCase(articles.get(c.ArticleTest__c).Product_Group__c)) {
						if (!validNextFlightPriorities.contains(c.Priority) && !'High'.equalsIgnoreCase(t.Priority)) {
							t.Priority = 'High';
							tasksUpdated.add(t);
						} else if (!c.Priority.equalsIgnoreCase(t.Priority)) {
							t.Priority = c.Priority;
							tasksUpdated.add(t);
						}
					} else if (!'Normal'.equalsIgnoreCase(t.Priority)) {
						t.Priority = 'Normal';
						tasksUpdated.add(t);
					}
				}
			}

			uow.registerDirty(tasksUpdated);
		}
	}

	public class Constructor implements ApplicationDomain.IConstructableModule {
		public ApplicationDomain.Module construct() {
			return (ApplicationDomain.Module) StarTrackSupportCasePriorityModule.newInstance();
		}
	}
}