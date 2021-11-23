/**
 * 2018-05-15 Hasantha.Liyanage@auspost.com.au updated: added getCustomSettingByListName
 **/
public with sharing class LightningUtilityController {

	/**
	 * Returns a Map of object/field names to labels
	 * Called from Lightning component to retrieve field labels since lightning doesn't carry native function
	 */
	@AuraEnabled
	public static Map<String, String> getSObjectFieldLabels(List<String> fieldNames) {

		// if additional labels need to be loaded that aren;t already in the cache
		// we only update the cache if needed as a call to cache items is expensive.
		Boolean updateCache = false;

		Map<String, String> fieldLabels = new Map<String, String>();
		Map<String, Schema.SObjectType> gd = CommonUtils.getGlobalDescribe();

		Map<String, String> cachedFieldLabels = (Map<String, String>)CacheManager.get('LTNG_UTIL_FIELD_LABELS');
		if(cachedFieldLabels == null)
			cachedFieldLabels = new Map<String, String>();

		for(String fieldObjectName : fieldNames) {

			if(cachedFieldLabels.keySet().contains(fieldObjectName)) {
				fieldLabels.put(fieldObjectName, cachedFieldLabels.get(fieldObjectName));
			} else {
				String[] parts = fieldObjectName.split('\\.');
				if(parts.size() == 2) {
					String obj = parts[0];
					String fieldName = parts[1];

					if(gd.get(obj) != null) {
						SObjectField sObjectField = gd.get(obj).getDescribe().fields.getMap().get(fieldName);
						if(sObjectField != null) {
							String fieldLabel = sObjectField.getDescribe().getLabel();
							fieldLabels.put(fieldObjectName, fieldLabel);
							cachedFieldLabels.put(fieldObjectName, fieldLabel);

							// make sure the cache is updated with the new label values
							// only do it if necessary to save costs.
							updateCache = true;
						}
					}
				}
			}
		}

		if(updateCache) {
			CacheManager.put('LTNG_UTIL_FIELD_LABELS', cachedFieldLabels);
		}

		return fieldLabels;
	}

	/**
	 * Returns a map of field names and picklist values
	 */
	@AuraEnabled
	public static Map<String, Map<String, String>> getSObjectFieldPicklistValues(List<String> fieldNames) {

		// if additional values need to be loaded that aren;t already in the cache
		// we only update the cache if needed as a call to cache items is expensive.
		Boolean updateCache = false;

		Map<String, Map<String, String>> fieldValues = new Map<String, Map<String, String>>();
		Map<String, Schema.SObjectType> gd = CommonUtils.getGlobalDescribe();

		Map<String, Map<String, String>> cachedFieldValues = (Map<String, Map<String, String>>)CacheManager.get('LTNG_UTIL_FIELD_PICKLIST_VALUES');
		if(cachedFieldValues == null)
			cachedFieldValues = new Map<String, Map<String, String>>();

		for(String fieldObjectName : fieldNames) {

			if(cachedFieldValues.keySet().contains(fieldObjectName)) {
				fieldValues.put(fieldObjectName, cachedFieldValues.get(fieldObjectName));
			} else {
				String[] parts = fieldObjectName.split('\\.');
				if(parts.size() == 2) {
					String obj = parts[0];
					String fieldName = parts[1];

					if(gd.get(obj) != null) {
						SObjectField sObjectField = gd.get(obj).getDescribe().fields.getMap().get(fieldName);
						if(sObjectField != null) {
							List<Schema.PicklistEntry> picklistValues = sObjectField.getDescribe().getPicklistValues();
							Map<String, String> picklistMap = new Map<String, String>();
							for(Schema.PicklistEntry picklistEntry : picklistValues) {
								picklistMap.put(picklistEntry.getValue(), picklistEntry.getLabel());
							}

							fieldValues.put(fieldObjectName, picklistMap);
							cachedFieldValues.put(fieldObjectName, picklistMap);

							// make sure the cache is updated with the new picklist values
							// only do it if necessary to save costs.
							updateCache = true;
						}
					}
				}
			}
		}

		if(updateCache) {
			CacheManager.put('LTNG_UTIL_FIELD_PICKLIST_VALUES', cachedFieldValues);
		}

		return fieldValues;
	}
    
    /**
    * This is to retrive visual force I frame instance url,
    * we cannot access the instance url inside a lighning component 
    **/
    @AuraEnabled
    public static sObject getSystemCustomSettingListByName(String listName, String recordName){
        try{
            SObjectType objToken = Schema.getGlobalDescribe().get(listName);
            DescribeSObjectResult objDef = objToken.getDescribe();

            // read all the fields on the custom setting
            Map<String, SObjectField> fields = objDef.fields.getMap();
            //prepare for SOQL
            string fieldsAPIname = '';
            for(string f : objDef.fields.getMap().keySet()){
                fieldsAPIname += f +',';
            }   
            if(fieldsAPIname.endsWith(',')){
                fieldsAPIname= fieldsAPIname.substring(0,fieldsAPIname.length()-1);
            }

            // query the custom setting
            for(sObject so: database.query('SELECT '+fieldsAPIname+' FROM '+listName+' WHERE Name=\''+recordName+'\'')) {
                system.debug(' fieldsAPIname '+fieldsAPIname);
                //return the custom setting if found
                return so;
            }
        } catch(exception e){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'LightningUtility', LightningUtilityController.class.getName(), 'getSystemCustomSettingListByName',
                null, LoggingLevel.ERROR
            );
        }
        
        // return null if not found
        return null ;
    }
}