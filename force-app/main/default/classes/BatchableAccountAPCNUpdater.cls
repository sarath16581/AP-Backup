global class BatchableAccountAPCNUpdater implements Database.Batchable<sObject> {
	
	private Integer numOfRecords = null;
	
	private BatchableAccountAPCNUpdater(Integer numOfRecords) {
		this.numOfRecords = numOfRecords;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return numOfRecords == null 
			? Database.getQueryLocator('SELECT APCN__pc FROM Account WHERE IsPersonAccount = true AND APCN__c = null AND APCN__pc != null')
			: Database.getQueryLocator('SELECT APCN__pc FROM Account WHERE IsPersonAccount = true AND APCN__c = null AND APCN__pc != null limit ' + numOfRecords);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		List<Account> accsToUpdate = new List<Account>();
		for (Account a : (List<Account>)scope) {
			a.APCN__c = a.APCN__pc;
			accsToUpdate.add(a);
		}
		
		if (accsToUpdate.size() > 0) {
			Database.update(accsToUpdate, false);
		}
	}
	
	global void finish(Database.BatchableContext BC) {		
	}

	global static Id run() {
		return run(null);
	}

	global static Id run(Integer numOfRecords) {
		return Database.executeBatch(new BatchableAccountAPCNUpdater(numOfRecords));
	}
}