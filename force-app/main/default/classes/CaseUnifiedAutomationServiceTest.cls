/**
 * @author Seth Heang
 * @group Tests
 * @tag ScheduledAction__c, Case
 * @domain Core
 * @description Test class for CaseUnifiedAutomationService
 * @changelog
 * 2024-07-26 - Seth Heang - Created
 */
@IsTest(IsParallel=true)
public with sharing class CaseUnifiedAutomationServiceTest {

	@TestSetup
	static void testSetup(){
		QM__c queueSettings = QM__c.getOrgDefaults();
		Group unifiedMonitoringQueue = ApplicationTestDataFactory.getGroups(1, 'queue', true)[0];
		unifiedMonitoringQueue.Name = 'Unified Customer Service Monitoring Queue';

		queueSettings.UnifiedDefaultMonitoringQueueId__c = unifiedMonitoringQueue.Id;
		insert queueSettings;
	}

	/**
	 * Scenario: Test execute() for Case Closure scenario to send reminder email for StarTrack Case successfully
	 *			Validate that a closure email for StarTrack case is sent successfully and case is updated with appropriate details
	 */
	@IsTest
	static void testCaseClosureANDSendReminderEmailForStarTrackCase() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCase.Exclude_Subscription_Automation__c = false;
		testCase.ProductSubCategory__c = 'StarTrack Post';
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'ContactEmail' => 'seth@test.com' });

		String actionType = CaseMonitoring5DayAutoClosureAction.newInstance().getName();
		ScheduledAction__c scheduledAction = ApplicationTestDataFactory.getScheduledActions(1, 'Test Scheduled Action', actionType, System.now(), testCase.Id, true)[0];
		scheduledAction = (ScheduledAction__c) ApplicationTestDataFactory.setUnwritableFields(scheduledAction, new Map<String, Object>{ 'Case__r' => testCase });

		CaseUnifiedAutomationService.RecordWrapper recordWrapper = new CaseUnifiedAutomationService.RecordWrapper();
		recordWrapper.srcObjectType = Case.SObjectType;
		recordWrapper.srcRecordId = testCase.Id;
		recordWrapper.caseRecord = testCase;
		recordWrapper.newRootCause = 'Service Failure';
		recordWrapper.newResolutionCode = 'Lost - unscanned';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseUnifiedAutomationService.getInstance().processForCaseClosure(new List<CaseUnifiedAutomationService.RecordWrapper>{ recordWrapper }, CaseUnifiedAutomationService.InvocationPoint.PROACTIVEAUTO, null);
		Integer invocations = Limits.getEmailInvocations();
		Test.stopTest();

		List<EmailMessage> sentEmails = [SELECT Id, ToAddress, TextBody, Subject FROM EmailMessage];
		System.assertEquals(1, invocations, 'One email should have been sent.');
		System.assertEquals(1, sentEmails.size(), 'One email should have been sent.');
		System.assertEquals('seth@test.com', sentEmails[0].ToAddress, 'Expected ToAddress is seth@test.com but instead got: ' + sentEmails[0].ToAddress);
		System.assertEquals(true, sentEmails[0].Subject.contains('StarTrack'), 'Expected Subject to contains AusPost but it did not: ' + sentEmails[0].Subject);
		System.assertEquals(true, sentEmails[0].TextBody.contains('StarTrack'), 'Expected TextBody to contains AusPost but it did not: ' + sentEmails[0].TextBody);

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
	 * Scenario: Test execute() for Case Closure scenario to send reminder email for AusPost Case successfully
	 *			Validate that a closure email for StarTrack case is sent successfully and case is updated with appropriate details
	 */
	@IsTest
	static void testCaseClosureANDSendReminderEmailForAusPostCase() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCase.Exclude_Subscription_Automation__c = false;
		testCase.ProductSubCategory__c = 'Parcel Post';
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'ContactEmail' => 'seth@test.com' });

		String actionType = CaseMonitoring5DayAutoClosureAction.newInstance().getName();
		ScheduledAction__c scheduledAction = ApplicationTestDataFactory.getScheduledActions(1, 'Test Scheduled Action', actionType, System.now(), testCase.Id, true)[0];
		scheduledAction = (ScheduledAction__c) ApplicationTestDataFactory.setUnwritableFields(scheduledAction, new Map<String, Object>{ 'Case__r' => testCase });

		CaseUnifiedAutomationService.RecordWrapper recordWrapper = new CaseUnifiedAutomationService.RecordWrapper();
		recordWrapper.srcObjectType = Case.SObjectType;
		recordWrapper.srcRecordId = testCase.Id;
		recordWrapper.caseRecord = testCase;
		recordWrapper.newRootCause = 'Service Failure';
		recordWrapper.newResolutionCode = 'Lost - unscanned';

		// =====================================
		// Stubbing
		// =====================================
		ScheduledActionsSelector mockScheduledActionsSelector = (ScheduledActionsSelector) MockUtility.mockSelector(ScheduledActionsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseUnifiedAutomationService.getInstance().processForCaseClosure(new List<CaseUnifiedAutomationService.RecordWrapper>{ recordWrapper }, CaseUnifiedAutomationService.InvocationPoint.PROACTIVEAUTO, null);
		Integer invocations = Limits.getEmailInvocations();
		Test.stopTest();

		List<EmailMessage> sentEmails = [SELECT Id, ToAddress, TextBody, Subject FROM EmailMessage];
		System.assertEquals(1, invocations, 'One email should have been sent.');
		System.assertEquals(1, sentEmails.size(), 'One email should have been sent.');
		System.assertEquals('seth@test.com', sentEmails[0].ToAddress, 'Expected ToAddress is seth@test.com but instead got: ' + sentEmails[0].ToAddress);
		System.assertEquals(true, sentEmails[0].Subject.contains('AusPost'), 'Expected Subject to contains AusPost but it did not: ' + sentEmails[0].Subject);
		System.assertEquals(true, sentEmails[0].TextBody.contains('AusPost'), 'Expected TextBody to contains AusPost but it did not: ' + sentEmails[0].TextBody);

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
	 * Scenario: Test execute() for Case Reassignment scenario where reason is due to Opt Out automation
	 *			Validate the case is updated with appropriate details
	 */
	@IsTest
	static void testCaseReassignmentDueToOptOutAutomationReason() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCase.Exclude_Subscription_Automation__c = true;
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'ContactEmail' => 'seth@test.com' });

		String actionType = CaseMonitoring5DayAutoClosureAction.newInstance().getName();
		ScheduledAction__c scheduledAction = ApplicationTestDataFactory.getScheduledActions(1, 'Test Scheduled Action', actionType, System.now(), testCase.Id, true)[0];
		scheduledAction = (ScheduledAction__c) ApplicationTestDataFactory.setUnwritableFields(scheduledAction, new Map<String, Object>{ 'Case__r' => testCase });

		CaseUnifiedAutomationService.RecordWrapper recordWrapper = new CaseUnifiedAutomationService.RecordWrapper();
		recordWrapper.srcObjectType = Case.sObjectType;
		recordWrapper.srcRecordId = testCase.Id;
		recordWrapper.caseRecord = testCase;
		recordWrapper.isClosedBySystem = false;
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseUnifiedAutomationService.getInstance().processForCaseReassignment(new List<CaseUnifiedAutomationService.RecordWrapper>{ recordWrapper }, CaseUnifiedAutomationService.InvocationPoint.PROACTIVEAUTO, null);
		Test.stopTest();

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
	 * Scenario: Test execute() for Case Reassignment scenario where reason is due to missing customer details
	 *			Validate the case is updated with appropriate details
	 */
	@IsTest
	static void testCaseReassignmentDueToMissingCustomerEmailReason() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCase.Exclude_Subscription_Automation__c = false;

		String actionType = CaseMonitoring5DayAutoClosureAction.newInstance().getName();
		ScheduledAction__c scheduledAction = ApplicationTestDataFactory.getScheduledActions(1, 'Test Scheduled Action', actionType, System.now(), testCase.Id, true)[0];
		scheduledAction = (ScheduledAction__c) ApplicationTestDataFactory.setUnwritableFields(scheduledAction, new Map<String, Object>{ 'Case__r' => testCase });

		CaseUnifiedAutomationService.RecordWrapper recordWrapper = new CaseUnifiedAutomationService.RecordWrapper();
		recordWrapper.srcObjectType = Case.sObjectType;
		recordWrapper.srcRecordId = testCase.Id;
		recordWrapper.caseRecord = testCase;
		recordWrapper.isClosedBySystem = false;
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseUnifiedAutomationService.getInstance().processForCaseReassignment(new List<CaseUnifiedAutomationService.RecordWrapper>{ recordWrapper }, CaseUnifiedAutomationService.InvocationPoint.PROACTIVEAUTO, null);
		Test.stopTest();

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