/**
 * @description
 * Domain Module to handle sharing of related objects with sales team members when parent account is moving sales channels
 * (e.g. SalesTeamType__c is changing from 'Holding' to 'Intermediary').
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Ranjeewa Silva
 * @date 2022-12-15
 * @group Domain
 * @domain Sales
 * @test SalesAccChildSObjectSharingModule_Test
 * @changelog
 * 2022-12-15 - Ranjeewa Silva - Created.
 */
public inherited sharing class SalesAccountChildSObjectSharingModule  extends ApplicationDomain.Module {

	// account ids already enqueued in current transaction. sharing recalculation is performed by a queueable job
	// when this module is called from a synchronous context.
	@TestVisible private static Set<Id> enqueuedAccountIds = new Set<Id>();

	// account ids processed synchronously in current transaction. sharing recalculation is performed synchronously only
	// if this module is executed from an async context.
	@TestVisible private static Map<Id, String> accountIdsProcessedInCurrentTransaction = new Map<Id, String>();

	// only for use in unit tests to mock execution in an async context
	@TestVisible private static Boolean mockAsyncContextInTests = false;

	// only for use in unit tests to mock the scenario of reaching queueable apex limit
	@TestVisible private static Boolean mockQueueableLimitReachedInTests = false;

	public static SalesAccountChildSObjectSharingModule newInstance() {
		return (SalesAccountChildSObjectSharingModule)Application.Utilities.newInstance(SalesAccountChildSObjectSharingModule.class);
	}

	// Setup which trigger events this module should respond to
	public SalesAccountChildSObjectSharingModule() {
		getTriggerEvents().enableAfterUpdate();
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		// get accounts where SalesTeamType__c is changing.
		Map<Id, Set<SObjectField>> sharingScope = getIsChanged(records, existingRecords, new Set<SObjectField>{Account.SalesTeamType__c});
		if (!sharingScope.isEmpty()) {
			shareChildRecords(sharingScope.keySet(), (List<Account>)records, uow);
		}
	}

	/**
	 * Share child records of the parent account ids passed in.
	 * @param accountIds parent account ids
	 * @param records account records going through dml operation
	 * @param uow unit of work instance
	 */
	private void shareChildRecords(Set<Id> accountIds, List<Account> records, ApplicationUnitOfWork uow) {

		// check if account ids have already been processed or enqueued in the current transaction. filter them out
		// from the sharing scope.
		Set<Id> processableAccountIds = filterAccountsAlreadyProcessedOrEnqueued(accountIds, new Map<Id, Account>(records));

		if (processableAccountIds.isEmpty()) {
			// account ids in scope have all been either processed or enqueued previously in current transaction.
			// return as there is nothing more to do here.
			return;
		}

		if (isInAsyncContext()) {
			// we are in an async context. attempt to process synchronously by directly calling the service.
			// depending on volume, we might not be able to process all the accounts synchronously.
			List<SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult> results = SalesRecordSharingService.getInstance().recalculateChildRecordSharing(processableAccountIds, uow);
			// process results and handle any unprocessed accounts.
			handleUnprocessedAccounts(results);
		} else {
			// we are in a synchronous context. enqueue a queueable to handle sharing.
			enqueueAccountIdsForAsyncProcessing(processableAccountIds);
		}
	}

	/**
	 * Process results of sharing recalculation attempt if already in an async context. If there are any unprocessed
	 * accounts based on the results, attempt to process them asynchronously via enqueueing a queueable. If queueable apex
	 * limit has already been reached in the current transaction, an 'Error' log entry is generated and parent accounts
	 * are ignored.
	 *
	 * @param results Results returned by SalesRecordSharingService.recalculateChildRecordSharing
	 */
	private void handleUnprocessedAccounts(List<SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult> results) {
		Set<Id> unprocessedAccountIds = new Set<Id>();
		for (SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult result: results) {
			if (!result.processed) {
				unprocessedAccountIds.add(result.accountId);
			} else {
				accountIdsProcessedInCurrentTransaction.put(result.accountId, result.salesTeamType);
			}
		}

		if (!unprocessedAccountIds.isEmpty()) {
			enqueueAccountIdsForAsyncProcessing(unprocessedAccountIds);
		}
	}

	private void enqueueAccountIdsForAsyncProcessing(Set<Id> accountIds) {
		// there are unprocessed accounts
		if (canEnqueueQueueableJobs()) {
			// current usage of queueable jobs allows enqueueing an additional Queueable.
			SalesRecordSharingService.getInstance().enqueueChildRecordsSharingHandlerQueueable(accountIds);
			// capture enqueued account ids to prevent enqueueing same accounts again in current transaction.
			enqueuedAccountIds.addAll(accountIds);
		} else {
			// current usage of queueable jobs does not allow enqueueing an additional Queueable.
			// in the rare case of reaching this we have to ignore the records and generate an error log.
			String message = 'Maximum number of queueable jobs enqueued in current transaction ['+Limits.getQueueableJobs()+']. Ignoring child record sharing recalculation for parent accounts.';
			String additionalInfo = 'Ignored Account Ids [' + accountIds + '].';
			ApplicationLogger.getInstance().logMessage(new List<String>{message}, new List<String>{additionalInfo},'Sales',
					SalesAccountChildSObjectSharingModule.class.getName(), 'onAfterUpdate','AccountTrigger', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	private static Boolean isInAsyncContext() {
		return (Test.isRunningTest() ? mockAsyncContextInTests 	: (System.isScheduled() || System.isBatch() || System.isQueueable() || System.isFuture()));
	}

	private static Boolean canEnqueueQueueableJobs() {
		return (Test.isRunningTest() ? !mockQueueableLimitReachedInTests : (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()));
	}

	private static Set<Id> filterAccountsAlreadyProcessedOrEnqueued(Set<Id> accountIds, Map<Id, Account> records) {
		Set<Id> processableAccountIds = accountIds.clone();

		// check if there are any accounts already enqueued for processing in current transaction
		if (!enqueuedAccountIds.isEmpty()) {
			// accounts already enqueued for processing is not required to be processed again. remove them from the set
			// of processable account ids.
			processableAccountIds.removeAll(enqueuedAccountIds);
		}

		// check if there are any more account ids to be processed and if any of those accounts have already been
		// processed (not enqueued) in current transaction. if so, we need to check if 'SalesTeamType__c' has changed
		// on those accounts compared to the 'SalesTeamType__c' set when it was last processed. if 'SalesTeamType__c' hasn't
		// changed on the account since it was last processed we can safely ignore such accounts.
		// this is to ensure we handle recursive updates to the record after the sharing recalculation has been last
		// performed by the trigger (e.g. processes, workflow field updates).
		if (!processableAccountIds.isEmpty() && !accountIdsProcessedInCurrentTransaction.isEmpty()) {
			for (Id processedAccountId: accountIdsProcessedInCurrentTransaction.keySet()) {
				if (processableAccountIds.contains(processedAccountId)
						&& accountIdsProcessedInCurrentTransaction.get(processedAccountId) == records.get(processedAccountId).SalesTeamType__c) {
					// sales team type hasn't change on the account. remove from processable account ids set.
					processableAccountIds.remove(processedAccountId);
				}
			}
		}

		return processableAccountIds;
	}
}