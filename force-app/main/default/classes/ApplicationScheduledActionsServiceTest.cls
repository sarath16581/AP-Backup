/**
 * @author Seth Heang
 * @group Tests
 * @tag ScheduledAction__c, Case
 * @domain Core
 * @description Test class for CaseUnifiedAutomationService
 * @changelog
 * 2024-07-28 - Seth Heang - Created
 * 2024-10-15 - Ranjeewa Silva - Refactored test method 'testExecuteAllActions' to only verify logic in method under test ApplicationScheduledActionsService.executeAll.
 */
@IsTest(IsParallel=true)
public with sharing class ApplicationScheduledActionsServiceTest {

	@TestSetup
	static void testSetup(){
		QM__c queueSettings = QM__c.getOrgDefaults();
		Group unifiedMonitoringQueue = ApplicationTestDataFactory.getGroups(1, 'queue', true)[0];
		unifiedMonitoringQueue.Name = 'Unified Customer Service Monitoring Queue';

		queueSettings.UnifiedDefaultMonitoringQueueId__c = unifiedMonitoringQueue.Id;
		insert queueSettings;
	}

	/**
	 * Scenario: Test testValidateCaseActionsSetup method to setup for both 3 days and 5 days case monitoring scheduled actions
	 *			Validate that two scheduled actions are inserted for both 3 days and 5 days
	 */
	@IsTest
	static void testValidateCaseActionsSetup() {
		// =====================================
		// Data Preparation
		// =====================================
		CacheManager.settings.CacheEnabled__c = true;
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCase.RecordTypeId = CaseUnifiedAutomationService.getUnifiedInvestigationCaseRecordTypeId();
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

		ApplicationScheduledActionsService service = ApplicationScheduledActionsService.newInstance();
		service.validateCaseActionsSetup(new Map<Id, Case>{ testCase.Id => testCase }, false, mockUow);

		Test.stopTest();

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
			'Expected schedule dateTime to be in next 3 days but instead got: ' + actionFor3Days.ScheduledDate__c
		);

		Assert.areEqual(CaseMonitoring5DayAutoClosureAction.newInstance().getName(), actionFor5Days.ActionType__c, 'Expected action type to match but instead got ' + actionFor5Days.ActionType__c);
		Assert.areEqual(testCase.Id, actionFor5Days.Case__c, 'Expected case Id to match but instead got ' + actionFor5Days.Case__c);
		Assert.areEqual(true, actionFor5Days.Active__c, 'Expected active flag to set to true');
		Assert.areEqual(
			BusinessHoursService.newInstance().calculateNextBusinessDateTime(caseCreatedDate, 5),
			actionFor5Days.ScheduledDate__c,
			'Expected schedule dateTime to be in next 3 days but instead got: ' + actionFor5Days.ScheduledDate__c
		);
	}

	/**
	 * Scenario: Test Invocable method to execute all actions for Case automated action including 3 days and 5 days case monitoring scheduled actions
	 *			Validate that 3 days and 5 days scheduled actions are executed. Verifying specifics of 3 days and 5 days
	 *			case monitoring scheduled actions are covered in respective action tests.
	 */
	@IsTest
	static void testExecuteAllActions() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactoryCase.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCase.Exclude_Subscription_Automation__c = false;
		testCase.ProductSubCategory__c = 'StarTrack Express';
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'ContactEmail' => 'seth@test.com' });

		ScheduledAction__c scheduledActionFor3Days = ApplicationTestDataFactory.getScheduledActions(1, 'Test Scheduled Action For 3 Days', CaseMonitoring3DayReminderEmailAction.class.getName(), System.now(), testCase.Id, true)[0];

		ScheduledAction__c scheduledActionFor5Days = ApplicationTestDataFactory.getScheduledActions(1, 'Test Scheduled Action For 5 Days', CaseMonitoring5DayAutoClosureAction.class.getName(), System.now(), testCase.Id, true)[0];

		// =====================================
		// Stubbing
		// =====================================
		ScheduledActionsSelector mockScheduledActionsSelector = (ScheduledActionsSelector) MockUtility.mockSelector(ScheduledActionsSelector.class);
		CaseMonitoring3DayReminderEmailAction mock3DayReminderEmailAction = (CaseMonitoring3DayReminderEmailAction) MockUtility.mockUtility(CaseMonitoring3DayReminderEmailAction.class);
		CaseMonitoring5DayAutoClosureAction mock5DayCaseClosureEmailAction = (CaseMonitoring5DayAutoClosureAction) MockUtility.mockUtility(CaseMonitoring5DayAutoClosureAction.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockScheduledActionsSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ scheduledActionFor3Days.Id, scheduledActionFor5Days.Id })))
			.thenReturn(new List<ScheduledAction__c>{ scheduledActionFor3Days, scheduledActionFor5Days });
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ApplicationScheduledActionsService.executeAll(new List<Id>{ scheduledActionFor3Days.Id, scheduledActionFor5Days.Id });
		Test.stopTest();

		// verify scheduled action records are queried using the selector
		((ScheduledActionsSelector) MockUtility.Mocks.verify(mockScheduledActionsSelector, 1)).selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ scheduledActionFor3Days.Id, scheduledActionFor5Days.Id }));

		// verify 3-day case monitoring scheduled actions are executed
		((CaseMonitoring3DayReminderEmailAction) MockUtility.Mocks.verify(mock3DayReminderEmailAction, 1)).execute((List<Id>) fflib_Match.eq(new List<Id>{ scheduledActionFor3Days.Id }));
		// verify 5-day case monitoring scheduled actions are executed
		((CaseMonitoring5DayAutoClosureAction) MockUtility.Mocks.verify(mock5DayCaseClosureEmailAction, 1)).execute((List<Id>) fflib_Match.eq(new List<Id>{ scheduledActionFor5Days.Id }));
	}

	/**
	 * Scenario: Test exception scenario where an exception occurs within executeAll()
	 *			Validate that ScheduledAction__c has the active__c flag set to false to prevent automatic rescheduling by the Flow's Scheduled Path Out-of-box functionality
	 */
	@IsTest
	static void testExceptionSetScheduledActionToInactive() {
		// =====================================
		// Data Preparation
		// =====================================
		Case testCase = ApplicationTestDataFactory.getCases(1, true)[0];
		testCase.RecordTypeId = ApplicationTestDataFactoryCase.caseUnifiedInvestigationRecordType;
		testCase.OwnerId = (Id) QM__c.getInstance().UnifiedDefaultMonitoringQueueId__c;
		testCase.Exclude_Subscription_Automation__c = false;
		testCase.ProductSubCategory__c = 'StarTrack Express';
		testCase = (Case) ApplicationTestDataFactory.setUnwritableFields(testCase, new Map<String, Object>{ 'ContactEmail' => 'seth@test.com' });

		String actionTypeFor3Days = 'TESTING';
		ScheduledAction__c scheduledActionFor3Days = ApplicationTestDataFactory.getScheduledActions(1, 'Test Scheduled Action For 3 Days', actionTypeFor3Days, System.now(), testCase.Id, true)[0];
		scheduledActionFor3Days = (ScheduledAction__c) ApplicationTestDataFactory.setUnwritableFields(scheduledActionFor3Days, new Map<String, Object>{ 'Case__r' => testCase });

		// =====================================
		// Stubbing
		// =====================================
		ScheduledActionsSelector mockScheduledActionsSelector = (ScheduledActionsSelector) MockUtility.mockSelector(ScheduledActionsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockScheduledActionsSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ scheduledActionFor3Days.Id }))).thenReturn(new List<ScheduledAction__c>{ scheduledActionFor3Days });
		MockUtility.Mocks.when(
				mockScheduledActionsSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ scheduledActionFor3Days.Id }), (Set<Object>) fflib_Match.eq(new Set<Object>{ ScheduledActionsSelector.Options.WITH_CASE }))
			)
			.thenReturn(new List<ScheduledAction__c>{ scheduledActionFor3Days });
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>) fflib_Match.anyObject(), (Boolean) fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ApplicationScheduledActionsService.executeAll(new List<Id>{ scheduledActionFor3Days.Id });
		Test.stopTest();

		fflib_ArgumentCaptor updatableScheduledActionsCaptor = fflib_ArgumentCaptor.forClass(List<ScheduledAction__c>.class);

		((ApplicationDatabase) MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<Case>) updatableScheduledActionsCaptor.capture());
		Map<Id, ScheduledAction__c> updateableScheduledActions = new Map<Id, ScheduledAction__c>((List<ScheduledAction__c>) updatableScheduledActionsCaptor.getValue());
		Assert.areEqual(
			false,
			updateableScheduledActions.get(scheduledActionFor3Days.Id).Active__c,
			'Scheduled Action active flag should be false but instead got ' + updateableScheduledActions.get(scheduledActionFor3Days.Id).Active__c
		);
	}
}