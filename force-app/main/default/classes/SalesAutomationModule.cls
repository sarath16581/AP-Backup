/**
 * @description
 * Domain Module to handle sales automation functionality
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Harry Wang
 * @group Domain
 * @domain Sales
 * @Test SalesAutomationModule_Test
 * @changelog
 * 2022-11-04 - Harry Wang - Created.
 * 2023-01-25 - Ranjeewa Silva - Refactored to enhance performance and readability / code structure
 */
public inherited sharing class SalesAutomationModule extends ApplicationDomain.Module {

	// cache key setting names for accessing platform cache
	private static final String CACHE_KEY_SALESTEAMTYPE_MAPPINGS = 'SALES_SALESTEAMTYPE_MAPPINGS';

	// accounts already enqueued in current transaction. any sales team type updates are performed by a queueable job
	// when this module is called from a synchronous context.
	@TestVisible private static Set<Id> enqueuedSalesTeamTypeUpdates = new Set<Id>();

	@TestVisible private static Map<String, List<String>> salesTeamTypeMappings {
		get {
			if (salesTeamTypeMappings == null) {
				// check in platform cache first
				if (CacheManager.get(CACHE_KEY_SALESTEAMTYPE_MAPPINGS) != null) {
					// use sales team mappings available in platform cache.
					salesTeamTypeMappings = (Map<String, List<String>>) CacheManager.get(CACHE_KEY_SALESTEAMTYPE_MAPPINGS);
				} else {
					// sales team mappings are not available in platform cache. need to be queried.
					Map<String, List<String>> mapping = AP_FieldDescribeUtil.getDependentPicklistValues(Account.SalesTeamType__c, Account.Sales_Segment__c);
					salesTeamTypeMappings = mapping;
					// also populate platform cache so it is available later
					CacheManager.put(CACHE_KEY_SALESTEAMTYPE_MAPPINGS, mapping);
				}
			}
			return salesTeamTypeMappings;
		}
		set;
	}

	// only for use in unit tests to mock execution in an async context
	@TestVisible private static Boolean mockAsyncContextInTests = false;

	// only for use in unit tests to mock the scenario of reaching queueable apex limit
	@TestVisible private static Boolean mockQueueableLimitReachedInTests = false;

	public static SalesAutomationModule newInstance() {
		return (SalesAutomationModule)Application.Utilities.newInstance(SalesAutomationModule.class);
	}

	// Setup which trigger events this module should respond to
	public SalesAutomationModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			populateSalesTeamType((List<Account>)records, false);
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales', SalesAutomationModule.class.getName(), 'onBeforeInsert', 'AccountTriggerClass', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			List<Account> accountsToPopulateSalesTeamType = new List<Account>();
			for (Account record: (List<Account>)records) {
				Account existingRecord = (Account) existingRecords.get(record.Id);
				if (record.Sales_Segment__c != existingRecord.Sales_Segment__c && !enqueuedSalesTeamTypeUpdates.contains(record.Id)) {
					accountsToPopulateSalesTeamType.add(record);
				}
			}

			if (!accountsToPopulateSalesTeamType.isEmpty()) {
				// populate sales tem type. if SalesTeamType__c is updated, it triggers standard sharing rule recalculations
				// on the account. if there are large number of cases / opportunities / contacts linked to an account
				// standard criteria based sharing rules could take quite a long time to complete.
				// attempt to do this asynchronously to avoid contributing to synchronous long running transactions limit on the org.
				populateSalesTeamType(accountsToPopulateSalesTeamType, true);
			}
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales', SalesAutomationModule.class.getName(), 'onBeforeUpdate', 'AccountTriggerClass', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	private void populateSalesTeamType(List<Account> records, Boolean asyncProcessing) {
		Map<String, List<Id>> excludedRecords = new Map<String, List<Id>>();
		Map<Id, String> recordsForAsyncProcessing = new Map<Id, String>();

		// if 'asyncProcessing' is 'false', set SalesTeamType__c directly on the records passed in.
		// if 'asyncProcessing' is 'true' and we are already in an async context, set SalesTeamType__c directly on the records passed in.
		// if 'asyncProcessing' is 'true' and not already in an async context, check if it is possible to enqueue additional queueable jobs.
		// if current governor limit allows enqueue an additional queueable job to set SalesTeamType__c on account records asynchronously.
		// if per-transaction queueable job allocation has been exhausted attempt to process synchronously in current transaction.
		Boolean enqueueForAsyncProcessing = (asyncProcessing && !isInAsyncContext() && canEnqueueQueueableJobs());

		for (Account record: records) {
			// Sales_Segment__c is being updated. get the new sales team type for the new Sales_Segment__c value
			String salesTeamType = getSalesTeamType(record);
			// compare with the current SalesTeamType__c set on the record.
			if (record.SalesTeamType__c != salesTeamType) {
				if (enqueueForAsyncProcessing) {
					// add to the list to be processed asynchronously
					recordsForAsyncProcessing.put(record.Id, salesTeamType);
				} else {
					// set directly on the record
					record.SalesTeamType__c = salesTeamType;
				}
			}

			if (salesTeamType == null && record.Sales_Segment__c != null) {
				// cannot derive SalesTeamType__c for a valid Sales_Segment__c. this indicates dependent
				// picklist values are not configured properly for Sales_Segment__c (controlling) --> SalesTeamType__c (dependent.
				// could be either one of:
				// 1. Sales_Segment__c on the account does not have a valid dependent picklist value configured for SalesTeamType__c.
				// 2. Sales_Segment__c on the account is mapped to multiple dependent picklist values for SalesTeamType__c.
				// log to exception log as this indicates the configuration is invalid.
				// Note that the record is updated with SalesTeamType__c set to null.
				if (!excludedRecords.containsKey(record.Sales_Segment__c)) {
					excludedRecords.put(record.Sales_Segment__c, new List<Id>());
				}
				excludedRecords.get(record.Sales_Segment__c).add(record.Id);
			}
		}

		if (!excludedRecords.isEmpty()) {
			logExcludedRecords(excludedRecords);
		}

		if (!recordsForAsyncProcessing.isEmpty()) {
			enqueueSalesTeamTypeUpdates(recordsForAsyncProcessing);
		}
	}

	private String getSalesTeamType(Account record) {
		if (record.Sales_Segment__c != null && salesTeamTypeMappings.containsKey(record.Sales_Segment__c)
				&& salesTeamTypeMappings.get(record.Sales_Segment__c).size() == 1) {
			return salesTeamTypeMappings.get(record.Sales_Segment__c)[0];
		} else {
			// cannot find a valid sales team type. this could be due to 3 reasons:
			// 1. Sales_Segment__c is not set on the account
			// 2. Sales_Segment__c on the account does not have a valid dependent picklist value configured for SalesTeamType__c.
			// 3. Sales_Segment__c on the account is mapped to multiple dependent picklist values for SalesTeamType__c.
			return null;
		}
	}

	/**
	 * Generate log entries from the excluded records collected while processing.
	 *
	 * @param excludedRecordsBySalesTeam excluded records to generate log entries.
	 */
	private void logExcludedRecords(Map<String, List<Id>> excludedRecordsBySalesTeam) {

		List<String> messages = new List<String>();
		List<String> additionalInfo = new List<String>();

		for (String salesTeam: excludedRecordsBySalesTeam.keySet()) {
			List<Id> ignoredRecordIds = excludedRecordsBySalesTeam.get(salesTeam);
			messages.add('Sales Team Type cannot be determined for Sales Team [' + salesTeam + '] from dependent picklist configuration in ' + Account.SalesTeamType__c + '. Ignoring [' + ignoredRecordIds.size() + '] accounts.');
			additionalInfo.add('Ignored accounts : ' + ignoredRecordIds.toString());
		}

		ApplicationLogger.getInstance().logMessage(messages, additionalInfo, 'Sales', SalesAutomationModule.class.getName(), 'populateSalesTeamType', 'AccountTriggerClass', ApplicationLogger.LoggingLevel.ERROR);
	}

	private static Boolean isInAsyncContext() {
		return (Test.isRunningTest() ? mockAsyncContextInTests 	: (System.isScheduled() || System.isBatch() || System.isQueueable() || System.isFuture()));
	}

	private static Boolean canEnqueueQueueableJobs() {
		return (Test.isRunningTest() ? !mockQueueableLimitReachedInTests : (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()));
	}

	private void enqueueSalesTeamTypeUpdates(Map<Id, String> asyncSalesTeamTypeUpdates) {

		if (!enqueuedSalesTeamTypeUpdates.isEmpty()) {
			asyncSalesTeamTypeUpdates.keySet().removeAll(enqueuedSalesTeamTypeUpdates);
		}

		// there are account sales team updates to be enqueued
		if (!asyncSalesTeamTypeUpdates.isEmpty()) {
			ApplicationDatabase.getInstance().enqueueJob(new AsyncUpdateSalesTeamTypeQueueable(asyncSalesTeamTypeUpdates));
			// capture enqueued updates to prevent enqueueing same accounts again in current transaction.
			enqueuedSalesTeamTypeUpdates.addAll(asyncSalesTeamTypeUpdates.keySet());
		}
	}

	@TestVisible private without sharing class AsyncUpdateSalesTeamTypeQueueable implements Queueable {

		@TestVisible private Map<Id, String> accountSalesTeamTypeUpdates = new Map<Id, String>();

		@TestVisible private AsyncUpdateSalesTeamTypeQueueable(Map<Id, String> accountSalesTemTypeUpdates) {
			this.accountSalesTeamTypeUpdates = accountSalesTemTypeUpdates;
		}

		public void execute(QueueableContext ctx) {
			List<Account> updatableAccounts = new List<Account>();
			for (Id accountId: accountSalesTeamTypeUpdates.keySet()) {
				updatableAccounts.add(new Account(Id=accountId, SalesTeamType__c= accountSalesTeamTypeUpdates.get(accountId)));
			}
			if (!updatableAccounts.isEmpty()) {
				List<Database.SaveResult> saveResults = ApplicationDatabase.getInstance().dmlUpdate(updatableAccounts, false);
				ApplicationLogger.getInstance().logFailedDatabaseResults(saveResults, 'Sales', SalesAutomationModule.AsyncUpdateSalesTeamTypeQueueable.class.getName(), 'execute', '', ApplicationLogger.LoggingLevel.ERROR);
			}
		}
	}
}