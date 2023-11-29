/**
* @author Seth Heang
* @date 2021-05-12
* @group Tests
* @tag Selector
* @tag APT_Sub_Account__c SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-12-18 - Seth Heang - Created
* 2022-05-30 - Seth Heang - updated getSObjectFieldList, Added selectByProposalId and Added WITH_ORGANISATION related list
* 2023-10-27 - Harry Wang - Added tests for selectByChargeAccountId and selectByBillingAccountId and option FILTER_UNPROVISIONED_FOLLOWER_ONLY, FILTER_DRAFT_ERROR
* 2023-10-30 - Ranjeewa Silva - Updated tests for selecting related billing account fields
 */
@IsTest
private with sharing class SubAccountRequestsSelector_Test {

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectString() {

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

		SubAccountRequestsSelector selector = SubAccountRequestsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APT_Sub_Account__c\\b').matcher(soql).find(), 'Resulting query does not select from opportunity product classification');

		Test.stopTest();

	}
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is querying with related list
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

		SubAccountRequestsSelector selector = SubAccountRequestsSelector.newInstance(1);
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{
			SubAccountRequestsSelector.Options.WITH_SUB_ACCOUNT_CONTACT,
			SubAccountRequestsSelector.Options.WITH_ORGANISATION,
			SubAccountRequestsSelector.Options.WITH_BILLING_ACCOUNT,
			SubAccountRequestsSelector.Options.WITH_ST_PARENT_BILLING_ACCOUNT
		});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)SubAccountContact__r\\..*?\\bfrom APT_Sub_Account__c\\b').matcher(soql).find(), 'Resulting query does not select sub account contact field');
		System.assertEquals(true, Pattern.compile('(?ism)APT_Organisation__r\\..*?\\bfrom APT_Sub_Account__c\\b').matcher(soql).find(), 'Resulting query does not select organisation field');
		System.assertEquals(true, Pattern.compile('(?ism)APT_Billing_Account__r\\..*?\\bfrom APT_Sub_Account__c\\b').matcher(soql).find(), 'Resulting query does not select billing account field');
		System.assertEquals(true, Pattern.compile('(?ism)ParentBillingAccount__r\\..*?\\bfrom APT_Sub_Account__c\\b').matcher(soql).find(), 'Resulting query does not select StarTrack parent billing account field');

		Test.stopTest();

	}

	/**
	* Test:
	*  Executes a query to ensure it returns expected results with actual inserted data
	*/
	@IsTest
	public static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		Account acc = ApplicationTestDataFactory.getAccounts(1, false)[0];
		acc.LEGACY_ID__c = '60000000';
		insert acc;
		//TODO: fix test failure and update feature branch. This is the last file
		Billing_Account__c billingAccount = ApplicationTestDataFactory.getBillingAccounts(1, acc.Id, 'TEAM', false)[0];
		insert billingAccount;
		Contact con = ApplicationTestDataFactory.getContacts(1, acc.Id, false)[0];
		insert con;
		Apttus_Proposal__Proposal__c proposal = ApplicationTestDataFactory.getApttusProposals(1, con.Id, false)[0];
		insert proposal;
		APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,false)[0];
		insert chargeAccountRequest;

		APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',false)[0];
		subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
		subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
		subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
		subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
		//subAccountRequest.SubAccountContact__c = contact.id;
		subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
		subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
		subAccountRequest.APT_Postal_Address_State__c = 'VIC';
		subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
		subAccountRequest.Name = 'Seth 1';
		subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
		subAccountRequest.APT_Charge_Account__c = chargeAccountRequest.Id;
		subAccountRequest.APT_Sub_Account_Request_Status__c = 'Draft';
		subAccountRequest.APT_Quote_Proposal__c = proposal.Id;
		insert subAccountRequest;
		subAccountRequest.APT_Sub_Account_Request_Status__c = 'Pending Charge Account';
		update subAccountRequest;

		APT_Sub_Account__c subAccountRequest2 = ApplicationTestDataFactory.getSubAccountRequest(1,'Test2',false)[0];
		subAccountRequest2.APT_Billing_Account__c = billingAccount.Id;
		subAccountRequest2.AccountType__c = 'Follower';
		subAccountRequest2.APT_Sub_Account_Request_Status__c = 'Draft';
		subAccountRequest2.APT_Charge_Account__c = chargeAccountRequest.Id;
		insert subAccountRequest2;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SubAccountRequestsSelector selector = SubAccountRequestsSelector.newInstance(1);


		Map<Id, APT_Sub_Account__c> resultsBySARID = selector.selectById(new Set<id>{subAccountRequest.Id});
		System.assertEquals(1, resultsBySARID.size(), 'Expected result size of 1');
		Map<Id, APT_Sub_Account__c> resultsByCARID = selector.selectByChargeAcountRequestIdAndStatus(new Set<id>{chargeAccountRequest.Id},new Set<String>{'Pending Charge Account'});
		System.assertEquals(1, resultsByCARID.size(), 'Expected result size of 1');

		List<APT_Sub_Account__c> resultsByProposalId = selector.selectByProposalId(
			new Set<id>{
				proposal.Id
			});
		System.assertEquals(1, resultsByProposalId.size(), 'Expected result size of 1');

		List<APT_Sub_Account__c> subAccounts = selector.selectByBillingAccountId(new Set<Id>{billingAccount.Id}, new Set<Object>{SubAccountRequestsSelector.Options.FILTER_UNPROVISIONED_FOLLOWER_ONLY});
		System.assertEquals(1, subAccounts.size(), 'Expecting 1');
		System.assertEquals(billingAccount.Id, subAccounts[0].APT_Billing_Account__c, 'Id not matched');

		List<APT_Sub_Account__c> subAccounts2 = selector.selectByChargeAccountId(new Set<Id>{chargeAccountRequest.Id}, new Set<Object>{SubAccountRequestsSelector.Options.FILTER_DRAFT_ERROR});
		System.assertEquals(1, subAccounts2.size(), 'Expecting 1');
		System.assertEquals(chargeAccountRequest.Id, subAccounts2[0].APT_Charge_Account__c, 'Id not matched');
		Test.stopTest();
	}
}