/**
* @author Alex Volkov
* @date 02/12/2021
* @tag Batch
* @tag Case SObject
* @domain SSSW
* @description Batch job responsible for reopening cases waiting on hold
* @changelog
* 02/12/2021 - Alex Volkov - Initial creation
*/

public with sharing virtual class CaseReopenBatch implements Database.Batchable<SObject>, Schedulable {

	private static final Integer BATCH_SIZE = 25;

	/**
	 * @description Overridable query
	 * @return Database.QueryLocator
	 */
	public virtual Database.QueryLocator getEligibleCases(){
		Date vReopenUpToDate = System.today().addDays(1);
		return (Database.QueryLocator)SSSWCasesSelector.newInstance().selectCasesEligibleForReopenByOwnerAndDate(new Set<String>{GroupsSelector.newInstance().selectByDeveloperName(new Set<String>{SSSWConstants.QUEUE_NAME_REOPEN_Q}).values()[0].Id}, Datetime.newInstance(vReopenUpToDate.year(), vReopenUpToDate.month(), vReopenUpToDate.day()), new Set<Object>{SSSWCasesSelector.Options.RETURN_QUERY_LOCATOR});
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		return getEligibleCases();
	}

	public void execute(Database.BatchableContext bc, List<SObject> scope) {
		for (Case c: (List<Case>)scope) {
			c.AllocateToQueue__c = true;
			c.Case_Reopen_Date__c = null;
			c.Bypass_Data_enforcement__c = true;
		}
		List<Database.SaveResult> vResult = ApplicationDatabase.getInstance().dmlUpdate(scope, false);
		UTIL_LoggingService.logDmlResults(vResult, null, scope, 'Case Reopen',
				CaseReopenBatch.class.getName(), 'execute',null, LoggingLevel.ERROR);
	}

	public void finish(Database.BatchableContext bc) {
	}

	public void execute(SchedulableContext sc) {
		Database.executeBatch(this, BATCH_SIZE);
	}
}