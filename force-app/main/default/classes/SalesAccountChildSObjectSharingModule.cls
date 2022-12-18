/**
 * @description
 * Domain Module to handle sharing of related objects with sales team members when parent account is moving sales channels
 * (e.g. SalesTeamType__c is changing from 'Holding' to 'Intermediary').
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Ranjeewa Silva
 * @date 2022-12-15
 * @group Domain
 * @domain Sales
 * @changelog
 * 2022-12-15 - Ranjeewa Silva - Created.
 */
public inherited sharing class SalesAccountChildSObjectSharingModule  extends ApplicationDomain.Module {

	// account ids already enqueued in current transactions
	private static Set<Id> enqueuedAccountIds = new Set<Id>();

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
			shareChildRecords(sharingScope.keySet(), uow);
		}
	}

	/**
	 * Share child records of the parent account ids passed in.
	 * @param accountIds parent account ids
	 * @param uow unit of work instance
	 */
	private void shareChildRecords(Set<Id> accountIds, ApplicationUnitOfWork uow) {

		if (enqueuedAccountIds.containsAll(accountIds)) {
			// accounts already enqueued in current transaction. nothing to do.
			return;
		}

		// we have accounts that need to be processed. remove accounts already enqueued previously in current transaction.
		Set<Id> accountIdsForProcessing = accountIds.clone();
		accountIdsForProcessing.removeAll(enqueuedAccountIds);

		if (System.isScheduled() || System.isBatch() || System.isQueueable() || System.isFuture()) {
			// we are in an async context. attempt to process synchronously by directly calling the service.
			// depending on volume, we might not be able to process all the accounts synchrnously.
			List<SalesRecordSharingService.AccountChildRecordsSharingRecalculationResult> results = SalesRecordSharingService.getInstance().recalculateChildRecordSharing(accountIdsForProcessing, uow);
			// process results and handle any unprocessed accounts.
			handleUnprocessedAccounts(results);
		} else {
			// we are in a synchronous context. enqueue a queueable to handle sharing.
			SalesRecordSharingService.getInstance().enqueueChildRecordsSharingHandlerQueueable(accountIdsForProcessing);
			// capture enqueued account ids to prevent enqueueing same accounts again in current transaction.
			enqueuedAccountIds.addAll(accountIdsForProcessing);
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
			}
		}

		if (!unprocessedAccountIds.isEmpty()) {
			// there are unprocessed accounts
			if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
				// current usage of queueable jobs allows enqueueing an additional Queueable.
				SalesRecordSharingService.getInstance().enqueueChildRecordsSharingHandlerQueueable(unprocessedAccountIds);
			} else {
				// current usage of queueable jobs does not allow enqueueing an additional Queueable.
				// in the rare case of reaching this we have to ignore the records and generate an error log.
				String message = 'Maximum number of queueable jobs enqueued in current transaction ['+Limits.getQueueableJobs()+']. Ignoring child record sharing recalculation for parent accounts.';
				String additionalInfo = 'Ignored Account Ids [' + unprocessedAccountIds + '].';
				ApplicationLogger.getInstance().logMessage(new List<String>{message}, new List<String>{additionalInfo},'Sales',
						SalesAccountChildSObjectSharingModule.class.getName(), 'onAfterUpdate','AccountTrigger', ApplicationLogger.LoggingLevel.ERROR);
			}
		}
	}
}