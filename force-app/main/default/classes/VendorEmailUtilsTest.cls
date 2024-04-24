/**
*@author: deepak.kemidi@auspost.com.au
*@date: 31/03/2024
*@description: Test Class for VendorEmailUtils class
*/
@IsTest
private class VendorEmailUtilsTest {

	@IsTest
	static void testGetEmailAddress() {
		//Stubbing
		AuspostVendorEmailSelector mockSelector = (AuspostVendorEmailSelector)MockUtility.mockSelector(AuspostVendorEmailSelector.class);

		//Preparing dummy data
		List<Auspost_Vendors_Email_Address__mdt> dummyData = new List<Auspost_Vendors_Email_Address__mdt>();
		for (Integer i = 0; i < 5; i++) {
			Auspost_Vendors_Email_Address__mdt record = new Auspost_Vendors_Email_Address__mdt();
			record.Vendor_Email__c = 'test' + i + '@example.com';
			dummyData.add(record);
		}

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector.selectAllRecords()).thenReturn(dummyData);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		List<String> result = VendorEmailUtils.getEmailAddress();
		Test.stopTest();

		// Verify result
		System.assertEquals(1, result.size(), 'Result should contain only one string');
		String[] emailAddresses = result[0].split(',');
		System.assertEquals(5, emailAddresses.size(), 'Should return 5 email addresses');
	}
}