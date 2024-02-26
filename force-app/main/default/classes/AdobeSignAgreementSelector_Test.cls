/***
 * @author Hasantha Liyanage
 * @date 2024-02-22
 * @domain Core
 * @description Test class for AdobeSignAgreementSelector
 * @changelog
 ***/

@IsTest
private class AdobeSignAgreementSelector_Test {
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

		AdobeSignAgreementSelector selector = AdobeSignAgreementSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom echosign_dev1__SIGN_Agreement__c\\b').matcher(soql).find(), 'Resulting query does not select from Contact');

		AdobeSignAgreementSelector selector1 = AdobeSignAgreementSelector.newInstance(1);
		QueryBuilder qb1 = selector1.newQueryBuilder();
		String soql1 = qb1.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\blimit 1\\b').matcher(soql1).find(), 'Resulting query does not have limit');

		Set<SObjectField> fieldOverrides=new Set<SObjectField>{echosign_dev1__SIGN_Agreement__c.Id, echosign_dev1__SIGN_Agreement__c.ApttusContract__c};
		AdobeSignAgreementSelector selector2 = AdobeSignAgreementSelector.newInstance(1,fieldOverrides);
		QueryBuilder qb2 = selector2.newQueryBuilder();
		String soql2 = qb2.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bid\\b').matcher(soql2).find(), 'Resulting query does not do filter overrides');

		Map<SObjectType, Set<SObjectField>> fieldOverrides2 = new Map<SObjectType, Set<SObjectField>>{
				Contact.SObjectType => new Set<SObjectField>{Contact.Id, Contact.AccountId, Contact.Name, Contact.Status__c, Contact.BillingAccount__c, Contact.OID_ID__c},
				Apttus__APTS_Agreement__c.SObjectType => new Set<SObjectField>{Apttus__APTS_Agreement__c.Id}
		};
		AdobeSignAgreementSelector selector3 = AdobeSignAgreementSelector.newInstance(1,fieldOverrides2);
		QueryBuilder qb3 = selector2.newQueryBuilder();
		String soql3 = qb3.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bid\\b').matcher(soql3).find(), 'Resulting query does not do filter overrides');

		Test.stopTest();

	}

	@IsTest
	private static void testSelectorIntegration() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		Account account = ApplicationTestDataFactory.getAccounts(2, false)[0];
		insert account;
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		insert primaryContact;
		Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
		insert opportunityRecord;
		// create contract
		Apttus__APTS_Agreement__c apttusContract = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunityRecord.Id, false)[0];
		insert apttusContract;

		List <echosign_dev1__SIGN_Agreement__c>  accountAgreements = ApplicationTestDataFactoryAdobeSign.getAgreementsForAccount(2, 'Draft', account.Id, false);
		accountAgreements[0].echosign_dev1__Status__c = 'Out for Signature';
		accountAgreements[1].echosign_dev1__Status__c = 'Waiting for Counter-Signature';
		insert accountAgreements;

		List <echosign_dev1__SIGN_Agreement__c>  contractAgreements = ApplicationTestDataFactoryAdobeSign.getDraftAgreementsForApttusContract(2, apttusContract.Id, false);
		insert contractAgreements;

		Map<Id, echosign_dev1__SIGN_Agreement__c> mappedContacts = new Map<Id, echosign_dev1__SIGN_Agreement__c>(accountAgreements);
		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AdobeSignAgreementSelector selector = AdobeSignAgreementSelector.newInstance(2);
		List<echosign_dev1__SIGN_Agreement__c> results = selector.selectById(mappedContacts.keySet());
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = selector.selectById(mappedContacts.keySet(), new Set<Object>{});
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = selector.selectByParentApttusContract(new Set<Id>{apttusContract.Id}, new Set<Object>{});
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = selector.selectOutForSignatureByApttusContractId(new Set<Id>{apttusContract.Id}, new Set<Object>{});
		System.assertEquals(2, results.size(), 'Expected result size of 2');
/*
		results = selector.selectByAccount(new Set<Id> {contacts[0].AccountId});
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = selector.selectById(mappedContacts.keySet(), new Set<Object>{ContactsSelector.Options.WITH_RECORDTYPE, ContactsSelector.Options.WITH_OWNER, ContactsSelector.Options.WITH_ACCOUNT});
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = selector.selectByAccount(new Set<Id> {contacts[0].AccountId}, new Set<Object>{ContactsSelector.Options.WITH_RECORDTYPE, ContactsSelector.Options.WITH_OWNER, ContactsSelector.Options.WITH_ACCOUNT});
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = selector.selectByLikedNameOrderByConsumerAndNameNullFirst(contacts[0].FirstName);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		results = selector.selectByLikedAnyPhoneOrderByName(contacts[0].phone);
		//System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = selector.selectById(mappedContacts.keySet(), new Set<Object>{ContactsSelector.Options.WITH_BILLING_ACCOUNT});
		System.assertEquals(2, results.size(), 'Expected result size of 2');
		System.assertNotEquals(null, results.get(contacts[0].Id).BillingAccount__r, 'Expected billing account object');

		List<Contact> listResults = selector.selectPrimaryContactByAccount(new Set<Id> {acc.Id});
		System.assertEquals(1, listResults.size(), 'Expected result size of 1');*/

		Test.stopTest();

	}
}