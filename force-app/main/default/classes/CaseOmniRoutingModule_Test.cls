/**
 * @author George Nguyen
 * @group Tests
 * @tag CaseOmniRoutingModule
 * @domain MyCustomer
 * @description Test class for CaseOmniRoutingModule
 * 
 * @changelog
 * 2022-11-03	George Nguyen	Created
 * 2022-12-06	Noel Lim		Added test method for testAssignToPreferredAgent
 * 2023-01-25	Noel Lim		Added logic to assign and test for SSSW and StarTrack recordtypes
 * 2023-02-06	Noel Lim		Added logic to test clearPreferredAgentPSRs and resetBypassPreferredAgentFlag
 */

@IsTest
public with sharing class CaseOmniRoutingModule_Test {
   
	
	
	/**
	 * Tests the logic in method CaseOmniRoutingModule.onBeforeInsert()
	 * Scenarios:
	 * a) Case secondary priority updated - Case has priority, and correct recordtype
	 * b) Case secondary priority not updated - Case not in Omni queue
	 * c) Case secondary priority not updated - incorrect recordtype
	 * d) Case secondary priority not updated - Case is coming from an Omni queue
	 * 
	 */
	@IsTest
	static void onBeforeInsert() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();

		//Omni queue
		Group omniQueue = ApplicationTestDataFactory.getGroups(1, true)[0];
		QueueRoutingConfig routingConfig = new QueueRoutingConfig();
		ApplicationTestDataFactory.generateRecordIds(new List<SObject> {routingConfig});
		omniQueue.QueueRoutingConfigId = routingConfig.Id;

		//Cases
		List<Case> cases = ApplicationTestDataFactory.getCases(5, true);
		cases[0].OwnerId = UserInfo.getUserId(); // invalid case - not going to an Omni queue
		cases[0].Priority = 'Low';

		cases[1].OwnerId = omniQueue.Id;
		cases[1].Priority = 'Low';

		cases[2].OwnerId = omniQueue.Id; 
		cases[2].Priority = ''; // invalid case - no Priority

		cases[3].OwnerId = omniQueue.Id;
		cases[3].Priority = 'Low';

		cases[4].OwnerId = omniQueue.Id;
		cases[4].Priority = 'Low'; // invalid case - incorrect recordtype


		Set<Id> ssswRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
		Id recTypeId;
		if(ssswRecTypes.size()>0){
			recTypeId = ssswRecTypes.iterator().next(); 
			cases[0].recordTypeId = recTypeId;
			cases[1].recordTypeId = recTypeId;
			cases[2].recordTypeId = recTypeId;
		}

		Set<Id> starTrackRecordTypes = new RecordTypesSelector().selectByDeveloperNameLike('Case', 'StarTrack').keySet();
		if(starTrackRecordTypes.size()>0){
			recTypeId = starTrackRecordTypes.iterator().next(); 
			cases[3].recordTypeId = recTypeId;
		}

		Map<Id,String> caseRecordTypes = Utility.getsObjectRecordTypeNames('Case');
		for(Id tempRtypeId : caseRecordTypes.keySet()){
			if(ssswRecTypes.contains(tempRTypeId) == false &&
			starTrackRecordTypes.contains(tempRtypeId) == false){
				cases[4].recordTypeId = tempRtypeId;
				break;
			}
		}

		// =====================================
		// Stubbing
		// =====================================

		OmniChannelService service = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		GroupsSelector grSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(grSelector.selectOmniQueues((Set<Object>)fflib_Match.eq(new Set<Object>()))).thenReturn(new Map<Id, Group>{ omniQueue.id => omniQueue });

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		CaseOmniRoutingModule.newInstance().onBeforeInsert(cases, uow);

		((OmniChannelService)MockUtility.Mocks.verify(service, MockUtility.Mocks.times(1))).setOmniRoutingSecondaryPriority(
																								(List<Case>)fflib_Match.eq(new List<Case> { cases[1],cases[3]}), 
																								(Boolean)fflib_Match.eq(true)
																							);

		// PMD Warning
		System.assert(true);

		Test.stopTest();
	}

	/**
	 * Tests the logic in method CaseOmniRoutingModule.onBeforeUpdate()
	 * Scenarios:
	 * a) Case secondary priority updated - Case has priority, and correct recordtype
	 * b) Case secondary priority not updated - Case not in Omni queue
	 * c) Case secondary priority not updated - incorrect recordtype
	 * d) Case secondary priority not updated - Case is coming from an Omni queue
	 * e) Case's preferred agent PSR deleted  - Case is being routed from the Preferred Agent holding queue
	 * f) Case moving from a Queue to a User  - Case Bypass Preferred Agent flag is reset
	 * g) Case Bypass Preferred Agent not set - incorect record type (for SSSW cases only)
	 * 
	 */
	@IsTest
	static void onBeforeUpdate() {
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();

		//Omni queue
		Group omniQueue = ApplicationTestDataFactory.getGroups(1, true)[0];
		QueueRoutingConfig routingConfig = new QueueRoutingConfig();
		ApplicationTestDataFactory.generateRecordIds(new List<SObject> {routingConfig});
		omniQueue.QueueRoutingConfigId = routingConfig.Id;

		//Preferred Agent holding queue
		QM__c custSetting = QM__c.getOrgDefaults();
		QueueSobject preferredAgentQueue = [SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'SSSW_Routing_Preferred_Agent_Queue' AND SobjectType = 'Case' LIMIT 1];
		custSetting.PreferredAgentQueueId__c = preferredAgentQueue.QueueId;
		Insert custSetting;
		Id preferredAgentQueueId = preferredAgentQueue.QueueId;

		//Agent User
		List<User> agents = ApplicationTestDataFactory.getUsers(1, true);

		//Cases
		List<Case> cases = ApplicationTestDataFactory.getCases(7, true);
		cases[0].OwnerId = UserInfo.getUserId(); // invalid case - not going to an Omni queue
		cases[0].Priority = 'Low';

		cases[1].OwnerId = omniQueue.Id;
		cases[1].Priority = 'Low';

		cases[2].OwnerId = omniQueue.Id; 
		cases[2].Priority = 'High';

		cases[3].OwnerId = omniQueue.Id; 
		cases[3].Priority = 'High';

		cases[4].OwnerId = omniQueue.Id; 
		cases[4].Priority = 'High'; // invalid case - incorrect recordtype

		cases[5].OwnerId = agents[0].Id; //clear preferred Agent PSRs
		cases[5].BypassPreferredAgent__c = true; //reset Bypass Preferred Agent

		cases[6].OwnerId = agents[0].Id; 
		cases[6].BypassPreferredAgent__c = true; // invalid case - incorrect recordtype


		List<Case> oldCases = cases.deepClone(true, false, false);
		oldCases[0].OwnerId = omniQueue.Id; // invalid case
		oldCases[0].Priority = 'High';

		oldCases[1].OwnerId = UserInfo.getUserId();
		oldCases[1].Priority = 'Low';

		oldCases[2].OwnerId = omniQueue.Id; 
		oldCases[2].Priority = ''; 

		oldCases[3].OwnerId = UserInfo.getUserId();
		oldCases[3].Priority = ''; 

		oldCases[4].OwnerId = UserInfo.getUserId();
		oldCases[4].Priority = ''; 

		oldCases[5].OwnerId = preferredAgentQueueId;

		oldCases[6].OwnerId = preferredAgentQueueId;


		Set<Id> ssswRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
		Id recTypeId;
		if(ssswRecTypes.size()>0){
			recTypeId = ssswRecTypes.iterator().next(); 
			cases[0].recordTypeId = recTypeId;
			cases[1].recordTypeId = recTypeId;
			cases[2].recordTypeId = recTypeId;
			cases[5].recordTypeId = recTypeId;
		}

		Set<Id> starTrackRecordTypes = new RecordTypesSelector().selectByDeveloperNameLike('Case', 'StarTrack').keySet();
		if(starTrackRecordTypes.size()>0){
			recTypeId = starTrackRecordTypes.iterator().next(); 
			cases[3].recordTypeId = recTypeId;
			cases[6].recordTypeId = recTypeId;
		}

		Map<Id,String> caseRecordTypes = Utility.getsObjectRecordTypeNames('Case');
		for(Id tempRtypeId : caseRecordTypes.keySet()){
			if(ssswRecTypes.contains(tempRTypeId) == false &&
			starTrackRecordTypes.contains(tempRtypeId) == false){
				cases[4].recordTypeId = tempRtypeId;
				break;
			}
		}

		//PSR
		Id serviceChannelId = OmniChannelTestDataFactory.getServiceChannels(1, 'Case', 'Priority', true)[0].Id;
		List<PendingServiceRouting> psrs = OmniChannelTestDataFactory.getPendingServiceRoutings(1, serviceChannelId, new Set<Id>{ cases[5].Id }, true);

		// =====================================
		// Stubbing
		// =====================================

		OmniChannelService service = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		GroupsSelector grSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);
		PendingServiceRoutingSelector pendingServiceRoutingSelector = (PendingServiceRoutingSelector) MockUtility.mockSelector(PendingServiceRoutingSelector.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(grSelector.selectOmniQueues(
			(Set<Object>)fflib_Match.eq(new Set<Object>())
		)).thenReturn(new Map<Id, Group>{ omniQueue.id => omniQueue });

		MockUtility.Mocks.when(pendingServiceRoutingSelector.selectByWorkItemId(
			(Set<Id>) fflib_Match.eq(new Set<Id>{ cases[5].Id }),
			(Set<Object>) fflib_Match.eq(new Set<Object>())
		)).thenReturn(psrs);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================

		Test.startTest();

		CaseOmniRoutingModule.newInstance().onBeforeUpdate(cases, new Map<Id, Case>(oldCases), uow);

		((OmniChannelService)MockUtility.Mocks.verify(service, MockUtility.Mocks.times(1))).setOmniRoutingSecondaryPriority(
																								(List<Case>)fflib_Match.eq(new List<Case> { cases[1], cases[2], cases[3] }), 
																								(Boolean)fflib_Match.eq(false)
																							);
		
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1)))
																							.registerDeleted((List<PendingServiceRouting>)fflib_Match.eq(psrs));
											
		// PMD Warning
		System.assert(true);

		Test.stopTest();

		System.assertEquals(false, cases[5].BypassPreferredAgent__c, 'BypassPreferredAgent field should have been reset');
	}


	/**
	 * Tests the logic in method CaseOmniRoutingModule.assignToPreferredAgent
	 * Scenarios:
	 * a) PSR inserted with correct PreferredUserId
	 * b) PSR not inserted - no AgentWork exists
	 * c) PSR not inserted - BypassPreferredAgent is true
	 * d) PSR not inserted - PreferredAgentExpiry is blank
	 * e) PSR not inserted - has Accepted AgentWork, but in Omni Queue 
	 * 
	 */
	@isTest
	static void assignToPreferredAgent(){

		//Queues
		QM__c custSetting = QM__c.getOrgDefaults();
		QueueSobject preferredAgentQueue = [SELECT QueueId FROM QueueSobject WHERE Queue.DeveloperName = 'SSSW_Routing_Preferred_Agent_Queue' AND SobjectType = 'Case' LIMIT 1];
		custSetting.PreferredAgentQueueId__c = preferredAgentQueue.QueueId;
		Insert custSetting;
		Id preferredAgentQueueId = preferredAgentQueue.QueueId;

		Group omniQueue = OmniChannelService.Cache.queuesWithRoutingConfig.values()[0].queue;		

		//Users
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		users[0].IsActive = true;	
		
		//DateTime
		DateTime oneHourFromNow = DateTime.now().addHours(1);

		//Cases
		List<Case> cases = ApplicationTestDataFactory.getCases(5, true);	

		Set<Id> ssswRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
		if(ssswRecTypes.size()>0){
			Id recTypeId = ssswRecTypes.iterator().next(); 
			for(Case tempCase : cases){
				tempCase.recordTypeId = recTypeId;
			}
		}

		cases[0].OwnerId = omniQueue.Id; //a) PSR inserted with correct PreferredUserId
		cases[0].Priority = 'Low';
		cases[0].BypassPreferredAgent__c = false;
		cases[0].PreferredAgentExpiry__c = oneHourFromNow;

		cases[1].OwnerId = omniQueue.Id; //b) PSR not inserted - no Accepted Agent Work exists
		cases[0].Priority = 'Low';
		cases[1].BypassPreferredAgent__c = false;
		cases[1].PreferredAgentExpiry__c = oneHourFromNow;

		cases[2].OwnerId = omniQueue.Id; //c) PSR not inserted - BypassPreferredAgent is true
		cases[2].BypassPreferredAgent__c = true;
		cases[2].PreferredAgentExpiry__c = oneHourFromNow;

		cases[3].OwnerId = omniQueue.Id; //d) PSR not inserted - PreferredAgentExpiry is blank
		cases[3].BypassPreferredAgent__c = false;
		cases[3].PreferredAgentExpiry__c = null;

		cases[4].OwnerId = omniQueue.Id; //e) PSR not inserted - has Accepted AgentWork, but currently in Omni Queue 
		cases[4].Priority = 'Low';
		cases[4].BypassPreferredAgent__c = false;
		cases[4].PreferredAgentExpiry__c = oneHourFromNow;

		

		//Clone to simulate existing Case records to test Case Update 
		List<Case> oldCases = new List<Case>{
			cases[0].clone(true),
			cases[1].clone(true),
			cases[2].clone(true),
			cases[3].clone(true),
			cases[4].clone(true)
		};

		for(Case tempCase : oldCases){
			tempCase.OwnerId = users[0].Id;
		}
		oldCases[4].OwnerId = omniQueue.Id;

		//AgentWorks
		List<AgentWork> agentWorks = OmniChannelTestDataFactory.getAgentWorks(3, users[0].Id, new Set<Id>{cases[0].Id, cases[2].Id, cases[3].Id, cases[4].Id}, true);

		// =====================================
		// Stubbing
		// =====================================

		OmniChannelService mockOmniChannelService = (OmniChannelService)MockUtility.mockUtility(OmniChannelService.class);
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		
		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockOmniChannelService.getLatestAcceptedAgentWorkWithActiveUser(
			(Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id,cases[1].Id})
		)).thenReturn(new Map<Id,AgentWork>{cases[0].Id => agentWorks[0]} );

		MockUtility.Mocks.when(mockUow.registerNew(
			(List<PendingServiceRouting>)fflib_Match.anyList()
		)).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseOmniRoutingModule module = CaseOmniRoutingModule.newInstance();		
		module.onBeforeUpdate(cases, new Map<Id,Case>(oldCases), mockUow);

		Test.stopTest();

		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1)))
			.registerNew((List<PendingServiceRouting>)fflib_Match.anyList());

		// PMD warning
		System.assertEquals(preferredAgentQueueId, cases[0].OwnerId, 'Case should be assigned to Preferred Agent Queue');		
		System.assertEquals(users[0].Id, ((PendingServiceRouting)MockUtility.mockUnitOfWorkDMLs[0]).PreferredUserId, 'Inserted PSR should have the correct PreferredUserId assigned');
		System.assertEquals(omniQueue.Id, cases[1].OwnerId, 'Case without accepted AgentWork should be in Omni Queue');
		System.assertEquals(omniQueue.Id, cases[2].OwnerId, 'Case with BypassPreferredAgent = true should be in Omni Queue');
		System.assertEquals(omniQueue.Id, cases[3].OwnerId, 'Case with blank PreferredAgentExpiry should be in Omni Queue');
		System.assertEquals(omniQueue.Id, cases[4].OwnerId, 'Case that is coming from an Omni Queue should be in new Omni Queue');
	}

	/**
	 * test the Exception handling on the module onBeforeInsert and onBeforeUpdate methods
	 */
	@isTest
	static void testExceptionHandling(){

		// =====================================
		// Data Preparation
		// =====================================
		LogSeverityLevelValue__c logLevel = LogSeverityLevelValue__c.getInstance(UserInfo.getOrganizationId());
		logLevel.LoggingLevel__c = UTIL_ErrorConstants.SEVERITY_LEVEL_ERROR;
		insert logLevel;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);

		 // =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseOmniRoutingModule module = CaseOmniRoutingModule.newInstance();
		module.onBeforeInsert(null,null);
		module.onBeforeUpdate(null,null,null);

		Test.stopTest();

		//An exception should be created when thre are invalid parameters in the onBeforeInsert and onBeforeUpdate
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 2)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
		
		// PMD warning
		System.assert(true);
	}

}