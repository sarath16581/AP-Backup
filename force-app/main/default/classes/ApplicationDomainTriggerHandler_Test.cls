/***
 * @description
 * Test class for ApplicationDomainTriggerHandler
 *
 * @author Nathan Franklin
 * @date 2020-07-27
 * @group Core
 * @domain Core
 * @changelog
 */
@IsTest
private class ApplicationDomainTriggerHandler_Test {

	/**
	 * Scenario:
	 * Making sure we can dispatch the correct domain/module calls
	 */
	@IsTest
	public static void testBeforeInsertDispatch() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);

		// =====================================
		// Stubbing
		// =====================================


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		(new AccountTriggerHandler()).dispatch(true, false, true, false, false, false, accounts, null);

		Test.stopTest();

		System.assertEquals(1, ApplicationTestDomain1_Test.moduleOnBeforeInsertCalled, 'OnBeforeInsert should have been called');
		System.assertEquals(0, ApplicationTestDomain1_Test.moduleOnAfterInsertCalled, 'OnAfterInsert should not have been called');
		System.assertEquals(0, ApplicationTestDomain1_Test.moduleOnBeforeUpdateCalled, 'OnBeforeUpdate should not have been called');
		System.assertEquals(0, ApplicationTestDomain1_Test.moduleOnAfterUpdateCalled, 'OnAfterUpdate should not have been called');
		//		System.assertEquals(1, moduleOnBeforeDeleteCalled, 'Expected only 1');
		//		System.assertEquals(1, moduleOnAfterDeleteCalled, 'Expected only 1');

	}

	/**
	 * Scenario:
	 * Making sure we can dispatch the correct domain/module calls
	 */
	@IsTest
	public static void testAfterInsertDispatch() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		(new AccountTriggerHandler()).dispatch(false, true, true, false, false, false, accounts, null);

		Test.stopTest();

		System.assertEquals(0, ApplicationTestDomain1_Test.moduleOnBeforeInsertCalled, 'OnBeforeInsert should not have been called');
		System.assertEquals(1, ApplicationTestDomain1_Test.moduleOnAfterInsertCalled, 'OnAfterInsert should have been called');
		System.assertEquals(0, ApplicationTestDomain1_Test.moduleOnBeforeUpdateCalled, 'OnBeforeUpdate should not have been called');
		System.assertEquals(0, ApplicationTestDomain1_Test.moduleOnAfterUpdateCalled, 'OnAfterUpdate should not have been called');
		//		System.assertEquals(1, moduleOnBeforeDeleteCalled, 'Expected only 1');
		//		System.assertEquals(1, moduleOnAfterDeleteCalled, 'Expected only 1');

	}

	/**
	 * Scenario:
	 * Making sure we can dispatch the correct domain/module calls
	 */
	@IsTest
	public static void testBeforeUpdateDispatch() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Account> oldAccounts = new List<Account>{accounts[0].clone(true)};

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		(new AccountTriggerHandler()).dispatch(true, false, false, true, false, false, accounts, new Map<Id, Account>(oldAccounts));

		Test.stopTest();

		System.assertEquals(0, ApplicationTestDomain1_Test.moduleOnBeforeInsertCalled, 'OnBeforeInsert should not have been called');
		System.assertEquals(0, ApplicationTestDomain1_Test.moduleOnAfterInsertCalled, 'OnAfterInsert should not have been called');
		System.assertEquals(1, ApplicationTestDomain1_Test.moduleOnBeforeUpdateCalled, 'OnBeforeUpdate should have been called');
		System.assertEquals(0, ApplicationTestDomain1_Test.moduleOnAfterUpdateCalled, 'OnAfterUpdate should not have been called');
		//		System.assertEquals(1, moduleOnBeforeDeleteCalled, 'Expected only 1');
		//		System.assertEquals(1, moduleOnAfterDeleteCalled, 'Expected only 1');

	}

	/**
	 * Scenario:
	 * Making sure we can dispatch the correct domain/module calls
	 */
	@IsTest
	public static void testAfterUpdateDispatch() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Account> oldAccounts = new List<Account>{accounts[0].clone(true)};

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		(new AccountTriggerHandler()).dispatch(false, true, false, true, false, false, accounts, new Map<Id, Account>(oldAccounts));

		Test.stopTest();

		System.assertEquals(0, ApplicationTestDomain1_Test.moduleOnBeforeInsertCalled, 'OnBeforeInsert should not have been called');
		System.assertEquals(0, ApplicationTestDomain1_Test.moduleOnAfterInsertCalled, 'OnAfterInsert should not have been called');
		System.assertEquals(0, ApplicationTestDomain1_Test.moduleOnBeforeUpdateCalled, 'OnBeforeUpdate should not have been called');
		System.assertEquals(1, ApplicationTestDomain1_Test.moduleOnAfterUpdateCalled, 'OnAfterUpdate should have been called');
		//		System.assertEquals(1, moduleOnBeforeDeleteCalled, 'Expected only 1');
		//		System.assertEquals(1, moduleOnAfterDeleteCalled, 'Expected only 1');

	}

	class AccountTriggerHandler extends ApplicationDomainTriggerHandler {
		public override SObjectType getSObjectType() {
			return Account.SObjectType;
		}

		public override List<Type> registerDomains() {
			return new List<Type>{
					ApplicationTestDomain1_Test.class
			};
		}

		/**
		 * Unit of work that encapsulates all the required objects for each domain within this SObject
		 */
		public override ApplicationUnitOfWork newUnitOfWork() {
			return ApplicationUnitOfWork.newInstance(new List<SObjectType>{
					Account.SObjectType
			});
		}
	}

}