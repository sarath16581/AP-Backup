/**
* @description Test class for AuspostVendorEmailSelector
* @author Deepak Kemidi
* @date 2024-06-04
* @changelog
*/

@IsTest
private class AuspostVendorEmailSelector_Test {
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

		AuspostVendorEmailSelector selector = AuspostVendorEmailSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		// Check if the query selects from Auspost_Vendors_Email_Address__mdt
		System.assert(Pattern.compile('(?ism)\\bfrom Auspost_Vendors_Email_Address__mdt\\b').matcher(soql).find(), 'Resulting query does not select from Auspost_Vendors_Email_Address__mdt');

		Test.stopTest();

	}

	/**
	* Executes a query to ensure it returns expected results with actual data
	*/
	@IsTest
	public static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		Auspost_Vendors_Email_Address__mdt vendorEmailRecord = [SELECT DeveloperName, Vendor_Email__c FROM Auspost_Vendors_Email_Address__mdt WHERE Vendor_Email__c != null LIMIT 1];
		String vendorEmail = vendorEmailRecord.Vendor_Email__c;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AuspostVendorEmailSelector selector = AuspostVendorEmailSelector.newInstance(1);
		List<Auspost_Vendors_Email_Address__mdt> results = selector.selectAllRecords();
		System.assertEquals(1, results.size(), 'Result count was wrong');

		results = selector.selectByVendorEmails(new Set<String>{vendorEmail});
		System.assertEquals(1, results.size(), 'Result count was wrong');

		Test.stopTest();

	}

}