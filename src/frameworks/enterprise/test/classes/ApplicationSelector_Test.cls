/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Test
 * @domain Core
 * @description Test Class covering ApplicationSelector
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2022-04-12 - Ranjeewa Silva - Added tests to verify the use of WITHOUT_DEFAULT_ORDER option to build queries with no default ordering applied
 * 2024-03-07 - Mahesh Parvathaneni - Added test method testEnsureQueryBuilderProducesCorrectStringWithForUpdate to verify the use of FOR UPDATE 
 */
@IsTest
public class ApplicationSelector_Test {

	@IsTest
	public static void testClassNameReturnsCorrectValue() {
		AccountsSelector selector = new AccountsSelector();
		System.assertEquals('AccountsSelector', selector.className, 'Class name property did not calculate correctly');
	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithoutSubQueries() {

		AccountsSelector selector = new AccountsSelector();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select from Account');

		// a bit dumb but should be ok for verification
		for(SObjectField field : selector.getSObjectFieldList()) {
			System.assertEquals(true, Pattern.compile('(?ism)\\b' + field + '\\b').matcher(soql).find(), 'Resulting query does not select ' + field);
		}

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithLimit() {

		AccountsSelector selector = new AccountsSelector();
		selector.setLimit(5);
		selector.setOffset(10);

		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select from Account: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?LIMIT 5').matcher(soql).find(), 'Resulting query does not include a LIMIT: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?OFFSET 10').matcher(soql).find(), 'Resulting query does not include an OFFSET: ' + soql);

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithForUpdate() {

		AccountsSelector selector = new AccountsSelector();
		selector.setLimit(5);
		selector.setOffset(10);
		selector.setForUpdate(true);

		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select from Account: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?LIMIT\\s+5\\s+FOR\\s+UPDATE\\s*$').matcher(soql).find(), 'Resulting query does not include a FOR UPDATE: ' + soql);
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?LIMIT 5').matcher(soql).find(), 'Resulting query does not include a LIMIT: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\bfrom account\\b.*?OFFSET 10').matcher(soql).find(), 'Resulting query should not set Order By when FOR UPDATE is used:' + soql);

	}

	/**
	 * Test:
	 *
	 */
	@IsTest
	public static void testCreateableFields() {

		AccountsSelector selector = new AccountsSelector();
		selector.setFieldOverrides(new Set<SObjectField>{Account.Id, Account.Name, Account.AccountSource});

		Set<SObjectField> creatableFields = new Set<SObjectField>(selector.getCreateableFields());
		System.assert(creatableFields.contains(Account.Name));
		System.assert(creatableFields.contains(Account.AccountSource));

		Set<SObjectField> allCreatableFields = ApplicationSelector.getAllCreatableFieldsBySObjectType(Account.SObjectType);
		System.assert(!allCreatableFields.isEmpty());

		selector = new AccountsSelector();
		selector.setFieldOverrides(new Map<SObjectType, Set<SObjectField>>{Account.SObjectType => new Set<SObjectField>{Account.Id, Account.Name, Account.AccountSource}});

		creatableFields = new Set<SObjectField>(selector.getCreateableFields());
		System.assert(creatableFields.contains(Account.Name));
		System.assert(creatableFields.contains(Account.AccountSource));

	}

	/**
	 * Test:
	 *
	 */
	@IsTest
	public static void testIdFieldOnlyOption() {

		AccountsSelector selector = new AccountsSelector();

		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ApplicationSelector.Options.ID_FIELD_ONLY});
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)select\\s+id\\s+from\\s+account').matcher(soql).find(), 'Resulting query does not select Id field only from Account: ' + soql);

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testFieldOverridesProduceCorrectString() {

		AccountsSelector selector = new AccountsSelector();
		selector.setFieldOverrides(new Set<SObjectField>{Account.Id, Account.Name, Account.AccountSource});

		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(false, Pattern.compile('(?ism)\\bownerid\\b').matcher(soql).find(), 'Resulting query selects OwnerId from Account: ' + soql);

	}

	/**
	 * Test: Ensures that selectors Query Builder is not applying default order when ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER
	 *		selector option is used.
	 */
	@IsTest
	public static void testWithoutDefaultOrderOption() {

		AccountsSelector selector = new AccountsSelector();

		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER});
		String soql = qb.toSoqlString();
		System.assertEquals(false, Pattern.compile('(?ism)\\bfrom account\\b.*?Order\\s+By\\s').matcher(soql).find(), 'Resulting query includes order by clause, but it should not: ' + soql);
	}

	// TODO: Activate Cache
	//	/**
	//	 * Test:
	//	 *  Ensure that Application Selector is caching what it should
	//	 */
	//	public static testMethod void testEnsureCacheByRecordIdFunctionsCorrectly() {
	//
	//		List<Id> accountIds = new List<Id>();
	//		Map<Id, Account> accounts = new Map<Id, Account>();
	//
	//		// pseudo records (not actually inserted to db)
	//		accountIds.add(fflib_IDGenerator.generate(Account.SObjectType));
	//		accountIds.add(fflib_IDGenerator.generate(Account.SObjectType));
	//
	//		Account acc = new Account(Id = accountIds[0], Name = 'Test 1');
	//		accounts.put(acc.Id, acc);
	//
	//		acc = new Account(Id = accountIds[1], Name = 'Test 2');
	//		accounts.put(acc.Id, acc);
	//
	//		AccountsSelector selector = new AccountsSelector();
	//
	//		// make sure the cache is empty
	//		ApplicationSelector.CacheResult result = ApplicationSelector.Cache.getByRecordId(selector, new Set<Id>(accountIds), 'selectById', 0);
	//		System.assertEquals(0, result.recordIds.size());
	//		System.assertEquals(0, result.rows.size());
	//
	//		// add both records to the cache
	//		ApplicationSelector.Cache.putByRecordId(selector, accounts, 'selectById', 0);
	//
	//		// try and retrieve just 1 record and ensure we only get 1 result
	//		result = ApplicationSelector.Cache.getByRecordId(selector, new Set<Id>{accountIds[0]}, 'selectById', 0);
	//		System.assertEquals(accountIds[0], new List<Id>(result.recordIds)[0]);
	//		System.assertEquals(1, result.recordIds.size());
	//
	//	}
	//
	//	/**
	//	 * Test:
	//	 *  Ensure that Application Selector is caching what it should by related value
	//	 */
	//	public static testMethod void testEnsureCacheByRelatedValueFunctionsCorrectly() {
	//
	//		// pseudo records (not actually inserted to db)
	//		List<Id> accountIds = new List<Id>();
	//		Map<Id, Account> accounts = new Map<Id, Account>();
	//		accountIds.add(fflib_IDGenerator.generate(Account.SObjectType));
	//		accountIds.add(fflib_IDGenerator.generate(Account.SObjectType));
	//
	//		Account acc = new Account(Id = accountIds[0], Name = 'Test 1');
	//		accounts.put(acc.Id, acc);
	//		acc = new Account(Id = accountIds[1], Name = 'Test 2');
	//		accounts.put(acc.Id, acc);
	//
	//		List<Id> contactIds = new List<Id>();
	//		Map<Id, Contact> contacts = new Map<Id, Contact>();
	//		contactIds.add(fflib_IDGenerator.generate(Contact.SObjectType));
	//		contactIds.add(fflib_IDGenerator.generate(Contact.SObjectType));
	//		contactIds.add(fflib_IDGenerator.generate(Contact.SObjectType));
	//		contactIds.add(fflib_IDGenerator.generate(Contact.SObjectType));
	//
	//		Contact con = new Contact(Id = contactIds[0], AccountId = accountIds[0], FirstName = 'Test 1', LastName = 'Test 1');
	//		contacts.put(con.Id, con);
	//		con = new Contact(Id = contactIds[1], AccountId = accountIds[0], FirstName = 'Test 2', LastName = 'Test 2');
	//		contacts.put(con.Id, con);
	//		con = new Contact(Id = contactIds[2], AccountId = accountIds[1], FirstName = 'Test 3', LastName = 'Test 3');
	//		contacts.put(con.Id, con);
	//		con = new Contact(Id = contactIds[3], AccountId = accountIds[1], FirstName = 'Test 4', LastName = 'Test 4');
	//		contacts.put(con.Id, con);
	//
	//		ContactsSelector selector = new ContactsSelector();
	//
	//		// add all contact records to the cache
	//		ApplicationSelector.Cache.putByRelatedValue(selector, contacts, Contact.AccountId, 'selectByAccountId', 0);
	//
	//		// try and retrieve all contact records from a single account and ensure we only get 2 contact records returned
	//		ApplicationSelector.CacheResult result = ApplicationSelector.Cache.getByRelatedValue(selector, new Set<String>{accountIds[0]}, 'selectByAccountId', 0);
	//		System.assertEquals(1, result.relatedValues.size());
	//		System.assertEquals(accountIds[0], new List<String>(result.relatedValues)[0]);
	//		System.assertEquals(2, result.rows.size());
	//
	//	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSearchParamValidation() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

	

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		MySelector selector = new MySelector();

		try {
			selector.validateSearchParams(new Set<String>{'invalidParam'});
			System.assert(true);
		} catch(ApplicationSelector.SelectorException ex) {
			System.assert(true);
		} catch(Exception ex) {
			System.assert(false);
		}

		selector.validateSearchParams(new Set<String>{'param1', 'param2'});

		System.assert(true); // :)

		Test.stopTest();
	}

	private class MySelector extends ApplicationSelector {
		public override SObjectType getSObjectType() {
			return Account.getSObjectType();
		}

		public virtual override Set<SObjectField> getSObjectFieldList() {
			return new Set<SObjectField>{
				Account.Id
			};
		}

		public void validateSearchParams(Set<String> paramKeys) {
			super.validateSearchParams(paramKeys, new Set<String>{'param1', 'param2', 'param3', 'param4'});
		}
	}


	public class AccountsSelector extends ApplicationSelector {

		public override SObjectType getSObjectType() {
			return Account.getSObjectType();
		}

		public virtual override Set<SObjectField> getSObjectFieldList() {
			return new Set<SObjectField> {
					Account.Id, Account.Name, Account.Type, Account.OwnerId
			};
		}

	}

	public class ContactsSelector extends ApplicationSelector {

		public override SObjectType getSObjectType() {
			return Contact.getSObjectType();
		}

		public virtual override Set<SObjectField> getSObjectFieldList() {
			return new Set<SObjectField> {
					Contact.Id, Contact.AccountId, Contact.FirstName, Contact.LastName, Account.OwnerId
			};
		}

	}

}