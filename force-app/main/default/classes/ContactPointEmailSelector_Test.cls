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
public with sharing class ContactPointEmailSelector_Test {
	@IsTest
	private static void ensureQueryBuilderProducesCorrectString() {
		Test.startTest();
		ContactPointEmailSelector selector = ContactPointEmailSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(
			true,
			Pattern.compile('(?is)\\bfrom ContactPointEmail\\b').matcher(soql).find(),
			'Resulting query does not select from ContactPointEmail'
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

		List<ContactPointEmail> contactPointEmails = ApplicationTestDataFactory.getContactPointEmails(2, acc.Id, false);
		contactPointEmails[0].Contact__c = contacts[0].Id;
		contactPointEmails[0].EmailAddress = 'test111@test1234.com';
		contactPointEmails[0].Verified__c = true;

		contactPointEmails[1].Contact__c = contacts[0].Id;
		contactPointEmails[0].EmailAddress = 'test222@test1234.com';
		contactPointEmails[1].Verified__c = false;

		insert contactPointEmails;

		Map<Id, ContactPointEmail> contactPointEmailMap = new Map<Id, ContactPointEmail>(contactPointEmails);

		Test.startTest();

		ContactPointEmailSelector selector = ContactPointEmailSelector.newInstance();
		List<ContactPointEmail> results = selector.selectById(ContactPointEmailMap.keySet());
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = selector.selectByContactAndEmail(new Set<Id>{ contacts[0].Id }, new List<String>(), new Set<Object>());
		System.assertEquals(0, results.size(), 'Expected result size of 0');

		results = selector.selectByContactAndEmail(
			new Set<Id>{ contacts[0].Id },
			new List<String>{ ContactPointEmails[0].EmailAddress },
			new Set<Object>()
		);
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		System.assertEquals(ContactPointEmails[0].EmailAddress, results[0].EmailAddress, 'Expected result should match on EmailAddress');

		results = selector.selectByContactAndEmail(
			new Set<Id>{ contacts[0].Id },
			new List<String>{ ContactPointEmails[0].EmailAddress },
			new Set<Object>{ ContactPointEmailSelector.Options.FILTER_VERIFIED_FALSE }
		);
		System.assertEquals(0, results.size(), 'Expected result size of 0');

		Set<SObjectField> fieldOverrides = new Set<SObjectField>{ContactPointEmail.EmailAddress};
		selector = ContactPointEmailSelector.newInstance(1, fieldOverrides);

		results = selector.selectByContactAndEmail(
			new Set<Id>{ contacts[0].Id },
			new List<String>{ ContactPointEmails[1].EmailAddress },
			new Set<Object>{ ContactPointEmailSelector.Options.FILTER_VERIFIED_FALSE }
		);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Map<SObjectType, Set<SObjectField>> fieldOverridesMap = new Map<SObjectType, Set<SObjectField>>{ContactPointEmail.getSObjectType() => new Set<SObjectField> {ContactPointEmail.EmailAddress}};
		selector = ContactPointEmailSelector.newInstance(1, fieldOverridesMap);

		results = selector.selectByParentId(
			new Set<Id>{ acc.Id },
			new Set<Object>{ ContactPointEmailSelector.Options.WITH_CONTACT }
		);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		Test.stopTest();
	}
}