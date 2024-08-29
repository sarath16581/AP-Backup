/**
 * @description Controller for the Lightning Web Component `UnifiedCaseCreation`
 *				This controller manages the creation of case including appropriate error handling and query related data for the LWC
 * @author: Marcel HK
 * @changelog:
 * 2024-08-21 - Marcel HK - Created
*/
public with sharing class UnifiedCaseCreationController {
	/**
	 * @description This method is used to get the Record Type Ids for the selected Record Type Names.
	 * 				It was created out of necessity due to the `lightning/uiObjectInfoApi.getObjectInfo` method not
	 * 				including the Developer Name in the `recordTypeInfos` data.
	 * 
	 * @param developerNames - List of Case Record Types
	 * @return Map<String, Object> - Map of record types similar to the `getObjectInfo` response.
	 */
	@AuraEnabled(cacheable=true)
	public static Map<String, Object> getCaseRecordTypeInfos(List<String> developerNames) {
		try {
			Map<String, Object> recordTypeInfos = new Map<String, Object>();
			for(Schema.RecordTypeInfo info : Case.getSObjectType().getDescribe().getRecordTypeInfos()) {
				if(developerNames.contains(info.getDeveloperName())) {
					Map<String, Object> data = new Map<String, Object>();
					data.put('available', info.available);
					data.put('defaultRecordTypeMapping', info.defaultrecordtypemapping);
					data.put('developerName', info.getDeveloperName());
					data.put('master', info.master);
					data.put('name', info.getName());
					data.put('recordTypeId', info.getRecordTypeId());
					recordTypeInfos.put(info.getRecordTypeId(), data);
				}
			}
			return recordTypeInfos;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}