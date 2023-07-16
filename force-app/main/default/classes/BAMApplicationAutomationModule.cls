/***
 * @author Mahesh Parvathaneni
 * @date 2023-07-14
 * @description Logic related to BAMApplication records.  
 * @changelog
 */

public inherited sharing class BAMApplicationAutomationModule extends ApplicationModule {

	//constants
	private static final String KEY_NOT_CONTAINS = 'notContains';

	/**
	 * Billing account field names
	 */
	private static Set<String> billingAccountFields {
		get {
			if (billingAccountFields == null) {
				billingAccountFields = Billing_Account__c.SObjectType.getDescribe().fields.getMap().keySet();
			}
			return billingAccountFields;
		}
		private set;
	}

	// Setup which triggers this module should respond to
	public BAMApplicationAutomationModule() {
		getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();
	}

	/**
	 * Called when a new BAMApplication is being inserted
	 * @param records list of BAMApplication  records
	 * @param uow instance of UnitOfWork
	 */
	public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			validateBillingAccountFilter((List<BAMApplication__c>)records, null , uow);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'BAM', BAMApplicationAutomationModule.class.getName(), 'onBeforeInsert', 'BAMApplication__c', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Called when a BAMApplication is being updated.
	 * @param records list of BAMApplication records
	 * @param existingRecords map of existing BAMApplication records
	 * @param uow instance of UnitOfWork
	 */
	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {
			validateBillingAccountFilter((List<BAMApplication__c>)records, (Map<Id, BAMApplication__c>)existingRecords , uow);
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'BAM', BAMApplicationAutomationModule.class.getName(), 'onBeforeUpdate', 'BAMApplication__c', ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * @description This method validates the BillingAccountFilter__c field on BAMApplication__c object for valid Billing Account field names
	 * 				are used in the filter criteria
	 * @param  records			list of BAMApplication records
	 * @param  existingRecords	map of existing BAMApplication records
	 * @param  uow             instance of UnitOfWork
	 */
	private void validateBillingAccountFilter(List<BAMApplication__c> records, Map<Id, BAMApplication__c> existingRecords, ApplicationUnitOfWork uow){		
		for (BAMApplication__c bamApp : (List<BAMApplication__c>) records) {
			if(String.isNotBlank(bamApp.BillingAccountFilter__c) && (existingRecords == null || 
				(existingRecords != null && bamApp.BillingAccountFilter__c != existingRecords.get(bamApp.Id).BillingAccountFilter__c))){
				Map<String, Object> filterMap;
				//deserialise the json to make sure it is valid
				try {
					filterMap = (Map<String, Object>)JSON.deserializeUntyped(bamApp.BillingAccountFilter__c);
				} catch (Exception ex) {
					//add error to the sobject record
					bamApp.addError(Label.BAMInvalidBillingAccountJsonFilter);
				}
				//check the field API names are valid in the filter
				for (String fieldName : filterMap.keySet()) {
					if (!fieldName.equalsIgnoreCase(KEY_NOT_CONTAINS) && !billingAccountFields.contains(fieldName.toLowerCase())) {
						//add error to the sobject record
						bamApp.addError(String.format(Label.BAMInvalidBillingAccountFields, new List<String>{fieldName}));
					} else if(fieldName.equalsIgnoreCase(KEY_NOT_CONTAINS)){
						//get the keys from 'notContains' defined at filter
						//this is in the Map<String, Object> format again
						Object notContainsValue = filterMap.get(fieldName);
						Map<String,Object> notContainsValueMap = (Map<String,Object>)notContainsValue;
						for (String ncFieldName : notContainsValueMap.keySet()) {
							if (!billingAccountFields.contains(ncFieldName.toLowerCase())) {
								bamApp.addError(String.format(Label.BAMInvalidBillingAccountFields, new List<String>{ncFieldName}));
							}
						}
					}
				}
			}			
		}
	}
}