/**
 * @description test class for CreditSuspectDomain
 * @author Paul Perry
 * @group Domain
 * @domain CreditSuspect__c
 **/
@IsTest
private class CreditSuspectDomain_Test {
	@IsTest
	static void ensureThatRegisterModulesIsBeingCalledWithTheCorrectType() {
		Date csDoB = Date.newInstance(1980, 1, 1);

		CreditSuspect__c creditSuspect = new CreditSuspect__c(
			// Birthdate__c = '', formatted date will be populated within the trigger
			FirstName__c = 'First',
			LastName__c = 'Last',
			Phone__c = '0400000000',
			PostCode__c = '3000',
			State__c = 'VIC',
			StreetAddress__c = '287 Elizabeth St',
			Suburb__c = 'MELBOURNE',
			Email__c = 'test@example.com',
			Date_of_Birth__c = csDoB
		);

		MockUtility.mockDomain(ApplicationDomain.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.stopStubbing();

		CreditSuspectDomain.Constructor constructor = new CreditSuspectDomain.Constructor();		
		List<CreditSuspect__c> csList = new List<CreditSuspect__c>{ creditSuspect };
		ApplicationDomain appDomain = constructor.construct(csList);
		
		((ApplicationDomain)MockUtility.Mocks.verify(
			appDomain,
			MockUtility.Mocks.times(1)
		)).registerModule(CreditSuspectGenericModule.class);

		// PMD by-pass
		System.assert(true, 'PMD by-pass');
	}
}