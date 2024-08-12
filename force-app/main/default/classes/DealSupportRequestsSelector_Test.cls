/**
* @author Nathan Franklin
* @date 2021-01-12
* @group Tests
* @tag Selector
* @tag Deal Support Request SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-04-10 - arjun.singh@auspost.com.au - Created
* 2022-04-08 - seth.heang@auspost.com.au - updated test method to test search method
* 2022-12-01 - Harry Wang - added test method for selectByAccountRelationshipQueryLocator
* 2024-02-02 - Mahesh Parvathaneni - updated test method to include dsrIds to test search method
* 2024-08-10 - Harry Wang - added tests for selectByAtRiskBusinessId and selectByAccountId
*/
@IsTest
public with sharing class DealSupportRequestsSelector_Test {
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

		DealSupportRequestsSelector selector = DealSupportRequestsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select from Deal Support Request');

		Test.stopTest();

	}

	/**
	* Test:
	*  Ensures that the selectors QueryBuilder is generating the correct output
	*/
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringForFieldOverride() {
		Test.startTest();

		DealSupportRequestsSelector selector = DealSupportRequestsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select from Deal_Support_Request__c');

		selector = DealSupportRequestsSelector.newInstance(1, new Set<SObjectField>{
				Deal_Support_Request__c.Id
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select from Deal_Support_Request__c');

		selector = DealSupportRequestsSelector.newInstance(1, new Map<SObjectType, Set<SObjectField>>{
				Deal_Support_Request__c.SObjectType => new Set<SObjectField>{Deal_Support_Request__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select from Deal_Support_Request__c');

		selector = DealSupportRequestsSelector.newInstance(new Map<SObjectType, Set<SObjectField>>{
				Deal_Support_Request__c.SObjectType => new Set<SObjectField>{Deal_Support_Request__c.Id}
		});
		qb = selector.newQueryBuilder();
		soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select from Deal_Support_Request__c');
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

		DealSupportRequestsSelector selector = DealSupportRequestsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{DealSupportRequestsSelector.Options.WITH_RECORDTYPE});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');

		qb = selector.newQueryBuilder(new Set<Object>{DealSupportRequestsSelector.Options.WITH_OWNER});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');

		qb = selector.newQueryBuilder(new Set<Object>{DealSupportRequestsSelector.Options.WITH_RECORDTYPE, DealSupportRequestsSelector.Options.WITH_OWNER});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)RecordType\\..*?\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select RecordType fields');
		System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');
		
		qb = selector.newQueryBuilder(new Set<Object>{DealSupportRequestsSelector.Options.WITH_PRIMARYCONTACT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)APT_Contract__r.Apttus__Primary_Contact__r\\..*?\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select Primary Contact fields');

		qb = selector.newQueryBuilder(new Set<Object>{DealSupportRequestsSelector.Options.WITH_CHARGE_ACCOUNT_REQUEST});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)APT_Contract__r.Apttus_QPComply__RelatedProposalId__r.APT_Credit_Assessment__r.APT_Charge_Account__r\\..*?\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select Charge Request fields');

		qb = selector.newQueryBuilder(new Set<Object>{DealSupportRequestsSelector.Options.WITH_CREDIT_ASSESSMENT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)APT_Contract__r.Apttus_QPComply__RelatedProposalId__r.APT_Credit_Assessment__r\\..*?\\bfrom Deal_Support_Request__c\\b').matcher(soql).find(), 'Resulting query does not select Credit Assessement  fields');

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

		At_Risk_Business__c atRiskBusiness = ApplicationTestDataFactory.getAtRiskBusiness(1, account.Id, false)[0];
		insert atRiskBusiness;

		/*APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,false)[0];
		insert chargeAccountRequest;

		APT_Credit_Assessment__c apttusCreditAssessment = ApplicationTestDataFactory.getApttusCreditsAssessment(1, chargeAccountRequest.Id, false)[0];
		insert apttusCreditAssessment ;

		Apttus_Proposal__Proposal__c apttusProposals = ApplicationTestDataFactory.getApttusProposals(1, primaryContact.Id, false)[0];
		insert apttusProposals;

		Apttus__APTS_Agreement__c apttusContracts = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, false)[0];
		insert apttusContracts;*/
		
		Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, false)[0];
		Id psrAPPCRecTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Deal_Support_Request__c', new Set<String>{APT_Constants.PSR_APPC_RECORD_TYPE_APINAME}).values()[0].Id;
		dealSupportRequest.recordTypeId = psrAPPCRecTypeId;
		dealSupportRequest.product__c = APT_Constants.PSR_APPC_PRODUCT_NAME;
		dealSupportRequest.Returns__c = true;
		dealSupportRequest.Business_At_Risk__c = atRiskBusiness.Id;
		insert dealSupportRequest;

		BAMExternalOnboardingRequest__c externalOnboardingRecord = ApplicationTestDataFactory.getBAMExternalOnboardingRequests(1,dealSupportRequest.Id, 'Deal_Support_Request__c', false)[0];
		insert externalOnboardingRecord;
		
		/* apttusCreditAssessment.APT_Proposal__c = apttusProposals.Id;
		apttusCreditAssessment.APT_Charge_Account__c = chargeAccountRequest.Id;
		apttusProposals.APT_Credit_Assessment__c = apttusCreditAssessment.Id;
		apttusContracts.Apttus_QPComply__RelatedProposalId__c = apttusProposals.Id;
		apttusContracts.Apttus__Account__c = account.Id;
		dealSupportRequest.APT_Contract__c = apttusContracts.Id;*/

		Map<Id, Deal_Support_Request__c> mappedDealSupports = new Map<Id, Deal_Support_Request__c>(new List<Deal_Support_Request__c>{dealSupportRequest});

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		DealSupportRequestsSelector selector = DealSupportRequestsSelector.newInstance(1);
		Map<Id, Deal_Support_Request__c> results = selector.selectById(mappedDealSupports.keySet());
		System.assertEquals(1, results.size(), 'Result count was wrong');
		results = selector.selectById(mappedDealSupports.keySet(), new Set<Object>{DealSupportRequestsSelector.Options.WITH_RECORDTYPE, DealSupportRequestsSelector.Options.WITH_OWNER});
		
		System.assertEquals(1, results.size(), 'Result count was wrong');
		System.assertNotEquals(null, results.values()[0].RecordType, 'Expected RecordType object');
		System.assertNotEquals(null, results.values()[0].OwnerId, 'Expected Owner object');

		Map<Id, Deal_Support_Request__c> resultsforMultipleDSR = selector.selectByRecordList(new List<Deal_Support_Request__c>{dealSupportRequest});
		System.assertEquals(1, resultsforMultipleDSR.size(), 'Result count was wrong');

		DealSupportRequestsSelector selector2 = DealSupportRequestsSelector.newInstance(1, new Set<SObjectField>{
			Deal_Support_Request__c.Id,
			Deal_Support_Request__c.Name,
			Deal_Support_Request__c.Product__c,
			Deal_Support_Request__c.Opportunity__c,
			Deal_Support_Request__c.RecordTypeId
		});
		
		Map<String, Object> searchParams = new Map<String, Object>();
		searchParams.put('opportunityIds', new Set<Id>{opportunityRecord.Id});
		searchParams.put('recTypeIds', new Set<Id>{psrAPPCRecTypeId});
		searchParams.put('productNames', new Set<String>{APT_Constants.PSR_APPC_PRODUCT_NAME});
		searchParams.put('dsrIds', new Set<String>{results.values()[0].Name});
		List<Deal_Support_Request__c> resultsforAPPCPSRList = selector2.search(searchParams, new Set<Object>(), true);
		System.assertEquals(1, resultsforAPPCPSRList.size(), 'Result count was wrong');

		Set<Id> accountIds = new Set<Id>{account.Id};
		Database.QueryLocator queryLocator = DealSupportRequestsSelector.newInstance().selectByAccountOrderByAccountIdQueryLocator(accountIds, new Set<Object>{
				DealSupportRequestsSelector.Options.WITH_ORGANISATION
		});

		List<Deal_Support_Request__c> queryResults = (List<Deal_Support_Request__c>)Database.query(queryLocator.getQuery());

		System.assertEquals(1, queryResults.size(), 'Expected to return only the DSRs related to the supplied account');
		System.assertEquals(dealSupportRequest.Id, queryResults[0].Id, 'Expected to return only the DSRs related to the supplied account');

		queryResults = selector.selectByAtRiskBusinessId(new Set<Id>{atRiskBusiness.Id}, new Set<Object>());
		System.assertEquals(dealSupportRequest.Id, queryResults[0].Id, 'Id not matched');

		Set<SObjectField> fieldOverrides = new Set<SObjectField>{Deal_Support_Request__c.Id, Deal_Support_Request__c.Organisation__c};
		queryResults = DealSupportRequestsSelector.newInstance(1, fieldOverrides).selectByAccountId(accountIds, new Set<Object>{DealSupportRequestsSelector.Options.WITH_OPPORTUNITY});
		System.assertEquals(account.Id, queryResults[0].Organisation__c, 'Parent account not matched');
		System.assertEquals(opportunityRecord.Id, queryResults[0].Opportunity__r.Id, 'Opportunity not matched');
		Test.stopTest();

	}
}