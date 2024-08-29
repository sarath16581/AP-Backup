/**
 * @description Controller for the Lightning Web Component `UnifiedCaseCreation`
 *				This controller manages the creation of case including appropriate error handling and query related data for the LWC
 * @author: Marcel HK
 * @tag Case, ImpactedArticle__c
 * @domain Core
 * @changelog:
 * 2024-08-21 - Marcel HK - Created
*/
public with sharing class UnifiedCaseCreationController {

	@TestVisible
	private static final String GENERIC_ERROR_MESSAGE = 'An unexpected error has occurred. Please check the data you\'ve entered and try again. If this error persists, please inform your manager.';

	/**
	 * @description This method is used to get the Record Type Ids for the selected Record Type Names.
	 * 				It was created out of necessity due to the `lightning/uiObjectInfoApi.getObjectInfo` method not
	 * 				including the Developer Name in the `recordTypeInfos` data.
	 *
	 * @param developerNames - List of Case Record Types
	 * @return Map<String, Object> - Map of record types similar to the `getObjectInfo` response.
	 */
	@AuraEnabled(Cacheable=true)
	public static Map<String, Object> getCaseRecordTypeInfos(List<String> developerNames) {
		try {
			if (developerNames == null || developerNames.isEmpty()) {
				AuraHandledException ae = new AuraHandledException(GENERIC_ERROR_MESSAGE);
				ae.setMessage(GENERIC_ERROR_MESSAGE);
				throw ae;
			}

			Map<String, Object> recordTypeInfos = new Map<String, Object>();
			for(Schema.RecordTypeInfo info : Case.getSObjectType().getDescribe().getRecordTypeInfos()) {
				if(developerNames.contains(info.getDeveloperName())) {
					Map<String, Object> data = new Map<String, Object>();
					data.put('available', info.available);
					data.put('defaultRecordTypeMapping', info.defaultRecordTypeMapping);
					data.put('developerName', info.getDeveloperName());
					data.put('master', info.master);
					data.put('name', info.getName());
					data.put('recordTypeId', info.getRecordTypeId());
					recordTypeInfos.put(info.getRecordTypeId(), data);
				}
			}
			return recordTypeInfos;
		}
		catch (AuraHandledException ex) {
			AuraHandledException ae = new AuraHandledException(ex.getMessage());
			ae.setMessage(ex.getMessage());
			throw ae;
		}
		catch (Exception ex) {
			AuraHandledException ae = new AuraHandledException(GENERIC_ERROR_MESSAGE);
			ae.setMessage(GENERIC_ERROR_MESSAGE);
			throw ae;
		}
	}
}