/**
* @author Ashapriya Gadi
* @date 2021-11-23
* @group Tests
* @tag Selector
* @tag BusinessHours
* @domain Core
* @description Test class covering BusinessHoursSelector
* @changelog
* 2021-11-23 - Ashapriya Gadi - Created
* 19/04/2023    hasantha.liyanage@auspost.com.au DDS-15568 added test testCreateEnquiryGeneralForEDD
*/
@IsTest
private class BusinessHoursSelector_Test {
	/**
		* Test:
		*  Ensures that the selectors QueryBuilder is generating the correct output
		*/
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {
		
		// =====================================
		// Data Preparation
		// =====================================
		// None!
		
		// =====================================
		// Stubbing
		// =====================================
		// None!
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		BusinessHoursSelector selector = BusinessHoursSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		Test.stopTest();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom BusinessHours\\b').matcher(soql).find(), 'Resulting query not select from BusinessHours');
	}
	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	private static void testSelectorByIdAndName() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		BusinessHours stdBusinessHours = [SELECT Id,Name FROM BusinessHours WHERE IsDefault = true LIMIT 1];
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		BusinessHoursSelector selector = BusinessHoursSelector.newInstance();
		List<BusinessHours> results = selector.selectById(new Set<Id>{stdBusinessHours.Id});
		List<BusinessHours> resultsName = selector.selectByName(new Set<String>{stdBusinessHours.Name});
		Test.stopTest();
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		System.assertEquals(1, resultsName.size(), 'Expected result size of 1');
	
	}

	@IsTest
	private static void testSelectorDefault() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		BusinessHours stdBusinessHours = [SELECT Id,Name FROM BusinessHours WHERE IsDefault = true LIMIT 1];
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BusinessHours result = BusinessHoursSelector.newInstance().selectDefault(true);

		Test.stopTest();
		System.assertNotEquals(null, result, 'Default business hour should return ');
		System.assertEquals(stdBusinessHours.Id, result.Id, 'Default business hour should return as expected');

	}
}