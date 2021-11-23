/**************************************************
Description:       Handles the rollup summary batchable for StatusTracking to Case rollups
					This is instantiated from the StatusTrackingRollupDelegator class which passes in case Ids to calculate a rollup for.
History:
--------------------------------------------------
2017-12-18  nathan.franklin@auspost.com.au  Created
2018-11-08	dilshan.egodawela@auspost.com.au	Removed reference to preventTransactionalTriggerExecution on CaseTriggerHandler
**************************************************/
global without sharing class StatusTrackingRollup_Batchable implements Database.Batchable<sObject>, Database.Stateful {

	private static final Set<String> EFFECTIVE_DURATION_STATUS_EXCLUSIONS = new Set<String>{'On Hold', 'Awaiting Customer Reply', 'New', 'Closed'};
	private static final Set<String> DURATION_STATUS_EXCLUSIONS = new Set<String>{'Awaiting Information', 'Closed'};

	/**
	 * Only used when running tests, this will simulate a case error and cause a log to occur.
	 */
	@TestVisible
	private Boolean forceTestFailure = false;

	@TestVisible
	private Id forceTestFailureId;

	/**
	 * Passed from the Delegator batch to handle the rollup summary calculations for these Case Ids
	 */
	private Set<Id> updateableIds = new Set<Id>();

	/**
	 * Stores a list of errors that occur during the execution of the rollup calculations
	 * This is used to store the record id to retry again on next run.
	 */
	private Map<Id, String> caseErrors = new Map<Id, String>();

	/**
	 * whenever a case rollup fails to complete, we store the ID in the RollupCalculationFailureLog__c
	 * these ID's will be reselected out each time the rollup batch runs until it successfully runs.
	 */
	private Set<String> newRollupLogFailures = new Set<String>();

	/**
	 * Stores a list of Id's that were successfully updated
	 * This is used to compare against any items that currently exist in the RollupCalculationFailureLog__c in the finish method
	 */
	private Set<String> processedUpdates = new Set<String>();



	/**
	 * @param updateableIds Specifies the case id's to calculate rollup summaries for.
	 */
	global StatusTrackingRollup_Batchable(Set<Id> updateableIds) {
		this.updateableIds = updateableIds;
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		System.Debug('>> StatusTrackingRollup_Batchable:start');
		System.Debug('>> Processing cases: ' + updateableIds);

		String query = 'Select Id, StatusTrackingDurationRollup__c, StatusTrackingCountRollup__c, EffectiveCaseDurationRollup__c, ' +
						'   (Select Id, Duration__c, DurationMins__c, StatusValue__c From Status_Tracking__r) ' +
						'From Case ' +
						'Where Id In :updateableIds';
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		try {
			List<Case> updates = new List<Case>();

			for(sObject obj : scope) {
				Case c = (Case)obj;

				// final check to ensure status tracking records exist
				if(c.Status_Tracking__r == null)
					continue;

				System.Debug('Processing Rollups for: ' + c.Id);

				Decimal caseDuration = 0;
				Decimal effectiveDuration = 0;
				Integer trackingCount = 0;

				List<StatusTracking__c> caseStatusTrackings = c.Status_Tracking__r;
				if(caseStatusTrackings != null) {
					for (StatusTracking__c tracking : caseStatusTrackings) {
						// count the status tracking records.
						trackingCount++;

						// calculate the overall case duration
						if (!DURATION_STATUS_EXCLUSIONS.contains(tracking.StatusValue__c) && tracking.Duration__c != null) {
							caseDuration += tracking.Duration__c;
						}

						// calculate the effective case duration
						if (!EFFECTIVE_DURATION_STATUS_EXCLUSIONS.contains(tracking.StatusValue__c) && tracking.DurationMins__c != null) {
							effectiveDuration += tracking.DurationMins__c;
						}
					}

					// Bypass_Data_enforcement__c should stop all validation rules from running and will hopefully allow the update to proceed.
					Case caseUpdate = new Case(Id = c.Id, Bypass_Data_enforcement__c = true, StatusTrackingDurationRollup__c = caseDuration, StatusTrackingCountRollup__c = trackingCount, EffectiveCaseDurationRollup__c = effectiveDuration, StatusTrackingRollupsLastRun__c = DateTime.now());

					//a little bit dodgy but I want to simulate a test failure
					// force a failure by using a variable
					if (Test.isRunningTest() && forceTestFailure && forceTestFailureId == c.Id) {
						// causes a validation rule to fire to set the Resolution Code which will cause the case the fail to update when the rollups are updated
						caseUpdate.Status = 'Closed';
						caseUpdate.Type = 'Phone';
						caseUpdate.Bypass_Data_enforcement__c = false;
					}

					updates.add(caseUpdate);
				}
			}

			// getId() only returns a value when the record was successfully processed
			// use an index to get the position of the original record
			Integer index = 0;

			// Disable the case trigger execution
			// this will increase performance of the update and prevent any unnecessary processing.
			//removed by dilshan.egodawela@auspost.com.au  8/11/2018
            //CaseTriggerHandler.preventTransactionalTriggerExecution = true;

			System.Debug('>> Updating Rollup Summaries: ' + updates);
			Database.SaveResult[] results = Database.update(updates, false);
			for(Database.SaveResult result : results) {
				if(!result.isSuccess()) {
					System.Debug('>> Failed to successfully update case rollups. ' + result.getErrors());

					String error = '';
					for(Database.Error err : result.getErrors()) {
						error += err.getMessage() + '\n';
					}
					caseErrors.put(updates[index].Id, error);

					// store a reference to the ID that failed to be updated
					// this will store a record in the RollupCalculationFailureLog__c table if it doesn't already exist
					// these records will be picked up on next run to try and be reprocessed.
					newRollupLogFailures.add(updates[index].Id);
				} else {
					// store the id's of the record that were successfully updated
					// these are used to compare against any records in the RollupCalculationFailureLog__c table.
					processedUpdates.add(updates[index].Id);
				}

				index++;
			}
		} catch(Exception exp) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'SSSW', 'StatusTrackingRollup_Batchable', 'execute', null, LoggingLevel.ERROR);
		}

	}

	global void finish(Database.BatchableContext BC) {
		System.Debug('>> StatusTrackingRollup_Batchable:finish');

		resetFailuresLog();

		System.Debug('>> Case Errors: ' + caseErrors);
		if(!caseErrors.isEmpty()) {
			UTIL_LoggingService.logHandledException(new BatchableException(String.valueOf(caseErrors)), UserInfo.getOrganizationId(), 'SSSW', 'StatusTrackingRollup_Batchable', 'finish', null, LoggingLevel.ERROR);
		}

	}

	/**
	 * Out of all record updated in this batch, check which ones were in the failure log which can now be removed.
	 * This will also add any new ids that have failed to be processed.
	 * RollupCalculationFailureLog__c table.
	 */
	private void resetFailuresLog() {

		// grab a list of any id's that existed in the failure log which have now been successfully updated and remove them
		List<RollupCalculationFailureLog__c> rollupsToRemove = [Select Id From RollupCalculationFailureLog__c Where RecordId__c in :processedUpdates];
		if(!rollupsToRemove.isEmpty()) {
			delete rollupsToRemove;
		}

		// any record that failed to update in this batch are logged to be retried next time.
		List<RollupCalculationFailureLog__c> logUpserts = new List<RollupCalculationFailureLog__c>();
		for(String newRollupLogFailureId : newRollupLogFailures) {
			logUpserts.add(new RollupCalculationFailureLog__c(RecordId__c = newRollupLogFailureId));
		}
		if(!logUpserts.isEmpty()) {
			upsert logUpserts RecordId__c;
		}
	}


	public class BatchableException extends Exception {}
}