/***
 * @author Steve W.
 * @date 2020-03-03
 * @group Tests
 * @tag Selector
 * @tag Task SObject
 * @domain Core
 * @description Test Class covering TasksSelector
 * @changelog
 * 2020-03-03 - Steve W - Created
 * 2023-08-11 - Steve L - added testSelectorAllRows
 */
@IsTest
public with sharing class TasksSelector_Test {

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		TasksSelector selector = TasksSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom task\\b').matcher(soql).find(), 'Resulting query does not select from Task');

		qb = selector.newQueryBuilder(new Set<Object>{TasksSelector.Options.WITH_OWNER});
		soql = qb.toSoqlString();

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		TasksSelector selector = TasksSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{TasksSelector.Options.WITH_OWNER});
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Owner\\..*?\\bfrom task\\b').matcher(soql).find(), 'Resulting query does not select Owner fields');

		qb = selector.newQueryBuilder(new Set<Object>{TasksSelector.Options.WITH_CONTACT});
		soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)Who\\..*?\\bfrom task\\b').matcher(soql).find(), 'Resulting query does not select related Contact fields');
		
        Test.stopTest();

	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorSpecificMethods() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
		insert accounts;

		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, false);
		insert contacts;

        List<Task> tasks = new List<Task>();
    
        for(Integer i = 0; i < 20; i++){
            Task t = TestDataProvider.createTask(accounts[0].Id, contacts[0].Id, 'Sales Task');
            t.Subject = 'Test' + i;
            t.Type = 'Phone Call';
            t.Status = 'Not Started';
            t.Category__c = 'Sales';
            t.ActivityDate = System.today().addDays(i);
            tasks.add(t);
        }

		tasks[0].CTIInteractionID__c = UUID.randomUUID().toString();

        insert tasks;


		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
        Set<Object> opts = new Set<Object>{TasksSelector.Options.WITH_OWNER, TasksSelector.Options.WITH_CONTACT};
		Map<SObjectType, Set<SObjectField>> fieldOverride = new Map<SObjectType, Set<SObjectField>>();
        fieldOverride.put(((SObject) Type.forName('User').newInstance()).getSObjectType(), new Set<SobjectField>{User.Name,User.Id});
		fieldOverride.put(((SObject) Type.forName('Contact').newInstance()).getSObjectType(), new Set<SobjectField>{Contact.Name,Contact.Id});
        TasksSelector selector = TasksSelector.newInstance();
		selector.setFieldOverrides(fieldOverride);
		Map<String, Object> searchParams = new Map<String, Object>();
        searchParams.put('IsClosed', false);
		searchParams.put('WhatId', accounts[0].Id);
        Map<Id, Task> taskMap = selector.search(searchParams, opts, true);
		System.assertEquals(20, taskMap.size(), 'Expected 20 results');
        System.assertEquals(true, String.isNotBlank(taskMap.values()[0].Who.Name), 'The related contact name is not included');
        
        taskMap = selector.selectById(new Set<Id>{tasks[0].Id});
		System.assertEquals(1, taskMap.size(), 'Expected 1 result');

        taskMap = selector.selectByWhatId(new Set<Id>{accounts[0].Id});
		System.assertEquals(20, taskMap.size(), 'Expected 20 result');

        TasksSelector selectorWithOffset = TasksSelector.newInstance(1);
        taskMap = selectorWithOffset.selectById(new Set<Id>{tasks[0].Id, tasks[1].Id}, new Set<Object>{});
		System.assertEquals(1, taskMap.size(), 'Expected 1 result');

		Set<SObjectField> taskFieldOverrides = new Set<SObjectField> {Task.Id};
		TasksSelector selectorWithOffsetLimitSorts = TasksSelector.newInstance(0,1,'CreatedDate','DESC',taskFieldOverrides);
		taskMap = selectorWithOffsetLimitSorts.selectById(new Set<Id>{tasks[0].Id, tasks[1].Id}, new Set<Object>{});
		System.assertEquals(1, taskMap.size(), 'Expected 1 result');

		searchParams = new Map<String,Object>{
			'ctiInteractionIds' => new Set<String>{ tasks[0].CTIInteractionID__c }
		};
		taskMap = selector.search(searchParams, new Set<Object>(), true);
		System.assertEquals(1, taskMap.size(), 'Expected 1 result');
		Test.stopTest();
	}

	/**
	 * Executes a query to ensure it returns expected results with ALL ROWS
	 */
	@IsTest
	public static void testSelectorSelectAllRows() {
		final Integer taskSize = 20;
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Task> tasks = new List<Task>{ApplicationTestDataFactory.getTasks(taskSize, accounts[0].Id,  true)[0]};

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		TasksSelector tasksSelector = (TasksSelector)MockUtility.mockSelector(TasksSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(tasksSelector.selectByWhatId((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject())).thenReturn(new Map<Id,Task>(tasks));
		MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id,Task> taskMap = tasksSelector.selectByWhatId(new Set<Id>{accounts[0].Id}, new Set<Object>(), true);
		System.assertEquals(tasks.size(), taskMap.size(), 'Expected ' + String.valueOf(taskSize) + ' result');

		Test.stopTest();
	}
}