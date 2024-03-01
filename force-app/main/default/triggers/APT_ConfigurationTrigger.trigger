/**
 *Description -
 * Sync with Opportunity, every time cart is updated
 * set pricing category = customised on contract when cart is set as customised pricing

 * last modified by - mausam padhiyar
 * last modified date - 30th April, 2016
 *
 * Last Modified By - Mausam Padhiyar
 * Last Modified Date - 3rd Nov, 2016 | Validate Approvals

 * Last Modified By - Mansi Shah
 * Last Modified Date - 15th June, 2021 | Call onAfterUpdate
* 06-12-2023 | Bharat Patel | STP-9773: Update condition, to sync Opportunity Products, with APT_Configuration_Update_Version__c & clean up commented code
*/
trigger APT_ConfigurationTrigger on Apttus_Config2__ProductConfiguration__c (before update, after insert, after update, before delete) {

	// before update
	if(trigger.isBefore && trigger.isUpdate) {
		String result = APT_ConfigurationTriggerHandler.beforeUpdateEvent(trigger.new);
		if(result != APT_Constants.SUCCESS_LABEL) {
			for(Apttus_Config2__ProductConfiguration__c configuration : trigger.new) {
				configuration.addError(result);
			}
		}
	}

	//after insert
	if(trigger.isAfter == true && trigger.isInsert == true) {
		String result = APT_ConfigurationTriggerHandler.afterInsertEvent(trigger.new);
		if(result != APT_Constants.SUCCESS_LABEL) {
			for(Apttus_Config2__ProductConfiguration__c configuration : trigger.new) {
				configuration.addError(result);
			}
		}
	}

	//after update
	if(trigger.isAfter && trigger.isupdate){
		Set<Id> prodConfigIdSet = new Set<Id>();
		Set<Id> quoteIdSet = new Set<Id>();
		Set<String> syncStatus = new Set<String>{'Saved','Finalized'};

		/* Checking if the Status of Product Configuration has Changed and the New Status is Saved or If Status is Changed and
		   there is an update on Number of Items in the Cart or the Status is changed to Finalized and DoV type is not DoV Decrease
		   then Queue the job asynchronously */
		for(Apttus_Config2__ProductConfiguration__c proConfig : trigger.new){
			if(((trigger.oldmap.get(proConfig.id).Apttus_Config2__Status__c!=proConfig.Apttus_Config2__Status__c
				&& syncStatus.Contains(proConfig.Apttus_Config2__Status__c)) ||
				('Saved'.equalsIgnoreCase(proConfig.Apttus_Config2__Status__c) &&
					trigger.oldmap.get(proConfig.id).APT_Configuration_Update_Version__c != proConfig.APT_Configuration_Update_Version__c ))){
						prodConfigIdSet.add(proConfig.id);
						quoteIdSet.add(proConfig.Apttus_QPConfig__Proposald__c);
			}
		}

		if(!prodConfigIdSet.isEmpty() && !quoteIdSet.isEmpty()){
		   /* Invoke the queable class to perform the Sync of the Shopping Cart Product to Opportunity Products. This is the only
			  place that the Sync would be getting invoked */
			System.enqueueJob(new APT_CreateOpportunityProductLICntlr (prodConfigIdSet, quoteIdSet));
		}
	}

	if(trigger.isAfter && trigger.isupdate){
		//Code Added by Mansi Shah
		APT_ConfigurationTriggerHandler.onAfterUpdate(trigger.new,trigger.oldMap);
	}
}