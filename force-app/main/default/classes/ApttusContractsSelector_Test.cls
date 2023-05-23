	/**
	* @author Nathan Franklin
	* @date 2021-01-12
	* @group Tests
	* @tag Selector
	* @tag Apttus Contract SObject
	* @domain Core
	* @description A very simple selector class that sits in the base domain
	* @changelog
	* 2020-04-10 - arjun.singh@auspost.com.au - Created
	* 2023-03-23 - sarath.burra@auspost.com.au - CI-703 added test for Search Method
	*/
	@IsTest
	public with sharing class ApttusContractsSelector_Test {
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

		ApttusContractsSelector selector = ApttusContractsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Apttus__APTS_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select from Apttus Contract');

		Test.stopTest();

	}

	/**
	* Test:
	*  Ensures that the selectors QueryBuilder is generating the correct output
	*/
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringForFieldOverride() {
		Test.startTest();

		ApttusContractsSelector selector = ApttusContractsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Apttus__APTS_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select from Apttus__APTS_Agreement__c');

		selector = ApttusContractsSelector.newInstance(1, new Set<SObjectField>{
				Apttus__APTS_Agreement__c.Id
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Apttus__APTS_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select from Apttus__APTS_Agreement__c');

		selector = ApttusContractsSelector.newInstance(1, new Map<SObjectType, Set<SObjectField>>{
				Apttus__APTS_Agreement__c.SObjectType => new Set<SObjectField>{Apttus__APTS_Agreement__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Apttus__APTS_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select from Apttus__APTS_Agreement__c');

		selector = ApttusContractsSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
				Apttus__APTS_Agreement__c.SObjectType => new Set<SObjectField>{Apttus__APTS_Agreement__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Apttus__APTS_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select from Apttus__APTS_Agreement__c');
		Test.stopTest();
	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

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

		ApttusContractsSelector selector = ApttusContractsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ApttusContractsSelector.Options.WITH_RECORDTYPE});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom Apttus__APTS_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');

		qb = selector.newQueryBuilder(new Set<Object>{ApttusContractsSelector.Options.WITH_OWNER});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom Apttus__APTS_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');

		qb = selector.newQueryBuilder(new Set<Object>{ApttusContractsSelector.Options.WITH_RECORDTYPE, ApttusContractsSelector.Options.WITH_OWNER});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom Apttus__APTS_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');
		System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom Apttus__APTS_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');

		qb = selector.newQueryBuilder(new Set<Object>{ApttusContractsSelector.Options.WITH_ORGANISATION});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Apttus__Account__r\\..*?\\bfrom Apttus__APTS_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select Organisation fields');

		qb = selector.newQueryBuilder(new Set<Object>{ApttusContractsSelector.Options.WITH_CONTACT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Apttus__Primary_Contact__r\\..*?\\bfrom Apttus__APTS_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select Primary Contact fields');

		qb = selector.newQueryBuilder(new Set<Object>{ApttusContractsSelector.Options.WITH_CREDIT_ASSESSMENT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Apttus_QPComply__RelatedProposalId__r.APT_Credit_Assessment__r\\..*?\\bfrom Apttus__APTS_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select related credit assessment fields');

		qb = selector.newQueryBuilder(new Set<Object>{ApttusContractsSelector.Options.WITH_PROPOSAL});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Apttus_QPComply__RelatedProposalId__r\\..*?\\bfrom Apttus__APTS_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select related proposal fields');

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

		List<Account> accountList = ApplicationTestDataFactory.getAccounts(2, false);
		insert accountList;
		Account account = accountList[0];
		Account chargeAccount = accountList[1];

		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		insert primaryContact;

		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
		insert opportunityRecord;

		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, false)[0];
		apttusContracts.Apttus__Account__c = account.Id;
		apttusContracts.Apttus__Agreement_Number__c='1234567';
		apttusContracts.Apttus__Version_Number__c=123;
		apttusContracts.APT_Pricing_Category__c='Standard';
		apttusContracts.Apttus__Status__c='Request';
		insert apttusContracts;

		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, false)[0];
		insert dealSupportRequest;

		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', false)[0];
		insert externalOnboardingRecord;


		Map<Id, Apttus__APTS_Agreement__c> mappedContracts = new Map<Id, Apttus__APTS_Agreement__c>(new List<Apttus__APTS_Agreement__c>{apttusContracts});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ApttusContractsSelector selector = ApttusContractsSelector.newInstance(1);
		Map<Id, Apttus__APTS_Agreement__c> results = selector.selectById(mappedContracts.keySet());
		System.assertEquals(1, results.size(), 'Result count was wrong');

		results = selector.selectById(mappedContracts.keySet(), new Set<Object>{ApttusContractsSelector.Options.WITH_RECORDTYPE, ApttusContractsSelector.Options.WITH_OWNER});

		System.assertEquals(1, results.size(), 'Result count was wrong');
		System.assertNotEquals(null, results.values()[0].RecordType, 'Expected RecordType object');
		System.assertNotEquals(null, results.values()[0].OwnerId, 'Expected Owner object');

		Database.QueryLocator queryLocator = ApttusContractsSelector.newInstance().selectByAccountOrderByAccountIdQueryLocator(new Set<Id>(), new Set<Object>{ApttusContractsSelector.Options.WITH_ORGANISATION});
		List<Apttus__APTS_Agreement__c> resultsList = (List<Apttus__APTS_Agreement__c>) Database.query(queryLocator.getQuery());
		System.assertEquals(1, resultsList.size(), 'Expected to return Apttus contracts related to any account when account id is not specified');

		//CI-703 test for Search Method
		List<Apttus__APTS_Agreement__c> cons = ApttusContractsSelector.newInstance().Search(new Map<String, Object>{'accountIds' => new Set<Id>{account.id},'pricingCategories'=>new Set<String>{'Standard'},'status'=>new Set<String>{'Request'}},true);
		System.assertEquals(1, cons.size(), 'Expected to return Apttus contracts related to any account');
		Test.stopTest();

	}
}