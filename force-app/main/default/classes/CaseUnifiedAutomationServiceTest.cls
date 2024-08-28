/**
 * @author Seth Heang
 * @group Tests
 * @tag ScheduledAction__c, Case
 * @domain Core
 * @description Test class for CaseUnifiedAutomationService
 * @changelog
 * 2024-07-26 - Seth Heang - Created
 * 2024-08-12 - Ranjeewa Silva - Added tests to cover case re-assignment on email automation
 * 2024-08-23 - Seth Heang - Added Assertion on PreferredAgentExpiry__c for Reassigned Case Update Check
 */
@IsTest(IsParallel=true)
public with sharing class CaseUnifiedAutomationServiceTest {

	@TestSetup
	static void testSetup(){
		QM__c queueSettings = QM__c.getOrgDefaults();
		Group unifiedMonitoringQueue = ApplicationTestDataFactory.getGroups(1, 'queue', true)[0];
		unifiedMonitoringQueue.Name = 'Unified Customer Service Monitoring Queue';

		queueSettings.UnifiedDefaultMonitoringQueueId__c = unifiedMonitoringQueue.Id;
		queueSettings.UnifiedPreferredAgentExpiry__c = 1;
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
		testCase.BusinessHoursId = BusinessHoursSelector.newInstance().selectDefault(true).Id;

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
			'Case ReassignmentReason__c should match but instead got ' + updateableCases.get(testCase.Id).ReassignmentReason__c
		);
		Assert.areEqual(
			QM__c.getInstance().UnifiedDefaultOmniQueueId__c,
			updateableCases.get(testCase.Id).OwnerId,
			'Case OwnerId should match but instead got ' + updateableCases.get(testCase.Id).OwnerId
		);
		Assert.areEqual(
			BusinessHours.add(updateableCases.get(testCase.Id).BusinessHoursId, Datetime.now(), QM__c.getInstance().UnifiedPreferredAgentExpiry__c.longValue() * 3600000),
			updateableCases.get(testCase.Id).PreferredAgentExpiry__c,
			'Case PreferredAgentExpiry__c should match but instead got: ' + updateableCases.get(testCase.Id).PreferredAgentExpiry__c
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
		testCase.BusinessHoursId = BusinessHoursSelector.newInstance().selectDefault(true).Id;

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
			'Case ReassignmentReason__c should match but instead got ' + updateableCases.get(testCase.Id).ReassignmentReason__c
		);
		Assert.areEqual(
			QM__c.getInstance().UnifiedDefaultOmniQueueId__c,
			updateableCases.get(testCase.Id).OwnerId,
			'Case OwnerId should match but instead got ' + updateableCases.get(testCase.Id).OwnerId
		);
		Assert.areEqual(
			BusinessHours.add(updateableCases.get(testCase.Id).BusinessHoursId, Datetime.now(), QM__c.getInstance().UnifiedPreferredAgentExpiry__c.longValue() * 3600000),
			updateableCases.get(testCase.Id).PreferredAgentExpiry__c,
			'Case PreferredAgentExpiry__c should match but instead got: ' + updateableCases.get(testCase.Id).PreferredAgentExpiry__c
		);
		Assert.areEqual(false, updateableCases.get(testCase.Id).ClosedBySystem__c, 'Case ClosedBySystem__c should match but instead got ' + updateableCases.get(testCase.Id).ClosedBySystem__c);
		Assert.areEqual(SSSWConstants.CASE_STATUS_UPDATED, updateableCases.get(testCase.Id).Status, 'Case Status should match but instead got ' + updateableCases.get(testCase.Id).Status);
	}

	/**
	 * Test to ensure closed cases are reassigned on email automation.
	 */
	@IsTest
	static void testClosedCasesAreReassignedOnEmailAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		Case caseRecord = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		caseRecord.Status = 'Closed';
		caseRecord = (Case) ApplicationTestDataFactory.setUnwritableFields(caseRecord, new Map<String, Object>{
				'IsClosed' => true
		});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		AgentWorkSelector mockAgentWorkSelector = (AgentWorkSelector)MockUtility.mockSelector(AgentWorkSelector.class);
		PendingServiceRoutingSelector mockPSRSelector = (PendingServiceRoutingSelector)MockUtility.mockSelector(PendingServiceRoutingSelector.class);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseUnifiedAutomationService.RecordWrapper caseWrapper = new CaseUnifiedAutomationService.RecordWrapper();
		caseWrapper.caseRecord = caseRecord;
		caseWrapper.newReassignmentReason = 'test reassignment reason';
		CaseUnifiedAutomationService.getInstance().processForCaseReassignment(new List<CaseUnifiedAutomationService.RecordWrapper>{caseWrapper}, CaseUnifiedAutomationService.InvocationPoint.EMAILAUTO, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerDirty((List<Case>) updatableCasesCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Case> updateableCases = (List<Case>) updatableCasesCaptor.getValue();

		Assert.areEqual(1, updateableCases.size(), 'Expected the closed case to be updated.');
		Assert.areEqual(caseRecord.Id, updateableCases[0].Id, 'Expected the closed case to be updated.');
		Assert.areEqual(CaseUnifiedAutomationService.QUEUE_SETTINGS?.UnifiedDefaultOmniQueueId__c, updateableCases[0].OwnerId, 'Expected the case to be assigned to unified cases omni queue.');
		Assert.areEqual(SSSWConstants.CASE_STATUS_UPDATED, updateableCases[0].Status, 'Expected the case status to be updated.');
		Assert.areEqual(caseWrapper.newReassignmentReason, updateableCases[0].ReassignmentReason__c, 'Expected the case reassignment reason to be set.');
		Assert.isTrue(updateableCases[0].Case_Reopen_Date__c != null, 'Expected Case_Reopen_Date__c field to be updated.');

		// verify that AgentWork is not queried for closed case
		((AgentWorkSelector) MockUtility.Mocks.verify(mockAgentWorkSelector, MockUtility.Mocks.times(0))).search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true));

		// verify that PendingServiceRouting is not queried for closed case
		((PendingServiceRoutingSelector) MockUtility.Mocks.verify(mockPSRSelector, MockUtility.Mocks.times(0))).selectByWorkItemId((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());
	}

	/**
	 * Test to ensure open cases with PSRs are NOT reassigned on email automation.
	 */
	@IsTest
	static void testOpenCasesWithPSRsAreNotReassignedOnEmailAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		Case caseRecord = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		caseRecord.Status = SSSWConstants.CASE_STATUS_UPDATED;

		PendingServiceRouting psr = ApplicationTestDataFactoryCase.getPendingServiceRoutings(1, null, null, caseRecord.Id, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		AgentWorkSelector mockAgentWorkSelector = (AgentWorkSelector)MockUtility.mockSelector(AgentWorkSelector.class);
		PendingServiceRoutingSelector mockPSRSelector = (PendingServiceRoutingSelector)MockUtility.mockSelector(PendingServiceRoutingSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockPSRSelector.selectByWorkItemId((Set<Id>)fflib_Match.eq(new Set<Id>{caseRecord.Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<PendingServiceRouting>{psr});
		MockUtility.Mocks.when(mockAgentWorkSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<AgentWork>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseUnifiedAutomationService.RecordWrapper caseWrapper = new CaseUnifiedAutomationService.RecordWrapper();
		caseWrapper.caseRecord = caseRecord;
		caseWrapper.newReassignmentReason = 'test reassignment reason';
		CaseUnifiedAutomationService.getInstance().processForCaseReassignment(new List<CaseUnifiedAutomationService.RecordWrapper>{caseWrapper}, CaseUnifiedAutomationService.InvocationPoint.EMAILAUTO, mockUow);

		Test.stopTest();

		// verify that no cases are registered with unit of work
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(0))).registerDirty((List<Case>) fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
	}

	/**
	* Test to ensure open cases with active AgentWork are NOT reassigned on email automation.
	*/
	@IsTest
	static void testOpenCasesWithActiveAgentWorkAreNotReassignedOnEmailAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(2, true);
		cases[0].Status = SSSWConstants.CASE_STATUS_UPDATED;
		cases[1].Status = SSSWConstants.CASE_STATUS_UPDATED;

		// setup AgentWork records for each case
		List<AgentWork> agentWork = ApplicationTestDataFactoryCase.getAgentWorks(2, null, new List<Id>{cases[0].Id, cases[1].Id}, true);
		// agentWork[0] is in status 'Opened'. cases[0] should not be reassigned as an agent has actively working on the case and has opened the case record.
		agentWork[0] = (AgentWork) ApplicationTestDataFactory.setUnwritableFields(agentWork[0], new Map<String, Object>{
				'Status' => SSSWConstants.OMNI_AGENTWORK_STATUS_OPENED
		});
		// agentWork[1] is in status 'Assigned'. cases[1] should not be reassigned as the case has been pushed to an agent by omni channel and in the process of being assigned to an agent.
		agentWork[1] = (AgentWork) ApplicationTestDataFactory.setUnwritableFields(agentWork[1], new Map<String, Object>{
				'Status' => SSSWConstants.OMNI_AGENTWORK_STATUS_ASSIGNED
		});

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		AgentWorkSelector mockAgentWorkSelector = (AgentWorkSelector)MockUtility.mockSelector(AgentWorkSelector.class);
		PendingServiceRoutingSelector mockPSRSelector = (PendingServiceRoutingSelector)MockUtility.mockSelector(PendingServiceRoutingSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockPSRSelector.selectByWorkItemId((Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id, cases[1].Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<PendingServiceRouting>());
		MockUtility.Mocks.when(mockAgentWorkSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(agentWork);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<CaseUnifiedAutomationService.RecordWrapper> caseWrappers = new List<CaseUnifiedAutomationService.RecordWrapper>();
		for (Case caseRecord: cases) {
			CaseUnifiedAutomationService.RecordWrapper caseWrapper = new CaseUnifiedAutomationService.RecordWrapper();
			caseWrapper.caseRecord = caseRecord;
			caseWrapper.newReassignmentReason = 'test reassignment reason';
			caseWrappers.add(caseWrapper);
		}
		CaseUnifiedAutomationService.getInstance().processForCaseReassignment(caseWrappers, CaseUnifiedAutomationService.InvocationPoint.EMAILAUTO, mockUow);

		Test.stopTest();

		// verify that no cases are registered with unit of work
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(0))).registerDirty((List<Case>) fflib_Match.anyObject(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
	}

	/**
	* Test to ensure open cases with No PSRs or active AgentWork are reassigned on email automation.
	*/
	@IsTest
	static void testOpenCasesWithNoPSRsOrActiveAgentWorkAreReassignedOnEmailAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		Case caseRecord = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		caseRecord.Status = SSSWConstants.CASE_STATUS_UPDATED;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		AgentWorkSelector mockAgentWorkSelector = (AgentWorkSelector)MockUtility.mockSelector(AgentWorkSelector.class);
		PendingServiceRoutingSelector mockPSRSelector = (PendingServiceRoutingSelector)MockUtility.mockSelector(PendingServiceRoutingSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockPSRSelector.selectByWorkItemId((Set<Id>)fflib_Match.eq(new Set<Id>{caseRecord.Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<PendingServiceRouting>());
		MockUtility.Mocks.when(mockAgentWorkSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(new List<AgentWork>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseUnifiedAutomationService.RecordWrapper caseWrapper = new CaseUnifiedAutomationService.RecordWrapper();
		caseWrapper.caseRecord = caseRecord;
		caseWrapper.newReassignmentReason = 'test reassignment reason';
		CaseUnifiedAutomationService.getInstance().processForCaseReassignment(new List<CaseUnifiedAutomationService.RecordWrapper>{caseWrapper}, CaseUnifiedAutomationService.InvocationPoint.EMAILAUTO, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerDirty((List<Case>) updatableCasesCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Case> updateableCases = (List<Case>) updatableCasesCaptor.getValue();

		Assert.areEqual(1, updateableCases.size(), 'Expected the case to be updated.');
		Assert.areEqual(caseRecord.Id, updateableCases[0].Id, 'Expected the case to be updated.');
		Assert.areEqual(CaseUnifiedAutomationService.QUEUE_SETTINGS?.UnifiedDefaultOmniQueueId__c, updateableCases[0].OwnerId, 'Expected the case to be assigned to unified cases omni queue.');
		Assert.areEqual(SSSWConstants.CASE_STATUS_UPDATED, updateableCases[0].Status, 'Expected the case status to be updated.');
		Assert.areEqual(caseWrapper.newReassignmentReason, updateableCases[0].ReassignmentReason__c, 'Expected the case reassignment reason to be set.');
		Assert.isTrue(updateableCases[0].Case_Reopen_Date__c == null, 'Expected Case_Reopen_Date__c field to be blank as the case was already open.');
	}

	/**
	* Test to ensure cases with scheduled contact requests are reassigned on email automation only if case and child contact
	* requests do not have any PSRs or active AgentWork.
	*/
	@IsTest
	static void testCasesWithChildContactRequestsReassignmentOnEmailAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(3, true);
		cases[0].Status = SSSWConstants.CASE_STATUS_UPDATED;
		cases[1].Status = SSSWConstants.CASE_STATUS_UPDATED;
		cases[2].Status = SSSWConstants.CASE_STATUS_UPDATED;

		List<ContactRequest> contactRequests = ApplicationTestDataFactoryCase.getContactRequests(3, new List<Id>{cases[0].Id, cases[1].Id, cases[2].Id}, null, true);

		// setup child contact requests on each case
		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0], new Map<String, List<SObject>>{'ContactRequests' => new List<ContactRequest>{contactRequests[0]}});
		cases[1] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[1], new Map<String, List<SObject>>{'ContactRequests' => new List<ContactRequest>{contactRequests[1]}});
		cases[2] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[2], new Map<String, List<SObject>>{'ContactRequests' => new List<ContactRequest>{contactRequests[2]}});

		// setup PSR record for contactRequests[0]. cases[0] should not be reassigned as the contact request is being re-assgined.
		PendingServiceRouting psr = ApplicationTestDataFactoryCase.getPendingServiceRoutings(1, null, null, new List<Id>{contactRequests[0].Id}, true)[0];

		// setup AgentWork record on contactRequests[1]
		List<AgentWork> agentWork = ApplicationTestDataFactoryCase.getAgentWorks(1, null, new List<Id>{contactRequests[1].Id}, true);
		// agentWork[0] is in status 'Opened'. cases[1] should not be reassigned as the contact request has been assigned to an agent.
		agentWork[0] = (AgentWork) ApplicationTestDataFactory.setUnwritableFields(agentWork[0], new Map<String, Object>{
				'Status' => SSSWConstants.OMNI_AGENTWORK_STATUS_OPENED
		});

		// contactRequests[2] has no PSR records or AgentWork. cases[2] should be re-assigned on email automation.

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		AgentWorkSelector mockAgentWorkSelector = (AgentWorkSelector)MockUtility.mockSelector(AgentWorkSelector.class);
		PendingServiceRoutingSelector mockPSRSelector = (PendingServiceRoutingSelector)MockUtility.mockSelector(PendingServiceRoutingSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockPSRSelector.selectByWorkItemId((Set<Id>)fflib_Match.eq(new Set<Id>{cases[0].Id, cases[1].Id, cases[2].Id, contactRequests[0].Id, contactRequests[1].Id, contactRequests[2].Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<PendingServiceRouting>{psr});
		MockUtility.Mocks.when(mockAgentWorkSelector.search((Map<String, Object>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenReturn(agentWork);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		List<CaseUnifiedAutomationService.RecordWrapper> caseWrappers = new List<CaseUnifiedAutomationService.RecordWrapper>();
		for (Case caseRecord: cases) {
			CaseUnifiedAutomationService.RecordWrapper caseWrapper = new CaseUnifiedAutomationService.RecordWrapper();
			caseWrapper.caseRecord = caseRecord;
			caseWrapper.newReassignmentReason = 'test reassignment reason';
			caseWrappers.add(caseWrapper);
		}
		CaseUnifiedAutomationService.getInstance().processForCaseReassignment(caseWrappers, CaseUnifiedAutomationService.InvocationPoint.EMAILAUTO, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerDirty((List<Case>) updatableCasesCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Case> updateableCases = (List<Case>) updatableCasesCaptor.getValue();

		Assert.areEqual(1, updateableCases.size(), 'Expected only one case to be updated.');
		Assert.areEqual(cases[2].Id, updateableCases[0].Id, 'Only the case whose SCRs does not have PSRs or active AgentWork is expected to be updated.');
		Assert.areEqual(CaseUnifiedAutomationService.QUEUE_SETTINGS?.UnifiedDefaultOmniQueueId__c, updateableCases[0].OwnerId, 'Expected the case to be assigned to unified cases omni queue.');
		Assert.areEqual(SSSWConstants.CASE_STATUS_UPDATED, updateableCases[0].Status, 'Expected the case status to be updated.');
		Assert.areEqual(caseWrappers[2].newReassignmentReason, updateableCases[0].ReassignmentReason__c, 'Expected the case reassignment reason to be set.');
		Assert.isTrue(updateableCases[0].Case_Reopen_Date__c == null, 'Expected Case_Reopen_Date__c field to be blank as the case was already open.');
	}
}