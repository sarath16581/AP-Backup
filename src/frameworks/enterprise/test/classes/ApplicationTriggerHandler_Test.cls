/***
 * @description
 * Test class for ApplicationDomainTriggerHandler
 *
 * @author Nathan Franklin
 * @date 2023-06-17
 * @changelog
 */
@IsTest
private class ApplicationTriggerHandler_Test {

	public static Integer moduleOnBeforeInsertCalled = 0;
	public static Integer moduleOnAfterInsertCalled = 0;
	public static Integer moduleOnBeforeUpdateCalled = 0;
	public static Integer moduleOnAfterUpdateCalled = 0;
	public static Integer moduleOnBeforeDeleteCalled = 0;
	public static Integer moduleOnAfterDeleteCalled = 0;
	public static Integer moduleOnAfterUndeleteCalled = 0;

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

		System.assertEquals(1, ApplicationTriggerHandler_Test.moduleOnBeforeInsertCalled, 'OnBeforeInsert should have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnAfterInsertCalled, 'OnAfterInsert should not have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnBeforeUpdateCalled, 'OnBeforeUpdate should not have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnAfterUpdateCalled, 'OnAfterUpdate should not have been called');
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

		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnBeforeInsertCalled, 'OnBeforeInsert should not have been called');
		System.assertEquals(1, ApplicationTriggerHandler_Test.moduleOnAfterInsertCalled, 'OnAfterInsert should have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnBeforeUpdateCalled, 'OnBeforeUpdate should not have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnAfterUpdateCalled, 'OnAfterUpdate should not have been called');
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

		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnBeforeInsertCalled, 'OnBeforeInsert should not have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnAfterInsertCalled, 'OnAfterInsert should not have been called');
		System.assertEquals(1, ApplicationTriggerHandler_Test.moduleOnBeforeUpdateCalled, 'OnBeforeUpdate should have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnAfterUpdateCalled, 'OnAfterUpdate should not have been called');
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

		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnBeforeInsertCalled, 'OnBeforeInsert should not have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnAfterInsertCalled, 'OnAfterInsert should not have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnBeforeUpdateCalled, 'OnBeforeUpdate should not have been called');
		System.assertEquals(1, ApplicationTriggerHandler_Test.moduleOnAfterUpdateCalled, 'OnAfterUpdate should have been called');
		//		System.assertEquals(1, moduleOnBeforeDeleteCalled, 'Expected only 1');
		//		System.assertEquals(1, moduleOnAfterDeleteCalled, 'Expected only 1');

	}

	/**
	 * Scenario:
	 * Making sure we can dispatch the correct domain/module calls
	 */
	@IsTest
	public static void testAfterUndeletetDispatch() {

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

		(new AccountTriggerHandler()).dispatch(false, true, false, false, false, true, accounts, null);

		Test.stopTest();

		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnBeforeInsertCalled, 'OnBeforeInsert should not have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnAfterInsertCalled, 'OnAfterInsert should not have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnBeforeUpdateCalled, 'OnBeforeUpdate should not have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnAfterUpdateCalled, 'OnAfterUpdate should not have been called');
		System.assertEquals(1, ApplicationTriggerHandler_Test.moduleOnAfterUndeleteCalled, 'OnAfterUndelete should have been called');

	}

	/**
	 * Scenario:
	 * Making sure we can dispatch the correct domain/module calls
	 */
	@IsTest
	public static void testFilteredTriggerHandlerDispatch() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		List<Account> accountsOld = new List<Account>{accounts[0].clone(true), accounts[1].clone(true)};
		Map<Id, Account> accountsOldMap = new Map<Id, Account>(accountsOld);

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// before insert
		(new AccountTriggerWithFilteringHandler()).dispatch(true, false, true, false, false, false, accounts, null);

		// before update
		(new AccountTriggerWithFilteringHandler()).dispatch(true, false, false, true, false, false, accounts, accountsOldMap);

		// after insert
		(new AccountTriggerWithFilteringHandler()).dispatch(false, true, true, false, false, false, accounts, null);

		// after update
		(new AccountTriggerWithFilteringHandler()).dispatch(false, true, false, true, false, false, accounts, accountsOldMap);

		// before delete
		(new AccountTriggerWithFilteringHandler()).dispatch(true, false, false, false, true, false, null, accountsOldMap);

		// after delete
		(new AccountTriggerWithFilteringHandler()).dispatch(false, true, false, false, true, false, null, accountsOldMap);

		// after undelete
		(new AccountTriggerWithFilteringHandler()).dispatch(false, true, false, false, false, true, accounts, null);

		Test.stopTest();

		// NOTE: the modules in AccountTriggerWithFilteringHandler and the handler itself assert values for an accurate test
		System.assertEquals(2, ApplicationTriggerHandler_Test.moduleOnBeforeInsertCalled, 'OnBeforeInsert should not have been called');
		System.assertEquals(2, ApplicationTriggerHandler_Test.moduleOnAfterInsertCalled, 'OnAfterInsert should not have been called');
		System.assertEquals(2, ApplicationTriggerHandler_Test.moduleOnBeforeUpdateCalled, 'OnBeforeUpdate should not have been called');
		System.assertEquals(2, ApplicationTriggerHandler_Test.moduleOnAfterUpdateCalled, 'OnAfterUpdate should not have been called');
		System.assertEquals(2, ApplicationTriggerHandler_Test.moduleOnBeforeDeleteCalled, 'OnBeforeDelete should have been called');
		System.assertEquals(2, ApplicationTriggerHandler_Test.moduleOnAfterDeleteCalled, 'OnAfterDelete should have been called');
		System.assertEquals(2, ApplicationTriggerHandler_Test.moduleOnAfterUndeleteCalled, 'OnAfterUndelete should have been called');

	}

	/**
	 * Scenario:
	 * Making sure we can dispatch the correct domain/module calls
	 */
	@IsTest
	public static void testModuleBuiltInMethods() {

		// =====================================
		// Data Preparation
		// =====================================
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		List<Account> accountsOld = new List<Account>{accounts[0].clone(true), accounts[1].clone(true)};
		Map<Id, Account> accountsOldMap = new Map<Id, Account>(accountsOld);

		accounts[0].Name = 'New Name';
		accounts[0].NumberOfEmployees = 7;
		
		accounts[1].Industry = 'Technology';
		accounts[1].AnnualRevenue = 7;
		accounts[1].NumberOfEmployees = 7;


		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		// before insert
		(new AccountTriggerHandlerForMethodCheck()).dispatch(true, false, true, false, false, false, accounts, null);

		// before update
		(new AccountTriggerHandlerForMethodCheck()).dispatch(true, false, false, true, false, false, accounts, accountsOldMap);

		Test.stopTest();

		// NOTE: the module in AccountTriggerHandlerForMethodCheck and the handler itself assert values for an accurate test
		System.assertEquals(1, ApplicationTriggerHandler_Test.moduleOnBeforeInsertCalled, 'OnBeforeInsert should not have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnAfterInsertCalled, 'OnAfterInsert should not have been called');
		System.assertEquals(1, ApplicationTriggerHandler_Test.moduleOnBeforeUpdateCalled, 'OnBeforeUpdate should not have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnAfterUpdateCalled, 'OnAfterUpdate should not have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnBeforeDeleteCalled, 'OnBeforeDelete should have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnAfterDeleteCalled, 'OnAfterDelete should have been called');
		System.assertEquals(0, ApplicationTriggerHandler_Test.moduleOnAfterUndeleteCalled, 'OnAfterUndelete should have been called');

	}

	class AccountTriggerHandler extends ApplicationTriggerHandler {
		public override SObjectType getSObjectType() {
			return Account.SObjectType;
		}

		public override void registerModules() {
			registerModule(AccountModule1.class);
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

	class AccountTriggerWithFilteringHandler extends ApplicationTriggerHandler {
		public override SObjectType getSObjectType() {
			return Account.SObjectType;
		}

		/**
		 * Pre filter records to minimise repetitive looping inside the modules
		 * This creates a type of index of records which are passed into the modules based on the 'filterKey' used when the module is registered
		 * This replicates Domain specific filtering logic and allows a module to execution with the record scope it needs
		 */
		public override Map<String, List<SObject>> primeRecordFilters(List<SObject> records) {
			System.assertEquals(2, records.size());

			Map<String, List<SObject>> filteredRecords = new Map<String, List<SObject>>{
				'filter1' => new List<SObject>{records[0]},
				'filter2' => new List<SObject>{records[1]}
			};

			return filteredRecords;
		}

		public override void registerModules() {
			registerModule(AccountModuleWithFiltering1.class, 'filter1');
			registerModule(AccountModuleWithFiltering2.class, 'filter2');
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

	class AccountTriggerHandlerForMethodCheck extends ApplicationTriggerHandler {
		public override SObjectType getSObjectType() {
			return Account.SObjectType;
		}

		public override void registerModules() {
			registerModule(AccountModuleMethodCheck.class);
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

	public class AccountModule1 extends ApplicationModule {

		public AccountModule1() {
			getTriggerEvents().enableAll();
		}

		public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
			ApplicationTriggerHandler_Test.moduleOnBeforeInsertCalled++;
		}
	
		public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
			ApplicationTriggerHandler_Test.moduleOnAfterInsertCalled++;
		}
	
		public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
			ApplicationTriggerHandler_Test.moduleOnBeforeUpdateCalled++;
		}
	
		public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
			ApplicationTriggerHandler_Test.moduleOnAfterUpdateCalled++;
		}
	
		public override void onBeforeDelete(List<SObject> records, ApplicationUnitOfWork uow) {
			ApplicationTriggerHandler_Test.moduleOnBeforeDeleteCalled++;
		}
	
		public override void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow) {
			ApplicationTriggerHandler_Test.moduleOnAfterDeleteCalled++;
		}
	
		public override void onAfterUndelete(List<SObject> records, ApplicationUnitOfWork uow) {
			ApplicationTriggerHandler_Test.moduleOnAfterUndeleteCalled++;
		}

	}

	public class AccountModuleWithFiltering1 extends ApplicationModule {

		public AccountModuleWithFiltering1() {
			getTriggerEvents().enableAll();
		}

		public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
			System.assertEquals(1, records.size());
			System.assertEquals('Test Name 1', String.valueOf(records[0].get('Name')));

			ApplicationTriggerHandler_Test.moduleOnBeforeInsertCalled++;
		}
	
		public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
			System.assertEquals(1, records.size());
			System.assertEquals('Test Name 1', String.valueOf(records[0].get('Name')));

			ApplicationTriggerHandler_Test.moduleOnAfterInsertCalled++;
		}
	
		public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
			System.assertEquals(1, records.size());
			System.assertEquals('Test Name 1', String.valueOf(records[0].get('Name')));

			ApplicationTriggerHandler_Test.moduleOnBeforeUpdateCalled++;
		}
	
		public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
			System.assertEquals(1, records.size());
			System.assertEquals('Test Name 1', String.valueOf(records[0].get('Name')));

			ApplicationTriggerHandler_Test.moduleOnAfterUpdateCalled++;
		}
	
		public override void onBeforeDelete(List<SObject> records, ApplicationUnitOfWork uow) {
			System.assertEquals(1, records.size());
			System.assertEquals('Test Name 1', String.valueOf(records[0].get('Name')));

			ApplicationTriggerHandler_Test.moduleOnBeforeDeleteCalled++;
		}
	
		public override void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow) {
			System.assertEquals(1, records.size());
			System.assertEquals('Test Name 1', String.valueOf(records[0].get('Name')));

			ApplicationTriggerHandler_Test.moduleOnAfterDeleteCalled++;
		}
	
		public override void onAfterUndelete(List<SObject> records, ApplicationUnitOfWork uow) {
			System.assertEquals(1, records.size());
			System.assertEquals('Test Name 1', String.valueOf(records[0].get('Name')));

			ApplicationTriggerHandler_Test.moduleOnAfterUndeleteCalled++;
		}

	}

	public class AccountModuleWithFiltering2 extends ApplicationModule {

		public AccountModuleWithFiltering2() {
			getTriggerEvents().enableAll();
		}

		public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
			System.assertEquals(1, records.size());
			System.assertEquals('Test Name 2', String.valueOf(records[0].get('Name')));

			ApplicationTriggerHandler_Test.moduleOnBeforeInsertCalled++;
		}
	
		public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
			System.assertEquals(1, records.size());
			System.assertEquals('Test Name 2', String.valueOf(records[0].get('Name')));

			ApplicationTriggerHandler_Test.moduleOnAfterInsertCalled++;
		}
	
		public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
			System.assertEquals(1, records.size());
			System.assertEquals('Test Name 2', String.valueOf(records[0].get('Name')));

			ApplicationTriggerHandler_Test.moduleOnBeforeUpdateCalled++;
		}
	
		public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
			System.assertEquals(1, records.size());
			System.assertEquals('Test Name 2', String.valueOf(records[0].get('Name')));

			ApplicationTriggerHandler_Test.moduleOnAfterUpdateCalled++;
		}
	
		public override void onBeforeDelete(List<SObject> records, ApplicationUnitOfWork uow) {
			System.assertEquals(1, records.size());
			System.assertEquals('Test Name 2', String.valueOf(records[0].get('Name')));

			ApplicationTriggerHandler_Test.moduleOnBeforeDeleteCalled++;
		}
	
		public override void onAfterDelete(List<SObject> records, ApplicationUnitOfWork uow) {
			System.assertEquals(1, records.size());
			System.assertEquals('Test Name 2', String.valueOf(records[0].get('Name')));

			ApplicationTriggerHandler_Test.moduleOnAfterDeleteCalled++;
		}
	
		public override void onAfterUndelete(List<SObject> records, ApplicationUnitOfWork uow) {
			System.assertEquals(1, records.size());
			System.assertEquals('Test Name 2', String.valueOf(records[0].get('Name')));

			ApplicationTriggerHandler_Test.moduleOnAfterUndeleteCalled++;
		}

	}

	public class AccountModuleMethodCheck extends ApplicationModule {

		public AccountModuleMethodCheck() {
			getTriggerEvents().enableBeforeInsert();
			getTriggerEvents().enableBeforeUpdate();
		}

		public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
			System.assertEquals('', nullToString(null));

			ApplicationTriggerHandler_Test.moduleOnBeforeInsertCalled++;
		}
	
		public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
			Map<Id, Set<SObjectField>> changed = getIsChanged(records, existingRecords, new Set<SObjectField>{Account.Name, Account.Industry, Account.AnnualRevenue});
			
			System.assertEquals(true, changed.values()[0].contains(Account.Name));
			System.assertEquals(false, changed.values()[0].contains(Account.Industry));
			System.assertEquals(false, changed.values()[0].contains(Account.AnnualRevenue));
			System.assertEquals(false, changed.values()[0].contains(Account.NumberOfEmployees));

			System.assertEquals(false, changed.values()[1].contains(Account.Name));
			System.assertEquals(true, changed.values()[1].contains(Account.Industry));
			System.assertEquals(true, changed.values()[1].contains(Account.AnnualRevenue));
			System.assertEquals(false, changed.values()[1].contains(Account.NumberOfEmployees));

			ApplicationTriggerHandler_Test.moduleOnBeforeUpdateCalled++;

		}

	}

	private static void resetCounts() {
		moduleOnBeforeInsertCalled = 0;
		moduleOnAfterInsertCalled = 0;
		moduleOnBeforeUpdateCalled = 0;
		moduleOnAfterUpdateCalled = 0;
		moduleOnBeforeDeleteCalled = 0;
		moduleOnAfterDeleteCalled = 0;
		moduleOnAfterUndeleteCalled = 0;
	}

}