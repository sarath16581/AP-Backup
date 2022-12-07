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

	// field override and account relationship passed to selector method
	public Map<SObjectType, Set<SObjectField>> fieldOverride = new Map<SObjectType, Set<SObjectField>>();
	public String accountRelationshipName;

	private Integer totalCount = 0;
	private Integer successCount = 0;

	protected SalesRecordSharingBatchable(SObjectType sObjectType) {
		this.sObjectType = sObjectType;

		try {
			SalesRecordSharingService.SalesSharingObjectMapping mapping = SalesRecordSharingService.getInstance().getSharingConfiguration(this.sObjectType);
			fieldOverride.put(this.sObjectType, new Set<SObjectField>{mapping.lookupField});
			fieldOverride.put(Account.getSObjectType(), new Set<SObjectField>{Account.SalesTeamType__c});
			accountRelationshipName = mapping.lookupRelationshipName;
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales Intermediary', SalesRecordSharingBatchable.class.getName(), 'constructor', 'SalesRecordSharingBatchable: ' + sObjectType, ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	protected abstract Database.QueryLocator getQueryLocator();

	public Database.QueryLocator start(Database.BatchableContext bc) {
		return getQueryLocator();
	}

	public void execute(Database.BatchableContext bc, List<SObject> objectList) {
		try {
			SalesRecordSharingService.getInstance().shareRecords(this.sObjectType, new Map<Id, SObject>(objectList), true);
			successCount += objectList.size();
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales Intermediary', SalesRecordSharingBatchable.class.getName(), 'execute', 'SalesRecordSharingBatchable: ' + sObjectType, ApplicationLogger.LoggingLevel.ERROR);
		} finally {
			totalCount += objectList.size();
		}

	}

	public void finish(Database.BatchableContext bc) {
		// Logging count of success out of total processed
		String message = sObjectType + ' Record Sharing Batch completed with ' + successCount + '/' + totalCount + ' processed.';
		ApplicationLogger.getInstance().logGenericMessage(new List<String>{message}, 'Sales Intermediary', SalesRecordSharingBatchable.class.getName(), 'finish', 'SalesRecordSharingBatchable: ' + sObjectType, ApplicationLogger.LoggingLevel.INFO);
	}

}