/**
 * @description Test Class covering AgentWorkCallbackRequestAutomationModule
 * @author Ranjeewa Silva
 * @date 2024-07-22
 * @changelog
 */
@IsTest
private class AgentWorkCBRequestAutomationModule_Test {
	/*
	* NOTE: Existing test method moved here as part of uplifting to ApplicationModule Framework.
	* Was previously in AgentWorkTriggerHandlerTest.
	*/
	@IsTest
	public static void assignDeclinedRemindersToQueueTest(){
		/*** Create Case record records. */
		Case cs2 = new Case();
		cs2.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW General Enquiry').getRecordTypeId();
		cs2.BusinessHoursId=[SELECT Id FROM BusinessHours WHERE Name='SSSWSydney'].Id;
		cs2.Type = SSSWConstants.CASE_TYPE;
		cs2.Origin = SSSWConstants.CASE_ORIGIN;
		cs2.ProductCategory__c = SSSWConstants.CASE_PROD_CAT;
		cs2.ProductSubCategory__c = SSSWConstants.CASE_PROD_SUB_CAT;
		cs2.Priority = SSSWConstants.CASE_PRIORITY;
		cs2.Subject='Testing 5 Days SLA';
		cs2.Status=SSSWConstants.CASE_SLA_STATUS;
		cs2.OwnerId = [SELECT Id, QueueId FROM QueueSobject WHERE Queue.Name='SSSW Network Queue'].QueueId;
		insert cs2;
		/*** Create Callback Reminder record records. */
		Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();
		List<Callback_Request__c> callbackRequestList = new List<Callback_Request__c>();
		DateTime dtNow = System.now();
		callbackRequestList.add(new Callback_Request__c(Type__c ='Business',ReExecutionDateTime__c=dtNow.addMinutes(15), RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId));
		callbackRequestList.add(new Callback_Request__c(Type__c ='FCR',ReExecutionDateTime__c=dtNow.addMinutes(15),RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId));
		insert callbackRequestList;

		List<AgentWork> agentWorkListOld = new List<AgentWork>();
		List<AgentWork> agentWorkList = new List<AgentWork>();
		Callback_Request__c cbr = [SELECT Id, Type__c FROM Callback_Request__c WHERE Type__c ='Business' LIMIT 1];

		AgentWork aw = new AgentWork();
		aw.ServiceChannelId = [SELECT Id FROM ServiceChannel WHERE DeveloperName='Callback_Request_Channel'].Id;
		aw.WorkItemId=cbr.Id;
		agentWorkList.add(aw);

		Test.startTest();

		AgentWorkCallbackRequestAutomationModule module = new AgentWorkCallbackRequestAutomationModule();
		module.onAfterUpdate(agentWorkList, new Map<Id, AgentWork>(agentWorkListOld), null);

		Test.stopTest();
		cbr = [SELECT Id, Type__c, OwnerId FROM Callback_Request__c WHERE Type__c ='Business' LIMIT 1];
		String retId = String.valueOf(cbr.OwnerId).substring(0,3);

		System.assert(retId=='00G', 'Owner changed to Queue');
	}
}