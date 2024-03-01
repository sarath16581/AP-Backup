/**
 * @description Test class for TransactionSecurityPolicyUtil
 * @author Naveen Rajanna
 * @date 2024-02-20
 * @group Tests
 * @changelog
 * 2024-02-20 - Naveen Rajanna - created - REQ3445775.
*/

@isTest
public class TransactionSecurityPolicyUtil_Test {

	@isTest
	private static void testIsSystemSupportUser() {
		User user = ApplicationTestDataFactory.getUsers(1, true)[0];
		ConfigSetting__c configSetting = new ConfigSetting__c(AutomatedCaseUser__c = user.Id);
		insert configSetting;
		Test.startTest();
			Boolean result = TransactionSecurityPolicyUtil.isSystemSupportUser(user.Id);
		Test.stopTest();
		System.Assert.areEqual(true, result, 'System Support User Id doesnt match');
	}

	@isTest
	private static void testIsSystemAdministrator() {
		User user = ApplicationTestDataFactory.getUsers(1, false)[0];
		insert user;
		Test.startTest();
			Boolean result = TransactionSecurityPolicyUtil.isSystemAdministrator(user.Id);
		Test.stopTest();
		System.Assert.areEqual(true, result, 'User must be System Administrator');
	}

	@isTest
	static void testParseFieldsByObjectFromColumnHeaders() {
		Test.startTest();
		
		// Test case: Column headers with simple field names
		String simpleHeaders = '[StreetAddress, Contact.Email],[Address, Email]';
		Map<String, Set<String>> result1 = TransactionSecurityPolicyUtil.parseFieldsByObjectFromColumnHeaders(simpleHeaders);
		Map<String, Set<String>> expected1 = new Map<String, Set<String>>{'Contact' => new Set<String>{'Contact.Email'}};

		// Test case: Column headers with hierarchical field names
		String hierarchicalHeaders = '[Contact.Email, Contact.Account.Name],[Email, AccountName]';
		Map<String, Set<String>> result2 = TransactionSecurityPolicyUtil.parseFieldsByObjectFromColumnHeaders(hierarchicalHeaders);
		Map<String, Set<String>> expected2 = new Map<String, Set<String>>{
			'Contact' => new Set<String>{'Contact.Email'},
			'Account' => new Set<String>{'Account.Name'}
		};

		// Test case: Column headers with mixed formats
		String mixedHeaders = '[StreetAddress, Contact.Email, Contact.Account.Name, Compensation__c.Number__c],[Address, Email, AccountName, Compensation]';
		Map<String, Set<String>> result3 = TransactionSecurityPolicyUtil.parseFieldsByObjectFromColumnHeaders(mixedHeaders);
		Map<String, Set<String>> expected3 = new Map<String, Set<String>>{
			'Contact' => new Set<String>{'Contact.Email'},
			'Account' => new Set<String>{'Account.Name'},
			'Compensation__c' => new Set<String>{'Compensation__c.Number__c'}
		};
		Test.stopTest();

		System.assertEquals(new Map<String, Set<String>>(), TransactionSecurityPolicyUtil.parseFieldsByObjectFromColumnHeaders(null));
		System.assertEquals(new Map<String, Set<String>>(), TransactionSecurityPolicyUtil.parseFieldsByObjectFromColumnHeaders(''));
		System.assertEquals(new Map<String, Set<String>>(), TransactionSecurityPolicyUtil.parseFieldsByObjectFromColumnHeaders('[],[]'));
		System.assertEquals(expected1, result1);
		System.assertEquals(expected2, result2);
		System.assertEquals(expected3, result3);
	}	

	@isTest
	private static void testGetSensitiveFieldsByObjects() {
		CacheManager.settings.CacheEnabled__c = true;

		Test.startTest();
		Set<String> objectsToQuery = new Set<String>{'Compensation__c'};
		Set<String> expected = TransactionSecurityPolicyUtil.getSensitiveFieldsByObjects(objectsToQuery);
		Test.stopTest();

		Map<String, Set<String>> sensitiveFieldsByObjectMap = (Map<String, Set<String>>) CacheManager.get(TransactionSecurityPolicyUtil.CACHE_KEY_TSP_SENSITIVE_FIELDS_BY_OBJECT);
		Set<String> actual = sensitiveFieldsByObjectMap.get('Compensation__c');
		
		System.Assert.areEqual(expected.size(), actual.size(), 'Sensitive fields returned doesnt match');
	}

}