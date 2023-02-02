/**
 * @File Name	: OmniChannelService_Test.cls
 * @Description	: 
 * @Author		: rajesh.punjabi@mav3rik.com
 * @Group		: 
 * @Last Modified By   : rajesh.punjabi@mav3rik.com
 * @Last Modified On   : 9/25/2019, 12:13:33 PM
 * @Modification Log   : 
 *==============================================================================
 * Ver	   Date					Author			   Modification
 *==============================================================================
 * 1.0	8/21/2019	rajesh.punjabi@mav3rik.com		Initial Version
 * 1.1	7/12/2022	Noel Lim						Added test method getUserIdFromLatestAcceptedAgentWork
 * 1.2	2/02/2022	Noel Lim						Update test method getUserIdFromLatestAcceptedAgentWork to getActiveUserIdFromLatestAcceptedAgentWork, only return active UserIds
 * 
**/
@IsTest (IsParallel=true)
public class OmniChannelService_Test {

	@TestSetup
	static void setup(){
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
		
		/*** Create callback records. */
		Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();
		List<Callback_Request__c> callbackRequestList = new List<Callback_Request__c>();
		DateTime dtNow = System.now();
		callbackRequestList.add(new Callback_Request__c(OwnerId=Userinfo.getUserId(),Type__c ='Business',ReExecutionDateTime__c=dtNow.addMinutes(15),RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId));
		callbackRequestList.add(new Callback_Request__c(OwnerId=Userinfo.getUserId(),Type__c ='Business',ReExecutionDateTime__c=dtNow.addMinutes(15),RecordTypeId=SSSW_Callback_ReminderId,Status__c=SSSWConstants.CALLBACK_REQUEST_STATUS_NEW, CaseId__c=cs2.Id, CaseBusinessHoursId__c=cs2.BusinessHoursId));
		insert callbackRequestList;
	}
	
	@IsTest
	static void queuesWithRoutingConfigShouldReturnFilteredQueues() {
		CacheManager.settings.CacheEnabled__c = true;
		OmniChannelService.Cache.resetStaticVariablesForUnitTestOnly();

		List<Group> queues = [SELECT QueueRoutingConfigId FROM Group WHERE Type = 'Queue' AND QueueRoutingConfigId != NULL];
		List<QueueRoutingConfig> queueRoutingConfigs = [SELECT DeveloperName FROM QueueRoutingConfig];
		Map<Id,QueueRoutingConfig> qrcMap = new Map<Id,QueueRoutingConfig>(queueRoutingConfigs);
		Map<Id,Id> queueIdToRoutingId = new Map<Id,Id>();

		for(Group queue : queues){
			queueIdToRoutingId.put(queue.Id, queue.QueueRoutingConfigId);
		}

		System.assertEquals(queues.size(), OmniChannelService.Cache.queuesWithRoutingConfig.size(), 'it should return the same number of queues');
		System.assertEquals(
			qrcMap.get(queueIdToRoutingId.get(queues[0].Id)).Id, 
			OmniChannelService.Cache.queuesWithRoutingConfig.get(queues[0].Id).routingConfiguration.Id, 
			'returned QueueRoutingConfig Ids should match');
		System.assertEquals(
			qrcMap.get(queueIdToRoutingId.get(queues[queues.size()-1].Id)).Id, 
			OmniChannelService.Cache.queuesWithRoutingConfig.get(queues[queues.size()-1].Id).routingConfiguration.Id, 
			'returned QueueRoutingConfig Ids should match');

		// test loading from cache
		OmniChannelService.Cache.resetStaticVariablesForUnitTestOnly();
		CacheManager.put('QUEUES_WITH_ROUTING_CONFIG', new Map<Id, OmniChannelService.QueueWrapper>{queues[0].Id=> new OmniChannelService.QueueWrapper(queues[0],qrcMap.get(queueIdToRoutingId.get(queues[0].Id)))});
		System.assertEquals(queues[0].Id, OmniChannelService.Cache.queuesWithRoutingConfig.get(queues[0].Id).queue.Id, 'should match');
		System.assertEquals(qrcMap.get(queueIdToRoutingId.get(queues[0].Id)).Id, OmniChannelService.Cache.queuesWithRoutingConfig.get(queues[0].Id).routingConfiguration.Id, 'returned QueueRoutingConfig Ids via Cache should match');
	}

	@IsTest
	static void serviceChannelsShouldReturnAllServiceChannels() {
		CacheManager.settings.CacheEnabled__c = true;
		OmniChannelService.Cache.resetStaticVariablesForUnitTestOnly();

		List<ServiceChannel> serviceChannels = [SELECT AfterConvoWorkMaxTime,DeveloperName,DoesMinimizeWidgetOnAccept,HasAfterConvoWorkTimer,RelatedEntity,SecRoutingPriorityField FROM ServiceChannel];

		System.assertEquals(serviceChannels.size(), OmniChannelService.Cache.serviceChannels.size(), 'it should return the same number of service channels');
		System.assertEquals(serviceChannels[0].Id, OmniChannelService.Cache.serviceChannels.get(serviceChannels[0].DeveloperName).Id, 'should match');
		System.assertEquals(serviceChannels[serviceChannels.size() - 1].Id, OmniChannelService.Cache.serviceChannels.get(serviceChannels[serviceChannels.size() - 1].DeveloperName).Id, 'should match');

		// test loading from cache
		OmniChannelService.Cache.resetStaticVariablesForUnitTestOnly();
		CacheManager.put('ALL_SERVICE_CHANNELS', new Map<String, ServiceChannel>{'test'=>serviceChannels[0]});
		System.assertEquals(serviceChannels[0].Id, OmniChannelService.Cache.serviceChannels.get('test').Id, 'should match');
	}

	@IsTest
	static void setOmniRoutingSecondaryPriorityForPSR() {
		Case aCase = (Case)ApplicationTestDataFactory.setUnwritableFields(new Case(), new Map<String, Object>{ 'CreatedDate' => Datetime.now().addDays(-10)});
		PendingServiceRouting psr = (PendingServiceRouting)ApplicationTestDataFactory.setUnwritableFields(new PendingServiceRouting(), new Map<String, Object>{ 'WorkItem' => aCase});
		List<PendingServiceRouting> psrs = new List<PendingServiceRouting>{psr};
		
		psr.WorkItem.Priority = 'Critical';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(990, psr.SecondaryRoutingPriority, 'Should be set to the value of range minus number of days');
		psr.WorkItem.Priority = 'Low';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(4990, psr.SecondaryRoutingPriority, 'Should be set to the value of range minus number of days');
		psr.WorkItem.Priority = 'Urgent';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(990, psr.SecondaryRoutingPriority, 'Should be set to the value of range minus number of days');
		psr.WorkItem.Priority = 'Medium';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(3990, psr.SecondaryRoutingPriority, 'Should be set to the value of range minus number of days');
		psr.WorkItem.Priority = 'Normal';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(1990, psr.SecondaryRoutingPriority, 'Should be set to the value of range minus number of days');
		psr.WorkItem.Priority = 'Regular';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(2990, psr.SecondaryRoutingPriority, 'Should be set to the value of range minus number of days');
		psr.WorkItem.Priority = 'High';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(1990, psr.SecondaryRoutingPriority, 'Should be set to the value of range minus number of days');

		aCase = (Case)ApplicationTestDataFactory.setUnwritableFields(aCase, new Map<String, Object>{ 'CreatedDate' => Datetime.now().addDays(-51)});
		psr = (PendingServiceRouting)ApplicationTestDataFactory.setUnwritableFields(new PendingServiceRouting(), new Map<String, Object>{ 'WorkItem' => aCase});
		psrs = new List<PendingServiceRouting>{psr};

		psr.WorkItem.Priority = 'Critical';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(950, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'Low';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(4950, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'Urgent';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(950, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'Medium';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(3950, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'Normal';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(1950, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'Regular';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(2950, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'High';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(1950, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
	}

	@IsTest
	static void setOmniRoutingSecondaryPriorityForCase() {
		Case aCase = new Case();
		List<Case> cases = new List<Case>{aCase};
		aCase.Priority = 'Critical';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, true);
		System.assertEquals('1000', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to highest value in the range');
		aCase.Priority = 'Low';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, true);
		System.assertEquals('5000', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to highest value in the range');
		aCase.Priority = 'Urgent';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, true);
		System.assertEquals('1000', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to highest value in the range');
		aCase.Priority = 'Medium';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, true);
		System.assertEquals('4000', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to highest value in the range');
		aCase.Priority = 'Normal';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, true);
		System.assertEquals('2000', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to highest value in the range');
		aCase.Priority = 'Regular';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, true);
		System.assertEquals('3000', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to highest value in the range');
		aCase.Priority = 'High';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, true);
		System.assertEquals('2000', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to highest value in the range');

		aCase = (Case)ApplicationTestDataFactory.setUnwritableFields(aCase, new Map<String, Object>{ 'CreatedDate' => Datetime.now().addDays(-10)});
		cases = new List<Case>{aCase};

		aCase.Priority = 'Critical';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('990', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to range minus number of days');
		aCase.Priority = 'Low';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('4990', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to range minus number of days');
		aCase.Priority = 'Urgent';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('990', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to range minus number of days');
		aCase.Priority = 'Medium';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('3990', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to range minus number of days');
		aCase.Priority = 'Normal';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('1990', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to range minus number of days');
		aCase.Priority = 'Regular';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('2990', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to range minus number of days');
		aCase.Priority = 'High';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('1990', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to range minus number of days');

		aCase = (Case)ApplicationTestDataFactory.setUnwritableFields(aCase, new Map<String, Object>{ 'CreatedDate' => Datetime.now().addDays(-51)});
		cases = new List<Case>{aCase};
		
		aCase.Priority = 'Critical';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('950', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'Low';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('4950', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'Urgent';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('950', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'Medium';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('3950', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'Normal';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('1950', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'Regular';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('2950', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'High';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('1950', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');

		aCase.Priority = 'blahblah';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('2500', aCase.OmniRoutingSecondaryPriority__c, 'default priority for un-mapped priorities');
	}

	/*
	* Test that the user belongs to an Omni Group
	*/
	@IsTest
	static void currentUserIsPartOfOmniGroup() {
		User testUser = [SELECT Id FROM User WHERE IsActive = True AND ProfileId IN (SELECT ProfileId FROM PresenceUserConfigProfile) LIMIT 1];
		System.runAs(testUser) {
			System.assertEquals(true, OmniChannelService.currentUserIsPartOfOmniGroup, 'Should be true for users in profiles assigned to Omni');
		}
	}
	
	@IsTest
	public static void assignRemindertoAgent_Test(){
		Boolean bReturn = false;
		Id SSSW_Callback_ReminderId = Schema.SObjectType.Callback_Request__c.getRecordTypeInfosByDeveloperName().get('SSSW_Callback_Reminder').getRecordTypeId();
		List<Callback_Request__c> cbrlist = [SELECT Id, OwnerId, Status__c,CreatedById FROM Callback_Request__c WHERE RecordTypeId=:SSSW_Callback_ReminderId LIMIT 1];
		Id HoldingQueueId = [SELECT Id FROM Group WHERE DeveloperName='SSSW_Callback_Reminder_Holding_Queue' LIMIT 1].Id;
		
		List<Callback_Request__c> cbrToUpdate = new List<Callback_Request__c>();	

		//.. updating owner to queue to generate pending service id
		for (Callback_Request__c cbr: cbrlist){
			cbrToUpdate.Add(new Callback_Request__c(Id=cbr.Id, OwnerId=HoldingQueueId));
		}
		if(cbrToUpdate.size()> 0){
			update cbrToUpdate;
		}
		
		for (Callback_Request__c cbr: cbrlist){
			cbr.OwnerId=Userinfo.getUserId();
		}
		
		Test.startTest();
		bReturn = OmniChannelService.assignRemindertoAgent(cbrlist);
		Test.stopTest();
		
		System.assert(bReturn, 'Reminder request assigned to agent');
	}

	/**
	 * Tests the following scenarios:
	 * a) the returned Map has a unique set of Case Ids
	 * b) a guest user is able to query the AgentWork object
	 * c) only AgentWork with a UserId that is active is included
	 * 
	 */
	@IsTest
	public static void getActiveUserIdFromLatestAcceptedAgentWork(){
		//Users
		List<User> users = ApplicationTestDataFactory.getUsers(2,true);
		users[0].IsActive = true;
		users[1].IsActive = false;

		//Cases
		List<Case> cases = ApplicationTestDataFactory.getCases(3, true);
		Set<Id> caseIds = new Set<Id>{cases[0].Id, cases[1].Id, cases[2].Id};

		//AgentWork - 2 are for the same case to simulate multiple Accepted AgentWorks
		List<AgentWork> agentWorks = new List<AgentWork>{
			OmniChannelTestDataFactory.getAgentWorks(1, users[0].Id, new Set<Id>{cases[0].Id}, true)[0],
			OmniChannelTestDataFactory.getAgentWorks(1, users[0].Id, new Set<Id>{cases[0].Id}, true)[0],
			OmniChannelTestDataFactory.getAgentWorks(1, users[1].Id, new Set<Id>{cases[1].Id}, true)[0]
		};


		//User (Community User)
		User communityUser = [SELECT Id FROM User WHERE IsActive = True AND ProfileId IN (SELECT Id FROM Profile WHERE Name='Consumer Help and Support Profile') LIMIT 1];

		// =====================================
		// Stubbing
		// =====================================
		AgentWorkSelector mockAgentWorkSelector = (AgentWorkSelector)MockUtility.mockSelector(AgentWorkSelector.class);	 
		UsersSelector mockUsersSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);	 

		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(mockAgentWorkSelector.selectByAcceptedWorkItemIds(
			(Set<Id>)fflib_Match.eq(caseIds), 
			(Set<Object>)fflib_Match.eq(new Set<Object>())		
		)).thenReturn(agentWorks);

		MockUtility.Mocks.when(mockUsersSelector.selectActiveUserById(
			(Set<Id>)fflib_Match.eq(new Set<Id>{users[0].Id, users[1].Id})
		)).thenReturn(new Map<Id,User>{users[0].Id => users[0]});

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<Id, AgentWork> caseIdToUserId = new Map<Id, AgentWork>();
		Boolean exceptionThrown = false;

		System.runAs(communityUser){
			try{
				caseIdToUserId = OmniChannelService.getInstance().getLatestAcceptedAgentWorkWithActiveUser(caseIds);   
			} catch(Exception ex) {
				exceptionThrown = true;
			}		   
		}

		Test.stopTest();

		System.assertEquals(1, caseIdToUserId.size(), 'caseIdToUserId map should contain 1 record');
		System.assertEquals(false, exceptionThrown, 'There should be no Exceptions thrown');

	}
}