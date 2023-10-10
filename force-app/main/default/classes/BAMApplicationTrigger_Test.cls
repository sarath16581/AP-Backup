/***
 * @description Test class for BAMApplicationTrigger
 * @author Mahesh Parvathaneni
 * @date 2023-07-14
 * @changelog
 */

@IsTest
private class BAMApplicationTrigger_Test {

	@IsTest
	static void makingSureThatTheDispatchMethodIsCalledFromTheCorrectClass() {
		// =====================================
		// Data Preparation
		// =====================================
		Id bamRecordType = new List<Id>(new RecordTypesSelector().selectByDeveloperNamesLike('BAMApplication__c', new Set<String>{'BAM'}).keySet())[0];
		//get products
		List<Product2> products = ApplicationTestDataFactory.getProducts(2, false);
		products[0].Name = 'Business Shop';
		products[1].Name = 'BSP';
		insert products;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		//get BAM Applications
		List<BAMApplication__c> bamApps = ApplicationTestDataFactory.getBamApplications(1,'Business Shop',products[0].Id, false);
		bamApps.addAll(ApplicationTestDataFactory.getBamApplications(1,'BSP',products[1].Id, false));
		bamApps[0].RecordTypeId = bamRecordType;
		bamApps[1].RecordTypeId = bamRecordType;

		Test.startTest();
		insert bamApps;
		Test.stopTest();

		System.assertNotEquals(null, bamApps[0].id,'BAM Applications should be inserted');
		System.assertNotEquals(null, bamApps[1].id,'BAM Applications should be inserted');

	}
}