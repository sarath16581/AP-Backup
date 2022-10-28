/**
* @author Seth Heang
* @date 2021-06-09
* @group Tests
* @tag Selector
* @tag APT_Agreement_Lodgement_Point__c SObject
* @domain Apttus
* @description A very simple selector class that sits in the base domain
* @changelog
* 2021-06-09 - Seth Heang - Created
* 2022-06-01 - Seth Heang - Updated test method to include Billing Acc, Charge Acc Req and Sub Acc Req related lists
*/
@IsTest
private with sharing class APT_AgreementLodgementPointsSelectorTest {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedList() {

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

		APT_AgreementLodgementPointsSelector selector = APT_AgreementLodgementPointsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom APT_Agreement_Lodgement_Point__c\\b').matcher(soql).find(), 'Resulting query does not select from agreement lodgement point object');

		qb = selector.newQueryBuilder(new Set<Object>{APT_AgreementLodgementPointsSelector.Options.WITH_NETWORK});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)APT_Lodgement_Point_Lookup__r\\..*?\\bfrom APT_Agreement_Lodgement_Point__c\\b').matcher(soql).find(), 'Resulting query does not select related network fields');

		qb = selector.newQueryBuilder(new Set<Object>{APT_AgreementLodgementPointsSelector.Options.WITH_BILLING_ACCOUNT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)APT_Billing_Account__r\\..*?\\bfrom APT_Agreement_Lodgement_Point__c\\b').matcher(soql).find(), 'Resulting query does not select related billing account fields');

		qb = selector.newQueryBuilder(new Set<Object>{APT_AgreementLodgementPointsSelector.Options.WITH_CHARGE_ACCOUNT_REQ});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)APT_Charge_Account__r\\..*?\\bfrom APT_Agreement_Lodgement_Point__c\\b').matcher(soql).find(), 'Resulting query does not select related charge account request fields');

		qb = selector.newQueryBuilder(new Set<Object>{APT_AgreementLodgementPointsSelector.Options.WITH_SUB_ACCOUNT_REQ});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)APT_Sub_Account__r\\..*?\\bfrom APT_Agreement_Lodgement_Point__c\\b').matcher(soql).find(), 'Resulting query does not select related sub account request fields');

		qb = selector.newQueryBuilder(new Set<Object>{APT_AgreementLodgementPointsSelector.Options.WITH_ORGANISATION});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)APT_Organisation__r\\..*?\\bfrom APT_Agreement_Lodgement_Point__c\\b').matcher(soql).find(), 'Resulting query does not select related organisation fields');

		qb = selector.newQueryBuilder(new Set<Object>{APT_AgreementLodgementPointsSelector.Options.WITH_CONTRACT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)APT_Agreement__r\\..*?\\bfrom APT_Agreement_Lodgement_Point__c\\b').matcher(soql).find(), 'Resulting query does not select related contract fields');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is querying the correct output including related fields
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		Account acc = ApplicationTestDataFactory.getAccounts(1, false)[0]; 
		insert acc;
		Contact con = ApplicationTestDataFactory.getContacts(1, acc.id, false)[0];
		insert con;
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, acc.id, false)[0];
		insert opp;
		Apttus__APTS_Agreement__c contract = ApplicationTestDataFactory.getApttusContracts(1, con.Id, opp.Id, false)[0];
		insert contract;
		APT_Agreement_Lodgement_Point__c agreementLP = ApplicationTestDataFactory.getAgreementLodgementPoints(1, null, contract.Id,acc.Id, false)[0];
		insert agreementLP;

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// Query Agreement Lodgement Point based on Apttus Contract Id
		Map<Id, APT_Agreement_Lodgement_Point__c> results = new Map<Id, APT_Agreement_Lodgement_Point__c>(
			APT_AgreementLodgementPointsSelector.newInstance(1).selectByApttusContractId(
			new Set<id>{contract.Id},
			new set<object>{
				APT_AgreementLodgementPointsSelector.Options.WITH_NETWORK,
				APT_AgreementLodgementPointsSelector.Options.WITH_BILLING_ACCOUNT,
				APT_AgreementLodgementPointsSelector.Options.WITH_CHARGE_ACCOUNT_REQ,
				APT_AgreementLodgementPointsSelector.Options.WITH_SUB_ACCOUNT_REQ
			}));
			
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		Test.stopTest();
	}
}