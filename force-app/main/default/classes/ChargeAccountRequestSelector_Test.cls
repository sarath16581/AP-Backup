/* @author Nathan Franklin
 * @date 2020-10-06
 * @group Tests
 * @tag Selector
 * @tag ProposaltSelector 
 * @domain Core
 * @description Test Class covering ChargeAccountRequestSelector
 * @changelog
 * 2020-10-06 - Shashwat.Nath@austpost.com.au - Created
 * 2022-06-01 - Seth Heang - Add test coverage for selectByProposalId and WITH_ORGANISATION related list
 */
@IsTest
private class ChargeAccountRequestSelector_Test{

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

	ChargeAccountRequestSelector selector = ChargeAccountRequestSelector.newInstance();
	QueryBuilder qb = selector.newQueryBuilder();
	String soql = qb.toSoqlString();

	System.assertEquals(true, Pattern.compile('(?ism)\\bfrom APT_Charge_Account__c\\b').matcher(soql).find(), 'Resulting query does not select from charge Account');

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

	ChargeAccountRequestSelector selector = ChargeAccountRequestSelector.newInstance(1);
	QueryBuilder qb = selector.newQueryBuilder(new Set < Object > {
		ChargeAccountRequestSelector.Options.WITH_OWNER,
		ChargeAccountRequestSelector.Options.WITH_ORGANISATION
	});
	String soql = qb.toSoqlString();
	System.assertEquals(true, Pattern.compile('(?ism)owner\\..*?\\bfrom APT_Charge_Account__c\\b').matcher(soql).find(), 'Resulting query does not select owner field');
	System.assertEquals(true, Pattern.compile('(?ism)APT_Organisation__r\\..*?\\bfrom APT_Charge_Account__c\\b').matcher(soql).find(), 'Resulting query does not select organisation field');

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

	ChargeAccountRequestSelector selector = ChargeAccountRequestSelector.newInstance(0, new Map < SObjectType, Set < SObjectField >> {
		APT_Charge_Account__c.SObjectType => new Set < SObjectField > {
			APT_Charge_Account__c.Name,
			APT_Charge_Account__c.Ownerid
		}
	});
	QueryBuilder qb = selector.newQueryBuilder(new Set < Object > {
		ChargeAccountRequestSelector.Options.WITH_OWNER,
		AccountsSelector.Options.WITH_RECORDTYPE
	});
	String soql = qb.toSoqlString();
	System.assertEquals(true, Pattern.compile('(?ism)owner.*?\\bfrom APT_Charge_Account__c\\b').matcher(soql).find(), 'Resulting query does not select owner field: ' + soql);
	System.assertEquals(true, Pattern.compile('(?ism)Name.*?\\bfrom APT_Charge_Account__c\\b').matcher(soql).find(), 'Resulting query does not select Name field: ' + soql);

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
		Account acc = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert acc;
		Contact con = ApplicationTestDataFactory.getContacts(1, acc.Id, false)[0];
		insert con;
		Apttus_Proposal__Proposal__c proposal = ApplicationTestDataFactory.getApttusProposals(1, con.Id, false)[0];
		insert proposal;

		List<APT_Charge_Account__c> chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,false);
		chargeAccountRequest[0].APT_Quote_Proposal__c = proposal.Id;
		insert chargeAccountRequest;

		Map<Id, APT_Charge_Account__c> mappedChargeAccounts = new Map<Id, APT_Charge_Account__c>(chargeAccountRequest);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ChargeAccountRequestSelector selector = ChargeAccountRequestSelector.newInstance(1, new Set<SObjectField>());
		Map<Id, APT_Charge_Account__c> results = selector.selectById(mappedChargeAccounts.keySet());
		System.assertEquals(1, results.size(), 'Result count was wrong');

		List<APT_Charge_Account__c> selectByProposalResult = selector.selectByProposalId(new Set<Id>{proposal.Id});
		System.assertEquals(1, selectByProposalResult.size(), 'Result count was wrong');
		Test.stopTest();
	}
}