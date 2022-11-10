/**
* @description Test class for MyCustomerCasesDomain
* @author Nathan Franklin
* @date 2020-07-24
* @group Domains
* @changelog
* 2022-11-03 George Nguyen - added ensureThatRegisterModulesIsBeingCalledWithTheCorrectType
*/
@IsTest
private class MyCustomerCasesDomain_Test {

	@IsTest
	static void ensureThatRegisterModulesIsBeingCalledWithTheCorrectType() {
		MockUtility.mockDomain(ApplicationDomain.class);
		List<Case> cases = ApplicationTestDataFactory.getCases(2, true);
		cases[0].RecordTypeId = ApplicationTestDataFactory.caseSSSWGeneralEnquiryRecordType;
		MyCustomerCasesDomain.Constructor constructor = new MyCustomerCasesDomain.Constructor();
		ApplicationDomain appDomain = constructor.construct(cases);

		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(MyCustomerCaseArticlesModule.class);
		((ApplicationDomain) MockUtility.Mocks.verify(appDomain, MockUtility.Mocks.times(1))).registerModule(MyCustomerCaseRoutingModule.class);

		MyCustomerCasesDomain domain = MyCustomerCasesDomain.newInstance(cases);
		List<SObject> filteredResult = domain.filter(cases);
		System.assertEquals(1, filteredResult.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(cases[0].Id, filteredResult[0].Id, 'Expected SSSW record');

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}

}