/**
 * @author Seth Heang
 * @group Tests
 * @tag ScheduledAction__c
 * @domain Core
 * @description Test class for CaseMonitoring5DayAutoClosureAction
 * @changelog
 * 2024-07-29 - Seth Heang - Created
 */
@IsTest(IsParallel=true)
public with sharing class CaseMonitoring5DayAutoClosureActionTest {

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

		CaseMonitoring5DayAutoClosureAction action = CaseMonitoring5DayAutoClosureAction.newInstance();
		action.add(new Map<Id, Case>{ testCase.Id => testCase }, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor insertableScheduledActionCaptor = fflib_ArgumentCaptor.forClass(List<ScheduledAction__c>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<ScheduledAction__c>) insertableScheduledActionCaptor.capture());
		List<ScheduledAction__c> insertableScheduledAction = (List<ScheduledAction__c>) insertableScheduledActionCaptor.getValue();

		Assert.areEqual(action.getName(), insertableScheduledAction[0].ActionType__c, 'Expected action type to match but instead got ' + insertableScheduledAction[0].ActionType__c);
		Assert.areEqual(testCase.Id, insertableScheduledAction[0].Case__c, 'Expected case Id to match but instead got ' + insertableScheduledAction[0].Case__c);
		Assert.areEqual(true, insertableScheduledAction[0].Active__c, 'Expected active flag to set to true');
		Assert.areEqual(
			BusinessHoursService.newInstance().calculateNextBusinessDateTime(caseCreatedDate, 5),
			insertableScheduledAction[0].ScheduledDate__c,
			'Expected schedule dateTime to be in next 5 days but instead got: ' + insertableScheduledAction[0].ScheduledDate__c
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
		String actionType = CaseMonitoring5DayAutoClosureAction.newInstance().getName();
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

		CaseMonitoring5DayAutoClosureAction action = CaseMonitoring5DayAutoClosureAction.newInstance();
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

		CaseMonitoring5DayAutoClosureAction action = CaseMonitoring5DayAutoClosureAction.newInstance();
		action.setup(new Map<Id, Case>{ testCase.Id => testCase }, mockUow, false);

		Test.stopTest();

		fflib_ArgumentCaptor insertableScheduledActionCaptor = fflib_ArgumentCaptor.forClass(List<ScheduledAction__c>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<ScheduledAction__c>) insertableScheduledActionCaptor.capture());
		List<ScheduledAction__c> insertableScheduledAction = (List<ScheduledAction__c>) insertableScheduledActionCaptor.getValue();

		Assert.areEqual(action.getName(), insertableScheduledAction[0].ActionType__c, 'Expected action type to match but instead got ' + insertableScheduledAction[0].ActionType__c);
		Assert.areEqual(testCase.Id, insertableScheduledAction[0].Case__c, 'Expected case Id to match but instead got ' + insertableScheduledAction[0].Case__c);
		Assert.areEqual(true, insertableScheduledAction[0].Active__c, 'Expected active flag to set to true');
		Assert.areEqual(
			BusinessHoursService.newInstance().calculateNextBusinessDateTime(caseCreatedDate, 5),
			insertableScheduledAction[0].ScheduledDate__c,
			'Expected schedule dateTime to be in next 5 days but instead got: ' + insertableScheduledAction[0].ScheduledDate__c
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

		testCases[1].OwnerId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCases[1].RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCases[1].EnquirySubType__c = 'Late Item';

		Datetime caseCreatedDate = Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
		testCases[0] = (Case) ApplicationTestDataFactory.setUnwritableFields(testCases[0], new Map<String, Object>{ 'CreatedDate' => caseCreatedDate });
		testCases[1] = (Case) ApplicationTestDataFactory.setUnwritableFields(testCases[1], new Map<String, Object>{ 'CreatedDate' => caseCreatedDate.addDays(-10) });

		// =====================================
		// Stubbing
		// =====================================
		// NONE

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseMonitoring5DayAutoClosureAction action = CaseMonitoring5DayAutoClosureAction.newInstance();
		Map<Id, Boolean> caseValidationResult = action.validate(new Map<Id, Case>(testCases), null);

		Test.stopTest();

		Assert.areNotEqual(0, caseValidationResult.size(), 'Expect the case validation map size to not be 0 but instead got 0');
		Assert.areEqual(true, caseValidationResult.get(testCases[0].Id), 'Expect the case validation to be true but instead got: ' + caseValidationResult.get(testCases[0].Id));
		Assert.areEqual(false, caseValidationResult.get(testCases[1].Id), 'Expect the case validation to be false but instead got: ' + caseValidationResult.get(testCases[1].Id));
	}

	/**
	 * Scenario: Test execute() to send reminder email for AusPost Case successfully
	 *			And Validate that case detail is updated appropriate for case closure
	 */
	@IsTest
	static void testCaseClosureANDSendReminderEmailForAusPostCase() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCase.Exclude_Subscription_Automation__c = false;
		testCase.ProductSubCategory__c = 'Parcel Post';
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'ContactEmail' => 'seth@test.com' });

		String actionType = CaseMonitoring5DayAutoClosureAction.newInstance().getName();
		ScheduledAction__c scheduledAction = ApplicationTestDataFactory.getScheduledActions(1, 'Test Scheduled Action', actionType, System.now(), testCase.Id, true)[0];
		scheduledAction = (ScheduledAction__c) ApplicationTestDataFactory.setUnwritableFields(scheduledAction, new Map<String, Object>{ 'Case__r' => testCase });

		// =====================================
		// Stubbing
		// =====================================
		ScheduledActionsSelector mockScheduledActionsSelector = (ScheduledActionsSelector) MockUtility.mockSelector(ScheduledActionsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockScheduledActionsSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ scheduledAction.Id }), (Set<Object>) fflib_Match.eq(new Set<Object>{ ScheduledActionsSelector.Options.WITH_CASE }))
			)
			.thenReturn(new List<ScheduledAction__c>{ scheduledAction });
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean())).thenReturn(true);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseMonitoring5DayAutoClosureAction.newInstance().execute(new List<Id>{ scheduledAction.Id });
		Integer invocations = Limits.getEmailInvocations();
		Test.stopTest();

		List<EmailMessage> sentEmails = [SELECT Id, ToAddress, TextBody, Subject FROM EmailMessage];
		System.assertEquals(1, invocations, 'One email should have been sent.');
		System.assertEquals(1, sentEmails.size(), 'One email should have been sent.');
		System.assertEquals('seth@test.com', sentEmails[0].ToAddress, 'Expected ToAddress is seth@test.com but instead got: ' + sentEmails[0].ToAddress);
		System.assertEquals(true, sentEmails[0].Subject.contains('AusPost'), 'Expected Subject to contains AusPost but it did not: ' + sentEmails[0].Subject);
		System.assertEquals(true, sentEmails[0].TextBody.contains('AusPost'), 'Expected TextBody to contains AusPost but it did not: ' + sentEmails[0].TextBody);

		((ScheduledActionsSelector) MockUtility.Mocks.verify(mockScheduledActionsSelector, 1))
			.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ scheduledAction.Id }), (Set<Object>) fflib_Match.eq(new Set<Object>{ ScheduledActionsSelector.Options.WITH_CASE }));
		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);

		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Case>) updatableCasesCaptor.capture());
		Map<Id, Case> updateableCases = new Map<Id, Case>((List<Case>) updatableCasesCaptor.getValue());
		Assert.areEqual('Service Failure', updateableCases.get(testCase.Id).Root_cause__c, 'Case Root_cause__c should match but instead got ' + updateableCases.get(testCase.Id).Root_cause__c);
		Assert.areEqual('Lost - unscanned', updateableCases.get(testCase.Id).ResolutionCode__c, 'Case ResolutionCode__c should matchbut instead got ' + updateableCases.get(testCase.Id).ResolutionCode__c);
		Assert.areEqual(
			QM__c.getInstance().ClosedQueueId__c,
			updateableCases.get(testCase.Id).OwnerId,
			'Case OwnerId should match but instead got ' + updateableCases.get(testCase.Id).OwnerId
		);
		Assert.areEqual(true, updateableCases.get(testCase.Id).ClosedBySystem__c, 'Case ClosedBySystem__c should match but instead got ' + updateableCases.get(testCase.Id).ClosedBySystem__c);
		Assert.areEqual(SSSWConstants.CASE_STATUS_CLOSED, updateableCases.get(testCase.Id).Status, 'Case Status should match but instead got ' + updateableCases.get(testCase.Id).Status);
	}

	/**
	 * Scenario: Test execute() to send reminder email for StarTrack Case successfully
	 *			And Validate that case detail is updated appropriate for case closure
	 */
	@IsTest
	static void testCaseClosureANDSendReminderEmailForStarTrackCase() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCase.Exclude_Subscription_Automation__c = false;
		testCase.ProductSubCategory__c = 'StarTrack Post';
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'ContactEmail' => 'seth@test.com' });

		String actionType = CaseMonitoring5DayAutoClosureAction.newInstance().getName();
		ScheduledAction__c scheduledAction = ApplicationTestDataFactory.getScheduledActions(1, 'Test Scheduled Action', actionType, System.now(), testCase.Id, true)[0];
		scheduledAction = (ScheduledAction__c) ApplicationTestDataFactory.setUnwritableFields(scheduledAction, new Map<String, Object>{ 'Case__r' => testCase });
		// =====================================
		// Stubbing
		// =====================================
		ScheduledActionsSelector mockScheduledActionsSelector = (ScheduledActionsSelector) MockUtility.mockSelector(ScheduledActionsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockScheduledActionsSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ scheduledAction.Id }), (Set<Object>) fflib_Match.eq(new Set<Object>{ ScheduledActionsSelector.Options.WITH_CASE }))
			)
			.thenReturn(new List<ScheduledAction__c>{ scheduledAction });
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean())).thenReturn(true);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseMonitoring5DayAutoClosureAction.newInstance().execute(new List<Id>{ scheduledAction.Id });
		Integer invocations = Limits.getEmailInvocations();
		Test.stopTest();

		List<EmailMessage> sentEmails = [SELECT Id, ToAddress, TextBody, Subject FROM EmailMessage];
		System.assertEquals(1, invocations, 'One email should have been sent.');
		System.assertEquals(1, sentEmails.size(), 'One email should have been sent.');
		System.assertEquals('seth@test.com', sentEmails[0].ToAddress, 'Expected ToAddress is seth@test.com but instead got: ' + sentEmails[0].ToAddress);
		System.assertEquals(true, sentEmails[0].Subject.contains('StarTrack'), 'Expected Subject to contains AusPost but it did not: ' + sentEmails[0].Subject);
		System.assertEquals(true, sentEmails[0].TextBody.contains('StarTrack'), 'Expected TextBody to contains AusPost but it did not: ' + sentEmails[0].TextBody);

		((ScheduledActionsSelector) MockUtility.Mocks.verify(mockScheduledActionsSelector, 1))
			.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ scheduledAction.Id }), (Set<Object>) fflib_Match.eq(new Set<Object>{ ScheduledActionsSelector.Options.WITH_CASE }));
		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);

		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Case>) updatableCasesCaptor.capture());
		Map<Id, Case> updateableCases = new Map<Id, Case>((List<Case>) updatableCasesCaptor.getValue());
		Assert.areEqual('Service Failure', updateableCases.get(testCase.Id).Root_cause__c, 'Case Root_cause__c should match but instead got ' + updateableCases.get(testCase.Id).Root_cause__c);
		Assert.areEqual('Lost - unscanned', updateableCases.get(testCase.Id).ResolutionCode__c, 'Case ResolutionCode__c should matchbut instead got ' + updateableCases.get(testCase.Id).ResolutionCode__c);
		Assert.areEqual(
			QM__c.getInstance().ClosedQueueId__c,
			updateableCases.get(testCase.Id).OwnerId,
			'Case OwnerId should match but instead got ' + updateableCases.get(testCase.Id).OwnerId
		);
		Assert.areEqual(true, updateableCases.get(testCase.Id).ClosedBySystem__c, 'Case ClosedBySystem__c should match but instead got ' + updateableCases.get(testCase.Id).ClosedBySystem__c);
		Assert.areEqual(SSSWConstants.CASE_STATUS_CLOSED, updateableCases.get(testCase.Id).Status, 'Case Status should match but instead got ' + updateableCases.get(testCase.Id).Status);
	}

	/**
	 * Scenario: Test execute() for Case reassignment scenario
	 *			And Validate that case detail is updated appropriate where reason is due to Opt out Automation
	 */
	@IsTest
	static void testCaseReassignmentDueToOptOutAutomationReason() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCase.Exclude_Subscription_Automation__c = true;
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'ContactEmail' => 'seth@test.com' });

		String actionType = CaseMonitoring5DayAutoClosureAction.newInstance().getName();
		ScheduledAction__c scheduledAction = ApplicationTestDataFactory.getScheduledActions(1, 'Test Scheduled Action', actionType, System.now(), testCase.Id, true)[0];
		scheduledAction = (ScheduledAction__c) ApplicationTestDataFactory.setUnwritableFields(scheduledAction, new Map<String, Object>{ 'Case__r' => testCase });
		// =====================================
		// Stubbing
		// =====================================
		ScheduledActionsSelector mockScheduledActionsSelector = (ScheduledActionsSelector) MockUtility.mockSelector(ScheduledActionsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockScheduledActionsSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ scheduledAction.Id }), (Set<Object>) fflib_Match.eq(new Set<Object>{ ScheduledActionsSelector.Options.WITH_CASE }))
			)
			.thenReturn(new List<ScheduledAction__c>{ scheduledAction });
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean())).thenReturn(true);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseMonitoring5DayAutoClosureAction.newInstance().execute(new List<Id>{ scheduledAction.Id });
		Test.stopTest();

		((ScheduledActionsSelector) MockUtility.Mocks.verify(mockScheduledActionsSelector, 1))
			.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ scheduledAction.Id }), (Set<Object>) fflib_Match.eq(new Set<Object>{ ScheduledActionsSelector.Options.WITH_CASE }));
		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);

		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Case>) updatableCasesCaptor.capture());
		Map<Id, Case> updateableCases = new Map<Id, Case>((List<Case>) updatableCasesCaptor.getValue());
		Assert.areEqual(
			'Cannot autoclose due to opt out automations',
			updateableCases.get(testCase.Id).ReassignmentReason__c,
			'Case ReassignmentReason__c should match but instead got ' + updateableCases.get(testCase.Id).Root_cause__c
		);
		Assert.areEqual(
			QM__c.getInstance().UnifiedDefaultOmniQueueId__c,
			updateableCases.get(testCase.Id).OwnerId,
			'Case OwnerId should match but instead got ' + updateableCases.get(testCase.Id).OwnerId
		);
		Assert.areEqual(false, updateableCases.get(testCase.Id).ClosedBySystem__c, 'Case ClosedBySystem__c should match but instead got ' + updateableCases.get(testCase.Id).ClosedBySystem__c);
		Assert.areEqual(SSSWConstants.CASE_STATUS_UPDATED, updateableCases.get(testCase.Id).Status, 'Case Status should match but instead got ' + updateableCases.get(testCase.Id).Status);
	}

	/**
	 * Scenario: Test execute() for Case reassignment scenario
	 *			And Validate that case detail is updated appropriate where reason is due to missing customer email
	 */
	@IsTest
	static void testCaseReassignmentDueToMissingCustomerEmailReason() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCase.Exclude_Subscription_Automation__c = false;

		String actionType = CaseMonitoring5DayAutoClosureAction.newInstance().getName();
		ScheduledAction__c scheduledAction = ApplicationTestDataFactory.getScheduledActions(1, 'Test Scheduled Action', actionType, System.now(), testCase.Id, true)[0];
		scheduledAction = (ScheduledAction__c) ApplicationTestDataFactory.setUnwritableFields(scheduledAction, new Map<String, Object>{ 'Case__r' => testCase });
		// =====================================
		// Stubbing
		// =====================================
		ScheduledActionsSelector mockScheduledActionsSelector = (ScheduledActionsSelector) MockUtility.mockSelector(ScheduledActionsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(
				mockScheduledActionsSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ scheduledAction.Id }), (Set<Object>) fflib_Match.eq(new Set<Object>{ ScheduledActionsSelector.Options.WITH_CASE }))
			)
			.thenReturn(new List<ScheduledAction__c>{ scheduledAction });
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean())).thenReturn(true);

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseMonitoring5DayAutoClosureAction.newInstance().execute(new List<Id>{ scheduledAction.Id });
		Test.stopTest();

		((ScheduledActionsSelector) MockUtility.Mocks.verify(mockScheduledActionsSelector, 1))
			.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ scheduledAction.Id }), (Set<Object>) fflib_Match.eq(new Set<Object>{ ScheduledActionsSelector.Options.WITH_CASE }));
		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);

		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Case>) updatableCasesCaptor.capture());
		Map<Id, Case> updateableCases = new Map<Id, Case>((List<Case>) updatableCasesCaptor.getValue());
		Assert.areEqual(
			'Cannot autoclose due to missing customer email',
			updateableCases.get(testCase.Id).ReassignmentReason__c,
			'Case ReassignmentReason__c should match but instead got ' + updateableCases.get(testCase.Id).Root_cause__c
		);
		Assert.areEqual(
			QM__c.getInstance().UnifiedDefaultOmniQueueId__c,
			updateableCases.get(testCase.Id).OwnerId,
			'Case OwnerId should match but instead got ' + updateableCases.get(testCase.Id).OwnerId
		);
		Assert.areEqual(false, updateableCases.get(testCase.Id).ClosedBySystem__c, 'Case ClosedBySystem__c should match but instead got ' + updateableCases.get(testCase.Id).ClosedBySystem__c);
		Assert.areEqual(SSSWConstants.CASE_STATUS_UPDATED, updateableCases.get(testCase.Id).Status, 'Case Status should match but instead got ' + updateableCases.get(testCase.Id).Status);
	}
}