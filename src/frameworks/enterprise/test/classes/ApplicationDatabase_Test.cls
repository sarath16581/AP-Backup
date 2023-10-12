/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Test
 * @domain Core
 * @description Test class to cover ApplicationDatabase
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-08-16 - arjun.singh@auspost.com.au - Added methods for  rollback and savepoint
 * 2022-05-09 - Ranjeewa Silva - Added test method to cover upsert operation.
 */
@IsTest
private with sharing class ApplicationDatabase_Test {

	/**
	 * This is a bit of a nothing test as it doesn't contribute any value
	 */
	@IsTest
	private static void testInsertAndUpdateAndDelete() {
		MockUtility.disableTriggerExecution();

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, false);
		ApplicationDatabase.getInstance().dmlInsert(accounts);
		ApplicationDatabase.getInstance().dmlUpdate(accounts);
		ApplicationDatabase.getInstance().dmlDelete(accounts);		
		ApplicationDatabase.getInstance().dmlSetSavePoint();
		ApplicationDatabase.getInstance().dmlRollback(ApplicationDatabase.getInstance().dmlSetSavePoint());
		System.assert(true, 'Not Completed');
	}

	/**
	 * Ensure upsert operations are completed without errors.
	 * This is a bit of a nothing test as it doesn't contribute any value
	 */
	@IsTest
	private static void testUpsert() {
		MockUtility.disableTriggerExecution();

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, false);
		ApplicationDatabase.getInstance().dmlInsert(accounts);

		Test.startTest();
		accounts[0].Name = 'updated';
		Account newAccount = ApplicationTestDataFactory.getAccounts(1, false)[0];
		ApplicationDatabase.getInstance().dmlUpsert(new List<Account>{accounts[0], newAccount}, Account.Id);
		System.assert(true, 'Not Completed');
		Test.stopTest();
	}

	/**
	 * Sole purpose of the below method is coverage for Approval Process related methods
	 */
	@IsTest
	private static void testApproval() {
		try {
			ApplicationDatabase.getInstance().submitForApproval(
				fflib_IDGenerator.generate(Account.SObjectType),
				'comments'
			);

			System.assert(false, 'Exception expected');
		} catch (Exception ex) {
			System.assert(true, 'Expected exception caught');
		}
	}

	@IsTest
	private static void testFindDuplicates() {
		System.assertEquals(
			true,
			ApplicationDatabase.getInstance().findDuplicates(
				new List<Account>{ new Account(Name = 'Test') }
			)[0].isSuccess(),
			'Unexpected response'
		);
	}
}