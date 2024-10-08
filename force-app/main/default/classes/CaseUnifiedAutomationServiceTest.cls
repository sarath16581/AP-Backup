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
 * 2024-09-02 - Ranjeewa Silva - Added tests to cover case reassignment / closure on scan event automation
 * 2024-09-24 - Ranjeewa Silva - Updated tests to assert case closure email for proactively monitored cases.
 * 2024-10-03 - Ranjeewa Silva - Updated tests to assert case closure email when cases are closed due to scan events.
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
		ApplicationEmailService mockEmailService = (ApplicationEmailService) MockUtility.mockUtility(ApplicationEmailService.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseUnifiedAutomationService.getInstance().processForCaseClosure(new List<CaseUnifiedAutomationService.RecordWrapper>{ recordWrapper }, CaseUnifiedAutomationService.InvocationPoint.PROACTIVEAUTO, null);
		Test.stopTest();

		// verify notification emails are queued for StarTrack case.
		fflib_ArgumentCaptor caseIdArgCaptor = fflib_ArgumentCaptor.forClass(Id.class);
		fflib_ArgumentCaptor emailAlertArgCaptor = fflib_ArgumentCaptor.forClass(String.class);
		((ApplicationEmailService) MockUtility.Mocks.verify(mockEmailService, MockUtility.Mocks.times(1))).queueEmailNotification((Id)caseIdArgCaptor.capture(), fflib_Match.eqSObjectType(Case.SObjectType), (String)emailAlertArgCaptor.capture());

		Id caseId = (Id)caseIdArgCaptor.getValue();
		Assert.areEqual(testCase.Id, caseId, 'Expected email notification not sent for the ST Case');

		String emailAlertName = (String)emailAlertArgCaptor.getValue();
		Assert.areEqual(CaseUnifiedAutomationService.EMAIL_ALERT_CASE_CLOSURE_NO_SCANS_OR_UPDATES_ST, emailAlertName, 'Incorrect email alert used to notify customer on ST Case.');

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
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ApplicationEmailService mockEmailService = (ApplicationEmailService) MockUtility.mockUtility(ApplicationEmailService.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseUnifiedAutomationService.getInstance().processForCaseClosure(new List<CaseUnifiedAutomationService.RecordWrapper>{ recordWrapper }, CaseUnifiedAutomationService.InvocationPoint.PROACTIVEAUTO, null);
		Test.stopTest();

		// verify notification emails are queued for Aus Post case.
		fflib_ArgumentCaptor caseIdArgCaptor = fflib_ArgumentCaptor.forClass(Id.class);
		fflib_ArgumentCaptor emailAlertArgCaptor = fflib_ArgumentCaptor.forClass(String.class);
		((ApplicationEmailService) MockUtility.Mocks.verify(mockEmailService, MockUtility.Mocks.times(1))).queueEmailNotification((Id)caseIdArgCaptor.capture(), fflib_Match.eqSObjectType(Case.SObjectType), (String)emailAlertArgCaptor.capture());

		Id caseId = (Id)caseIdArgCaptor.getValue();
		Assert.areEqual(testCase.Id, caseId, 'Expected email notification not sent for the AP Case');

		String emailAlertName = (String)emailAlertArgCaptor.getValue();
		Assert.areEqual(CaseUnifiedAutomationService.EMAIL_ALERT_CASE_CLOSURE_NO_SCANS_OR_UPDATES_AP, emailAlertName, 'Incorrect email alert used to notify customer on AP Case.');

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

	/**
	* Test to ensure open cases with active AgentWork are NOT closed on scan event case closure automation.
	*/
	@IsTest
	static void testOpenCasesWithActiveAgentWorkAreNotClosedOrReassignedOnScanEventCaseClosureAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(2, true);
		cases[0].Status = SSSWConstants.CASE_STATUS_UPDATED;
		// cases[1] is in 'Monitoring' status. this should get updated to 'Updated'
		cases[1].Status = SSSWConstants.CASE_STATUS_MONITORING;

		// setup AgentWork records for each case
		List<AgentWork> agentWork = ApplicationTestDataFactoryCase.getAgentWorks(2, null, new List<Id>{cases[0].Id, cases[1].Id}, true);
		// agentWork[0] is in status 'Opened'. cases[0] should not be closed as an agent is actively working on the case and has opened the case record.
		agentWork[0] = (AgentWork) ApplicationTestDataFactory.setUnwritableFields(agentWork[0], new Map<String, Object>{
				'Status' => SSSWConstants.OMNI_AGENTWORK_STATUS_OPENED
		});
		// agentWork[1] is in status 'Assigned'. cases[1] should not be closed as the case has been pushed to an agent by omni channel and in the process of being assigned to an agent.
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
			caseWrapper.newRootCause = 'test root cause';
			caseWrapper.newResolutionCode = 'test resolution code';
			caseWrappers.add(caseWrapper);
		}
		CaseUnifiedAutomationService.getInstance().processForCaseClosure(caseWrappers, CaseUnifiedAutomationService.InvocationPoint.SCANAUTO, mockUow);

		Test.stopTest();

		// verify that only cases[a1] are registered with unit of work for a status update. no cases are reassigned or closed.
		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerDirty((List<Case>) updatableCasesCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Case> updateableCases = (List<Case>) updatableCasesCaptor.getValue();

		Assert.areEqual(1, updateableCases.size(), 'Expected the case to be updated.');
		Assert.areEqual(cases[1].Id, updateableCases[0].Id, 'Expected the case to be updated.');
		Assert.areEqual(SSSWConstants.CASE_STATUS_UPDATED, updateableCases[0].Status, 'Expected the case status to be set to \'Updated\'.');
		Assert.isNull(updateableCases[0].ReassignmentReason__c, 'Expected the case reassignment reason to be null, as the case is not reassigned.');

		// verify emails are not queued
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(0))).queueEmailNotification(fflib_Match.anyId(), fflib_Match.anySObjectType(), fflib_Match.anyString());
	}

	/**
	 * Test to ensure open cases with PSRs are closed on scan event case closure automation.
	 */
	@IsTest
	static void testOpenCasesWithPSRsAreClosedOnScanEventClosureAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		Case caseRecord = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		caseRecord.Status = SSSWConstants.CASE_STATUS_UPDATED;
		caseRecord.Exclude_Subscription_Automation__c = false;
		caseRecord = (Case)ApplicationTestDataFactory.setUnwritableFields(caseRecord, new Map<String, Object>{
				'ContactEmail' => 'test@test.invalid'
		});

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
		caseWrapper.newRootCause = 'test root cause';
		caseWrapper.newResolutionCode = 'test resolution code';
		caseWrapper.caseClosureEmailAlert = 'CaseClosureAlert';
		CaseUnifiedAutomationService.getInstance().processForCaseClosure(new List<CaseUnifiedAutomationService.RecordWrapper>{caseWrapper}, CaseUnifiedAutomationService.InvocationPoint.SCANAUTO, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerDirty((List<Case>) updatableCasesCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Case> updateableCases = (List<Case>) updatableCasesCaptor.getValue();

		Assert.areEqual(1, updateableCases.size(), 'Expected the case to be updated.');
		Assert.areEqual(caseRecord.Id, updateableCases[0].Id, 'Expected the case to be updated.');
		Assert.areEqual(CaseUnifiedAutomationService.QUEUE_SETTINGS?.ClosedQueueId__c, updateableCases[0].OwnerId, 'Expected the case to be assigned to closed cases omni queue.');
		Assert.areEqual(SSSWConstants.CASE_STATUS_CLOSED, updateableCases[0].Status, 'Expected the case status to be closed.');
		Assert.areEqual(caseWrapper.newRootCause, updateableCases[0].Root_cause__c, 'Expected the case root cause to be set.');
		Assert.areEqual(caseWrapper.newResolutionCode, updateableCases[0].ResolutionCode__c, 'Expected the case resolution code to be set.');

		// verify customer notification email is queued
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).queueEmailNotification(fflib_Match.eqId(caseRecord.Id), fflib_Match.eqSObjectType(Case.SObjectType), fflib_Match.eqString(caseWrapper.caseClosureEmailAlert));
	}

	/**
	 * Test to ensure open cases opted out of subscription automation (Exclude_Subscription_Automation__c = true) are
	 * reassigned (NOT closed) on scan event case closure automation.
	 */
	@IsTest
	static void testOpenCasesOptedOutOfSubscriptionAutomationAreReassignedOnScanEventClosureAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		Case caseRecord = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		caseRecord.Status = SSSWConstants.CASE_STATUS_UPDATED;
		caseRecord.Exclude_Subscription_Automation__c = true;
		caseRecord = (Case)ApplicationTestDataFactory.setUnwritableFields(caseRecord, new Map<String, Object>{
				'ContactEmail' => 'test@test.invalid'
		});

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
		caseWrapper.newRootCause = 'test root cause';
		caseWrapper.newResolutionCode = 'test resolution code';
		CaseUnifiedAutomationService.getInstance().processForCaseClosure(new List<CaseUnifiedAutomationService.RecordWrapper>{caseWrapper}, CaseUnifiedAutomationService.InvocationPoint.SCANAUTO, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerDirty((List<Case>) updatableCasesCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Case> updateableCases = (List<Case>) updatableCasesCaptor.getValue();

		Assert.areEqual(1, updateableCases.size(), 'Expected the case to be updated.');
		Assert.areEqual(caseRecord.Id, updateableCases[0].Id, 'Expected the case to be updated.');
		Assert.areEqual(CaseUnifiedAutomationService.QUEUE_SETTINGS?.UnifiedDefaultOmniQueueId__c, updateableCases[0].OwnerId, 'Expected the case to be assigned to unified cases omni queue.');
		Assert.areEqual(SSSWConstants.CASE_STATUS_UPDATED, updateableCases[0].Status, 'Expected the case status to be updated.');
		Assert.areEqual(CaseUnifiedAutomationService.REASSIGNMENT_REASON_OPT_OUT_AUTOMATION, updateableCases[0].ReassignmentReason__c, 'Expected the case reassignment reason to be set.');

		// verify emails are not queued
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(0))).queueEmailNotification(fflib_Match.anyId(), fflib_Match.anySObjectType(), fflib_Match.anyString());
	}

	/**
	 * Test to ensure open cases with no associated contact email are reassigned (NOT closed) on scan event case closure automation.
	 */
	@IsTest
	static void testOpenCasesWithNoContactEmailAreReassignedOnScanEventClosureAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		Case caseRecord = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		caseRecord.Status = SSSWConstants.CASE_STATUS_UPDATED;
		caseRecord.Exclude_Subscription_Automation__c = false;

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
		caseWrapper.newRootCause = 'test root cause';
		caseWrapper.newResolutionCode = 'test resolution code';
		CaseUnifiedAutomationService.getInstance().processForCaseClosure(new List<CaseUnifiedAutomationService.RecordWrapper>{caseWrapper}, CaseUnifiedAutomationService.InvocationPoint.SCANAUTO, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerDirty((List<Case>) updatableCasesCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Case> updateableCases = (List<Case>) updatableCasesCaptor.getValue();

		Assert.areEqual(1, updateableCases.size(), 'Expected the case to be updated.');
		Assert.areEqual(caseRecord.Id, updateableCases[0].Id, 'Expected the case to be updated.');
		Assert.areEqual(CaseUnifiedAutomationService.QUEUE_SETTINGS?.UnifiedDefaultOmniQueueId__c, updateableCases[0].OwnerId, 'Expected the case to be assigned to unified cases omni queue.');
		Assert.areEqual(SSSWConstants.CASE_STATUS_UPDATED, updateableCases[0].Status, 'Expected the case status to be updated.');
		Assert.areEqual(CaseUnifiedAutomationService.REASSIGNMENT_REASON_MISSING_CUSTOMER_EMAIL, updateableCases[0].ReassignmentReason__c, 'Expected the case reassignment reason to be set.');

		// verify emails are not queued
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(0))).queueEmailNotification(fflib_Match.anyId(), fflib_Match.anySObjectType(), fflib_Match.anyString());
	}

	/**
	* Test to ensure cases with scheduled contact requests are closed on scan event case closure automation only if case
	 * and child contact requests do not have any active AgentWork.
	*/
	@IsTest
	static void testOpenCasesWithChildContactRequestsOnScanEventClosureAutomation() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(3, true);
		cases[0].Status = SSSWConstants.CASE_STATUS_UPDATED;
		cases[1].Status = SSSWConstants.CASE_STATUS_UPDATED;
		cases[2].Status = SSSWConstants.CASE_STATUS_UPDATED;
		cases[2] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[2], new Map<String, Object>{
				'ContactEmail' => 'test@test.invalid'
		});

		List<ContactRequest> contactRequests = ApplicationTestDataFactoryCase.getContactRequests(3, new List<Id>{cases[0].Id, cases[1].Id, cases[2].Id}, null, true);

		// setup child contact requests on each case
		cases[0] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[0], new Map<String, List<SObject>>{'ContactRequests' => new List<ContactRequest>{contactRequests[0]}});
		cases[1] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[1], new Map<String, List<SObject>>{'ContactRequests' => new List<ContactRequest>{contactRequests[1]}});
		cases[2] = (Case)ApplicationTestDataFactory.setChildRelationships(cases[2], new Map<String, List<SObject>>{'ContactRequests' => new List<ContactRequest>{contactRequests[2]}});

		// setup PSR record for contactRequests[0]. cases[0] should be closed as there is currently no active agent work on Case or child contact request.
		PendingServiceRouting psr = ApplicationTestDataFactoryCase.getPendingServiceRoutings(1, null, null, new List<Id>{contactRequests[0].Id}, true)[0];

		// setup AgentWork record on contactRequests[1]
		List<AgentWork> agentWork = ApplicationTestDataFactoryCase.getAgentWorks(1, null, new List<Id>{contactRequests[1].Id}, true);
		// agentWork[0] is in status 'Opened'. cases[1] should not be closed or reassigned as the contact request has been assigned to an agent.
		agentWork[0] = (AgentWork) ApplicationTestDataFactory.setUnwritableFields(agentWork[0], new Map<String, Object>{
				'Status' => SSSWConstants.OMNI_AGENTWORK_STATUS_OPENED
		});

		// contactRequests[2] has no PSR records or AgentWork. cases[2] should be closed.

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
			caseWrapper.newResolutionCode = 'test resolution code';
			caseWrapper.newRootCause = 'test root cause';
			caseWrapper.caseClosureEmailAlert = 'CaseClosureAlert';
			caseWrappers.add(caseWrapper);
		}
		CaseUnifiedAutomationService.getInstance().processForCaseClosure(caseWrappers, CaseUnifiedAutomationService.InvocationPoint.SCANAUTO, mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor updatableCasesCaptor = fflib_ArgumentCaptor.forClass(List<Case>.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerDirty((List<Case>) updatableCasesCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		List<Case> updateableCases = (List<Case>) updatableCasesCaptor.getValue();

		Assert.areEqual(1, updateableCases.size(), 'Expected only one case to be updated.');
		Assert.areEqual(cases[2].Id, updateableCases[0].Id, 'Only the case whose SCRs does not have PSRs or active AgentWork is expected to be updated.');
		Assert.areEqual(CaseUnifiedAutomationService.QUEUE_SETTINGS?.ClosedQueueId__c, updateableCases[0].OwnerId, 'Expected the case to be assigned to closed cases omni queue.');
		Assert.areEqual(SSSWConstants.CASE_STATUS_CLOSED, updateableCases[0].Status, 'Expected the case to be closed.');
		Assert.areEqual(caseWrappers[2].newRootCause, updateableCases[0].Root_cause__c, 'Expected the case root cause to be set.');
		Assert.areEqual(caseWrappers[2].newResolutionCode, updateableCases[0].ResolutionCode__c, 'Expected the case resolution code to be set.');

		// verify customer notification email is queued for the closed case
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).queueEmailNotification(fflib_Match.eqId(cases[2].Id), fflib_Match.eqSObjectType(Case.SObjectType), fflib_Match.eqString(caseWrappers[2].caseClosureEmailAlert));
	}

}