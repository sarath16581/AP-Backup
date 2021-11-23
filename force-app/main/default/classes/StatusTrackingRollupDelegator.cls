/**************************************************
Description:       Orchestrates the batch updates for the Status Tracking Rollups to case.
					This was a necessary step since the time to update Cases is very slow
					This will simulate a 'Bulk API' operation without using Bulk API and still allow for custom business logic.
History:
--------------------------------------------------
2017-12-18  nathan.franklin@auspost.com.au  Created
**************************************************/
global without sharing class StatusTrackingRollupDelegator implements Database.Batchable<sObject>, Database.Stateful {

	private DateTime startTime;

	private static Integer MINIMUM_RECORDS_PER_BATCH = 50;


	// config
    private Integer MAX_STATUS_TRACKING_COUNT;
	private Integer MAX_BATCH_COUNT;
	private Integer BATCH_SIZE;

	/**
	 * Stores a list of all the case Ids where Status Tracking rollups should be recalculated.
	 * In the finish method, these case Ids will be divided into a number of batch jobs and executed simultaneously
	 */
	private Set<Id> allCaseIds = new Set<Id>();

    //instantiate config variables
    global StatusTrackingRollupDelegator(){
        RollupCalculationConfig__c config = RollupCalculationConfig__c.getOrgDefaults();
        this.MAX_STATUS_TRACKING_COUNT = Integer.valueOf(config.StatusTrackingMaxRecordSelection__c);
		this.MAX_BATCH_COUNT = Integer.valueOf(config.StatusTrackingConcurrentBatches__c);
		this.BATCH_SIZE = Integer.valueOf(config.StatusTrackingCaseBatchSize__c);
    }
	/**
	 * Just used to assert in test class.
	 */
	@TestVisible
	private Static List<List<Id>> batchIds = new List<List<Id>>();

	global Database.QueryLocator start(Database.BatchableContext BC) {
		System.Debug('>> StatusTrackingRollupDelegator:start');

		// grab all the configuration for status tracking rollups
		RollupCalculationConfig__c config = RollupCalculationConfig__c.getOrgDefaults();

		if(config == null || config.StatusTrackingConcurrentBatches__c == null ||
				config.StatusTrackingMaxRecordSelection__c == null || config.StatusTrackingCaseBatchSize__c == null ||
				config.StatusTrackingConcurrentBatches__c > 5 ||
				config.StatusTrackingConcurrentBatches__c <= 0 ||
				config.StatusTrackingMaxRecordSelection__c > 2000000 ||
				config.StatusTrackingMaxRecordSelection__c <= 0 ||
				config.StatusTrackingCaseBatchSize__c > 200 ||
				config.StatusTrackingCaseBatchSize__c <= 0) {
			throw new RollupInvalidConfigException('The configuration is invalid. Please see help on Custom Settings page.');
		}

		MAX_STATUS_TRACKING_COUNT = Integer.valueOf(config.StatusTrackingMaxRecordSelection__c);
		MAX_BATCH_COUNT = Integer.valueOf(config.StatusTrackingConcurrentBatches__c);
		BATCH_SIZE = Integer.valueOf(config.StatusTrackingCaseBatchSize__c);
        
        System.Debug('>> MAX_BATCH_COUNT: ' + MAX_BATCH_COUNT);
        System.Debug('>> MAX_STATUS_TRACKING_COUNT: ' + MAX_STATUS_TRACKING_COUNT);
        System.Debug('>> BATCH_SIZE: ' + BATCH_SIZE);

		// since StatusTracking is a very large table, we are opting for a select all approach and sift through the extracted data in the execute since the original query all was timing out
		// the execute will grab all the applicable cases that require rolling up
		String query = 'Select Id From StatusTracking__c Order By Id Desc LIMIT :MAX_STATUS_TRACKING_COUNT ';
		return Database.getQueryLocator(query);
	}

	/**
	 * Build a list of case ids to be dished out to a small number of batch jobs
	 */
	global void execute(Database.BatchableContext BC, List<sObject> scope) {

		Set<Id> statusTrackingIds = new Set<Id>();
		for(sObject record : scope) {
			statusTrackingIds.add(record.Id);
		}

		Long t1 = DateTime.now().getTime();

		// Grab only the cases that require updating
		// This will retrieve only the cases where the last time a rollup is completed is less than the modified date on the status tracking record

		List<AggregateResult> results = [Select Case__c From StatusTracking__c
											Where Id in :statusTrackingIds
											And FormulaModifiedAfterRollupCalculation__c = true
											Group By Case__c
											Order By Case__c Desc];
//		// ------------------------------------------ TESTING ONLY ------------------------------------------
//		List<AggregateResult> results = [Select Case__c From StatusTracking__c
//											Where Id in :statusTrackingIds
//											And FormulaModifiedAfterRollupCalculation__c = true
//											And Case__r.IsClosed = true
//											And Case__r.IsStopped = true
//											Group By Case__c
//											Order By Case__c Desc];
//		// ------------------------------------------ TESTING ONLY ------------------------------------------

		Long t2 = DateTime.now().getTime();

		System.Debug('Searching for Cases >> Running Time: ' + (t2 - t1));
		System.Debug('>> Cases Found: ' + results.size());

		for(AggregateResult result : results) {
			allCaseIds.add((Id)result.get('Case__c'));
		}

	}

	global void finish(Database.BatchableContext BC) {
		System.Debug('>> StatusTrackingRollupDelegator:finish');
		// grab the failed rollups from the last attempt at running the rollup batch
		// limit to 2000 to leave room for other queries to run
		// any additional records will be processed the next time the batch is run
		// these are cleared in the StatusTrackingRollup_Schedulable after they have been successfully updated.
		List<RollupCalculationFailureLog__c> rollupLogs = [Select Id, RecordId__c From RollupCalculationFailureLog__c LIMIT 2000];
		for(RollupCalculationFailureLog__c log : rollupLogs) {
			try {
				allCaseIds.add((Id)log.RecordId__c);
			} catch(Exception ex) { }
		}

		System.Debug('>> ALL CASES FOUND: ' + allCaseIds.size());
		System.Debug('>> MAX_BATCH_COUNT: ' + MAX_BATCH_COUNT);
		// A little hack to get the proper CEIL figure
		Integer recordsPerBatch = Integer.valueOf(Math.ceil(Decimal.valueOf(allCaseIds.size()).divide(MAX_BATCH_COUNT, 1)));

		// if the records are less than minimum we use a single batch
		Integer batchCount = (recordsPerBatch < MINIMUM_RECORDS_PER_BATCH ? 1 : MAX_BATCH_COUNT);
		recordsPerBatch = (recordsPerBatch < MINIMUM_RECORDS_PER_BATCH ? MINIMUM_RECORDS_PER_BATCH : recordsPerBatch);

		System.Debug('>> recordsPerBatch: ' + recordsPerBatch);
		System.Debug('>> batchCount: ' + batchCount);

		for(Integer i = 0; i < batchCount; i++) {
			Set<Id> thisBatch = slice(new List<Id>(allCaseIds), i * recordsPerBatch, recordsPerBatch);
			batchIds.add(new List<Id>(thisBatch));

			if(!Test.isRunningTest()) {
				System.Debug('>> Enqueueing: ' + thisBatch.size());
				System.Debug('>> ' + thisBatch);
				StatusTrackingRollup_Batchable batch = new StatusTrackingRollup_Batchable(thisBatch);
				Database.executeBatch(batch, BATCH_SIZE);
			}
		}
	}

	@TestVisible
	private static Set<Id> slice(List<Id> input, Integer start, Integer length) {
		Set<Id> output = new Set<Id>();
		for (Integer i = start; i < (start + length); i++) {
			if(input.size() > i) {
				output.add(input[i]);
			} else {
				break;
			}
		}
		return output;
	}

	public class RollupInvalidConfigException extends Exception {}
}