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
public with sharing class ContactPointPhoneSelector_Test {
	@IsTest
	private static void ensureQueryBuilderProducesCorrectString() {
		Test.startTest();
		ContactPointPhoneSelector selector = ContactPointPhoneSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		System.assertEquals(
			true,
			Pattern.compile('(?is)\\bfrom ContactPointPhone\\b').matcher(soql).find(),
			'Resulting query does not select from ContactPointPhone'
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

		List<ContactPointPhone> contactPointPhones = ApplicationTestDataFactory.getContactPointPhones(2, acc.Id, false);
		contactPointPhones[0].Contact__c = contacts[0].Id;
		contactPointPhones[0].TelephoneNumber = '+61211112222';
		contactPointPhones[0].PhoneType = 'Home';
		contactPointPhones[0].Verified__c = true;

		contactPointPhones[1].Contact__c = contacts[0].Id;
		contactPointPhones[1].TelephoneNumber = '+61404222222';
		contactPointPhones[1].PhoneType = 'Mobile';
		contactPointPhones[1].Verified__c = false;

		insert contactPointPhones;

		Map<Id, ContactPointPhone> contactPointPhoneMap = new Map<Id, ContactPointPhone>(contactPointPhones);

		Test.startTest();

		ContactPointPhoneSelector selector = ContactPointPhoneSelector.newInstance();
		List<ContactPointPhone> results = selector.selectById(contactPointPhoneMap.keySet());
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		results = selector.selectByContactAndPhoneNumber(new Set<Id>{ contacts[0].Id }, new List<String>(), new Set<Object>());
		System.assertEquals(0, results.size(), 'Expected result size of 0');

		results = selector.selectByContactAndPhoneNumber(
			new Set<Id>{ contacts[0].Id },
			new List<String>{ contactPointPhones[0].TelephoneNumber },
			new Set<Object>{ ContactPointPhoneSelector.Options.FILTER_HOMEPHONE }
		);
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		System.assertEquals(
			contactPointPhones[0].TelephoneNumber,
			results[0].TelephoneNumber,
			'Expected result should match on TelephoneNumber'
		);
		System.assertEquals(contactPointPhones[0].PhoneType, results[0].PhoneType, 'Expected result should match on PhoneType');

		results = selector.selectByContactAndPhoneNumber(
			new Set<Id>{ contacts[0].Id },
			new List<String>{ contactPointPhones[1].TelephoneNumber },
			new Set<Object>{ ContactPointPhoneSelector.Options.FILTER_HOMEPHONE }
		);
		System.assertEquals(0, results.size(), 'Expected result size of 0');

		results = selector.selectByContactAndPhoneNumber(
			new Set<Id>{ contacts[0].Id },
			new List<String>{ contactPointPhones[1].TelephoneNumber },
			new Set<Object>{ ContactPointPhoneSelector.Options.FILTER_MOBILEPHONE }
		);
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		System.assertEquals(
			contactPointPhones[1].TelephoneNumber,
			results[0].TelephoneNumber,
			'Expected result should match on TelephoneNumber'
		);
		System.assertEquals(contactPointPhones[1].PhoneType, results[0].PhoneType, 'Expected result should match on PhoneType');

		results = selector.selectByContactAndPhoneNumber(
			new Set<Id>{ contacts[0].Id },
			new List<String>{ contactPointPhones[0].TelephoneNumber },
			new Set<Object>{ ContactPointPhoneSelector.Options.FILTER_MOBILEPHONE }
		);
		System.assertEquals(0, results.size(), 'Expected result size of 0');

		results = selector.selectByContactAndPhoneNumber(
			new Set<Id>{ contacts[0].Id },
			new List<String>{ contactPointPhones[0].TelephoneNumber },
			new Set<Object>{ ContactPointPhoneSelector.Options.FILTER_HOMEPHONE, ContactPointPhoneSelector.Options.FILTER_VERIFIED_FALSE }
		);
		System.assertEquals(0, results.size(), 'Expected result size of 0');

		results = selector.selectByContactAndPhoneNumber(
			new Set<Id>{ contacts[0].Id },
			new List<String>{ contactPointPhones[1].TelephoneNumber },
			new Set<Object>{ ContactPointPhoneSelector.Options.FILTER_MOBILEPHONE, ContactPointPhoneSelector.Options.FILTER_VERIFIED_FALSE }
		);
		System.assertEquals(1, results.size(), 'Expected result size of 1');

		results = selector.selectByContact(new Set<Id>{ contacts[0].Id }, new Set<Object>());
		System.assertEquals(2, results.size(), 'Expected result size of 2');

		Test.stopTest();
	}
}