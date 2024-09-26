/**
 * @author Seth Heang
 * @group Tests
 * @tag ScheduledAction__c, Case
 * @domain Core
 * @description Test class for CaseMonitoring3DayReminderEmailAction
 * @changelog
 * 2024-07-28 - Seth Heang - Created
 * 2024-09-24 - Ranjeewa Silva - Updated tests to assert sending customer notification email.
 */
@IsTest(IsParallel=true)
public with sharing class CaseMonitoring3DayReminderEmailActTest {

	@TestSetup
	static void testSetup(){
		QM__c queueSettings = QM__c.getOrgDefaults();
		Group unifiedMonitoringQueue = ApplicationTestDataFactory.getGroups(1, 'queue', true)[0];
		unifiedMonitoringQueue.Name = 'Unified Customer Service Monitoring Queue';

		queueSettings.UnifiedDefaultMonitoringQueueId__c = unifiedMonitoringQueue.Id;
		insert queueSettings;
	}

	/**
	 * Scenario: Test add() method to insert ScheduledAction__c successfully
	 */
	@IsTest
	static void testAddScheduledAction() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;

		Datetime caseCreatedDate = Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'CreatedDate' => caseCreatedDate });
		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUow.registerNew((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseMonitoring3DayReminderEmailAction action = CaseMonitoring3DayReminderEmailAction.newInstance();
		action.add(new Map<Id, Case>{ testCase.Id => testCase }, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor insertableScheduledActionCaptor = fflib_ArgumentCaptor.forClass(List<ScheduledAction__c>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<ScheduledAction__c>) insertableScheduledActionCaptor.capture());
		List<ScheduledAction__c> insertableScheduledAction = (List<ScheduledAction__c>) insertableScheduledActionCaptor.getValue();

		Assert.areEqual(action.getName(), insertableScheduledAction[0].ActionType__c, 'Expected action type to match but instead got ' + insertableScheduledAction[0].ActionType__c);
		Assert.areEqual(testCase.Id, insertableScheduledAction[0].Case__c, 'Expected case Id to match but instead got ' + insertableScheduledAction[0].Case__c);
		Assert.areEqual(true, insertableScheduledAction[0].Active__c, 'Expected active flag to set to true');
		Assert.areEqual(
			BusinessHoursService.newInstance().calculateNextBusinessDateTime(caseCreatedDate, 3),
			insertableScheduledAction[0].ScheduledDate__c,
			'Expected schedule dateTime to be in next 3 days but instead got: ' + insertableScheduledAction[0].ScheduledDate__c
		);
	}

	/**
	 * Scenario: Test remove() method to remove ScheduledAction__c successfully
	 */
	@IsTest
	static void testRemoveScheduledAction() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> testCases = ApplicationTestDataFactory.getCases(2, true);
		String actionType = CaseMonitoring3DayReminderEmailAction.newInstance().getName();
		List<ScheduledAction__c> scheduledActions = ApplicationTestDataFactory.getScheduledActions(2, 'Test Scheduled Action', actionType, System.now(), testCases[0].Id, true);
		scheduledActions[1].Case__c = testCases[1].Id;
		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		MockUtility.Mocks.startStubbing();
		((ApplicationUnitOfWork) MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockUow)).registerDeleted((List<SObject>) fflib_Match.anyObject());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseMonitoring3DayReminderEmailAction action = CaseMonitoring3DayReminderEmailAction.newInstance();
		action.remove(new List<Id>(new Map<Id, ScheduledAction__c>(scheduledActions).keySet()), mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor deletedScheduledActionCapture = fflib_ArgumentCaptor.forClass(ScheduledAction__c.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerDeleted((List<ScheduledAction__c>) deletedScheduledActionCapture.capture());
		List<ScheduledAction__c> deletedScheduledActions = (List<ScheduledAction__c>) deletedScheduledActionCapture.getValue();
		Set<Id> deletedIds = new Set<Id>{ deletedScheduledActions[0].Id, deletedScheduledActions[1].Id };
		Assert.areEqual(true, deletedIds.contains(scheduledActions[0].Id), 'Expected the scheduled action to be deleted but did not ' + scheduledActions[0].Id);
		Assert.areEqual(true, deletedIds.contains(scheduledActions[1].Id), 'Expected the scheduled action to be deleted but did not ' + scheduledActions[1].Id);
	}

	/**
	 * Scenario: Test setup() method to insert ScheduledAction__c Successfully
	 */
	@IsTest
	static void testSetupToAddScheduledAction() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCase.EnquirySubType__c = 'Late Item';
		testCase.Exclude_Subscription_Automation__c = false;
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'ContactEmail' => 'seth@test.com' });

		Datetime caseCreatedDate = Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'CreatedDate' => caseCreatedDate });

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUow.registerNew((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseMonitoring3DayReminderEmailAction action = CaseMonitoring3DayReminderEmailAction.newInstance();
		action.setup(new Map<Id, Case>{ testCase.Id => testCase }, mockUow, false);

		Test.stopTest();

		fflib_ArgumentCaptor insertableScheduledActionCaptor = fflib_ArgumentCaptor.forClass(List<ScheduledAction__c>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<ScheduledAction__c>) insertableScheduledActionCaptor.capture());
		List<ScheduledAction__c> insertableScheduledAction = (List<ScheduledAction__c>) insertableScheduledActionCaptor.getValue();

		Assert.areEqual(action.getName(), insertableScheduledAction[0].ActionType__c, 'Expected action type to match but instead got ' + ((ScheduledAction__c) MockUtility.mockUnitOfWorkDMLs[0]).ActionType__c);
		Assert.areEqual(testCase.Id, insertableScheduledAction[0].Case__c, 'Expected case Id to match but instead got ' + ((ScheduledAction__c) MockUtility.mockUnitOfWorkDMLs[0]).Case__c);
		Assert.areEqual(true, insertableScheduledAction[0].Active__c, 'Expected active flag to set to true');
		Assert.areEqual(
			BusinessHoursService.newInstance().calculateNextBusinessDateTime(caseCreatedDate, 3),
			insertableScheduledAction[0].ScheduledDate__c,
			'Expected schedule dateTime to be in next 3 days but instead got: ' + insertableScheduledAction[0].ScheduledDate__c
		);
	}

	/**
	 * Scenario: Test validate() to return one successful and one failure validation
	 *			Where one case meets the criteria and the other does not meet criteria for 5 days case monitoring
	 */
	@IsTest
	static void testValidateToReturnBothSuccessfulAndFailedValidation() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> testCases = ApplicationTestDataFactory.getCases(2, true);
		testCases[0].RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;

		testCases[0].OwnerId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCases[0].RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCases[0].EnquirySubType__c = 'Late Item';
		testCases[0].Exclude_Subscription_Automation__c = false;
		testCases[0] = (Case) ApplicationTestDataFactory.setUnwritableFields(testCases[0], new Map<String, Object>{ 'ContactEmail' => 'seth@test.com' });

		testCases[1].OwnerId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCases[1].RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCases[1].EnquirySubType__c = 'Late Item';
		testCases[1].Exclude_Subscription_Automation__c = true;
		testCases[1] = (Case) ApplicationTestDataFactory.setUnwritableFields(testCases[1], new Map<String, Object>{ 'ContactEmail' => 'seth@test.com' });

		Datetime caseCreatedDate = Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
		testCases[0] = (Case) ApplicationTestDataFactory.setUnwritableFields(testCases[0], new Map<String, Object>{ 'CreatedDate' => caseCreatedDate });
		testCases[1] = (Case) ApplicationTestDataFactory.setUnwritableFields(testCases[1], new Map<String, Object>{ 'CreatedDate' => caseCreatedDate });

		// =====================================
		// Stubbing
		// =====================================
		// NONE

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseMonitoring3DayReminderEmailAction action = CaseMonitoring3DayReminderEmailAction.newInstance();
		Map<Id, Boolean> caseValidationResult = action.validate(new Map<Id, Case>(testCases), null);

		Test.stopTest();

		Assert.areNotEqual(0, caseValidationResult.size(), 'Expect the case validation map size to not be 0 but instead got 0');
		Assert.areEqual(true, caseValidationResult.get(testCases[0].Id), 'Expect the case validation to be true but instead got: ' + caseValidationResult.get(testCases[0].Id));
		Assert.areEqual(false, caseValidationResult.get(testCases[1].Id), 'Expect the case validation to be false but instead got: ' + caseValidationResult.get(testCases[1].Id));
	}

	/**
	 * Scenario: Test getCaseIdHasNoIndividualAgentAssignmentsMap()
	 *			And Validate that correct Case status map is returned with one status being true and other false
	 *			Where one case has individual agent and the other does not
	 */
	@IsTest
	static void testBuildCaseIdHasNoIndividualAgentAssignmentsMap() {
		// =====================================
		// Data Preparation
		// =====================================
		List<User> testUsers = ApplicationTestDataFactory.getUsers(2, true);
		testUsers[0].IsActive = true;
		testUsers[1].IsActive = true;

		List<Case> testCases = ApplicationTestDataFactory.getCases(2, true);
		testCases[0].RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCases[1].RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCases[0] = (Case) ApplicationTestDataFactory.setUnwritableFields(testCases[0], new Map<String, Object>{ 'CreatedById' => testUsers[0].Id });
		testCases[1] = (Case) ApplicationTestDataFactory.setUnwritableFields(testCases[1], new Map<String, Object>{ 'CreatedById' => testUsers[0].Id });

		List<AgentWork> agentWorks = new List<AgentWork>{
			OmniChannelTestDataFactory.getAgentWorks(1, testUsers[0].Id, new Set<Id>{ testCases[0].Id }, true)[0],
			OmniChannelTestDataFactory.getAgentWorks(1, testUsers[0].Id, new Set<Id>{ testCases[0].Id }, true)[0],
			OmniChannelTestDataFactory.getAgentWorks(1, testUsers[0].Id, new Set<Id>{ testCases[1].Id }, true)[0],
			OmniChannelTestDataFactory.getAgentWorks(1, testUsers[0].Id, new Set<Id>{ testCases[1].Id }, true)[0]
		};

		agentWorks[0].Case__c = testCases[0].Id;
		agentWorks[1].Case__c = testCases[0].Id;
		agentWorks[2].Case__c = testCases[1].Id;
		agentWorks[3].Case__c = testCases[1].Id;

		agentWorks[0] = (AgentWork) ApplicationTestDataFactory.setUnwritableFields(agentWorks[0], new Map<String, Object>{ 'Case__r' => testCases[0] });
		agentWorks[1] = (AgentWork) ApplicationTestDataFactory.setUnwritableFields(agentWorks[1], new Map<String, Object>{ 'Case__r' => testCases[0] });
		agentWorks[2] = (AgentWork) ApplicationTestDataFactory.setUnwritableFields(agentWorks[2], new Map<String, Object>{ 'Case__r' => testCases[1] });
		agentWorks[3] = (AgentWork) ApplicationTestDataFactory.setUnwritableFields(agentWorks[3], new Map<String, Object>{ 'Case__r' => testCases[1] });

		// Case 1 has Queue assignment and ownerId as case creator, therefore has no individual agent assignment excluding creator
		agentWorks[0].OwnerId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		agentWorks[1].OwnerId = testUsers[0].Id;

		// Case 2 has ownerId as user Id that is not case creator
		agentWorks[2].OwnerId = testUsers[0].Id;
		agentWorks[3].OwnerId = testUsers[1].Id; // different user Id from case creator

		Set<Id> caseIds = new Map<Id, Case>(testCases).keySet();
		// =====================================
		// Stubbing
		// =====================================
		AgentWorkSelector mockAgentWorkSelector = (AgentWorkSelector) MockUtility.mockSelector(AgentWorkSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockAgentWorkSelector.selectByWorkItemIds((Set<Id>) fflib_Match.eq(caseIds), (Set<Object>) fflib_Match.eq(new Set<Object>{ AgentWorkSelector.Options.WITH_CASE }))).thenReturn(agentWorks);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id, Boolean> caseIdHasNoIndividualAgentAssignmentMap = CaseMonitoring3DayReminderEmailAction.newInstance().getCaseIdHasNoIndividualAgentAssignmentsMap(new Map<Id, Case>(testCases));

		Test.stopTest();
		Assert.areEqual(
			true,
			caseIdHasNoIndividualAgentAssignmentMap.get(testCases[0].Id),
			'Expect the Case to have no individual agent flag set to True but instead got: ' + caseIdHasNoIndividualAgentAssignmentMap.get(testCases[0].Id)
		);
		Assert.areEqual(
			false,
			caseIdHasNoIndividualAgentAssignmentMap.get(testCases[1].Id),
			'Expect the Case to have no individual agent flag set to False but instead got: ' + caseIdHasNoIndividualAgentAssignmentMap.get(testCases[0].Id)
		);
	}

	/**
	 * Scenario: Test execute() to send reminder email for AusPost Case successfully
	 */
	@IsTest
	static void testSendReminderEmailForAusPostCase() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.ProductSubCategory__c = 'Parcel Post';
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'ContactEmail' => 'seth@test.com' });

		String actionType = CaseMonitoring3DayReminderEmailAction.newInstance().getName();
		ScheduledAction__c scheduledAction = ApplicationTestDataFactory.getScheduledActions(1, 'Test Scheduled Action', actionType, System.now(), testCase.Id, true)[0];
		scheduledAction = (ScheduledAction__c) ApplicationTestDataFactory.setUnwritableFields(scheduledAction, new Map<String, Object>{ 'Case__r' => testCase });

		// =====================================
		// Stubbing
		// =====================================
		ScheduledActionsSelector mockScheduledActionsSelector = (ScheduledActionsSelector) MockUtility.mockSelector(ScheduledActionsSelector.class);
		ApplicationEmailService mockEmailService = (ApplicationEmailService) MockUtility.mockUtility(ApplicationEmailService.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockScheduledActionsSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ scheduledAction.Id }), (Set<Object>) fflib_Match.eq(new Set<Object>{ ScheduledActionsSelector.Options.WITH_CASE }))
			)
			.thenReturn(new List<ScheduledAction__c>{ scheduledAction });
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseMonitoring3DayReminderEmailAction.newInstance().execute(new List<Id>{ scheduledAction.Id });
		Test.stopTest();

		// verify notification emails are queued for Aus Post case.
		fflib_ArgumentCaptor caseIdArgCaptor = fflib_ArgumentCaptor.forClass(Id.class);
		fflib_ArgumentCaptor emailAlertArgCaptor = fflib_ArgumentCaptor.forClass(String.class);
		((ApplicationEmailService) MockUtility.Mocks.verify(mockEmailService, MockUtility.Mocks.times(1))).queueEmailNotification((Id)caseIdArgCaptor.capture(), fflib_Match.eqSObjectType(Case.SObjectType), (String)emailAlertArgCaptor.capture());

		Id caseId = (Id)caseIdArgCaptor.getValue();
		Assert.areEqual(testCase.Id, caseId, 'Expected email notification not sent for the AP Case');

		String emailAlertName = (String)emailAlertArgCaptor.getValue();
		Assert.areEqual(CaseMonitoring3DayReminderEmailAction.EMAIL_ALERT_NO_SCANS_OR_UPDATES_AP, emailAlertName, 'Incorrect email alert used to notify customer on AP Case.');
	}

	/**
	 * Scenario: Test execute() to send reminder email for StarTrack Case successfully
	 */
	@IsTest
	static void testSendReminderEmailForStarTrackCase() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.ProductSubCategory__c = 'StarTrack Express';
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'ContactEmail' => 'seth@test.com' });

		String actionType = CaseMonitoring3DayReminderEmailAction.newInstance().getName();
		ScheduledAction__c scheduledAction = ApplicationTestDataFactory.getScheduledActions(1, 'Test Scheduled Action', actionType, System.now(), testCase.Id, true)[0];
		scheduledAction = (ScheduledAction__c) ApplicationTestDataFactory.setUnwritableFields(scheduledAction, new Map<String, Object>{ 'Case__r' => testCase });

		// =====================================
		// Stubbing
		// =====================================
		ScheduledActionsSelector mockScheduledActionsSelector = (ScheduledActionsSelector) MockUtility.mockSelector(ScheduledActionsSelector.class);
		ApplicationEmailService mockEmailService = (ApplicationEmailService) MockUtility.mockUtility(ApplicationEmailService.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockScheduledActionsSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ scheduledAction.Id }), (Set<Object>) fflib_Match.eq(new Set<Object>{ ScheduledActionsSelector.Options.WITH_CASE }))
			)
			.thenReturn(new List<ScheduledAction__c>{ scheduledAction });
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseMonitoring3DayReminderEmailAction.newInstance().execute(new List<Id>{ scheduledAction.Id });
		Test.stopTest();

		// verify notification emails are queued for StarTrack case.
		fflib_ArgumentCaptor caseIdArgCaptor = fflib_ArgumentCaptor.forClass(Id.class);
		fflib_ArgumentCaptor emailAlertArgCaptor = fflib_ArgumentCaptor.forClass(String.class);
		((ApplicationEmailService) MockUtility.Mocks.verify(mockEmailService, MockUtility.Mocks.times(1))).queueEmailNotification((Id)caseIdArgCaptor.capture(), fflib_Match.eqSObjectType(Case.SObjectType), (String)emailAlertArgCaptor.capture());

		Id caseId = (Id)caseIdArgCaptor.getValue();
		Assert.areEqual(testCase.Id, caseId, 'Expected email notification not sent for the ST Case');

		String emailAlertName = (String)emailAlertArgCaptor.getValue();
		Assert.areEqual(CaseMonitoring3DayReminderEmailAction.EMAIL_ALERT_NO_SCANS_OR_UPDATES_ST, emailAlertName, 'Incorrect email alert used to notify customer on ST Case.');
	}
}