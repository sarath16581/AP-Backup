/***
 * @author Seth Heang
 * @description Test class for CaseUnifiedProactiveMonitoringModule
 * @changelog
 * 2024-07-10 - Seth Heang - Created
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
		Date last5BusinessDays = BusinessHoursService.newInstance().calculateNextBusinessDay(last7days, 0);
		Datetime last5BusinessDaysDT = Datetime.newInstance(last5BusinessDays, Time.newInstance(0, 0, 0, 0));
		Datetime last6BusinessDaysDT = Datetime.newInstance(System.today().addDays(-8), Time.newInstance(0, 0, 0, 0));

		// Set created data within valid SLA period
		cases[0] = (Case) ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{ 'CreatedDate' => last5BusinessDaysDT });
		cases[1] = (Case) ApplicationTestDataFactory.setUnwritableFields(cases[1], new Map<String, Object>{ 'CreatedDate' => last6BusinessDaysDT });

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
}