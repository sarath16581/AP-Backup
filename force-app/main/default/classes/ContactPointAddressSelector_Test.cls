/**
 * @author George Nguyen
 * @group Tests
 * @tag Selector
 * @tag Contact SObject
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2022-06-07- George Nguyen - Created
 */
@IsTest
public with sharing class ContactPointAddressSelector_Test {
	@IsTest
	private static void ensureQueryBuilderProducesCorrectString() {
		Test.startTest();
		ContactPointAddressSelector selector = ContactPointAddressSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(
			true,
			Pattern.compile('(?is)\\bfrom ContactPointAddress\\b').matcher(soql).find(),
			'Resulting query does not select from ContactPointAddress'
		);
		Test.stopTest();
	}

	@IsTest
	private static void queryingActualDB() {
		MockUtility.disableTriggerExecution();

		Account acc = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert acc;
		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, acc.Id, false);
		insert contacts;

		List<ContactPointAddress> cpas = ApplicationTestDataFactory.getContactPointAddresses(2, acc.Id, false);
		cpas[0].Contact__c = contacts[0].Id;
		cpas[0].Name = 'test 1';
		cpas[0].AddressType = 'Other';

		cpas[1].Contact__c = contacts[0].Id;
		cpas[1].Name = 'test 1';
		cpas[1].AddressType = 'Mailing';

		insert cpas;

		Map<Id, ContactPointAddress> cpasMap = new Map<Id, ContactPointAddress>(cpas);

		Test.startTest();

		ContactPointAddressSelector selector = ContactPointAddressSelector.newInstance();
		Map<Id, ContactPointAddress> results = new Map<Id, ContactPointAddress>(selector.selectById(cpasMap.keySet()));
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = new Map<Id, ContactPointAddress>(selector.selectByContactWithOtherOrMailingAddressType(new Set<Id>{ contacts[0].Id }));
		System.assertEquals(2, results.size(), 'Expected result size of 0');

		System.assertEquals(cpas[0].Name, results.get(cpas[0].id).Name, 'Expected result should match on Name');
		System.assertEquals(cpas[0].AddressType, results.get(cpas[0].id).AddressType, 'Expected result should match on AddressType');

		System.assertEquals(cpas[1].Name, results.get(cpas[1].id).Name, 'Expected result should match on Name');
		System.assertEquals(cpas[1].AddressType, results.get(cpas[1].id).AddressType, 'Expected result should match on AddressType');

		Test.stopTest();
	}
}