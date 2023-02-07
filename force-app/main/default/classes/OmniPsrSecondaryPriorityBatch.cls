/**
* @author George Nguyen
* @date 2022-11-06
* @group Batch
* @tag Batch
* @tag Omni SObject
* @description This batch is used to update the Secondary Priority of PendingServiceRouting records that have yet to be pushed. 

* @changelog
* 2022-11-06 - George Nguyen 	Created
* 2023-02-08 - Noel Lim			Updated to use PendingServiceRoutingSelector
*/
public inherited sharing class OmniPsrSecondaryPriorityBatch implements Database.Batchable<sObject>,Schedulable  {
	public final Integer nDaysAgo;
	public final String query;

	public OmniPsrSecondaryPriorityBatch(Integer nDaysAgo) {
		this.nDaysAgo = nDaysAgo;
	}

	public Database.QueryLocator start(Database.BatchableContext BC){
		return (Database.QueryLocator)PendingServiceRoutingSelector.newInstance().selectByLastModifiedDateLessThanEqualNDaysAgo(nDaysAgo, new Set<Object>{PendingServiceRoutingSelector.Options.EXCLUDE_ISPUSHED,PendingServiceRoutingSelector.Options.WITH_WORKITEM});
	}

	// enables scheduling of this batch via cron or UI
	public void execute(SchedulableContext sc) {
		Database.executeBatch(this);
	 }

	public void execute(Database.BatchableContext BC, List<sObject> scope){
		try {
			OmniChannelService.getInstance().setOmniRoutingSecondaryPriority(scope);
			ApplicationDatabase.getInstance().dmlUpdate(scope);
		} catch(Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, OmniPsrSecondaryPriorityBatch.class.getName(), 'execute', 'Batch', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public void finish(Database.BatchableContext BC) { }
}