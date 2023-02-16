/**
 * @author Harry Wang
 * @date 2022-11-22
 * @group Service
 * @domain Sales
 * @description Abstract batch class for Sales Intermediary
 * @changelog
 * 2022-11-22 - Harry Wang - Created
 */
public abstract class SalesRecordSharingBatchable implements Database.Batchable<SObject>, Database.Stateful{
	protected SObjectType sObjectType;

	protected Set<Id> accountIds;

	@TestVisible private Integer totalRecordsCount = 0;

	protected SalesRecordSharingBatchable(SObjectType sObjectType, Set<Id> accountIds) {
		this.sObjectType = sObjectType;
		this.accountIds = (accountIds != null ? accountIds: new Set<Id>());
	}

	protected abstract Database.QueryLocator getQueryLocator(Map<SObjectType, Set<SObjectField>> fieldOverrides);

	public Database.QueryLocator start(Database.BatchableContext bc) {

		SalesRecordSharingService.SalesSharingObjectMapping mapping = SalesRecordSharingService.getInstance().getSharingConfiguration(this.sObjectType);

		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
			this.sObjectType => new Set<SObjectField>{mapping.lookupField},
			Account.SObjectType => new Set<SObjectField>{Account.SalesTeamType__c}
		};

		return getQueryLocator(fieldOverrides);
	}

	public void execute(Database.BatchableContext bc, List<SObject> objectList) {
		try {
			SalesRecordSharingService.getInstance().shareRecords(this.sObjectType, new Map<Id, SObject>(objectList), true);
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales', SalesRecordSharingBatchable.class.getName(), 'execute', 'SalesRecordSharingBatchable: ' + sObjectType, ApplicationLogger.LoggingLevel.ERROR);
		} finally {
			this.totalRecordsCount += objectList.size();
		}
	}

	public void finish(Database.BatchableContext bc) {
		// Logging count of total processed
		String message = 'Sharing recalculation batch completed. Processed [' + totalRecordsCount +'] ' + sObjectType + ' records.';
		ApplicationLogger.getInstance().logGenericMessage(new List<String>{message}, 'Sales', SalesRecordSharingBatchable.class.getName(), 'finish', '', ApplicationLogger.LoggingLevel.INFO);
	}

}