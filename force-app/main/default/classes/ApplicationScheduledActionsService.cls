/**
 * @description Service class for validating and registering Scheduled Actions related automation.
 *		It also contains invocable method that will be called by Flow at scheduled date and time to run all scheduled actions automation.
 * @author Seth Heang
 * @date 2024-07-18
 * @test UnifiedScheduledActionsService_Test
 * @changelog
 * 2024-07-18 - Seth Heang - Created.
 */
public with sharing class ApplicationScheduledActionsService {
	public static final List<System.Type> CASE_SCHEDULED_ACTIONS = new List<System.Type>{ CaseMonitoring3DayReminderEmailAction.class, CaseMonitoring5DayAutoClosureAction.class };

	public static ApplicationScheduledActionsService newInstance() {
		return (ApplicationScheduledActionsService) Application.Utilities.newInstance(ApplicationScheduledActionsService.class);
	}

	/**
	 * @description Validate and setup Case actions for scheduled action automation
	 * @param parentRecords
	 * @param revalidateOperation
	 * @param uow
	 */
	public void validateCaseActionsSetup(Map<Id, SObject> parentRecords, Boolean revalidateOperation, ApplicationUnitOfWork uow) {
		for (System.Type actionType : CASE_SCHEDULED_ACTIONS) {
			((ApplicationScheduledAction) Application.Utilities.newInstance(actionType)).setup(parentRecords, uow, revalidateOperation);
		}
	}

	/**
	 * @description Invoked by a record-triggered flow at the scheduled action's scheduled date and time to execute all automations.
	 *				Group scheduled actions into unique type and process their respective automation.
	 * @param scheduledActionIds
	 */
	@InvocableMethod(Label='Run Scheduled Actions' Description='Execute scheduled action related automations')
	public static void executeAll(List<Id> scheduledActionIds) {
		try {
			// group a set of scheduled actions Id by Automation type
			Map<System.Type, Set<Id>> actionGroups = new Map<System.Type, Set<Id>>();
			for (System.Type action : CASE_SCHEDULED_ACTIONS) {
				actionGroups.put(action, new Set<Id>());
			}

			for (ScheduledAction__c action : ScheduledActionsSelector.newInstance().selectById(new Set<Id>(scheduledActionIds))) {
				actionGroups.get(Type.forName(action.ActionType__c))?.add(action.Id);
			}
			// execute the automation type with its respective set of scheduled action Ids
			for(System.Type actionType : actionGroups.keySet()) {
				Set<Id> actionIds = actionGroups.get(actionType);
				if(actionIds != null) {
					((ApplicationScheduledAction) Application.Utilities.newInstance(actionType)).execute(new List<Id>(actionIds));
				}
			}
		} catch (Exception ex) {
			// When an exception occurs, it's observed that Flow automatically retries by rescheduling a path sometimes later(e.g. 5-10 mins) as per Out-of-box behaviour
			// Therefore, Set active flag to false, to end the cycle
			List<ScheduledAction__c> setScheduledActionsToInActive = new List<ScheduledAction__c>();
			for (Id actionId : scheduledActionIds) {
				setScheduledActionsToInActive.add(new ScheduledAction__c(Id = actionId, Active__c = false));
			}
			ApplicationDatabase.getInstance().dmlUpdate(setScheduledActionsToInActive);
			// Log Error
			ApplicationLogger.getInstance()
				.logException(
					ApplicationLogger.wrapException(ex),
					ApplicationScheduledActionsService.class.getName(),
					ApplicationScheduledActionsService.class.getName(),
					'executeAll',
					'ScheduledAction__c',
					ApplicationLogger.LoggingLevel.ERROR
				);
		}
	}
}