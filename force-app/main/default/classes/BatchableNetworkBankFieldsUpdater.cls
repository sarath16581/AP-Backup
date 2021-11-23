global class BatchableNetworkBankFieldsUpdater implements Database.Batchable<sObject> {
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator('SELECT BusBankChq__c, BusBankChqCash__c FROM Network__c');
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		NetworkUtil.updateBankFields((List<Network__c>) scope);
		update scope;
	}
	
	global void finish(Database.BatchableContext BC) {		
	}

	global static Id run() {
		return Database.executeBatch(new BatchableNetworkBankFieldsUpdater());
	}	
}