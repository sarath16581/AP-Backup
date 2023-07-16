/***
 * @description Test class for BAMApplicationAutomationTriggerHandler
 * @author Mahesh Parvathaneni
 * @date 2023-07-14
 * @changelog
 */

@IsTest
private class BAMApplicationAutomationTriggerHdlr_Test {

	/**
	 * This class does not do much so we just need a single test for coverage
	 */
	@IsTest
	private static void testForCoverage() {

		BAMApplicationAutomationTriggerHandler handler = new BAMApplicationAutomationTriggerHandler();

		ApplicationUnitOfWork uow = handler.newUnitOfWork();

		handler.registerModules();

		Id bamRecordType = new List<Id>(new RecordTypesSelector().selectByDeveloperNamesLike('BAMApplication__c', new Set<String>{'BAM'}).keySet())[0];

		//get products
		List<Product2> products = ApplicationTestDataFactory.getProducts(1, true);
		//get BAM Applications
		List<BAMApplication__c> bamApps = ApplicationTestDataFactory.getBamApplications(1,'Business Shop',products[0].Id, true);
		bamApps.addAll(ApplicationTestDataFactory.getBamApplications(1,'Business Support Portal',products[0].Id, true));
		bamApps[0].RecordTypeId = bamRecordType;
		bamApps[1].RecordTypeId = bamRecordType;

		Map<String, List<SObject>> filteredGroupRecords = handler.primeRecordFilters(bamApps);

		System.assertEquals(1, filteredGroupRecords.size());

		System.assertEquals(2, filteredGroupRecords.get('filterBAM').size());
		System.assertEquals(bamApps[0].Id, filteredGroupRecords.get('filterBAM')[0].Id);

		System.assertEquals(BAMApplication__c.SObjectType, handler.getSObjectType());

	}

}