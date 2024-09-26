/***
 * @author George Nguyen
 * @domain Core
 * @description Test class for AgentWorkAPCaseAutomationModule 
 * @changelog
 * 2023-02-16 - George Nguyen - Created
 * 2023-03-18 - Noel Lim - Updated to test routing logic which directly assigns the routed Queue as the Owner, and handle AgentWork with Unavailable status
 * 2023-03-31 - Noel Lim - Updated test methods to test:
 *							 a) implement 2 registerDirty() calls
 *							 b) generate Status Tracking records on Accept
 *							 c) new method populateCaseField
  * 2023-04-14 - Noel Lim - Updated class name from APCaseAgentWorkPreferredAgentModule_Test to AgentWorkAPCaseAutomationModule_Test
  * 2023-06-05 - Nathan Franklin - Fixing failing test class
  * 2024-07-22 - Ranjeewa Silva - Test class updates after uplifting the module to new ApplicationModule framework.
 */
@IsTest
class AgentWorkCaseAutomationModule_Test {
   
	/**
	 * Tests the logic in method processUserResponseToOmniPush, except for the StatusTracking Logic
	 * 
	 * Scenarios:
	 * a) AgentWork in Opened status - logic for Accepting an Omni pushed Case is fired 
	 * b) AgentWork in Assigned status - no logic performed
	 * c) AgentWork in Declined status - no logic performed
	 * d) AgentWork in Declined status and has Preferred User - logic for Declining an Omni pushed Case is fired
	 * e) AgentWork in DeclinedOnPushTimeout status and has Preferred User - logic for Declining an Omni pushed Case is fired
	 * f) AgentWork in Unavailable status and has Preferred User - logic for Declining an Omni pushed Case is fired
	 * g) AgentWork in Opened status, previous was Opened Status - no logic performed
	 * h) AgentWork in Declined status, previous was Declined Status-  no logic performed
	 */
	@IsTest
	static void checkCaseUpdatesFromUserResponsesToOmniPush() {
		
		//User
		List<User> users = ApplicationTestDataFactory.getUsers(1, true);

		Map<Id, Group> queues = new Map<Id, Group>(ApplicationTestDataFactory.getGroups(1, 'Queue', true));	
		
		//Case
		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(8, true));
		Set<Id> ssswRecTypes = Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
		Id recTypeId = ssswRecTypes.iterator().next();

		for(Case csRec : cases.values()){
			csRec.BypassPreferredAgent__c = true;
			csRec.PreferredAgentExpiry__c = Datetime.now();
			csRec.OwnerId = users[0].Id;
			csRec.Origin = 'Email';
			csRec.Status = 'New';
			csRec.RecordTypeId = recTypeId;
		}

		//Routing Rule
		SSSWRouting__c routingRule = new SSSWRouting__c();
		Id routingRuleRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'SSSWRouting__c' AND DeveloperName = 'SSSWRouting'].Id;
		routingRule.RecordTypeId = routingRuleRecordTypeId;
		routingRule.Match_Rules_On__c = 'All';
		routingRule.Origin__c = 'Email';
		routingRule.IsActive__c = true;
		routingRule.Queue_ID__c = queues.values()[0].Id;
		routingRule.Sequence__c = 1;
		insert routingRule;

		//AgentWork
		List<AgentWork> agentWorks = OmniChannelTestDataFactory.getAgentWorks(8, UserInfo.getUserId(), cases.keySet(), true);
		agentWorks[0] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorks[0], new Map<String, Object> { 'Status' => 'Opened', 'OriginalGroupId' => queues.values()[0].Id});
		agentWorks[1] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorks[1], new Map<String, Object> { 'Status' => 'Assigned'});
		agentWorks[2] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorks[2], new Map<String, Object> { 'Status' => 'Declined'});
		agentWorks[3] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorks[3], new Map<String, Object> { 'Status' => 'Declined', 'PreferredUserId' => users[0].Id });
		agentWorks[4] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorks[4], new Map<String, Object> { 'Status' => 'DeclinedOnPushTimeout', 'PreferredUserId' => users[0].Id });
		agentWorks[5] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorks[5], new Map<String, Object> { 'Status' => 'Unavailable', 'PreferredUserId' => users[0].Id });
		agentWorks[6] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorks[6], new Map<String, Object> { 'Status' => 'Opened', 'OriginalGroupId' => queues.values()[0].Id});
		agentWorks[7] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorks[7], new Map<String, Object> { 'Status' => 'Declined', 'PreferredUserId' => users[0].Id });

		Set<Id> caseIdsToQuery = new Set<Id>{agentWorks[0].WorkItemId, agentWorks[3].WorkItemId, agentWorks[4].WorkItemId, agentWorks[5].WorkItemId};
		List<Case> casesQueried = new List<Case>{cases.values()[0],cases.values()[3],cases.values()[4], cases.values()[5]};

		//old AgentWork
		List<AgentWork> existingRecords = agentWorks.deepClone(true, true, true);
		existingRecords[0] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[0], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[1] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[1], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[2] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[2], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[3] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[3], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[4] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[4], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[5] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[5], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[6] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[6], new Map<String, Object> { 'Status' => 'Opened'});
		existingRecords[7] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[7], new Map<String, Object> { 'Status' => 'Declined'});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CasesSelector mockCaseSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockCaseSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true))).thenReturn(casesQueried);

		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		new AgentWorkCaseAutomationModule().onAfterUpdate(agentWorks, new Map<Id, AgentWork>(existingRecords), mockUow);
		
		// ((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
		// 	(List<Case>) fflib_Match.eq(new List<Case>{
		// 		new Case(Id = agentWorks[0].WorkItemId, AllocateToQueue__c = false, PreferredAgentExpiry__c = null, BypassPreferredAgent__c = false, Bypass_Data_enforcement__c = true)
		// 	}),
		// 	(List<SObjectField>)fflib_Match.eq(new List<SObjectField>{ Case.BypassPreferredAgent__c, Case.PreferredAgentExpiry__c, Case.AllocateToQueue__c, Case.Bypass_Data_enforcement__c }),
		// 	fflib_Match.eqString(AgentWorkAPCaseAutomationModule.class.getName())
		// );

		fflib_ArgumentCaptor dirtyRecordsCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);
		fflib_ArgumentCaptor dirtySObjectFieldsCaptor = fflib_ArgumentCaptor.forClass(List<SObjectField>.class);

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 2)).registerDirty((List<Case>)dirtyRecordsCaptor.capture(), (List<SObjectField>)dirtySObjectFieldsCaptor.capture(), fflib_Match.anyString());
		List<Object> dirtyRecords = (List<Object>)dirtyRecordsCaptor.getAllValues();
		List<Object> dirtySObjectFields = (List<Object>)dirtySObjectFieldsCaptor.getAllValues();

		System.debug(dirtyRecords);
		System.debug(dirtySObjectFields);

		List<Case> dirtyRecords1 = (List<Case>)dirtyRecords[0];
		List<Case> dirtyRecords2 = (List<Case>)dirtyRecords[1];

		System.assertEquals(1, dirtyRecords1.size());
		System.assertEquals(agentWorks[0].WorkItemId, dirtyRecords1[0].Id);
		System.assertEquals(false, dirtyRecords1[0].BypassPreferredAgent__c);
		System.assertEquals(false, dirtyRecords1[0].AllocateToQueue__c);
		System.assertEquals(true, dirtyRecords1[0].Bypass_Data_enforcement__c);
		System.assertEquals(null, dirtyRecords1[0].PreferredAgentExpiry__c);

		System.assertEquals(3, dirtyRecords2.size());
		System.assertEquals(agentWorks[3].WorkItemId, dirtyRecords2[0].Id);
		System.assertEquals(true, dirtyRecords2[0].Bypass_Data_enforcement__c);
		System.assertEquals(true, dirtyRecords2[0].BypassPreferredAgent__c);
		System.assertEquals(true, dirtyRecords2[0].AllocateToQueue__c);
		System.assertEquals(null, dirtyRecords2[0].PreferredAgentExpiry__c);
		System.assertEquals(true, CaseRoutingService.getInstance().isCaseRoutingEligibilityBypassed(dirtyRecords2[0].Id));

		System.assertEquals(agentWorks[4].WorkItemId, dirtyRecords2[1].Id);
		System.assertEquals(true, dirtyRecords2[1].Bypass_Data_enforcement__c);
		System.assertEquals(true, dirtyRecords2[1].BypassPreferredAgent__c);
		System.assertEquals(true, dirtyRecords2[1].AllocateToQueue__c);
		System.assertEquals(null, dirtyRecords2[1].PreferredAgentExpiry__c);
		System.assertEquals(true, CaseRoutingService.getInstance().isCaseRoutingEligibilityBypassed(dirtyRecords2[1].Id));

		System.assertEquals(agentWorks[5].WorkItemId, dirtyRecords2[2].Id);
		System.assertEquals(true, dirtyRecords2[2].Bypass_Data_enforcement__c);
		System.assertEquals(true, dirtyRecords2[2].BypassPreferredAgent__c);
		System.assertEquals(true, dirtyRecords2[2].AllocateToQueue__c);
		System.assertEquals(null, dirtyRecords2[2].PreferredAgentExpiry__c);
		System.assertEquals(true, CaseRoutingService.getInstance().isCaseRoutingEligibilityBypassed(dirtyRecords2[2].Id));

		List<SObjectField> dirtySObjectFields1 = (List<SObjectField>)dirtySObjectFields[0];
		List<SObjectField> dirtySObjectFields2 = (List<SObjectField>)dirtySObjectFields[1];

		System.assertEquals(true, dirtySObjectFields1.contains(Case.BypassPreferredAgent__c));
		System.assertEquals(true, dirtySObjectFields1.contains(Case.PreferredAgentExpiry__c));
		System.assertEquals(true, dirtySObjectFields1.contains(Case.AllocateToQueue__c));
		System.assertEquals(true, dirtySObjectFields1.contains(Case.Bypass_Data_enforcement__c));

		System.assertEquals(true, dirtySObjectFields2.contains(Case.BypassPreferredAgent__c));
		System.assertEquals(true, dirtySObjectFields2.contains(Case.PreferredAgentExpiry__c));
		System.assertEquals(true, dirtySObjectFields2.contains(Case.AllocateToQueue__c));
		System.assertEquals(true, dirtySObjectFields2.contains(Case.Bypass_Data_enforcement__c));

		Test.stopTest();

		// PMD Warning
		System.assert(true);
	}

	/**
	 * Tests the logic related to Status Tracking method in processUserResponseToOmniPush
	 * Note the logic for Status Tracking in CaseTrackingHelper does not use the framework, so test data from database is used.
	 * 
	 */
	@IsTest
	static void checkStatusTrackingRecordsGenerated() {
		
		User agentUser = [SELECT Id FROM User WHERE IsActive = TRUE AND Profile.Name = :SSSWConstants.SSSW_AGENT_PROFILE LIMIT 1];
		Group omniBOHQueue = [SELECT Id,DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'SSSW_BOH_Group_2' LIMIT 1];
		
		//Case Setup - for StatusTracking
		Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
		Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
														accRecTypeMap.get('Organisation').getRecordTypeId());
		Database.insert(acc);

		Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
		Database.insert(con);
		
		Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
		Case insertedCase = TestUtility.createCase('Enquiry','In Progress','General Enquiry',acc.Id,con.Id,
												caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
		insertedCase.ownerId = agentUser.Id;

		Database.insert(insertedCase);
		CaseTrackingHelper.isUpdateStatusTrackRecursive = false;

		//AgentWork
		List<AgentWork> agentWorks = OmniChannelTestDataFactory.getAgentWorks(1, UserInfo.getUserId(), new Set<Id>{insertedCase.Id}, true);
		agentWorks[0] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorks[0], new Map<String, Object> { 'Status' => 'Opened', 'OriginalGroupId' => omniBOHQueue.Id}); 
		agentWorks.addAll(OmniChannelTestDataFactory.getAgentWorks(1, UserInfo.getUserId(), new Set<Id>{insertedCase.Id}, true));
		agentWorks[1] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorks[1], new Map<String, Object> { 'Status' => 'Opened', 'PreferredUserId' => agentUser.Id, 'OriginalGroupId' => null});
		agentWorks.addAll(OmniChannelTestDataFactory.getAgentWorks(1, UserInfo.getUserId(), new Set<Id>{insertedCase.Id}, true));
		agentWorks[2] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(agentWorks[2], new Map<String, Object> { 'Status' => 'Opened'}); 

		//old AgentWork
		List<AgentWork> existingRecords = agentWorks.deepClone(true, true, true);
		existingRecords[0] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[0], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[1] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[1], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[2] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[2], new Map<String, Object> { 'Status' => 'Assigned'});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		new AgentWorkCaseAutomationModule().onAfterUpdate(new List<AgentWork>{agentWorks[0]}, new Map<Id, AgentWork>{existingRecords[0].Id => existingRecords[0]}, mockUow);
		new AgentWorkCaseAutomationModule().onAfterUpdate(new List<AgentWork>{agentWorks[1]}, new Map<Id, AgentWork>{existingRecords[1].Id => existingRecords[1]}, mockUow);
		new AgentWorkCaseAutomationModule().onAfterUpdate(new List<AgentWork>{agentWorks[2]}, new Map<Id, AgentWork>{existingRecords[2].Id => existingRecords[2]}, mockUow);

		Integer count = [SELECT COUNT() FROM StatusTracking__c WHERE Case__c = :insertedCase.Id];
		System.assertEquals(4, count, '4 StatusTracking records should exist - 1 from Case insert and 3 from the module onAfterUpdate() calls');
		System.assertEquals(false, CaseTrackingHelper.isSetStatusTrackRecursive, 'Recursive flag in CaseTrackingHelper should be set to false after the AgentWork logic has run');
		Test.stopTest();
	}

	/**
	 * Tests the logic related to populateCaseField method.
	 * 
	 */
	@IsTest
	static void checkCaseLookupField() {
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		InteractionService mockInteractionService = (InteractionService)MockUtility.mockUtility(InteractionService.class);

		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact ct = ApplicationTestDataFactory.getContacts(1, acc.Id, true)[0];
		List<Case> caseList = ApplicationTestDataFactoryCase.getCases(4, true);

		ContactRequest cr = ApplicationTestDataFactoryCase.getContactRequests(1, caseList[0].Id, ct.Id, true)[0];
		cr.Case__c = caseList[0].Id; 

		VoiceCall vc = ApplicationTestDataFactoryCase.getVoiceCalls(new List<Id>{caseList[1].Id}, true)[0];
		vc.Case__c = caseList[1].Id; 

		LiveChatTranscript lc = ApplicationTestDataFactoryCase.getLiveChatTranscripts(1, new List<Id>{caseList[2].Id}, true)[0];
		
		String source = 'AgentWorkCaseAutomationModule.populateCaseField';
		List<AgentWork> agentWorks = OmniChannelTestDataFactory.getAgentWorks(4, UserInfo.getUserId(), new Set<Id>{cr.id, vc.id, lc.id, caseList[3].id}, true);
		Map<SObjectType, Set<Id>> mappedObjectTypeAndIds = new Map<SObjectType, Set<Id>>{
			ContactRequest.SObjectType => new Set<Id>{cr.id},
			VoiceCall.SObjectType => new Set<Id>{vc.id},
			LiveChatTranscript.SObjectType => new Set<Id>{lc.id}
		};
		List<AgentWork> qualifiedAgentWorkRecords = new List<AgentWork>{agentWorks[0], agentWorks[1], agentWorks[2]};
		Map<Id, SObject> workItems = new Map<Id, SObject>{cr.id => cr, vc.id => vc, lc.id => lc};

		// =====================================
		// Stubbing
		// =====================================
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockInteractionService.retrieveInteractionRecords(
																(Map<SObjectType, Set<Id>>)fflib_Match.eq(mappedObjectTypeAndIds)															
															)).thenReturn(
																workItems
															);

		MockUtility.Mocks.stopStubbing();
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		new AgentWorkCaseAutomationModule().onBeforeInsert(agentWorks, mockUow);

		Test.stopTest();

		// PMD Warning
		System.assertEquals(caseList[3].Id,agentWorks[3].Case__c,'Case Id assigned to the AgentWork record is incorrect');

		((InteractionService) MockUtility.Mocks.verify(mockInteractionService, MockUtility.Mocks.times(1))).populateCaseFieldOnAgentWorks(
															(Map<Id, SObject>)fflib_Match.eq(workItems), 
															(List<AgentWork>)fflib_Match.eq(qualifiedAgentWorkRecords), 
															(ApplicationUnitOfWork)fflib_Match.eq(mockUow),
															(String)fflib_Match.eq(source)
														);
	}


	/**
	 * test the Exception handling on the module onBeforeInsert, onBeforeUpdate, onAfterUpdate methods
	 */
	@IsTest
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

		AgentWorkCaseAutomationModule module = new AgentWorkCaseAutomationModule();
		module.onBeforeInsert(null,null);
		module.onAfterUpdate(null,null,null);

		Test.stopTest();

		//An exception should be created when thre are invalid parameters in the onBeforeInsert and onBeforeUpdate
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 2)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
		
		// PMD warning
		System.assert(true);
	}
}