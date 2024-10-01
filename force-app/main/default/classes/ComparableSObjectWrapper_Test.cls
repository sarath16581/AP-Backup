/**
 * @description Testclass for ComparableSObjectWrapper utilit
 * NOTE: 	Can be used to sort List<SObject> by field and sortDirection
 * @author 	Paul Perry
 * @date 	2024-09-23
 * @group 	Global
 * @changelog
 * 2024-09-23 - Paul Perry - created
 */
@IsTest
public with sharing class ComparableSObjectWrapper_Test {
	@IsTest
	static void testSortRecords() {
		// Create test data
		List<Account> accounts = new List<Account>{
			(Account)ApplicationTestDataFactory.setUnwritableFields(
				new Account(Name = 'Test C', AnnualRevenue = 1000, NumberOfEmployees = 50),
				new Map<String,Object>{ 'CreatedDate' => System.now().addDays(50) }
			),
			(Account)ApplicationTestDataFactory.setUnwritableFields(
				new Account(Name = 'Test A', AnnualRevenue = 3000, NumberOfEmployees = 100),
				new Map<String,Object>{ 'CreatedDate' => System.now().addDays(100) }
			),
			(Account)ApplicationTestDataFactory.setUnwritableFields(
				new Account(Name = 'Test B', AnnualRevenue = 2000, NumberOfEmployees = 75),
				new Map<String,Object>{ 'CreatedDate' => System.now().addDays(75) }
			)
		};

		Test.startTest();

		// Test sorting by String field (Name)
		List<SObject> sortedByName = ComparableSObjectWrapper.sortRecords(accounts, String.valueOf(Account.Name));
		System.assertEquals('Test A', ((Account)sortedByName[0]).Name, 'First account should be Test A');
		System.assertEquals('Test C', ((Account)sortedByName[2]).Name, 'Last account should be Test C');

		// Test sorting by Decimal field (AnnualRevenue)
		List<SObject> sortedByRevenue = ComparableSObjectWrapper.sortRecords(accounts, Account.AnnualRevenue, 'DESC');
		System.assertEquals(3000, ((Account)sortedByRevenue[0]).AnnualRevenue, 'First account should have 3000 revenue');
		System.assertEquals(1000, ((Account)sortedByRevenue[2]).AnnualRevenue, 'Last account should have 1000 revenue');

		// Test sorting by Integer field (NumberOfEmployees)
		List<SObject> sortedByEmployees = ComparableSObjectWrapper.sortRecords(accounts, Account.NumberOfEmployees, 'ASC');
		System.assertEquals(50, ((Account)sortedByEmployees[0]).NumberOfEmployees, 'First account should have 50 employees');
		System.assertEquals(100, ((Account)sortedByEmployees[2]).NumberOfEmployees, 'Last account should have 100 employees');

		// Test sorting by DateTime field (CreatedDate)
		List<SObject> sortedByCreatedDate = ComparableSObjectWrapper.sortRecords(accounts, Account.CreatedDate, 'DESC');
		System.assertEquals(System.now().addDays(100), ((Account)sortedByCreatedDate[0]).CreatedDate, 'First account should have Today + 100 as CreatedDate');
		System.assertEquals(System.now().addDays(50), ((Account)sortedByCreatedDate[2]).CreatedDate, 'Last account should have Today + 50 as CreatedDate');

		Test.stopTest();
	}

	@IsTest
	static void testSortRecordsWithNulls() {
		// Create test data with null values
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Test C', AnnualRevenue = null),
			new Account(Name = 'Test A', AnnualRevenue = 3000),
			new Account(Name = 'Test B', AnnualRevenue = null)
		};

		Test.startTest();

		// Test sorting with null values
		List<SObject> sortedByRevenue = ComparableSObjectWrapper.sortRecords(accounts, Account.AnnualRevenue, 'ASC');
		System.assertEquals(null, ((Account)sortedByRevenue[0]).AnnualRevenue, 'First account should have null revenue');
		System.assertEquals(null, ((Account)sortedByRevenue[1]).AnnualRevenue, 'Second account should have null revenue');
		System.assertEquals(3000, ((Account)sortedByRevenue[2]).AnnualRevenue, 'Last account should have 3000 revenue');

		Test.stopTest();
	}

	@IsTest
	static void testSortRecordsWithInvalidInputs() {
		Test.startTest();

		// Test with null list
		List<SObject> result = ComparableSObjectWrapper.sortRecords(null, Account.Name, 'ASC');
		System.assertEquals(null, result, 'Result should be null when input list is null');

		// Test with empty list
		result = ComparableSObjectWrapper.sortRecords(new List<Account>(), Account.Name, 'ASC');
		System.assertEquals(0, result.size(), 'Result should be an empty list when input list is empty');

		// Test with null field
		List<Account> accounts = new List<Account>{new Account(Name = 'Test')};
		result = ComparableSObjectWrapper.sortRecords(accounts, (String)null, 'ASC');
		System.assertEquals(1, result.size(), 'Input should be unchanged');

		// Test with invalid sort direction
		result = ComparableSObjectWrapper.sortRecords(accounts, Account.Name, 'INVALID');
		System.assertEquals(1, result.size(), 'Fallback to default sortOrder ASC');

		Test.stopTest();
	}
}