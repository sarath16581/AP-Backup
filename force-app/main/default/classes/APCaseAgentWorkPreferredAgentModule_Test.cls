/***
 * @author George Nguyen
 * @domain Core
 * @description Test class for APCaseAgentWorkPreferredAgentModule 
 * @changelog
 * 2023-02-16 - George Nguyen - Created
 * 2023-03-18 - Noel Lim - Updated to test routing logic which directly assigns the routed Queue as the Owner.
 */
@IsTest
class APCaseAgentWorkPreferredAgentModule_Test {
   
	@IsTest
	static void processUserResponseForPreferredAgent() {
		
		//User
		List<User> users = ApplicationTestDataFactory.getUsers(1, true);

		Map<Id, Group> queues = new Map<Id, Group>(ApplicationTestDataFactory.getGroups(1, 'Queue', true));	
		
		//Case
		Map<Id, Case> cases = new Map<Id, Case>(ApplicationTestDataFactory.getCases(5, true));
		for(Case csRec : cases.values()){
			csRec.BypassPreferredAgent__c = true;
			csRec.PreferredAgentExpiry__c = Datetime.now();
			csRec.OwnerId = users[0].Id;
			csRec.Origin = 'Email';
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
		List<AgentWork> records = OmniChannelTestDataFactory.getAgentWorks(5, UserInfo.getUserId(), cases.keySet(), true);
		records[0] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[0], new Map<String, Object> { 'Status' => 'Opened'});
		records[1] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[1], new Map<String, Object> { 'Status' => 'Assigned'});
		records[2] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[2], new Map<String, Object> { 'Status' => 'Declined'});
		records[3] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[3], new Map<String, Object> { 'Status' => 'Declined', 'PreferredUserId' => users[0].Id });
		records[4] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(records[4], new Map<String, Object> { 'Status' => 'DeclinedOnPushTimeout', 'PreferredUserId' => users[0].Id });

		Set<Id> caseIdsToRoute = new Set<Id>{ records[3].WorkItemId, records[4].WorkItemId};
		List<Case> casesToRoute = new List<Case>{cases.values()[3],cases.values()[4]};

		List<AgentWork> existingRecords = records.deepClone(true, true, true);
		existingRecords[0] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[0], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[1] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[1], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[2] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[2], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[3] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[3], new Map<String, Object> { 'Status' => 'Assigned'});
		existingRecords[4] = (AgentWork)ApplicationTestDataFactory.setUnwritableFields(existingRecords[4], new Map<String, Object> { 'Status' => 'Assigned'});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		SSSWCasesSelector mockCaseSelector = (SSSWCasesSelector)MockUtility.mockSelector(SSSWCasesSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(mockCaseSelector.selectById(
				(Set<Id>)fflib_Match.eq(caseIdsToRoute)
		)).thenReturn(new Map<Id, Case>(casesToRoute));

		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		APCaseAgentWorkPreferredAgentModule.newInstance().onAfterUpdate(records, new Map<Id, AgentWork>(existingRecords), mockUow);

		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDirty(
			(List<Case>) fflib_Match.eq(new List<Case>{
				new Case(Id = records[0].WorkItemId, BypassPreferredAgent__c = false, AllocateToQueue__c = false, PreferredAgentExpiry__c = null),
				new Case(Id = records[3].WorkItemId, OwnerId = queues.values()[0].Id, BypassPreferredAgent__c = true, PreferredAgentExpiry__c = null),
				new Case(Id = records[4].WorkItemId, OwnerId = queues.values()[0].Id, BypassPreferredAgent__c = true, PreferredAgentExpiry__c = null)
			}),
			(List<SObjectField>)fflib_Match.eq(new List<SObjectField>{ Case.OwnerId, Case.BypassPreferredAgent__c, Case.PreferredAgentExpiry__c, Case.AllocateToQueue__c }),
			fflib_Match.eqBoolean(true),
			fflib_Match.eqString(APCaseAgentWorkPreferredAgentModule.class.getName())
		);

		// PMD Warning
		System.assert(true);

		Test.stopTest();
	}
}