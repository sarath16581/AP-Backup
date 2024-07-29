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
 * 1.2	2/02/2022	Noel Lim						Update test method getUserIdFromLatestAcceptedAgentWork to getCaseIdsWithLatestAcceptedAgentWorks, only return active UserIds. 
 * 													Update secondaryPriorityRanges from a 50-point range to a 150-point range
 * 													Add queuesToAgentTypesShouldReturnCustomMetadata
 *		17/07/2024  Ranjeewa Silva					Added tests to verify changes to support preferred agent selection for Unified cases.
 *													Replaced references to 'getCaseIdsWithLatestAcceptedAgentWorks' with new method 'getLatestAcceptedAgentWork'
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
	static void rerouteCasesWithPreferredAgentByPass() {
		Case aCase = (Case)ApplicationTestDataFactory.setUnwritableFields(new Case(), new Map<String, Object>{ 'CreatedDate' => Datetime.now().addDays(-10)});
		aCase.BypassPreferredAgent__c = false;
		PendingServiceRouting psr = (PendingServiceRouting)ApplicationTestDataFactory.setUnwritableFields(new PendingServiceRouting(), new Map<String, Object>{ 'WorkItem' => aCase});
		List<PendingServiceRouting> psrs = new List<PendingServiceRouting>{psr};

		Test.startTest();

		List<Case> actual = OmniChannelService.getInstance().rerouteCasesWithPreferredAgentByPass(psrs);
		System.assertEquals(1, actual.size(), 'Should return the case');
		System.assertEquals(true, actual[0].BypassPreferredAgent__c, 'It should be true to bypass preferred agent logic');
		System.assertEquals(true, actual[0].AllocateToQueue__c, 'It should be true to force the routing rules to run again');
		System.assertEquals(true, actual[0].Bypass_Data_enforcement__c, 'It should be true to bypass validations');
		System.assertEquals(true, actual[0].Email_Bypass_Data_enforcement__c, 'It should be true to bypass emails');

		Test.stopTest();

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
	static void queuesToAgentTypesShouldReturnCustomMetadata() {
		CacheManager.settings.CacheEnabled__c = true;
		OmniChannelService.Cache.resetStaticVariablesForUnitTestOnly();

		List<SSSW_Queue_to_Agent_Type__mdt> listQAT = [SELECT QueueId__c, AgentType__c from SSSW_Queue_to_Agent_Type__mdt];
		Map<String,String> queuesToAgentType = new Map<String,String>();

		//necessary for when the Org does not have any Custom Metadata records yet. This Custom Metadata relies on QueueId so it cannot be deployed via metadata
		if(listQAT.isEmpty()){
			Group queueRec = ApplicationTestDataFactory.getGroups(1, true)[0];
			queuesToAgentType = OmniChannelTestDataFactory.getQueuesToAgentType(queueRec.Id);
			
			CacheManager.put('QUEUES_TO_AGENT_TYPE', queuesToAgentType);
		} else {
			for(SSSW_Queue_to_Agent_Type__mdt qat : listQAT){
				queuesToAgentType.put(qat.QueueId__c,qat.AgentType__c);
			}
		}
		
		Set<String> queueIds = queuesToAgentType.keySet();
		Id queueId = queueIds.iterator().next();

		System.assertEquals(queuesToAgentType.size(), OmniChannelService.Cache.queuesToAgentType.size(), 'it should return the same number of records');
		System.assertEquals(
			queuesToAgentType.get(queueId), OmniChannelService.Cache.queuesToAgentType.get(queueId), 'should match');

		// test loading from cache
		OmniChannelService.Cache.resetStaticVariablesForUnitTestOnly();
		CacheManager.put('QUEUES_TO_AGENT_TYPE', new Map<String, String>{queueId => queuesToAgentType.get(queueId)});
		System.assertEquals(queuesToAgentType.get(queueId), OmniChannelService.Cache.queuesToAgentType.get(queueId), 'should match');
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

		aCase = (Case)ApplicationTestDataFactory.setUnwritableFields(aCase, new Map<String, Object>{ 'CreatedDate' => Datetime.now().addDays(-151)});
		psr = (PendingServiceRouting)ApplicationTestDataFactory.setUnwritableFields(new PendingServiceRouting(), new Map<String, Object>{ 'WorkItem' => aCase});
		psrs = new List<PendingServiceRouting>{psr};

		psr.WorkItem.Priority = 'Critical';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(850, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'Low';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(4850, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'Urgent';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(850, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'Medium';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(3850, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'Normal';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(1850, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'Regular';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(2850, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
		psr.WorkItem.Priority = 'High';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(psrs);
		System.assertEquals(1850, psr.SecondaryRoutingPriority, 'Should be set to the lowest value of range');
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

		aCase = (Case)ApplicationTestDataFactory.setUnwritableFields(aCase, new Map<String, Object>{ 'CreatedDate' => Datetime.now().addDays(-151)});
		cases = new List<Case>{aCase};
		
		aCase.Priority = 'Critical';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('850', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'Low';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('4850', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'Urgent';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('850', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'Medium';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('3850', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'Normal';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('1850', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'Regular';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('2850', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');
		aCase.Priority = 'High';
		OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(cases, false);
		System.assertEquals('1850', aCase.OmniRoutingSecondaryPriority__c, 'Should be set to the lowest value of range');

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
	public static void getCaseIdsWithLatestAcceptedAgentWorks(){
		//Users
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		users[0].IsActive = true;

		//Cases
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		Set<Id> caseIds = new Set<Id>{cases[0].Id, cases[1].Id};

		//AgentWork - 2 are for the same case to simulate multiple Accepted AgentWorks
		List<AgentWork> agentWorks = new List<AgentWork>{
			OmniChannelTestDataFactory.getAgentWorks(1, users[0].Id, new Set<Id>{cases[0].Id}, true)[0],
			OmniChannelTestDataFactory.getAgentWorks(1, users[0].Id, new Set<Id>{cases[0].Id}, true)[0]
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
		
		MockUtility.Mocks.when(mockAgentWorkSelector.selectByAcceptedWorkItemIdsAndActiveUser(
			(Set<Id>)fflib_Match.eq(caseIds), 
			(Set<Object>)fflib_Match.eq(new Set<Object>())		
		)).thenReturn(agentWorks);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Map<Id, AgentWork> caseIdsVsAgentWorks = new Map<Id, AgentWork>();

		System.runAs(communityUser){
			try{
				caseIdsVsAgentWorks = OmniChannelService.getInstance().getLatestAcceptedAgentWork(new Map<Id, Case>(cases), false);
			} catch(Exception ex) {
				Assert.fail('Unexpected exception thrown running as community user : ' + ex.getMessage());
			}		   
		}

		Test.stopTest();

		System.assertEquals(1, caseIdsVsAgentWorks.size(), 'caseIdsVsAgentWorks map should contain 1 record');
	}

	@IsTest 
	static void testClassVariables() {
		// =====================================
		// Data Preparation
		// =====================================

		List<Group> queues = ApplicationTestDataFactory.getGroups(6, true);

		QM__c custSetting = new QM__c();
		custSetting.PreferredAgentQueueId__c = queues[0].Id;
		custSetting.ClosedQueueId__c = queues[1].Id;
		custSetting.HoldingQueueId__c = queues[2].Id;
		custSetting.DefaultOmniQueueId__c = queues[3].Id;
		custSetting.UnifiedDefaultOmniQueueId__c = queues[4].Id;
		custSetting.UnifiedPreferredAgentExpiry__c = 1;

		Insert custSetting;

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		Assert.areEqual(queues[0].Id, OmniChannelService.getInstance().preferredAgentQueueId, 'Preferred Agent Queue Id is not as configured in custom setting.');
		Assert.areEqual(queues[1].Id, OmniChannelService.getInstance().omniClosedCaseQueueId, 'Omni Closed Case Queue Id is not as configured in custom setting.');
		Assert.areEqual(queues[2].Id, OmniChannelService.getInstance().omniHoldingQueueId, 'Omni Holding Queue Id is not as configured in custom setting.');
		Assert.areEqual(queues[3].Id, OmniChannelService.getInstance().omniDefaultQueueId, 'Omni Default Queue Id is not as configured in custom setting.');
		Assert.areEqual(queues[4].Id, OmniChannelService.getInstance().omniUnifiedDefaultQueueId, 'Unified preferred agent Queue Id is not as configured in custom setting.');
		Assert.areEqual(1, OmniChannelService.omniUnifiedPreferredAgentExpiry, 'Unified preferred agent expiry is not as configured in custom setting.');

		Test.stopTest();
	}

	/**
	 * Tests selecting AgentWork on work items when 'includeChildContactRequestWorkItems=false' does not consider AgentWork
	 * on child ContactRequests.
	 */
	@IsTest
	public static void testGetLatestAcceptedAgentWorkExcludingChildContactRequests() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(3, true);
		for (Case caseRec : cases) {
			caseRec.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		}

		// setup contact requests for each case
		Account consumer = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		List<ContactRequest> contactRequests = ApplicationTestDataFactoryCase.getContactRequests(3, new List<Id>{cases[0].Id, cases[1].Id, cases[2].Id}, consumer.PersonContactId, true);

		User agentUser = ApplicationTestDataFactory.getUsers(1, true)[0];

		// setup existing AgentWork on case records and contact requests.
		// cases[0] has 2 AgentWork records, cases[1] has only 1 AgentWork record, cases[2] has no AgentWork record.
		List<AgentWork> agentWorkOnCases = OmniChannelTestDataFactory.getAgentWorks(3, agentUser.Id, new List<Id>{cases[0].Id, cases[0].Id, cases[1].Id}, true);
		// each contact request has one AgentWork record.
		List<AgentWork> agentWorkOnContactRequests = OmniChannelTestDataFactory.getAgentWorks(3, agentUser.Id, new List<Id>(new Map<Id,ContactRequest>(contactRequests).keySet()), true);

		// =====================================
		// Stubbing
		// =====================================
		AgentWorkSelector mockAgentWorksSelector = (AgentWorkSelector)MockUtility.mockSelector(AgentWorkSelector.class);
		ContactRequestsSelector mockContactRequestsSelector = (ContactRequestsSelector)MockUtility.mockSelector(ContactRequestsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockAgentWorksSelector.selectByAcceptedWorkItemIdsAndActiveUser((Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id, cases[1].Id, cases[2].Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(agentWorkOnCases);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id, AgentWork> results = OmniChannelService.getInstance().getLatestAcceptedAgentWork(new Map<Id, Case>(cases), false);

		Test.stopTest();

		Assert.isNotNull(results, 'Expected a valid AgentWorks mapping for cases, but received null');
		Assert.areEqual(2, results.size(), 'Expected AgentWork mappings only for cases with existing AgentWork.');
		Assert.isTrue(results.containsKey(cases[0].Id), 'Expected AgentWork mapping for cases[0], it has 2 previous AgentWork records.');
		Assert.isTrue(results.containsKey(cases[1].Id), 'Expected AgentWork mapping for cases[1], it has 1 previous AgentWork records.');
		Assert.isFalse(results.containsKey(cases[2].Id), 'Expected no AgentWork mapping for cases[2], it has no previous AgentWork records.');
		Assert.areEqual(agentWorkOnCases[0].Id, results.get(cases[0].Id).Id, 'Expected only one AgentWork to be returned for cases[0] based on the selector query results order.');
		Assert.areEqual(agentWorkOnCases[2].Id, results.get(cases[1].Id).Id, 'Expected only AgentWork available to be returned for cases[1].');

		// verify contact request selector is not called as we are setting includeChildContactRequestWorkItems=false to exclude contact request agent work.
		((ContactRequestsSelector)MockUtility.Mocks.verify(mockContactRequestsSelector, 0)).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
	}

	/**
	 * Tests selecting AgentWork on work items when 'includeChildContactRequestWorkItems=true' consider AgentWork
	 * on child ContactRequests.
	 */
	@IsTest
	public static void testGetLatestAcceptedAgentWorkIncludingChildContactRequests() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(3, true);
		for (Case caseRec : cases) {
			caseRec.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		}

		// setup contact requests for each case
		Account consumer = ApplicationTestDataFactory.getPersonAccounts(1, true)[0];
		List<ContactRequest> contactRequests = ApplicationTestDataFactoryCase.getContactRequests(3, new List<Id>{cases[0].Id, cases[1].Id, cases[2].Id}, consumer.PersonContactId, true);

		User agentUser = ApplicationTestDataFactory.getUsers(1, true)[0];

		// setup existing AgentWork on case records and contact requests.
		// cases[0] has 2 AgentWork records, cases[1] has only 1 AgentWork record, cases[2] has no AgentWork record.
		List<AgentWork> agentWorkOnCases = OmniChannelTestDataFactory.getAgentWorks(3, agentUser.Id, new List<Id>{cases[0].Id, cases[0].Id, cases[1].Id}, true);
		// each contact request has one AgentWork record.
		List<AgentWork> agentWorkOnContactRequests = OmniChannelTestDataFactory.getAgentWorks(3, agentUser.Id, new List<Id>(new Map<Id,ContactRequest>(contactRequests).keySet()), true);

		// setup AcceptedDateTime on AgentWork so we can ensure the latest AgentWork record is selected

		// related to cases[0]. should not be selected as the latest.
		agentWorkOnCases[0] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorkOnCases[0], new Map<String, Object>{
				'AcceptDateTime' => Datetime.now().addDays(-5)
		});
		// related to cases[0]. should be selected as latest AgentWork for cases[0].
		agentWorkOnCases[1] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorkOnCases[1], new Map<String, Object>{
				'AcceptDateTime' => Datetime.now().addDays(-2)
		});
		// related to cases[1]. should not be selected as more recent AgentWork on child contact request.
		agentWorkOnCases[2] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorkOnCases[2], new Map<String, Object>{
				'AcceptDateTime' => Datetime.now().addDays(-5)
		});
		// related to contactRequests[0] linked to cases[0]. should not be selected as more recent AgentWork on Case.
		agentWorkOnContactRequests[0] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorkOnContactRequests[0], new Map<String, Object>{
				'AcceptDateTime' => Datetime.now().addDays(-4)
		});
		// related to contactRequests[1] linked to cases[1]. should be selected as latest AgentWork on Case.
		agentWorkOnContactRequests[1] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorkOnContactRequests[1], new Map<String, Object>{
				'AcceptDateTime' => Datetime.now().addDays(-4)
		});
		// related to contactRequests[2] linked to cases[2]. should be selected as latest AgentWork on Case.
		agentWorkOnContactRequests[2] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorkOnContactRequests[2], new Map<String, Object>{
				'AcceptDateTime' => Datetime.now().addDays(-10)
		});

		// =====================================
		// Stubbing
		// =====================================
		AgentWorkSelector mockAgentWorksSelector = (AgentWorkSelector)MockUtility.mockSelector(AgentWorkSelector.class);
		ContactRequestsSelector mockContactRequestsSelector = (ContactRequestsSelector)MockUtility.mockSelector(ContactRequestsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockContactRequestsSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true))).thenReturn(contactRequests);
		Set<Id> workItemIds = new Set<Id>{cases[0].Id, cases[1].Id, cases[2].Id, contactRequests[0].Id, contactRequests[1].Id, contactRequests[2].Id};
		// ensure AgentWork returned by mock selector is orderd simulating order by in query
		List<AgentWork> agentWorkResults = new List<AgentWork>{agentWorkOnCases[1], agentWorkOnCases[0], agentWorkOnCases[2], agentWorkOnContactRequests[0], agentWorkOnContactRequests[1], agentWorkOnContactRequests[2]};
		agentWorkResults.addAll(agentWorkOnContactRequests);
		MockUtility.Mocks.when(mockAgentWorksSelector.selectByAcceptedWorkItemIdsAndActiveUser((Set<Id>)fflib_Match.eq(workItemIds), (Set<Object>)fflib_Match.anyObject())).thenReturn(agentWorkResults);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id, AgentWork> results = OmniChannelService.getInstance().getLatestAcceptedAgentWork(new Map<Id, Case>(cases), true);

		Test.stopTest();

		Assert.isNotNull(results, 'Expected a valid AgentWorks mapping for cases, but received null');
		Assert.areEqual(3, results.size(), 'Expected AgentWork mappings for cases with existing AgentWork on either the case or child contact requests.');
		Assert.isTrue(results.containsKey(cases[0].Id), 'Expected AgentWork mapping for cases[0], it has 2 direct AgentWork records and 1 AgentWork on child ContactRequest.');
		Assert.isTrue(results.containsKey(cases[1].Id), 'Expected AgentWork mapping for cases[1], it has 1 direct AgentWork record and 1 AgentWork on child ContactRequest.');
		Assert.isTrue(results.containsKey(cases[2].Id), 'Expected AgentWork mapping for cases[2], it has no direct AgentWork record, but has 1 AgentWork on child ContactRequest.');
		Assert.areEqual(agentWorkOnCases[1].Id, results.get(cases[0].Id).Id, 'Expected the last accepted AgentWork to be returned for cases[0] considering AgentWork on child contact requests.');
		Assert.areEqual(agentWorkOnContactRequests[1].Id, results.get(cases[1].Id).Id, 'Expected the last accepted AgentWork to be returned for cases[1] considering AgentWork on child contact requests.');
		Assert.areEqual(agentWorkOnContactRequests[2].Id, results.get(cases[2].Id).Id, 'Expected the last accepted AgentWork to be returned for cases[2] considering AgentWork on child contact requests.');

		// verify contact request selector is called as we are setting includeChildContactRequestWorkItems=true to include contact request agent work.
		((ContactRequestsSelector)MockUtility.Mocks.verify(mockContactRequestsSelector, 1)).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean());
	}

	/**
	 * Ensure agent's eligibility to accept work assigned to a omni channel queue configured with skills based routing
	 * is based on the skills assigned to agent. (Existing logic for SSSW cases checks for skills configured in custom setting:
	 * QM__c.getOrgDefaults().PreferredAgentSkillDeveloperNames__c)
	 */
	@IsTest
	public static void testVerifyEligibilityToAcceptWorkAssignedToSkillsBasedOmniQueues() {
		// =====================================
		// Data Preparation
		// =====================================
		QueueRoutingConfig queueRoutingConfig = ApplicationTestDataFactory.getQueueRoutingConfigs(1, true)[0];
		queueRoutingConfig.IsAttributeBased = true;

		Group omniQueue = ApplicationTestDataFactory.getGroups(1, 'Queue', true)[0];
		omniQueue.QueueRoutingConfigId = queueRoutingConfig.Id;

		// setup agents with skills
		List<User> users = ApplicationTestDataFactory.getUsers(3, true);
		Skill skill = OmniChannelTestDataFactory.getSkills(1, true)[0];
		List<ServiceResource> serviceResources = OmniChannelTestDataFactory.getServiceResources(2, 'A', true);
		// only users[0] and users[1] are setup for skills. users[2] is not eligible based on skills.
		serviceResources[0].RelatedRecordId = users[0].Id;
		serviceResources[1].RelatedRecordId = users[1].Id;

		List<ServiceResourceSkill> serviceResourceSkills = OmniChannelTestDataFactory.getServiceResourceSkills(2, skill.Id, new Set<Id>{serviceResources[0].Id, serviceResources[1].Id}, true);
		serviceResourceSkills[0].ServiceResource = serviceResources[0];
		serviceResourceSkills[1].ServiceResource = serviceResources[1];

		OmniChannelService.getInstance().preferredAgentQualifySkillDeveloperNames = new Set<String>{'test'};

		// =====================================
		// Stubbing
		// =====================================
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);
		QueueRoutingConfigSelector mockQueueRoutingConfigSelector = (QueueRoutingConfigSelector)MockUtility.mockSelector(QueueRoutingConfigSelector.class);
		ServiceResourceSkillSelector mockServiceResourceSkillSelector = (ServiceResourceSkillSelector)MockUtility.mockSelector(ServiceResourceSkillSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockGroupsSelector.selectOmniQueues((Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Group>{omniQueue.Id => omniQueue});
		MockUtility.Mocks.when(mockQueueRoutingConfigSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{queueRoutingConfig.Id}))).thenReturn(new List<QueueRoutingConfig>{queueRoutingConfig});
		MockUtility.Mocks.when(mockServiceResourceSkillSelector.selectByActiveServiceResourceRelatedRecordIdsAndSkills((Set<Id>)fflib_Match.eq(new Set<Id>{users[0].Id, users[1].Id, users[2].Id}), (Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(serviceResourceSkills);
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id, Set<Id>> results = OmniChannelService.getInstance().verifyEligibilityForOmniChannelQueues(new Map<Id, Set<Id>>{
				omniQueue.Id => new Map<Id, User>(users).keySet()
		});

		Test.stopTest();

		Assert.isNotNull(results, 'Expected a valid results, but got null');
		Assert.areEqual(2, results.get(omniQueue.Id).size(), 'Expected only eligible agents with skills to be returned.');
		Assert.isTrue(results.get(omniQueue.Id).contains(users[0].Id), 'Eligible user with skills not returned.');
		Assert.isTrue(results.get(omniQueue.Id).contains(users[1].Id), 'Eligible user with skills not returned.');
	}

	/**
	 * Ensure agent's eligibility to accept work assigned to a omni channel queue configured with queue based routing
	 * is based on queue membership.
	 */
	@IsTest
	public static void testVerifyEligibilityToAcceptWorkAssignedToQueueBasedOmniQueues() {
		// =====================================
		// Data Preparation
		// =====================================
		QueueRoutingConfig queueRoutingConfig = ApplicationTestDataFactory.getQueueRoutingConfigs(1, true)[0];
		queueRoutingConfig.IsAttributeBased = false;

		Group omniQueue = ApplicationTestDataFactory.getGroups(1, 'Queue', true)[0];
		omniQueue.QueueRoutingConfigId = queueRoutingConfig.Id;

		// setup agents
		List<User> users = ApplicationTestDataFactory.getUsers(3, true);

		// only users[0] and users[1] are members of omni queue. users[2] is not eligible based on queue membership.
		// users[0] is a direct member of the omni queue
		GroupMember omniQueueMemberUser = ApplicationTestDataFactory.getGroupMembers(1, new List<Id>{omniQueue.Id}, new List<Id>{users[0].Id}, true)[0];

		// users[1] is a member of omni queue through another public group.
		Group regularPublicGroup = ApplicationTestDataFactory.getGroups(1, 'Regular', true)[0];
		GroupMember regularPublicGroupMember = ApplicationTestDataFactory.getGroupMembers(1, new List<Id>{regularPublicGroup.Id}, new List<Id>{users[1].Id}, true)[0];
		regularPublicGroup = (Group)ApplicationTestDataFactory.setChildRelationships(regularPublicGroup, new Map<String, List<SObject>>{
				'GroupMembers' => new List<GroupMember>{regularPublicGroupMember}
		});
		// make the public group 'regularPublicGroup' member of omni queue.
		GroupMember omniQueueMemberGroup = ApplicationTestDataFactory.getGroupMembers(1, new List<Id>{omniQueue.Id}, new List<Id>{regularPublicGroup.Id}, true)[0];

		// set child relationships on omni queue
		omniQueue = (Group)ApplicationTestDataFactory.setChildRelationships(omniQueue, new Map<String, List<SObject>>{
				'GroupMembers' => new List<GroupMember>{omniQueueMemberUser, omniQueueMemberGroup}
		});

		// =====================================
		// Stubbing
		// =====================================
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);
		QueueRoutingConfigSelector mockQueueRoutingConfigSelector = (QueueRoutingConfigSelector)MockUtility.mockSelector(QueueRoutingConfigSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockGroupsSelector.selectOmniQueues((Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Group>{omniQueue.Id => omniQueue});
		MockUtility.Mocks.when(mockGroupsSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{omniQueue.Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Group>{omniQueue.Id => omniQueue});
		MockUtility.Mocks.when(mockGroupsSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{regularPublicGroup.Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Group>{regularPublicGroup.Id => regularPublicGroup});
		MockUtility.Mocks.when(mockQueueRoutingConfigSelector.selectById((Set<Id>)fflib_Match.eq(new Set<Id>{queueRoutingConfig.Id}))).thenReturn(new List<QueueRoutingConfig>{queueRoutingConfig});
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id, Set<Id>> results = OmniChannelService.getInstance().verifyEligibilityForOmniChannelQueues(new Map<Id, Set<Id>>{
				omniQueue.Id => new Map<Id, User>(users).keySet()
		});

		Test.stopTest();

		Assert.isNotNull(results, 'Expected a valid results, but got null');
		Assert.areEqual(2, results.get(omniQueue.Id).size(), 'Expected only eligible agents with skills to be returned.');
		Assert.isTrue(results.get(omniQueue.Id).contains(users[0].Id), 'Eligible user with skills not returned.');
		Assert.isTrue(results.get(omniQueue.Id).contains(users[1].Id), 'Eligible user with skills not returned.');
	}
}