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

	@TestVisible private static Map<String, List<String>> salesTeamTypeMappings {
		get {
			if (salesTeamTypeMappings == null) {
				// TODO cache the mappings in platform cache to improve performance
				Map<String, List<String>> mapping = AP_FieldDescribeUtil.getDependentPicklistValues(Account.SalesTeamType__c, Account.Sales_Segment__c);
				salesTeamTypeMappings = mapping;
			}
			return salesTeamTypeMappings;
		}
		set;
	}

	public static SalesAutomationModule newInstance() {
		return (SalesAutomationModule)Application.Utilities.newInstance(SalesAutomationModule.class);
	}

	// Setup which trigger events this module should respond to
	public SalesAutomationModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			populateSalesTeamType((List<Account>)records);
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'AP Sales', SalesAutomationModule.class.getName(), 'onBeforeInsert', 'AccountTriggerClass', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			List<Account> accountsToPopulateSalesTeamType = new List<Account>();
			for (Account record: (List<Account>)records) {
				Account existingRecord = (Account) existingRecords.get(record.Id);
				if (record.Sales_Segment__c != existingRecord.Sales_Segment__c) {
					accountsToPopulateSalesTeamType.add(record);
				}
			}

			if (!accountsToPopulateSalesTeamType.isEmpty()) {
				populateSalesTeamType(accountsToPopulateSalesTeamType);
			}
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'AP Sales', SalesAutomationModule.class.getName(), 'onBeforeUpdate', 'AccountTriggerClass', ApplicationLogger.LoggingLevel.ERROR);
		}
	}


	private void populateSalesTeamType(List<Account> records) {

		Map<String, List<Id>> excludedRecords = new Map<String, List<Id>>();
		for (Account record: records) {
			if (record.Sales_Segment__c != null && salesTeamTypeMappings.containsKey(record.Sales_Segment__c)
					&& salesTeamTypeMappings.get(record.Sales_Segment__c).size() == 1) {
				// found a valid Sales Team type
				record.SalesTeamType__c = salesTeamTypeMappings.get(record.Sales_Segment__c)[0];
			} else {
				// cannot find a valid sales team type. this could be due to 3 reasons:
				// 1. Sales_Segment__c is not set on the account
				// 2. Sales_Segment__c on the account does not have a valid dependent picklist value configured for SalesTeamType__c.
				// 3. Sales_Segment__c on the account is mapped to multiple dependent picklist values for SalesTeamType__c.
				// set to null and proceed.
				record.SalesTeamType__c = null;

				// if this is scenario (2) or (3) above, log to exception log as this indicates the configuration is invalid.
				// Note that the record is allowed to be saved with SalesTeamType__c set to null.
				if (record.Sales_Segment__c != null) {
					if (!excludedRecords.containsKey(record.Sales_Segment__c)) {
						excludedRecords.put(record.Sales_Segment__c, new List<Id>());
					}
					excludedRecords.get(record.Sales_Segment__c).add(record.Id);
				}
			}
		}

		if (!excludedRecords.isEmpty()) {
			logExcludedRecords(excludedRecords);
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

		ApplicationLogger.getInstance().logMessage(messages, additionalInfo, 'AP Sales', SalesAutomationModule.class.getName(), 'populateSalesTeamType', 'AccountTriggerClass', ApplicationLogger.LoggingLevel.ERROR);
	}
}