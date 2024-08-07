/***
 * @author Seth Heang
 * @description Test class for CaseUnifiedProactiveMonitoringModule
 * @changelog
 * 2024-07-10 - Seth Heang - Created
 * 2024-07-30 - Seth Heang - Added test methods for 3Days/5Days Case monitoring Scheduled Actions functionalities
 */
@IsTest
public with sharing class CaseUnifiedProactiveMonitoringModuleTest {

	@TestSetup
	static void testSetup(){
		QM__c queueSettings = QM__c.getOrgDefaults();
		Group unifiedMonitoringQueue = ApplicationTestDataFactory.getGroups(1, 'queue', true)[0];
		unifiedMonitoringQueue.Name = 'Unified Customer Service Monitoring Queue';

		queueSettings.UnifiedDefaultMonitoringQueueId__c = unifiedMonitoringQueue.Id;
		insert queueSettings;
	}

	/**
	 * Test: BeforeUpdate Scenario, when updating the case owner to Unified Customer Service monitoring queue,
	 * 		Given, case is within SLA period, validate that below details is updated:
	 * - Case owner is updated to Unified Customer Service monitoring queue
	 * - Status is updated to 'Monitoring'
	 * - exclude automation flag is updated to False
	 */
	@IsTest
	private static void testEnsureBeforeUpdatePopulatesCaseStatusAndAutomationFlag() {
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseAutomationTriggerHandler.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(3, true);
		// Set the record type Id on case
		cases[0].RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		cases[1].RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		cases[2].RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;

		// Set status to New
		cases[0].Status = 'New';
		cases[1].Status = 'New';
		cases[2].Status = 'New';

		Date last7days = System.today().addDays(-7);
		Date last4BusinessDays = BusinessHoursService.newInstance().calculateNextBusinessDay(last7days, 1);
		Datetime last4BusinessDaysDT = Datetime.newInstance(last4BusinessDays, Time.newInstance(0, 0, 0, 0));
		Date last1BusinessDays = BusinessHoursService.newInstance().calculateNextBusinessDay(last7days, 4);
		Datetime last1BusinessDayDT = Datetime.newInstance(last1BusinessDays, Time.newInstance(0, 0, 0, 0));

		// Set created data within valid SLA period
		cases[0] = (Case) ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{ 'CreatedDate' => last4BusinessDaysDT });
		cases[1] = (Case) ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{ 'CreatedDate' => last1BusinessDayDT });
		cases[2] = (Case) ApplicationTestDataFactory.setUnwritableFields(cases[2], new Map<String, Object>{ 'CreatedDate' => System.today() });

		List<Case> oldCases = new List<Case>{ cases[0].clone(true), cases[1].clone(true), cases[2].clone(true) };

		// Change Owner to Unified Case Monitoring Queue
		Id unifiedCaseMonitoringQueueId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		cases[0].OwnerId = unifiedCaseMonitoringQueueId;
		cases[1].OwnerId = unifiedCaseMonitoringQueueId;
		cases[2].OwnerId = unifiedCaseMonitoringQueueId;

		// =====================================
		// Stubbing
		// =====================================
		// NONE

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseUnifiedProactiveMonitoringModule module = CaseUnifiedProactiveMonitoringModule.newInstance();
		module.onBeforeUpdate(cases, new Map<Id, Case>(oldCases), uow);

		Test.stopTest();

		for (Case c : cases) {
			Assert.areEqual(unifiedCaseMonitoringQueueId, c.OwnerId, 'Expected ownerId to belong to ' + unifiedCaseMonitoringQueueId + 'but instead got ' + c.OwnerId);
			Assert.areEqual(SSSWConstants.CASE_STATUS_MONITORING, c.Status, 'Expected status to be Monitoring but instead got ' + c.Status);
		}
	}

	/**
	 *	Test: BeforeUpdate Scenario, when updating the case owner to Unified Customer Service monitoring queue,
	 *	Given, that SLA period is exceeded, validate that below details is updated:
	 *	- An error occurs and error message is appropriate
	 *	- Status remains unchanged
	 *	- exclude automation flag remains unchanged
	 */
	@IsTest
	private static void testEnsureBeforeUpdateValidateSLA() {
		// =====================================
		// Data Preparation
		// =====================================
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseAutomationTriggerHandler.getUnitOfWorkSObjectTypes());
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		// Set the record type Id on case
		cases[0].RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		cases[1].RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;

		// Set status automation flag to New
		cases[0].Status = 'New';
		cases[1].Status = 'New';

		Date last7days = System.today().addDays(-7);
		Date last4BusinessDays = BusinessHoursService.newInstance().calculateNextBusinessDay(last7days, 1);
		Datetime last4BusinessDaysDT = Datetime.newInstance(last4BusinessDays, Time.newInstance(0, 0, 0, 0));
		Date last5BusinessDays = BusinessHoursService.newInstance().calculateNextBusinessDay(last7days, 0);
		Datetime last5BusinessDaysDT = Datetime.newInstance(last5BusinessDays, Time.newInstance(0, 0, 0, 0));


		// Set created data within valid SLA period
		cases[0] = (Case) ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{ 'CreatedDate' => last4BusinessDaysDT });
		cases[1] = (Case) ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{ 'CreatedDate' => last5BusinessDaysDT });

		List<Case> oldCases = new List<Case>{ cases[0].clone(true), cases[1].clone(true) };

		// Change Owner to Unified Case Monitoring Queue
		Id unifiedCaseMonitoringQueueId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		cases[0].OwnerId = unifiedCaseMonitoringQueueId;
		cases[1].OwnerId = unifiedCaseMonitoringQueueId;

		// =====================================
		// Stubbing
		// =====================================
		// NONE

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseUnifiedProactiveMonitoringModule module = CaseUnifiedProactiveMonitoringModule.newInstance();
		module.onBeforeUpdate(cases, new Map<Id, Case>(oldCases), uow);

		Test.stopTest();

		Map<Id, Case> oldCaseMap = new Map<Id, Case>(oldCases);

		// assert successful update
		Assert.areEqual(unifiedCaseMonitoringQueueId, cases[0].OwnerId, 'Expected ownerId to belong to ' + unifiedCaseMonitoringQueueId + 'but instead got ' + cases[0].OwnerId);
		Assert.areEqual(SSSWConstants.CASE_STATUS_MONITORING, cases[0].Status, 'Expected status to be Monitoring but instead got ' + cases[0].Status);
		// assert error due to SLA period
		Assert.areEqual(1, cases[1].getErrors().size(), 'Expected 1 error to be thrown but instead got ' + cases[1].getErrors().size());
		Assert.areEqual(
				CaseUnifiedProactiveMonitoringModule.ERROR_SLA_EXPIRED,
				cases[1].getErrors().get(0).getMessage(),
				'Expected error message to be "' + CaseUnifiedProactiveMonitoringModule.ERROR_SLA_EXPIRED + ' but instead got ' + cases[1].getErrors().get(0).getMessage()
		);
		Assert.areEqual(oldCaseMap.get(cases[1].Id).Status, cases[1].Status, 'Expected status to be remain unchanged but instead got ' + cases[1].Status);
	}

	/**
	 *	Test: AfterInsert Scenario, when inserting a case of 'UnifiedInvestigation' record type and appropriate criteria is met,
	 *		Then Validate that the Async Worker is enqueued And ensure Two Scheduled Actions are created for 3 Days and 5 Days Case Monitoring
	 */
	@IsTest
	private static void testEnsureAfterInsertRegisterAsyncWorkerAndInsertScheduledAction() {
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

		CaseUnifiedProactiveMonitoringModule module = CaseUnifiedProactiveMonitoringModule.newInstance();
		module.onAfterInsert(new List<Case>{ testCase }, mockUow);

		CaseUnifiedProactiveMonitoringModule.CaseUnifiedScheduledActionsParam params = new CaseUnifiedProactiveMonitoringModule.CaseUnifiedScheduledActionsParam(new List<Case>{ testCase }, false);

		// verify worker was enqueued correctly
		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.capture());

		ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.getValue();
		CaseUnifiedProactiveMonitoringModule.AsyncUnifiedCaseScheduledActionWorker caseUnifiedCaseScheduledActionWorker = new CaseUnifiedProactiveMonitoringModule.AsyncUnifiedCaseScheduledActionWorker();
		caseUnifiedCaseScheduledActionWorker.params = (CaseUnifiedProactiveMonitoringModule.CaseUnifiedScheduledActionsParam) stagedWorker.params;
		Assert.areEqual(params.cases, caseUnifiedCaseScheduledActionWorker.params.cases, 'Expected params are not matched instead got: ' + caseUnifiedCaseScheduledActionWorker.params.cases);
		Assert.areEqual(
			params.revalidateOperation,
			caseUnifiedCaseScheduledActionWorker.params.revalidateOperation,
			'Expected params are not matched instead got: ' + caseUnifiedCaseScheduledActionWorker.params.revalidateOperation
		);

		Test.stopTest();

		// Since the Platform Event trigger does not automatically get triggered, explicitly call execute() to trigger the next step of automation
		caseUnifiedCaseScheduledActionWorker.execute(mockUow);

		fflib_ArgumentCaptor insertableObjectsCaptor = fflib_ArgumentCaptor.forClass(Object.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 2)).registerNew((List<ScheduledAction__c>) insertableObjectsCaptor.capture());
		List<Object> insertRecords = (List<Object>) insertableObjectsCaptor.getAllValues();
		List<ScheduledAction__c> insertedScheduledActions = new List<ScheduledAction__c>();
		insertedScheduledActions.addAll((List<ScheduledAction__c>) insertRecords[0]);
		insertedScheduledActions.addAll((List<ScheduledAction__c>) insertRecords[1]);
		ScheduledAction__c actionFor3Days;
		ScheduledAction__c actionFor5Days;
		for (ScheduledAction__c action : insertedScheduledActions) {
			if (action.ActionType__c.equals(CaseMonitoring3DayReminderEmailAction.newInstance().getName())) {
				actionFor3Days = action;
			} else if (action.ActionType__c.equals(CaseMonitoring5DayAutoClosureAction.newInstance().getName())) {
				actionFor5Days = action;
			}
		}

		Assert.areEqual(CaseMonitoring3DayReminderEmailAction.newInstance().getName(), actionFor3Days.ActionType__c, 'Expected action type to match but instead got ' + actionFor3Days.ActionType__c);
		Assert.areEqual(testCase.Id, actionFor3Days.Case__c, 'Expected case Id to match but instead got ' + actionFor3Days.Case__c);
		Assert.areEqual(true, actionFor3Days.Active__c, 'Expected active flag to set to true');
		Assert.areEqual(
			BusinessHoursService.newInstance().calculateNextBusinessDateTime(caseCreatedDate, 3),
			actionFor3Days.ScheduledDate__c,
			'Expected schedule dateTime to be in next 5 days but instead got: ' + actionFor3Days.ScheduledDate__c
		);

		Assert.areEqual(CaseMonitoring5DayAutoClosureAction.newInstance().getName(), actionFor5Days.ActionType__c, 'Expected action type to match but instead got ' + actionFor5Days.ActionType__c);
		Assert.areEqual(testCase.Id, actionFor5Days.Case__c, 'Expected case Id to match but instead got ' + actionFor5Days.Case__c);
		Assert.areEqual(true, actionFor5Days.Active__c, 'Expected active flag to set to true');
		Assert.areEqual(
			BusinessHoursService.newInstance().calculateNextBusinessDateTime(caseCreatedDate, 5),
			actionFor5Days.ScheduledDate__c,
			'Expected schedule dateTime to be in next 5 days but instead got: ' + actionFor5Days.ScheduledDate__c
		);
	}

	/**
	 *	Test: AfterUpdate Scenario, when update a case without child scheduled actions to meet the appropriate criteria for 3 Days and 5 Days Case Monitoring,
	 *		Then Validate that the Async Worker is enqueued And ensure Two Scheduled Actions are created for 3 Days and 5 Days Case Monitoring
	 */
	@IsTest
	private static void testEnsureAfterUpdateRegisterAsyncWorkerAndInsertScheduledAction() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCase.EnquirySubType__c = 'Late Item';
		testCase.Exclude_Subscription_Automation__c = true;
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'ContactEmail' => 'seth@test.com' });

		Datetime caseCreatedDate = Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'CreatedDate' => caseCreatedDate });

		Case updatedCase = testCase.clone(true);
		updatedCase.Exclude_Subscription_Automation__c = false; // this will pass the validation
		updatedCase = (Case) ApplicationTestDataFactory.setUnwritableFields(updatedCase, new Map<String, Object>{ 'CreatedDate' => caseCreatedDate });

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

		CaseUnifiedProactiveMonitoringModule module = CaseUnifiedProactiveMonitoringModule.newInstance();
		module.onAfterUpdate(new List<Case>{ updatedCase }, new Map<Id, Case>{ testCase.Id => testCase }, mockUow);

		CaseUnifiedProactiveMonitoringModule.CaseUnifiedScheduledActionsParam params = new CaseUnifiedProactiveMonitoringModule.CaseUnifiedScheduledActionsParam(new List<Case>{ updatedCase }, true);

		// verify worker was enqueued correctly
		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.capture());

		ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.getValue();
		CaseUnifiedProactiveMonitoringModule.AsyncUnifiedCaseScheduledActionWorker caseUnifiedCaseScheduledActionWorker = new CaseUnifiedProactiveMonitoringModule.AsyncUnifiedCaseScheduledActionWorker();
		caseUnifiedCaseScheduledActionWorker.params = (CaseUnifiedProactiveMonitoringModule.CaseUnifiedScheduledActionsParam) stagedWorker.params;
		Assert.areEqual(params.cases[0].Id, caseUnifiedCaseScheduledActionWorker.params.cases[0].Id, 'Expected case Id to match instead got: ' + caseUnifiedCaseScheduledActionWorker.params.cases[0].Id);
		Assert.areEqual(
			params.cases[0].ContactEmail,
			caseUnifiedCaseScheduledActionWorker.params.cases[0].ContactEmail,
			'Expected case ContactEmail to match instead got: ' + caseUnifiedCaseScheduledActionWorker.params.cases[0].ContactEmail
		);
		Assert.areEqual(
			params.cases[0].Exclude_Subscription_Automation__c,
			caseUnifiedCaseScheduledActionWorker.params.cases[0].Exclude_Subscription_Automation__c,
			'Expected case Exclude_Subscription_Automation__c to match instead got: ' + caseUnifiedCaseScheduledActionWorker.params.cases[0].Exclude_Subscription_Automation__c
		);
		Assert.areEqual(
			params.cases[0].EnquirySubType__c,
			caseUnifiedCaseScheduledActionWorker.params.cases[0].EnquirySubType__c,
			'Expected case EnquirySubType__c to match instead got: ' + caseUnifiedCaseScheduledActionWorker.params.cases[0].EnquirySubType__c
		);
		Assert.areEqual(
			params.revalidateOperation,
			caseUnifiedCaseScheduledActionWorker.params.revalidateOperation,
			'Expected params are not matched instead got: ' + caseUnifiedCaseScheduledActionWorker.params.revalidateOperation
		);

		Test.stopTest();
		// Since the Platform Event trigger does not automatically get triggered, explicitly call execute() to trigger the next step of automation
		caseUnifiedCaseScheduledActionWorker.execute(mockUow);

		// verify the scheduled action is inserted correctly
		fflib_ArgumentCaptor insertableObjectsCaptor = fflib_ArgumentCaptor.forClass(Object.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 2)).registerNew((List<ScheduledAction__c>) insertableObjectsCaptor.capture());
		List<Object> insertRecords = (List<Object>) insertableObjectsCaptor.getAllValues();
		List<ScheduledAction__c> insertedScheduledActions = new List<ScheduledAction__c>();
		insertedScheduledActions.addAll((List<ScheduledAction__c>) insertRecords[0]);
		insertedScheduledActions.addAll((List<ScheduledAction__c>) insertRecords[1]);
		ScheduledAction__c actionFor3Days;
		ScheduledAction__c actionFor5Days;
		for (ScheduledAction__c action : insertedScheduledActions) {
			if (action.ActionType__c.equals(CaseMonitoring3DayReminderEmailAction.newInstance().getName())) {
				actionFor3Days = action;
			} else if (action.ActionType__c.equals(CaseMonitoring5DayAutoClosureAction.newInstance().getName())) {
				actionFor5Days = action;
			}
		}
		Assert.areEqual(CaseMonitoring3DayReminderEmailAction.newInstance().getName(), actionFor3Days.ActionType__c, 'Expected action type to match but instead got ' + actionFor3Days.ActionType__c);
		Assert.areEqual(testCase.Id, actionFor3Days.Case__c, 'Expected case Id to match but instead got ' + actionFor3Days.Case__c);
		Assert.areEqual(true, actionFor3Days.Active__c, 'Expected active flag to set to true');
		Assert.areEqual(
			BusinessHoursService.newInstance().calculateNextBusinessDateTime(caseCreatedDate, 3),
			actionFor3Days.ScheduledDate__c,
			'Expected schedule dateTime to be in next 5 days but instead got: ' + actionFor3Days.ScheduledDate__c
		);
		Assert.areEqual(CaseMonitoring5DayAutoClosureAction.newInstance().getName(), actionFor5Days.ActionType__c, 'Expected action type to match but instead got ' + actionFor5Days.ActionType__c);
		Assert.areEqual(testCase.Id, actionFor5Days.Case__c, 'Expected case Id to match but instead got ' + actionFor5Days.Case__c);
		Assert.areEqual(true, actionFor5Days.Active__c, 'Expected active flag to set to true');
		Assert.areEqual(
			BusinessHoursService.newInstance().calculateNextBusinessDateTime(caseCreatedDate, 5),
			actionFor5Days.ScheduledDate__c,
			'Expected schedule dateTime to be in next 5 days but instead got: ' + actionFor5Days.ScheduledDate__c
		);
	}

	/**
	 *	Test: AfterUpdate Scenario, when update a case having a child scheduled actions to no longer meet the appropriate criteria for 3 Days Case Monitoring,
	 *			Then Validate that the Async Worker is enqueued And ensure the Scheduled Actions are created for 3 Days and 5 Days Case Monitoring
	 */
	@IsTest
	private static void testEnsureAfterUpdateRegisterAsyncWorkerAndDeleteExistingScheduledAction() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCase.EnquirySubType__c = 'Late Item';
		testCase.Exclude_Subscription_Automation__c = false;
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'ContactEmail' => 'seth@test.com' });

		String actionTypeFor3Days = CaseMonitoring3DayReminderEmailAction.newInstance().getName();
		ScheduledAction__c scheduledActionFor3Days = ApplicationTestDataFactory.getScheduledActions(1, 'Test Scheduled Action', actionTypeFor3Days, System.now(), testCase.Id, true)[0];
		String actionTypeFor5Days = CaseMonitoring5DayAutoClosureAction.newInstance().getName();
		ScheduledAction__c scheduledActionFor5Days = ApplicationTestDataFactory.getScheduledActions(1, 'Test Scheduled Action', actionTypeFor5Days, System.now(), testCase.Id, true)[0];

		Datetime caseCreatedDate = Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'CreatedDate' => caseCreatedDate });

		Case updatedCase = testCase.clone(true);
		// this will fail the validation, and automation will delete the scheduled action
		updatedCase = (Case) ApplicationTestDataFactory.setUnwritableFields(updatedCase, new Map<String, Object>{ 'CreatedDate' => caseCreatedDate.addDays(-10) });
		updatedCase.Exclude_Subscription_Automation__c = true;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		ScheduledActionsSelector mockScheduledActionsSelector = (ScheduledActionsSelector) MockUtility.mockSelector(ScheduledActionsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockScheduledActionsSelector.selectByCaseId((Set<Id>) fflib_Match.eq(new Set<Id>{ testCase.Id })))
			.thenReturn(new List<ScheduledAction__c>{ scheduledActionFor3Days, scheduledActionFor5Days });
		((ApplicationUnitOfWork) MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockUow)).registerDeleted((List<SObject>) fflib_Match.anyObject());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseUnifiedProactiveMonitoringModule module = CaseUnifiedProactiveMonitoringModule.newInstance();
		module.onAfterUpdate(new List<Case>{ updatedCase }, new Map<Id, Case>{ testCase.Id => testCase }, mockUow);

		CaseUnifiedProactiveMonitoringModule.CaseUnifiedScheduledActionsParam params = new CaseUnifiedProactiveMonitoringModule.CaseUnifiedScheduledActionsParam(new List<Case>{ updatedCase }, true);

		// verify worker was enqueued correctly
		fflib_ArgumentCaptor stagedWorkerCapture = fflib_ArgumentCaptor.forClass(ApplicationUnitOfWork.AsyncStagingWorker.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, MockUtility.Mocks.times(1))).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.capture());

		ApplicationUnitOfWork.AsyncStagingWorker stagedWorker = (ApplicationUnitOfWork.AsyncStagingWorker) stagedWorkerCapture.getValue();
		CaseUnifiedProactiveMonitoringModule.AsyncUnifiedCaseScheduledActionWorker caseUnifiedCaseScheduledActionWorker = new CaseUnifiedProactiveMonitoringModule.AsyncUnifiedCaseScheduledActionWorker();
		caseUnifiedCaseScheduledActionWorker.params = (CaseUnifiedProactiveMonitoringModule.CaseUnifiedScheduledActionsParam) stagedWorker.params;

		Assert.areEqual(params.cases[0].Id, caseUnifiedCaseScheduledActionWorker.params.cases[0].Id, 'Expected case Id to match instead got: ' + caseUnifiedCaseScheduledActionWorker.params.cases[0].Id);
		Assert.areEqual(
			params.cases[0].ContactEmail,
			caseUnifiedCaseScheduledActionWorker.params.cases[0].ContactEmail,
			'Expected case ContactEmail to match instead got: ' + caseUnifiedCaseScheduledActionWorker.params.cases[0].ContactEmail
		);
		Assert.areEqual(
			params.cases[0].Exclude_Subscription_Automation__c,
			caseUnifiedCaseScheduledActionWorker.params.cases[0].Exclude_Subscription_Automation__c,
			'Expected case Exclude_Subscription_Automation__c to match instead got: ' + caseUnifiedCaseScheduledActionWorker.params.cases[0].Exclude_Subscription_Automation__c
		);
		Assert.areEqual(
			params.cases[0].EnquirySubType__c,
			caseUnifiedCaseScheduledActionWorker.params.cases[0].EnquirySubType__c,
			'Expected case EnquirySubType__c to match instead got: ' + caseUnifiedCaseScheduledActionWorker.params.cases[0].EnquirySubType__c
		);
		Assert.areEqual(
			params.revalidateOperation,
			caseUnifiedCaseScheduledActionWorker.params.revalidateOperation,
			'Expected params are not matched instead got: ' + caseUnifiedCaseScheduledActionWorker.params.revalidateOperation
		);

		Test.stopTest();

		// Since the Platform Event trigger does not automatically get triggered, explicitly call execute() to trigger the next step of automation
		caseUnifiedCaseScheduledActionWorker.execute(mockUow);
		((ScheduledActionsSelector) MockUtility.Mocks.verify(mockScheduledActionsSelector, 2)).selectByCaseId((Set<Id>) fflib_Match.eq(new Set<Id>{ testCase.Id }));

		// verify the scheduled action is inserted correctly
		fflib_ArgumentCaptor deletedScheduledActionCaptor = fflib_ArgumentCaptor.forClass(Object.class);
		((ApplicationUnitOfWork) MockUtility.Mocks.verify(mockUow, 2)).registerDeleted((List<ScheduledAction__c>) deletedScheduledActionCaptor.capture());
		List<Object> deletedRecords = (List<Object>) deletedScheduledActionCaptor.getAllValues();
		List<ScheduledAction__c> deletedScheduledActions = new List<ScheduledAction__c>();
		deletedScheduledActions.addAll((List<ScheduledAction__c>) deletedRecords[0]);
		deletedScheduledActions.addAll((List<ScheduledAction__c>) deletedRecords[1]);
		Set<Id> deletedIds = new Set<Id>{ deletedScheduledActions[0].Id, deletedScheduledActions[1].Id };
		Assert.areEqual(true, deletedIds.contains(scheduledActionFor3Days.Id), 'Expected the scheduled action to be deleted but did not ' + deletedIds);
		Assert.areEqual(true, deletedIds.contains(scheduledActionFor5Days.Id), 'Expected the scheduled action to be deleted but did not ' + deletedIds);
	}
}