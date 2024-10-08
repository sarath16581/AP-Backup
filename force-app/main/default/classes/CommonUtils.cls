/******************************************************************************************
    
    Author:         Stephen James Laylo
    Date Created:   04/02/2015
    Description:    Common utility methods
    
    Change Log:
    Date:          Author:                  Description:
    04/02/2016     Stephen James Laylo      Created

2017-10-02          nathan.franklin@auspost.com.au             Added Caching
2024-09-13			Marcel HK									Added isUnifiedCase method

*******************************************************************************************/
public class CommonUtils {
	@testVisible
	private static String STR_COMMON_UTILS_GLOBAL_DESCRIBE = 'COMMON_UTILS_GLOBAL_DESCRIBE';
	/*****************************************************************************
    	Author: 		Stephen James Laylo
    	Description:	Returns sObject Type from Record Id
    
    	Input:		    Id
    	Output:		    String - sObject Type
	*****************************************************************************/
	public static String getObjectAPINameByRecordId(Id theId) {
		if (theId != null) {
			String myIdPrefix = String.valueOf(theId).substring(0, 3); //get just the prefix

			String apiName = String.valueOf(CacheManager.get('COMMON_UTILS_API_NAMES', myIdPrefix));
			if (!String.isEmpty(apiName)) {
				return apiName;
			}

			Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
			for (Schema.SObjectType sType : gd.values()) {
				Schema.DescribeSObjectResult r = sType.getDescribe();
				String prefix = r.getKeyPrefix();

				if (prefix != null && prefix.equals(myIdPrefix)) {
					CacheManager.put('COMMON_UTILS_API_NAMES', myIdPrefix, r.getName());
					return r.getName();
				}
			}
		}

		return null;
	}

	/**
	 * Retrieve global describe and store it in cache for faster access.
	 */
	public static Map<String, Schema.SObjectType> getGlobalDescribe() {
		Map<String, Schema.SObjectType> gd = (Map<String, Schema.SObjectType>) CacheManager.get(STR_COMMON_UTILS_GLOBAL_DESCRIBE);
		if (gd != null) {
			return gd;
		}

		gd = Schema.getGlobalDescribe();
		CacheManager.put(STR_COMMON_UTILS_GLOBAL_DESCRIBE, gd);
		return gd;
	}

	/**
	 * @description Use the Case Record Type to identify if a Case is a 'Unified' Case or not.
	 *
	 * @param recordTypeDeveloperName - The Case.RecordType.DeveloperName value
	 * @return true if the Case is a Unified Case, otherwise false.
	 */
	public static Boolean isUnifiedCase(String recordTypeDeveloperName) {
		return String.isNotBlank(recordTypeDeveloperName) ? recordTypeDeveloperName.startsWith('Unified') : false;
	}
}