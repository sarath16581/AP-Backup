/***
 * @description Domain wrapper class for ContactPointPhone
 * @author George Nguyen
 * @group Domain
 * @tag AgentWorkDomain
 * @domain AgentWork
 * @Test AgentWorkTriggerHandlerTest, AgentWorkCBRequestAutomationModule_Test
 * @changelog
 * 2023-02-16 - George Nguyen - updated. This class was created a while back but does not follow the framework. I have updated to use our framework
 * 2023-04-14 - Noel Lim - Updated of Domain class from APCaseAgentWorkDomain to AgentWorkAPCaseDomain
 * 2024-07-19 - Ranjeewa Silva - Uplifted to new domain less trigger dispatch framework.
 */
public inherited sharing class AgentWorkTriggerHandler extends ApplicationTriggerHandler {

	public override SObjectType getSObjectType() {
		return AgentWork.SObjectType;
	}

	public override void registerModules() {
		registerModule(AgentWorkCaseAutomationModule.class, 'filterCaseWorkItems');
		registerModule(AgentWorkCallbackRequestAutomationModule.class, 'filterCallbackRequestWorkItems');
	}

	/**
	 * Pre filter records to minimise repetitive looping inside the modules.
	 * This creates a type of index of records which are passed into the modules based on the 'filterKey' used when the module is registered.
	 * This replicates Domain specific filtering logic and allows a module to execution with the record scope it needs
	 *
	 * @param records
	 *
	 * @return
	 */
	public override Map<String, List<SObject>> primeRecordFilters(List<SObject> records) {
		Map<String, List<SObject>> filteredRecords = new Map<String, List<SObject>>{
				'filterCaseWorkItems' => new List<SObject>(),
				'filterCallbackRequestWorkItems' => new List<SObject>()
		};

		Set<Id> caseIds = new Set<Id>();
		for(SObject record : records) {
			Id workItemId = (Id)record.get('WorkItemId');
			if (workItemId.getSobjectType() == Case.SObjectType) {
				filteredRecords.get('filterCaseWorkItems').add(record);
			} else if (workItemId.getSobjectType() == Callback_Request__c.SObjectType) {
				filteredRecords.get('filterCallbackRequestWorkItems').add(record);
			}
		}

		return filteredRecords;
	}

	/**
	 * Unit of work that encapsulates all the required objects for each domain within this SObject
	 *
	 * @return unit or work instance
	 */
	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{ 
			AgentWork.SObjectType, 
			Case.SObjectType
		};
	}

	/*
	* NOTE: This is existing method. It should be uplifted to the framework. 
	*/
	public static void assignDeclinedRemindersToQueue(List<AgentWork> agentWorkListOld, List<AgentWork> agentWorkList){
		Id recordTypeIdCallbackReminder = Utility.getRecordTypesAsIdByDevName('Callback_Request__c', 'SSSW_Callback_Reminder');
		Set<Id> callbackReminderSet = new Set<Id>();
		Set<Id> agentWorkSetOld = new Set<Id>();
		
		if(Test.isRunningTest()){
			//.. get Reminder Ids
			for(AgentWork aw: agentWorkList){
				callbackReminderSet.add(aw.WorkItemId);
			}	
		}
		else{
			for(AgentWork awOld: agentWorkListOld){
				if(awOld.Status != 'Declined' || awOld.Status != 'DeclinedOnPushTimeout'){
					agentWorkSetOld.add(awOld.Id);
				}
			}
			
			//.. get Reminder Ids
			for(AgentWork aw: agentWorkList){
				if((aw.Status == 'Declined' || aw.Status == 'DeclinedOnPushTimeout') && agentWorkSetOld.contains(aw.Id)){
					callbackReminderSet.add(aw.WorkItemId);	
				}
			}	
		}
		
		
		List<Callback_Request__c> callbackReminderList = [SELECT Id, Type__c, OwnerId FROM Callback_Request__c 
														  WHERE RecordTypeId=:recordTypeIdCallbackReminder AND Id IN:callbackReminderSet];
		
		if(callbackReminderList.size()>0){
			//.. get list of queues and permsets related to callback reminders.
			List<Callback_Reminder_Settings__mdt> lstCBRmdt = [SELECT Id, Callback_Reminder_Queue_Name__c, Callback_Reminder_Type__c FROM Callback_Reminder_Settings__mdt];
			Map<String, String> mapQueueType = new Map<String,String>();
			for(Callback_Reminder_Settings__mdt oCBRmdt:lstCBRmdt){
				mapQueueType.put(oCBRmdt.Callback_Reminder_Queue_Name__c, oCBRmdt.Callback_Reminder_Type__c);
			}
			
			//.. get queue ids related to callback reminder.
			List<Group> lstCallbackReminderQueues = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN:mapQueueType.keySet()];
			Map<String, Id> mapTypeWithQueueId = new Map<String, Id>();
			for(Group grp: lstCallbackReminderQueues){
				mapTypeWithQueueId.put(mapQueueType.get(grp.DeveloperName), grp.Id);
			}

			for(Callback_Request__c cbr:callbackReminderList){
				cbr.OwnerId=mapTypeWithQueueId.get(cbr.Type__c);
			}
			
			update callbackReminderList;
		}
	}

}