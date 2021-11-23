/***
 * @description
 * Test class for ApplicationDomain
 *
 * @author Nathan Franklin
 * @date 2020-07-27
 * @group Core
 * @domain Core
 * @changelog
 */
@IsTest
private class ApplicationDomain_Test {

	/**
	 * Scenario: Ensure the application domain fires:
	 * 1. All the methods from ApplicationTestDomain1_Test.TestModuleAll
	 * 2. None the methods from ApplicationTestDomain1_Test.TestModuleNone
	 *
	 * Utilise the static count variables in ApplicationTestDomain1_Test to confirm
	 */
	@IsTest
	public static void testApplicationDomain1() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		List<Account> oldAccounts = ApplicationTestDataFactory.getAccounts(2, false);

		// setup our old values so we can perform comparisons on what is changed
		oldAccounts[0].Id = accounts[0].Id;
		oldAccounts[0].NumberOfEmployees = 10;

		oldAccounts[1].Id = accounts[1].Id;
		oldAccounts[1].NumberOfEmployees = 10;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork uow = (ApplicationUnitOfWork)MockUtility.mockUtility(ApplicationUnitOfWork.class);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ApplicationTestDomain1_Test domain = (ApplicationTestDomain1_Test)ApplicationDomain.newInstance(ApplicationTestDomain1_Test.class, accounts);
		System.assertEquals(1, domain.records.size(), 'Expected only 1 record, instead got ' + domain.records.size());
		System.assertEquals('ApplicationTestDomain1_Test', domain.className, 'Expected ApplicationTestDomain1_Test, instead got ' + domain.className);

		// test method handlers
		domain.onBeforeInsert(uow);
		domain.onAfterInsert(uow);
		domain.onBeforeUpdate(new Map<Id, Account>(oldAccounts), uow);
		domain.onAfterUpdate(new Map<Id, Account>(oldAccounts), uow);
		//		domain.onBeforeDelete(uow);
		//		domain.onAfterDelete(uow);

		System.assertEquals(1, ApplicationTestDomain1_Test.moduleOnBeforeInsertCalled, 'Expected only 1');
		System.assertEquals(1, ApplicationTestDomain1_Test.moduleOnAfterInsertCalled, 'Expected only 1');
		System.assertEquals(1, ApplicationTestDomain1_Test.moduleOnBeforeUpdateCalled, 'Expected only 1');
		System.assertEquals(1, ApplicationTestDomain1_Test.moduleOnAfterUpdateCalled, 'Expected only 1');
		//		System.assertEquals(1, moduleOnBeforeDeleteCalled, 'Expected only 1');
		//		System.assertEquals(1, moduleOnAfterDeleteCalled, 'Expected only 1');

		// verify that getIsChanged fired successfully in the module
		System.assertEquals(1, ApplicationTestDomain1_Test.moduleBeforeUpdateChangedValues.size(), 'Expected only 1');
		System.assertEquals(1, ApplicationTestDomain1_Test.moduleBeforeUpdateChangedValues.get(accounts[0].Id).size(), 'Expected only 1');
		System.assert(ApplicationTestDomain1_Test.moduleBeforeUpdateChangedValues.get(accounts[0].Id).contains(Account.NumberOfEmployees), 'Expected only 1');

		System.assertEquals(1, ApplicationTestDomain1_Test.moduleAfterUpdateChangedValues.size(), 'Expected only 1');
		System.assertEquals(1, ApplicationTestDomain1_Test.moduleAfterUpdateChangedValues.get(accounts[0].Id).size(), 'Expected only 1');
		System.assert(ApplicationTestDomain1_Test.moduleAfterUpdateChangedValues.get(accounts[0].Id).contains(Account.NumberOfEmployees), 'Expected only 1');

		Test.stopTest();

	}

	/**
	 * Scenario: Ensure the application domain fires:
	 * 1. All the methods from ApplicationTestDomain2_Test.TestModuleAll
	 * 2. None the methods from ApplicationTestDomain2_Test.TestModuleNone
	 *
	 * Utilise the static count variables in ApplicationTestDomain2_Test to confirm
	 */
	@IsTest
	public static void testApplicationDomain2() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		List<Account> oldAccounts = ApplicationTestDataFactory.getAccounts(2, false);

		// setup our old values so we can perform comparisons on what is changed
		oldAccounts[0].Id = accounts[0].Id;
		oldAccounts[0].NumberOfEmployees = 10;

		oldAccounts[1].Id = accounts[1].Id;
		oldAccounts[1].NumberOfEmployees = 10;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork uow = (ApplicationUnitOfWork)MockUtility.mockUtility(ApplicationUnitOfWork.class);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		ApplicationTestDomain2_Test domain = (ApplicationTestDomain2_Test)ApplicationDomain.newInstance(ApplicationTestDomain2_Test.class, accounts);
		System.assertEquals(1, domain.records.size(), 'Expected only 1 record, instead got ' + domain.records.size());
		System.assertEquals('ApplicationTestDomain2_Test', domain.className, 'Expected ApplicationTestDomain2_Test, instead got ' + domain.className);

		// test method handlers
		domain.onBeforeInsert(uow);
		domain.onAfterInsert(uow);
		domain.onBeforeUpdate(new Map<Id, Account>(oldAccounts), uow);
		domain.onAfterUpdate(new Map<Id, Account>(oldAccounts), uow);
		//		domain.onBeforeDelete(uow);
		//		domain.onAfterDelete(uow);

		System.assertEquals(1, ApplicationTestDomain2_Test.moduleOnBeforeInsertCalled, 'Expected only 1');
		System.assertEquals(1, ApplicationTestDomain2_Test.moduleOnAfterInsertCalled, 'Expected only 1');
		System.assertEquals(1, ApplicationTestDomain2_Test.moduleOnBeforeUpdateCalled, 'Expected only 1');
		System.assertEquals(1, ApplicationTestDomain2_Test.moduleOnAfterUpdateCalled, 'Expected only 1');
		//		System.assertEquals(1, moduleOnBeforeDeleteCalled, 'Expected only 1');
		//		System.assertEquals(1, moduleOnAfterDeleteCalled, 'Expected only 1');

		// verify that getIsChanged fired successfully in the module
		System.assertEquals(1, ApplicationTestDomain2_Test.moduleBeforeUpdateChangedValues.size(), 'Expected only 1');
		System.assertEquals(1, ApplicationTestDomain2_Test.moduleBeforeUpdateChangedValues.get(accounts[0].Id).size(), 'Expected only 1');
		System.assert(ApplicationTestDomain2_Test.moduleBeforeUpdateChangedValues.get(accounts[0].Id).contains(Account.NumberOfEmployees), 'Expected only 1');

		System.assertEquals(1, ApplicationTestDomain2_Test.moduleAfterUpdateChangedValues.size(), 'Expected only 1');
		System.assertEquals(1, ApplicationTestDomain2_Test.moduleAfterUpdateChangedValues.get(accounts[0].Id).size(), 'Expected only 1');
		System.assert(ApplicationTestDomain2_Test.moduleAfterUpdateChangedValues.get(accounts[0].Id).contains(Account.NumberOfEmployees), 'Expected only 1');

		Test.stopTest();

	}

}