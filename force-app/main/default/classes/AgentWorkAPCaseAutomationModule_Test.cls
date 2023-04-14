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
 */
@IsTest
class AgentWorkAPCaseAutomationModule_Test {
   
	/**
	 * Tests the logic in method AgentWorkAPCaseAutomationModule.processUserResponseForPreferredAgent()
	 * 
	 * Scenarios:
	 * a) AgentWork in Opened status - logic for Accepting an Omni pushed Case is fired 
	 * b) AgentWork in Assigned status - no logic performed
	 * c) AgentWork in Declined status - no logic performed
	 * d) AgentWork in Declined status and has Preferred User - logic for Declining an Omni pushed Case is fired
	 * e) AgentWork in DeclinedOnPushTimeout status and has Preferred User - logic for Declining an Omni pushed Case is fired
	 * f) AgentWork in Unavailable status and has Preferred User - logic for Declining an Omni pushed Case is fired
	 * 
	 */
	@IsTest
	static void processUserResponseForPreferredAgent() {
		
		//User
		List<User> users = ApplicationTestDataFactory.getUsers(1, true);

		Map<Id, Group> queues = new Map<Id, Group>(ApplicationTestDataFactory.getGroups(1, 'Queue', true));	
		
		//Case
		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(8, true));
		for(Case csRec : cases.values()){
			csRec.BypassPreferredAgent__c = true;
			csRec.PreferredAgentExpiry__c = Datetime.now();
			csRec.OwnerId = users[0].Id;
			csRec.Origin = 'Email';
			csRec.Status = 'New';
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
		Insert routingRule;

		//AgentWork
		List<AgentWork> records = OmniChannelTestDataFactory.getAgentWorks(8, UserInfo.getUserId(), cases.keySet(), true);
		records[0] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[0], new Map<String, Object> { 'Status' => 'Opened', 'OriginalGroupId' => queues.values()[0].Id});
		records[1] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[1], new Map<String, Object> { 'Status' => 'Assigned'});
		records[2] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[2], new Map<String, Object> { 'Status' => 'Declined'});
		records[3] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[3], new Map<String, Object> { 'Status' => 'Declined', 'PreferredUserId' => users[0].Id });
		records[4] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[4], new Map<String, Object> { 'Status' => 'DeclinedOnPushTimeout', 'PreferredUserId' => users[0].Id });
		records[5] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[5], new Map<String, Object> { 'Status' => 'Unavailable', 'PreferredUserId' => users[0].Id });
		records[6] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[6], new Map<String, Object> { 'Status' => 'Opened', 'OriginalGroupId' => queues.values()[0].Id});
		records[7] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[7], new Map<String, Object> { 'Status' => 'Declined', 'PreferredUserId' => users[0].Id });

		Set<Id> caseIdsToRoute = new Set<Id>{records[3].WorkItemId, records[4].WorkItemId, records[5].WorkItemId};
		List<Case> casesToRoute = new List<Case>{cases.values()[3],cases.values()[4], cases.values()[5]};

		Set<Id> caseIdsAccepted = new Set<Id>{records[0].WorkItemId};
		List<Case> casesAccepted = new List<Case>{cases.values()[0]};

		Set<Id> caseIdsToQuery = new Set<Id>{records[0].WorkItemId, records[3].WorkItemId, records[4].WorkItemId, records[5].WorkItemId};
		List<Case> casesQueried = new List<Case>{cases.values()[0],cases.values()[3],cases.values()[4], cases.values()[5]};

		//old AgentWork
		List<AgentWork> existingRecords = records.deepClone(true, true, true);
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
		SSSWCasesSelector mockCaseSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockCaseSelector.selectById(
				(Set<Id>)fflib_Match.eq(caseIdsToQuery)
		)).thenReturn(new Map<Id, Case>(casesQueried));

		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AgentWorkAPCaseAutomationModule.newInstance().onAfterUpdate(records, new Map<Id, AgentWork>(existingRecords), mockUow);
		
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
			(List<Case>) fflib_Match.eq(new List<Case>{
				new Case(Id = records[0].WorkItemId, AllocateToQueue__c = false, PreferredAgentExpiry__c = null, BypassPreferredAgent__c = false, Bypass_Data_enforcement__c = true)
			}),
			(List<SObjectField>)fflib_Match.eq(new List<SObjectField>{ Case.BypassPreferredAgent__c, Case.PreferredAgentExpiry__c, Case.AllocateToQueue__c, Case.Bypass_Data_enforcement__c }),
			fflib_Match.eqString(AgentWorkAPCaseAutomationModule.class.getName())
		);

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
			(List<Case>) fflib_Match.eq(new List<Case>{
				new Case(Id = records[3].WorkItemId, AllocateToQueue__c = false, PreferredAgentExpiry__c = null, BypassPreferredAgent__c = true, Bypass_Data_enforcement__c = true, OwnerId = queues.values()[0].Id),
				new Case(Id = records[4].WorkItemId, AllocateToQueue__c = false, PreferredAgentExpiry__c = null, BypassPreferredAgent__c = true, Bypass_Data_enforcement__c = true, OwnerId = queues.values()[0].Id),
				new Case(Id = records[5].WorkItemId, AllocateToQueue__c = false, PreferredAgentExpiry__c = null, BypassPreferredAgent__c = true, Bypass_Data_enforcement__c = true, OwnerId = queues.values()[0].Id)
			}),
			(List<SObjectField>)fflib_Match.eq(new List<SObjectField>{ Case.OwnerId, Case.BypassPreferredAgent__c, Case.PreferredAgentExpiry__c, Case.AllocateToQueue__c, Case.Bypass_Data_enforcement__c}),
			fflib_Match.eqString(AgentWorkAPCaseAutomationModule.class.getName())
		);

		// PMD Warning
		System.assert(true);

		Test.stopTest();
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

		AgentWorkAPCaseAutomationModule module = AgentWorkAPCaseAutomationModule.newInstance();
		module.onBeforeInsert(null,null);
		module.onBeforeUpdate(null,null,null);
		module.onAfterUpdate(null,null,null);

		Test.stopTest();

		//An exception should be created when thre are invalid parameters in the onBeforeInsert and onBeforeUpdate
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 3)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), (ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
		
		// PMD warning
		System.assert(true);
	}
}