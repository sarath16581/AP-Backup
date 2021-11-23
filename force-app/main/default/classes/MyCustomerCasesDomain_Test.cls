/**
* @description Test class for MyCustomerCasesDomain
* @author Nathan Franklin
* @date 2020-07-24
* @group Domains
* @changelog
*/
@IsTest
private class MyCustomerCasesDomain_Test {

	@IsTest
	private static void testMethods() {
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWGeneralEnquiryRecordType;

		ApplicationDomain.IConstructable constructableDomain = new MyCustomerCasesDomain.Constructor();
		MyCustomerCasesDomain domain = (MyCustomerCasesDomain)constructableDomain.construct(cases);

		System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(cases[0].Id, domain.records[0].Id, 'Expected SSSW record');
	}

}