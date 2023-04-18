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
		Boolean exceptionThrown = false;

		System.runAs(communityUser){
			try{
				caseIdsVsAgentWorks = OmniChannelService.getInstance().getCaseIdsWithLatestAcceptedAgentWorks(caseIds);   
			} catch(Exception ex) {
				exceptionThrown = true;
			}		   
		}

		Test.stopTest();

		System.assertEquals(1, caseIdsVsAgentWorks.size(), 'caseIdsVsAgentWorks map should contain 1 record');
		System.assertEquals(false, exceptionThrown, 'There should be no Exceptions thrown');

	}

	@IsTest 
	static void testClassVariables(){

		QM__c custSetting = QM__c.getOrgDefaults();
		List<Group> omniQueues = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN ('SSSW_Routing_Preferred_Agent_Queue','SSSW_Closed_Omnichannel_Cases','SSSW_Routing_Holding_Queue','SSSW_BOH_Group_4')];
		for(Group omniQueue : omniQueues){
			if(omniQueue.DeveloperName == 'SSSW_Routing_Preferred_Agent_Queue'){
				custSetting.PreferredAgentQueueId__c = omniQueue.Id;
			}
			
			if(omniQueue.DeveloperName == 'SSSW_Closed_Omnichannel_Cases'){
				custSetting.ClosedQueueId__c = omniQueue.Id;
			}

			if(omniQueue.DeveloperName == 'SSSW_Routing_Holding_Queue'){
				custSetting.HoldingQueueId__c = omniQueue.Id;
			}

			if(omniQueue.DeveloperName == 'SSSW_BOH_Group_4'){
				custSetting.DefaultOmniQueueId__c = omniQueue.Id;
			}
		}
		Insert custSetting;


		System.assert(String.isEmpty(OmniChannelService.getInstance().preferredAgentQueueId) == false, 'Preferred Agent Queue Id is empty');
		System.assert(String.isEmpty(OmniChannelService.getInstance().omniClosedCaseQueueId) == false, 'Omni Closed Case Queue Id is empty');
		System.assert(String.isEmpty(OmniChannelService.getInstance().omniHoldingQueueId) == false, 'Omni Holding Queue Id is empty');
		System.assert(String.isEmpty(OmniChannelService.getInstance().omniDefaultQueueId) == false, 'Omni Default Queue Id is empty');
	}

	@IsTest
	public static void getUserIdsWithSkills(){
		//Users
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		users[0].IsActive = true;

		Map<Id, Skill> skills = new Map<Id, Skill>(OmniChannelTestDataFactory.getSkills(1, true));
		Map<Id, ServiceResource> serviceResources = new Map<Id, ServiceResource>(OmniChannelTestDataFactory.getServiceResources(1, 'A', true));
		serviceResources.values()[0].RelatedRecordId = users[0].id;
		List<ServiceResourceSkill> serviceResourceSkills = OmniChannelTestDataFactory.getServiceResourceSkills(1, skills.keySet(), serviceResources.keySet(), true);

		// =====================================
		// Stubbing
		// =====================================
		ServiceResourceSkillSelector mockServiceResourceSkillSelector = (ServiceResourceSkillSelector)MockUtility.mockSelector(ServiceResourceSkillSelector.class);	 

		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(mockServiceResourceSkillSelector.selectByActiveServiceResourceRelatedRecordIdsAndSkills(
			(Set<Id>)fflib_Match.eq(new Set<Id> {users[0].id}), 
			(Set<String>)fflib_Match.eq(new Set<String> { skills.values()[0].DeveloperName }), 
			(Set<Object>)fflib_Match.eq(new Set<Object> { ServiceResourceSkillSelector.Options.WITH_SERVICE_RESOURCE })		
		)).thenReturn(serviceResourceSkills);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		Set<Id> result = OmniChannelService.getInstance().getUserIdsWithSkills(new Set<Id> {users[0].id}, new Set<String> { skills.values()[0].DeveloperName });

		Test.stopTest();

		System.assertEquals(1, result.size(), 'result map should contain 1 record');
		System.assertEquals(true, result.contains(users[0].id), 'It should return the same id');

	}
}