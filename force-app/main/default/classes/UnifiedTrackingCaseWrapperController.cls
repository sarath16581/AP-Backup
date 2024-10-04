/**
 * @description Controller class for UnifiedTrackingCaseWrapper LWC
 * 
 * @author Raghav Ravipati
 * @date 2024-09-15
 * @changelog
 */
public with sharing class UnifiedTrackingCaseWrapperController {
	/**
	 * @param recordTypeDeveloperName RecordType's Developer Name
	 * @return Returns true if recordtype related to unified.
	 */
	@AuraEnabled(cacheable=true)
	public static Boolean isUnifiedCase(String recordTypeDeveloperName) {
		return CommonUtils.isUnifiedCase(recordTypeDeveloperName);
	}
}