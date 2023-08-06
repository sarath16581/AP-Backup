/**
 * @description Test class for BAMApplicationAutomationModule
 * @author Mahesh Parvathaneni
 * @date 2023-07-14
 * @changelog
*/

@IsTest
private class BAMApplicationAutomationModule_Test {

	/**
	* Scenario: Testing the before insert trigger event
	* Test to ensure an error is thrown when invalid billing account field names are defined in BillingAccountFilter__c
	*/
	@IsTest
	static void testBeforeInsertValidateBillingAccountFilter() {
		// =====================================
		// Data Preparation
		// =====================================
		//get products
		List<Product2> products = ApplicationTestDataFactory.getProducts(2, true);
		//get BAM Applications
		List<BAMApplication__c> records = ApplicationTestDataFactory.getBamApplications(1,'Business Shop',products[0].Id, true);
		records.addAll(ApplicationTestDataFactory.getBamApplications(1,'Business Support Portal',products[1].Id, true));
		records[0].BillingAccountFilter__c = '{"Source_System__c": "TEAM","Credit_Status__c": false}';
		records[1].BillingAccountFilter__c = '{"SourceSystem__c": "TEAM","Credit_Status__c": false}';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BAMApplicationAutomationModule module = new BAMApplicationAutomationModule();
		module.onBeforeInsert(records, mockUow);

		//make sure error is thrown as SourceSystem__c is not valid field API name for Billing_Account__c
		System.assertEquals(true, records[1].hasErrors(), 'Expected validation error on the BAM Application record');
		//make sure no error is thrown
		System.assertEquals(false, records[0].hasErrors(), 'Expected no validation error on the BAM Application record');

		Test.stopTest();
	}

	/**
	* Scenario: Testing the before update trigger event
	* Test to ensure an error is thrown when invalid billing account field names are defined in BillingAccountFilter__c
	*/
	@IsTest
	static void testBeforeUpdateValidateBillingAccountFilter() {
		// =====================================
		// Data Preparation
		// =====================================
		//get products
		List<Product2> products = ApplicationTestDataFactory.getProducts(2, true);
		//get BAM Applications
		List<BAMApplication__c> records = ApplicationTestDataFactory.getBamApplications(1,'Business Shop',products[0].Id, true);
		records.addAll(ApplicationTestDataFactory.getBamApplications(1,'Business Support Portal',products[1].Id, true));
		records[0].BillingAccountFilter__c = '{"Source_System__c": "TEAM","Credit_Status__c": false}';
		records[1].BillingAccountFilter__c = '{"Credit_Status__c": false,"notContains":{"SourceSystem__c": "TEAM"}}';

		List<BAMApplication__c> existingRecords = records.deepClone(true, true, true);

		// updated the filter with correct API field names
		existingRecords[1].BillingAccountFilter__c = '{"Source_System__c": "TEAM","Credit_Status__c": false}';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BAMApplicationAutomationModule module = new BAMApplicationAutomationModule();
		module.onBeforeUpdate(records, new Map<Id, BAMApplication__c>(existingRecords), mockUow);

		//make sure error is thrown as SourceSystem__c is not valid field API name for Billing_Account__c
		System.assertEquals(true, records[1].hasErrors(), 'Expected validation error on the BAM Application record');

		Test.stopTest();

	}

	/**
	* Scenario: Testing the before insert trigger event
	* Test to ensure an error is thrown when invalid json defined in BillingAccountFilter__c
	*/
	@IsTest
	static void testBeforeInsertValidateBillingAccountFilterJSON() {
		// =====================================
		// Data Preparation
		// =====================================
		//get products
		List<Product2> products = ApplicationTestDataFactory.getProducts(2, true);
		//get BAM Applications
		List<BAMApplication__c> records = ApplicationTestDataFactory.getBamApplications(1,'Business Shop',products[0].Id, true);
		records.addAll(ApplicationTestDataFactory.getBamApplications(1,'Business Support Portal',products[1].Id, true));
		records[0].BillingAccountFilter__c = '{"Source_System__c": "TEAM","Credit_Status__c": false}';
		//invalid json string
		records[1].BillingAccountFilter__c = '[Source_System__c": "TEAM","Credit_Status__c": false]';

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		BAMApplicationAutomationModule module = new BAMApplicationAutomationModule();
		module.onBeforeInsert(records, mockUow);

		//make sure error is thrown as SourceSystem__c is not valid field API name for Billing_Account__c
		System.assertEquals(true, records[1].hasErrors(), 'Expected validation error on the BAM Application record');
		//make sure no error is thrown
		System.assertEquals(false, records[0].hasErrors(), 'Expected no validation error on the BAM Application record');

		Test.stopTest();
	}

}