/***
 * @description Common utility methods
 *
 * @author Stephen James Laylo
 * @date 2015-02-04
 * @group Integration
 * @changelog
 * 2017-10-02 - nathan.franklin - Added Caching
 * 2021-03-01 - nathan.franklin - Updated Caching
 */
public class CommonUtils {
    @testVisible private static String STR_COMMON_UTILS_GLOBAL_DESCRIBE = 'COMMON_UTILS_GLOBAL_DESCRIBE';

    private static Map<String, Schema.SObjectType> describeGlobalCache;

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
            if(!String.isEmpty(apiName)) {
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
        if(describeGlobalCache != null) {
            return describeGlobalCache;
        }

        Map<String, Schema.SObjectType> gd = (Map<String, Schema.SObjectType>)CacheManager.get(STR_COMMON_UTILS_GLOBAL_DESCRIBE);
        if(gd != null) {
            return gd;
        }

        gd = Schema.getGlobalDescribe();
        CacheManager.put(STR_COMMON_UTILS_GLOBAL_DESCRIBE, gd);

        describeGlobalCache = gd;

        return gd;
    }

}