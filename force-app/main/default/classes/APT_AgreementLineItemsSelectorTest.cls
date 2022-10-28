/* @author Seth Heang
 * @date 2022-06-01
 * @group Tests
 * @tag Selector
 * @domain Apttus
 * @description Test Class covering APT_AgreementLineItemsSelector
 * @changelog
 * 2022-06-01 - Seth Heang - Created
 */
@IsTest
public with sharing class APT_AgreementLineItemsSelectorTest {
	/**
	 * Test: Ensures that the selectors QueryBuilder is correctly querying from agreement line item
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringAndRelatedField() {
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

		APT_AgreementLineItemsSelector selector = APT_AgreementLineItemsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Apttus__AgreementLineItem__c\\b').matcher(soql).find(), 'Resulting query does not select from agreement line item');

		qb = selector.newQueryBuilder(new Set<Object>{APT_AgreementLineItemsSelector.Options.WITH_OPTION});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Apttus_CMConfig__OptionId__r\\..*?\\bfrom Apttus__AgreementLineItem__c\\b').matcher(soql).find(), 'Resulting query does not select related Option fields');

		qb = selector.newQueryBuilder(new Set<Object>{APT_AgreementLineItemsSelector.Options.WITH_AGREEMENT_ATTRIBUTE_VALUE});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Apttus_CMConfig__AttributeValueId__r\\..*?\\bfrom Apttus__AgreementLineItem__c\\b').matcher(soql).find(), 'Resulting query does not select related Attribute Value fields');

		qb = selector.newQueryBuilder(new Set<Object>{APT_AgreementLineItemsSelector.Options.WITH_CONTRACT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Apttus__AgreementId__r\\..*?\\bfrom Apttus__AgreementLineItem__c\\b').matcher(soql).find(), 'Resulting query does not select related Contract fields');

		qb = selector.newQueryBuilder(new Set<Object>{APT_AgreementLineItemsSelector.Options.WITH_PROPOSAL});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__r\\..*?\\bfrom Apttus__AgreementLineItem__c\\b').matcher(soql).find(), 'Resulting query does not select related Proposal fields');

		Test.stopTest();
	}

	/**
	 * Test: Ensures that the selectors is querying contractId and LineType and then return correct output
	 */
	@IsTest
	public static void testSelectByContractIdsAndLineType() {
		MockUtility.disableTriggerExecution();
		// =====================================
		// Data Preparation
		// =====================================
		Account acc = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert acc;
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, acc.Id, false)[0];
		insert opp;
		Contact con = ApplicationTestDataFactory.getContacts(1, acc.Id, false)[0];
		insert con;
		Apttus__APTS_Agreement__c contract = ApplicationTestDataFactory.getApttusContracts(1, con.Id, opp.id, false)[0];
		insert contract;
		Apttus__AgreementLineItem__c cliRec = APT_TestDataFactory.getAPTAgreementLineItem(1, false)[0];
		cliRec.Apttus_CMConfig__LineType__c = 'Product/Service';
		cliRec.Apttus__AgreementId__c = contract.Id;
		insert cliRec;
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		APT_AgreementLineItemsSelector selector = APT_AgreementLineItemsSelector.newInstance();
		Map<Id, Apttus__AgreementLineItem__c> results = new Map<Id, Apttus__AgreementLineItem__c>(selector.selectByContractIdsAndLineType(
			new Set<id>{contract.Id},
			new Set<String>{'Product/Service'},
			new Set<Object>{
				APT_AgreementLineItemsSelector.Options.WITH_CONTRACT, 
				APT_AgreementLineItemsSelector.Options.WITH_PROPOSAL
			}
		));
		
		System.assertEquals(1, results.size(), 'Result count was wrong');
		System.assertEquals(results.get(cliRec.Id).Id, cliRec.Id, 'Agreement line item Id does not match');

		Test.stopTest();
	}
}