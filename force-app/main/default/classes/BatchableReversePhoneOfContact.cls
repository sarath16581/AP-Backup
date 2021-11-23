global class BatchableReversePhoneOfContact implements Database.Batchable<sObject> {
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator('SELECT ReversePhoneFields__c, Phone, HomePhone, MobilePhone, OtherPhone FROM Contact WHERE ReversePhoneFields__c = null AND (Phone != null OR HomePhone != null OR MobilePhone != null OR OtherPhone != null)');
	}
	
	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		List<Contact> list_contact2update = (List<Contact>)scope;
		ContactUtility.generateReversePhoneFields(list_contact2update);
		
		// will fire Contact before/after update trigger.
		// as currently the trigger logic creteria not matched, the fired trigger won't do anything
		//update list_contact2update;
		Database.update(list_contact2update, false);
	}
	
	global void finish(Database.BatchableContext BC) { }
}