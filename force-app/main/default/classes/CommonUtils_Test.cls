/******************************************************************************************
Description:    Common utility test methods

2017-10-02          nathan.franklin@auspost.com.au             Created for Coverage
2018-05-28			hasantha.liyanage@auspost.com.au			added tests only for test coverage
*******************************************************************************************/
@isTest
public class CommonUtils_Test {

	/**
	 * SCENARIO:
	 *      Ensure the getObjectAPINameByRecordId method is resolving the correct object name
	 */
	public static testMethod void testObjectName() {

		Case myCase = TestDataProvider.createCase('My Subject', 'My Description', 'SSSW General Enquiry');
		myCase.Status = 'New';
		insert myCase;

		String objectName = CommonUtils.getObjectAPINameByRecordId(myCase.Id);
		System.assertEquals('Case', objectName);

	}

	/**
	 * SCENARIO:
	 *      Read the cache if the STR_COMMON_UTILS_GLOBAL_DESCRIBE available
	 */
	public static testMethod void CommonUtils_getGlobalDescribe() {
		//These tests are just to get the coverage
		System.assertEquals(null, CacheManager.get(CommonUtils.STR_COMMON_UTILS_GLOBAL_DESCRIBE));
		CommonUtils.getGlobalDescribe();
	}

}