/**
* @author Nathan Franklin
* @date 2021-01-12
* @group Tests
* @tag Selector
* @tag Line Item SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2021-05-12 - Shashwat.Nath@auspost.com.au - Created
* 2022-05-09 - NAsir Jawed - Added test for selectByProposalId methods
* 2023-01-19 - Mahesh Parvathaneni - Added tests for selectByProposalIdAndStatusWithOrder method
*/
@IsTest
public with sharing class ProductConfigurationSelector_Test{
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

		ProductConfigurationSelector selector = ProductConfigurationSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ProductConfigurationSelector.Options.WITH_LINE_ITEMS});
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Apttus_Config2__ProductConfiguration__c\\b').matcher(soql).find(), 'Resulting query does not select from Product Configuration');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithSubQuery() {

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

		ProductConfigurationSelector selector = ProductConfigurationSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ProductConfigurationSelector.Options.WITH_LINE_ITEMS});
		String soql = qb.toSoqlString();
		System.assertEquals(false, Pattern.compile('(?is)Apttus_QPConfig__Proposald__c\\..*?\\bfrom Apttus_Config2__ProductConfiguration__c\\b').matcher(soql).find(), 'Resulting query does not select product configuration fields');
		Test.stopTest();

	}
	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Contact con = APT_TestUtils.createContact();
		con.MailingCity = 'Melbourne';
		con.MailingState = 'VIC';
		con.MailingStreet = 'Flinders Street';
		con.MailingPostalCode = '3000'; 
		insert con;

		//Creating account test data
		Account tempacct = APT_TestUtils.createOrganisation();
		insert tempacct;

		//Creating Opportunity Test Data
		Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
		insert opp;

		//Creating Pricelist test data
		Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
		insert priceList;

		//Creating proposal test data
		Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
		quote.Expected_Revenue_Start_Date__c = System.today() + 2;
		insert quote;

		//Inserting product test data
		Product2 bundle1 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST001','Postal Services');
		bundle1.Non_contracted__c = false;
		insert bundle1;

		//Inserting product test data 2
		Product2 bundle2 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST002','Postal Services');
		bundle2.APT_Sync_with_Opportunity__c = true;
		bundle2.Apttus_Config2__HasOptions__c = true;
		bundle2.Non_contracted__c = true;
		bundle2.Apttus_Config2__ConfigurationType__c = 'Bundle';
		insert bundle2;

		//Inserting product configuration test data
		Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
		quote.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
		insert prodconfig;
			// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ProductConfigurationSelector selector = ProductConfigurationSelector.newInstance(1);
		Map<Id, Apttus_Config2__ProductConfiguration__c > results = selector.selectById(new Set<Id>{prodconfig.id});
		System.assertNotEquals(1, results.size(), 'Result count was wrong');

		results = selector.selectById(new Set<Id>{prodconfig.id}, new Set<Object>{ProductConfigurationSelector.Options.WITH_LINE_ITEMS});

		//Getting the prod config record by passing the proposal id and checking the result
		ProductConfigurationSelector selectorConfigId = ProductConfigurationSelector.newInstance(1);
		List<Apttus_Config2__ProductConfiguration__c> resultsByConfigId = selectorConfigId.selectByConfigId(new Set<ID>{prodconfig.id});
		System.assertEquals(1, resultsByConfigId.size(), 'Expected result size of 1');

		//Getting the prod config record by passing the proposal id and checking the result
		ProductConfigurationSelector selectorProp = ProductConfigurationSelector.newInstance(1);
		List<Apttus_Config2__ProductConfiguration__c> resultsByProp = selectorProp.selectByProposalId(new Set<ID>{quote.id});
		System.assertEquals(1, resultsByProp.size(), 'Expected result size of 1');

		//Getting the prod config record by passing the proposal id and status and checking the result
		List<Apttus_Config2__ProductConfiguration__c> resultsByPropAndStatus = selectorProp.selectByProposalIdAndStatusWithOrder(new Set<Id>{quote.id}, new Set<String> {'Ready For Finalization'});
		System.assertEquals(1, resultsByPropAndStatus.size(), 'Expected result size of 1');
		Test.stopTest();

	}

		/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

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
		ProductConfigurationSelector selector1 = ProductConfigurationSelector.newInstance(0, new Set<SObjectField>{Apttus_Config2__ProductConfiguration__c.Name});

		ProductConfigurationSelector selector = ProductConfigurationSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
				Apttus_Config2__ProductConfiguration__c.SObjectType => new Set<SObjectField>{Apttus_Config2__ProductConfiguration__c.Name}
		});
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ProductConfigurationSelector.Options.WITH_LINE_ITEMS});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Name.*?\\bfrom Apttus_Config2__ProductConfiguration__c\\b').matcher(soql).find(), 'Resulting query does not select Name field: ' + soql);

		qb = selector.newQueryBuilder(new Set<Object>{ProductConfigurationSelector.Options.WITH_ACCOUNT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Apttus_Config2__AccountId__r\\..*?\\bfrom Apttus_Config2__ProductConfiguration__c\\b').matcher(soql).find(), 'Resulting query does not select Apttus_Config2__AccountId__r field: ' + soql);

		Test.stopTest();
	}
}