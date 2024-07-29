/***
 * @author Seth Heang
 * @description Test class for CaseUnifiedProactiveMonitoringModule
 * @changelog
 * 2024-07-10 - Seth Heang - Created
 */
@IsTest
public with sharing class CaseUnifiedProactiveMonitoringModuleTest {
	/**
	 *	Test: BeforeUpdate Scenario, when updating the case owner to Unified Customer Service monitoring queue,
	 *	Given, case is within SLA period, validate that below details is updated:
	 *	- Case owner is updated to Unified Customer Service monitoring queue
	 *	- Status is updated to 'Monitoring'
	 *	- exclude automation flag is updated to False
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

		// Set status automation flag to New
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

		Group unifiedMonitoringQueue = ApplicationTestDataFactory.getGroups(1, 'queue', true)[0];
		unifiedMonitoringQueue.Name = 'Unified CustomerService Monitoring Queue';
		unifiedMonitoringQueue.DeveloperName = 'UnifiedCustomerServiceMonitoringQueue';

		// Change Owner
		cases[0].OwnerId = unifiedMonitoringQueue.Id;
		cases[1].OwnerId = unifiedMonitoringQueue.Id;
		cases[2].OwnerId = unifiedMonitoringQueue.Id;

		// =====================================
		// Stubbing
		// =====================================
		GroupsSelector mockGroupsSelector = (GroupsSelector) MockUtility.mockSelector(GroupsSelector.class);

		// Set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockGroupsSelector.selectByGroupTypeAndDeveloperName((Set<String>) fflib_Match.anyObject(), (Set<String>) fflib_Match.anyObject()))
			.thenReturn(new Map<Id, Group>(new List<Group>{ unifiedMonitoringQueue }));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseUnifiedProactiveMonitoringModule module = CaseUnifiedProactiveMonitoringModule.newInstance();
		module.onBeforeUpdate(cases, new Map<Id, Case>(oldCases), uow);

		Test.stopTest();

		((GroupsSelector) MockUtility.Mocks.verify(mockGroupsSelector, MockUtility.Mocks.times(1))).selectByGroupTypeAndDeveloperName((Set<String>) fflib_Match.anyObject(), (Set<String>) fflib_Match.anyObject());
		for (Case c : cases) {
			Assert.areEqual(unifiedMonitoringQueue.Id, c.OwnerId, 'Expected ownerId to belong to ' + unifiedMonitoringQueue.DeveloperName + 'but instead got ' + c.OwnerId);
			Assert.areEqual('Monitoring', c.Status, 'Expected status to be Monitoring but instead got ' + c.Status);
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

		//Integer dayOfWeek = System.today().toStartOfWeek().dayOfWeek(); // 1 = Monday, 7 = Sunday
		Date last7days = System.today().addDays(-7);
		Date last5BusinessDays = BusinessHoursService.newInstance().calculateNextBusinessDay(last7days, 0);
		Datetime last5BusinessDaysDT = Datetime.newInstance(last5BusinessDays, Time.newInstance(0, 0, 0, 0));
		Datetime last6BusinessDaysDT = Datetime.newInstance(System.today().addDays(-8), Time.newInstance(0, 0, 0, 0));

		// Set created data within valid SLA period
		cases[0] = (Case) ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{ 'CreatedDate' => last5BusinessDaysDT });
		cases[1] = (Case) ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{ 'CreatedDate' => last6BusinessDaysDT });

		List<Case> oldCases = new List<Case>{ cases[0].clone(true), cases[1].clone(true) };

		Group unifiedMonitoringQueue = ApplicationTestDataFactory.getGroups(1, 'queue', true)[0];
		unifiedMonitoringQueue.Name = 'Unified CustomerService Monitoring Queue';
		unifiedMonitoringQueue.DeveloperName = 'UnifiedCustomerServiceMonitoringQueue';

		// Change Owner
		cases[0].OwnerId = unifiedMonitoringQueue.Id;
		cases[1].OwnerId = unifiedMonitoringQueue.Id;

		// =====================================
		// Stubbing
		// =====================================
		GroupsSelector mockGroupsSelector = (GroupsSelector) MockUtility.mockSelector(GroupsSelector.class);

		// Set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockGroupsSelector.selectByGroupTypeAndDeveloperName((Set<String>) fflib_Match.anyObject(), (Set<String>) fflib_Match.anyObject()))
			.thenReturn(new Map<Id, Group>(new List<Group>{ unifiedMonitoringQueue }));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		CaseUnifiedProactiveMonitoringModule module = CaseUnifiedProactiveMonitoringModule.newInstance();
		module.onBeforeUpdate(cases, new Map<Id, Case>(oldCases), uow);

		Test.stopTest();

		Map<Id, Case> oldCaseMap = new Map<Id, Case>(oldCases);
		((GroupsSelector) MockUtility.Mocks.verify(mockGroupsSelector, MockUtility.Mocks.times(1))).selectByGroupTypeAndDeveloperName((Set<String>) fflib_Match.anyObject(), (Set<String>) fflib_Match.anyObject());
		for (Case c : cases) {
			Assert.areEqual(c.getErrors().size(), 1, 'Expected 1 error to be thrown but instead got ' + c.getErrors().size());
			Assert.areEqual(
				c.getErrors().get(0).getMessage(),
				CaseUnifiedProactiveMonitoringModule.ERROR_SLA_EXPIRED,
				'Expected error message to be "' + CaseUnifiedProactiveMonitoringModule.ERROR_SLA_EXPIRED + ' but instead got ' + c.getErrors().get(0).getMessage()
			);
			Assert.areEqual(oldCaseMap.get(c.Id).Status, c.Status, 'Expected status to be remain unchanged but instead got ' + c.Status);
		}
	}
}