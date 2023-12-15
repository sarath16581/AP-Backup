/**
* @author George Nguyen
* @group Batch
* @tag Batch
* @tag Omni SObject
* @domain OmniDomain
* @description This batch is used to move the case out of the preferred agent queue if the assigned preferred agent hasn't accepted the case in the allocated timeline. 
* @changelog
* 2023-02-10 - George Nguyen - Created
* 2023-03-15 - Noel Lim - updated DML to allow partial success (allOrNothing = false)
*/
public inherited sharing class OmniPreferredAgentBatch implements Database.Batchable<sObject>,Schedulable  {
	public final String query;
	public Datetime now;
	public Integer batchSize;

	public Id preferredAgentRoutingQueueId;

	public OmniPreferredAgentBatch(Integer batchSize) {	
		this.batchSize = batchSize;
		this.preferredAgentRoutingQueueId = OmniChannelService.getInstance().preferredAgentQueueId;			
		// This query is used to retrieved all PSR's that have IsPushed = False AND the related Case.PreferredAgentExpiry__c is less than Now. 
		this.query = 'SELECT WorkItemId FROM PendingServiceRouting WHERE IsPushed = FALSE AND WorkItem.PreferredAgentExpiry__c < :now AND Workitem.OwnerId = :preferredAgentRoutingQueueId';
	}

	public Database.QueryLocator start(Database.BatchableContext BC){
		now = System.Now();
		return Database.getQueryLocator(query);
	}

	// enables scheduling of this batch via cron or UI
	public void execute(SchedulableContext sc) {
		Database.executeBatch(this, this.batchSize);
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope){
		try {
			
			List<Case> casesToUpdate = OmniChannelService.getInstance().rerouteCasesWithPreferredAgentByPass(scope);
			if(casesToUpdate.isEmpty() == false) {
				ApplicationDatabase.getInstance().dmlUpdate(casesToUpdate,false);
			}
		} catch(Exception ex) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), SSSWConstants.SSSW_APP, OmniPreferredAgentBatch.class.getName(), 'execute', 'Batch', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public void finish(Database.BatchableContext BC) { }
}