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
* 2023-10-31 - Ranjeewa Silva - Added tests for search method
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

		//Getting the prod config record by passing the proposal id and checking the result
		ProductConfigurationSelector selector = ProductConfigurationSelector.newInstance(1);
		List<Apttus_Config2__ProductConfiguration__c> resultsByConfigId = selector.selectByConfigId(new Set<ID>{prodconfig.id});
		System.assertEquals(1, resultsByConfigId.size(), 'Expected result size of 1');

		//Getting the prod config record by passing the proposal id and checking the result
		List<Apttus_Config2__ProductConfiguration__c> resultsByProp = selector.selectByProposalId(new Set<ID>{quote.id});
		System.assertEquals(1, resultsByProp.size(), 'Expected result size of 1');

		//Getting the prod config record by passing the proposal id and status and checking the result
		List<Apttus_Config2__ProductConfiguration__c> resultsByPropAndStatus = selector.selectByProposalIdAndStatusWithOrder(new Set<Id>{quote.id}, new Set<String> {'Ready For Finalization'});
		System.assertEquals(1, resultsByPropAndStatus.size(), 'Expected result size of 1');

		Map<String, Object> searchParams = new Map<String, Object>{
				'proposalIds' => quote.Id,
				'status' => 'Ready For Finalization'
		};
		List<Apttus_Config2__ProductConfiguration__c> searchResults = selector.search(searchParams, new Set<Object>{}, true, Apttus_Config2__ProductConfiguration__c.Apttus_Config2__VersionNumber__c, 'DESC');
		Assert.areEqual(1, searchResults.size(), 'Expected result size of 1');

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

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureSearchMethodProducesCorrectString() {

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

		Map<String, Object> searchParams = new Map<String, Object>{
				'proposalIds' => 'aAf000000000000000',
				'status' => 'Finalized'
		};

		String soql = selector.getSearchSoql(searchParams, new Set<Object>(), true, Apttus_Config2__ProductConfiguration__c.Apttus_Config2__VersionNumber__c, 'DESC');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Apttus_Config2__ProductConfiguration__c\\s+where\\b.*?\\bApttus_QPConfig__Proposald__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter related proposal id: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Apttus_Config2__ProductConfiguration__c\\s+where\\b.*?\\bApttus_Config2__Status__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter Apttus_Config2__Status__c: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Apttus_Config2__ProductConfiguration__c\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not match ALL filters: ' + soql);
		System.assertEquals(true, Pattern.compile('\\bORDER BY ' + Apttus_Config2__ProductConfiguration__c.Apttus_Config2__VersionNumber__c + ' DESC').matcher(soql).find(), 'Resulting query does not Order by version number: ' + soql);

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, new Set<Object>(), true, Apttus_Config2__ProductConfiguration__c.Apttus_Config2__VersionNumber__c, 'DESC');

		searchParams = new Map<String, Object>{
				'proposalIds' => new Set<Id>{'aAf000000000000000'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true, null, 'DESC');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Apttus_Config2__ProductConfiguration__c\\s+where\\b.*?\\bApttus_QPConfig__Proposald__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter related proposal id: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\s+from Apttus_Config2__ProductConfiguration__c\\s+where\\b.*?\\bApttus_Config2__Status__c\\s+In\\b').matcher(soql).find(), 'Resulting query filters Apttus_Config2__Status__c, but it should not: ' + soql);

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, new Set<Object>(), true, Apttus_Config2__ProductConfiguration__c.Apttus_Config2__VersionNumber__c, 'DESC');

		searchParams = new Map<String, Object>{
				'status' => new Set<String>{'Finalized', 'Ready For Finalization'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true, Apttus_Config2__ProductConfiguration__c.Apttus_Config2__VersionNumber__c, 'DESC');

		System.assertEquals(false, Pattern.compile('(?ism)\\s+from Apttus_Config2__ProductConfiguration__c\\s+where\\b.*?\\bApttus_QPConfig__Proposald__c\\s+In\\b').matcher(soql).find(), 'Resulting query filters related proposal id, but it should not: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Apttus_Config2__ProductConfiguration__c\\s+where\\b.*?\\bApttus_Config2__Status__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter Apttus_Config2__Status__c: ' + soql);

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, new Set<Object>(), true, Apttus_Config2__ProductConfiguration__c.Apttus_Config2__VersionNumber__c, 'DESC');

		searchParams = new Map<String, Object>{
				'proposalIds' => 'aAf000000000000000',
				'status' => 'Finalized'
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), false, Apttus_Config2__ProductConfiguration__c.Apttus_Config2__VersionNumber__c, 'DESC');
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Apttus_Config2__ProductConfiguration__c\\s+where\\b.*?\\bApttus_QPConfig__Proposald__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter related proposal id: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Apttus_Config2__ProductConfiguration__c\\s+where\\b.*?\\bApttus_Config2__Status__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter Apttus_Config2__Status__c: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\s+from Apttus_Config2__ProductConfiguration__c\\s+where\\b.*?\\bOR\\b').matcher(soql).find(), 'Resulting query does not match ANY filter: ' + soql);

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, new Set<Object>(), false, Apttus_Config2__ProductConfiguration__c.Apttus_Config2__VersionNumber__c, 'DESC');

		Test.stopTest();

	}
}