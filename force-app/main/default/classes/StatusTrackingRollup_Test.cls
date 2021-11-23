/**************************************************
Description:       Test class to cover StatusTrackingRollup_Batchable and StatusTrackingRollup_Schedulable
History:
--------------------------------------------------
2017-12-18  nathan.franklin@auspost.com.au  Created
**************************************************/
@isTest
public without sharing class StatusTrackingRollup_Test {

	/*****************************************************
	 * SCENARIO:
	 *
	 *  Rollup status tracking records to Case
	 * All records will successfully update.
	 *****************************************************/
	public static testMethod void testBatchCaseProcessing() {

		// set the status tracking config
		RollupCalculationConfig__c config = new RollupCalculationConfig__c(StatusTrackingConcurrentBatches__c = 1, StatusTrackingMaxRecordSelection__c = 100000, StatusTrackingCaseBatchSize__c = 100);
		insert config;

		List<Case> cases = new List<Case>{
			TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery'),
			TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery'),
			TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery')
		};

		// this will also create some Status Tracking records...
		// these will not have any calculable values for rollups though.
		insert cases;

		Set<Id> caseIds = new Set<Id>();
		for(Case c : cases) {
			caseIds.add(c.Id);
		}


		List<StatusTracking__c> statusTrackings = [Select Id, StatusValue__c, Status__c, Duration__c, DurationMins__c From StatusTracking__c];
		System.Debug(statusTrackings);

		// similating some status tracking options
		statusTrackings = new List<StatusTracking__c>();
		for(Case c : cases) {
			StatusTracking__c statusTracking = TestDataProvider.createTestStatusTracking();
			statusTracking.Case__c = c.Id;
			statusTracking.Duration__c = 15;
			statusTracking.StatusValue__c = 'New';
			statusTrackings.add(statusTracking);

			statusTracking = TestDataProvider.createTestStatusTracking();
			statusTracking.Case__c = c.Id;
			statusTracking.Duration__c = 40;
			statusTracking.StatusValue__c = 'New';
			statusTrackings.add(statusTracking);

			statusTracking = TestDataProvider.createTestStatusTracking();
			statusTracking.Case__c = c.Id;
			statusTracking.DurationMins__c = 10;
			statusTracking.StatusValue__c = 'Awaiting Information';
			statusTrackings.add(statusTracking);

			statusTracking = TestDataProvider.createTestStatusTracking();
			statusTracking.Case__c = c.Id;
			statusTracking.DurationMins__c = 15;
			statusTracking.StatusValue__c = 'Awaiting Information';
			statusTrackings.add(statusTracking);
		}
		insert statusTrackings;

		statusTrackings = [Select Id, StatusValue__c, Status__c, Duration__c, DurationMins__c From StatusTracking__c];
		System.Debug(statusTrackings);

		Test.startTest();
		StatusTrackingRollup_Batchable batch = new StatusTrackingRollup_Batchable(caseIds);
		Database.executeBatch(batch, 200);
		Test.stopTest();

		for(Case c : [Select Id, CaseNumber, EffectiveCaseDurationRollup__c, StatusTrackingCountRollup__c, StatusTrackingDurationRollup__c From Case]) {
			System.assertEquals(5, c.StatusTrackingCountRollup__c); // (1 on case creation + 4 created)
			System.assertEquals(55, c.StatusTrackingDurationRollup__c);
			System.assertEquals(25, c.EffectiveCaseDurationRollup__c);
		}
	}


	/*****************************************************
	 * SCENARIO:
	 *
	 *  Rollup status tracking records to Case
	 *  A previous case record already failed but this time it will be processed successfully
	 *  A different case record will fail to update and will be logged in the rollup log.
	 *  Overall, 2 records will be successfully updated and 1 will fail.
	 *****************************************************/
	public static testMethod void testBatchCaseFailures() {

		// set the status tracking config
		// note: StatusTrackingMaxRecordSelection__c = 1 which ensures only a single status tracking record will be processed
		//          the case selection is based off this record.
		RollupCalculationConfig__c config = new RollupCalculationConfig__c(StatusTrackingConcurrentBatches__c = 1, StatusTrackingMaxRecordSelection__c = 100000, StatusTrackingCaseBatchSize__c = 100);
		insert config;

		List<Case> cases = new List<Case>{
			TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery'),
			TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery'),
			TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery')
		};

		// this will also create some Status Tracking records...
		// these will not have any calculable values for rollups though.
		insert cases;

		Set<Id> caseIds = new Set<Id>();
		for(Case c : cases) {
			caseIds.add(c.Id);
		}

		// put an entry for the second case inserted into the RollupCalculationFailureLog__c which will simulate that it failed the *last* time it was run
		// this record should be deleted at the end of the batch run since this record is successfully processed in the batch for this scenario.
		insert new RollupCalculationFailureLog__c(RecordId__c = cases[1].Id);

		List<StatusTracking__c> statusTrackings = [Select Id, StatusValue__c, Status__c, Duration__c, DurationMins__c From StatusTracking__c];
		System.Debug(statusTrackings);

		// similating some status tracking options
		statusTrackings = new List<StatusTracking__c>();
		for(Case c : cases) {
			StatusTracking__c statusTracking = TestDataProvider.createTestStatusTracking();
			statusTracking.Case__c = c.Id;
			statusTracking.Duration__c = 15;
			statusTracking.StatusValue__c = 'New';
			statusTrackings.add(statusTracking);

			statusTracking = TestDataProvider.createTestStatusTracking();
			statusTracking.Case__c = c.Id;
			statusTracking.Duration__c = 40;
			statusTracking.StatusValue__c = 'New';
			statusTrackings.add(statusTracking);

			statusTracking = TestDataProvider.createTestStatusTracking();
			statusTracking.Case__c = c.Id;
			statusTracking.DurationMins__c = 10;
			statusTracking.StatusValue__c = 'Awaiting Information';
			statusTrackings.add(statusTracking);

			statusTracking = TestDataProvider.createTestStatusTracking();
			statusTracking.Case__c = c.Id;
			statusTracking.DurationMins__c = 15;
			statusTracking.StatusValue__c = 'Awaiting Information';
			statusTrackings.add(statusTracking);
		}
		insert statusTrackings;

		statusTrackings = [Select Id, StatusValue__c, Status__c, Duration__c, DurationMins__c From StatusTracking__c];
		System.Debug(statusTrackings);

		Test.startTest();
		StatusTrackingRollup_Batchable batch = new StatusTrackingRollup_Batchable(caseIds);

		// this is a special test only field which sets additional values on the case which, in this scenario, will cause the case to fail to update
		batch.forceTestFailureId = cases[0].Id;
		batch.forceTestFailure = true;

		Database.executeBatch(batch, 200);
		Test.stopTest();

		for(Case c : [Select Id, CaseNumber, StatusTrackingRollupsLastRun__c, EffectiveCaseDurationRollup__c, StatusTrackingCountRollup__c, StatusTrackingDurationRollup__c From Case Where Id != :cases[0].Id]) {
			System.assertEquals(5, c.StatusTrackingCountRollup__c); // (1 on case creation + 4 created)
			System.assertEquals(55, c.StatusTrackingDurationRollup__c);
			System.assertEquals(25, c.EffectiveCaseDurationRollup__c);
			System.assertNotEquals(null, c.StatusTrackingRollupsLastRun__c);
		}

		// check the first case didn't update (because of errors - there should also be a log in the RollupCalculationFailureLog__c table)
		Case c = [Select Id, CaseNumber, StatusTrackingRollupsLastRun__c, EffectiveCaseDurationRollup__c, StatusTrackingCountRollup__c, StatusTrackingDurationRollup__c From Case Where Id = :cases[0].Id];
		System.assertEquals(null, c.StatusTrackingCountRollup__c); // (1 on case creation + 4 created)
		System.assertEquals(null, c.StatusTrackingDurationRollup__c);
		System.assertEquals(null, c.EffectiveCaseDurationRollup__c);
		System.assertEquals(null, c.StatusTrackingRollupsLastRun__c);

		// make sure the first case generated an entry in the RollupCalculationFailureLog__c so it will be processed in the next run due to an error updating the Case record.
		List<RollupCalculationFailureLog__c> logEntry = [Select Id, RecordId__c From RollupCalculationFailureLog__c];
		System.assertEquals(1, logEntry.size());
		System.assertEquals(String.valueOf(cases[0].Id), logEntry[0].RecordId__c);
	}

	public static testMethod void testBatchCaseDelegator() {
		// set the status tracking config
		RollupCalculationConfig__c config = new RollupCalculationConfig__c(StatusTrackingConcurrentBatches__c = 1, StatusTrackingMaxRecordSelection__c = 1, StatusTrackingCaseBatchSize__c = 100);
		insert config;

		List<Case> cases = new List<Case>{
			TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery'),
			TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery'),
			TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery')
		};

		// this will also create some Status Tracking records...
		// these will not have any calculable values for rollups though.
		insert cases;

		// put an entry for the second case inserted into the RollupCalculationFailureLog__c which will simulate that it failed the *last* time it was run
		// this record should be deleted at the end of the batch run since this record is successfully processed in the batch for this scenario.
		insert new RollupCalculationFailureLog__c(RecordId__c = cases[1].Id);

		List<StatusTracking__c> statusTrackings = [Select Id, StatusValue__c, Status__c, Duration__c, DurationMins__c From StatusTracking__c];
		System.Debug(statusTrackings);

		// similating some status tracking options
		for(Case c : cases) {
			statusTrackings = new List<StatusTracking__c>();

			StatusTracking__c statusTracking = TestDataProvider.createTestStatusTracking();
			statusTracking.Case__c = c.Id;
			statusTracking.Duration__c = 15;
			statusTracking.StatusValue__c = 'New';
			statusTrackings.add(statusTracking);

			statusTracking = TestDataProvider.createTestStatusTracking();
			statusTracking.Case__c = c.Id;
			statusTracking.Duration__c = 40;
			statusTracking.StatusValue__c = 'New';
			statusTrackings.add(statusTracking);

			statusTracking = TestDataProvider.createTestStatusTracking();
			statusTracking.Case__c = c.Id;
			statusTracking.DurationMins__c = 10;
			statusTracking.StatusValue__c = 'Awaiting Information';
			statusTrackings.add(statusTracking);

			statusTracking = TestDataProvider.createTestStatusTracking();
			statusTracking.Case__c = c.Id;
			statusTracking.DurationMins__c = 15;
			statusTracking.StatusValue__c = 'Awaiting Information';
			statusTrackings.add(statusTracking);

			// insert each group so we know which ones got added last
			insert statusTrackings;
		}

		// Status tracking records for cases[2].Id should be the last inserted
		// cases[1].Id should also be included because its in RollupCalculationFailureLog__c

		Test.startTest();
		StatusTrackingRollupDelegator batch = new StatusTrackingRollupDelegator();
		Database.executeBatch(batch, 200);
		Test.stopTest();

		System.Debug(StatusTrackingRollupDelegator.batchIds);

		System.assertEquals(1, StatusTrackingRollupDelegator.batchIds.size());
		System.assertEquals(2, StatusTrackingRollupDelegator.batchIds[0].size());

		Set<Id> selectedIds = new Set<Id>(StatusTrackingRollupDelegator.batchIds[0]);
		System.assertEquals(true, selectedIds.contains(cases[2].Id));
		System.assertEquals(true, selectedIds.contains(cases[1].Id));

		List<Id> caseIds = new List<Id>();
		for(Case c : cases) {
			caseIds.add(c.Id);
		}

		// assert the slice function index 0
		List<Id> sliceIds = new List<Id>(StatusTrackingRollupDelegator.slice(caseIds, 0, 1));
		System.assertEquals(caseIds[0], sliceIds[0]);

		// assert the slice function index 0, 1
		sliceIds = new List<Id>(StatusTrackingRollupDelegator.slice(caseIds, 0, 2));
		System.assertEquals(caseIds[0], sliceIds[0]);
		System.assertEquals(caseIds[1], sliceIds[1]);

	}

	/*****************************************************
	 * SCENARIO:
	 *
	 *  Testing the Delegator Scheduler functionality
	 *****************************************************/
	public static testMethod void testBatchCaseDelegatorScheduler() {
		// set the status tracking config
		RollupCalculationConfig__c config = new RollupCalculationConfig__c(StatusTrackingConcurrentBatches__c = 1, StatusTrackingMaxRecordSelection__c = 1, StatusTrackingCaseBatchSize__c = 100);
		insert config;

		List<Case> cases = new List<Case>{
			TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery'),
			TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery'),
			TestDataProvider.createCase('my subject', 'mydescription', 'SSSWDelivery')
		};

		// this will also create some Status Tracking records...
		// these will not have any calculable values for rollups though.
		insert cases;

		Test.startTest();
		StatusTrackingRollup_Schedulable schedule = new StatusTrackingRollup_Schedulable();
		schedule.execute(null);
		Test.stopTest();
	}

}