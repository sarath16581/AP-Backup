/**
* @author Ashapriya Gadi
* @date 2021-12-21
* @group Tests
* @tag module
* @tag CampaignContactAssignment__c
* @domain CampaignContactAssignmentsDomain
* @description Test class covering CampaignSurveysModule
* @changelog
* 2021-12-21 - Ashapriya Gadi - Created
* 2021-01-22 - Mathew Jose - Added test methods for saveCampaignMembers methods.
*/
@IsTest
private class CampaignAssignCampaignMembersModule_Test {

	/**
	 * Test:
	 *  Ensures that a task is created for an account manager after the initial contact assignment record creation
	 *  The task should be marked as Not Started (until a contact id value is applied)
	 *  NOTE: This should handle at least 2 different accounts / campaigns
	 */
	@IsTest
	private static void testEnsureTaskCreatedForAccountManagerOnContactAssignmentRecordCreation() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		//Create two accounts
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].ownerId = users[0].Id;
		accounts[1].ownerId = users[0].Id;
		//Create two campaigns
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(2, true);
		List<CampaignContactAssignment__c> campaignContactAssignments = new List<CampaignContactAssignment__c>{ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[0].Id,campaigns[0].Id, true)[0],
																											ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[1].Id,campaigns[1].Id, true)[0]};
		//Expected task output
		List<Task>tasks = new List<Task>{ApplicationTestDataFactory.getTasks(1, campaigns[0].Id,  true)[0],ApplicationTestDataFactory.getTasks(1, campaigns[1].Id,  true)[0]};
		tasks[0].ownerId = users[0].Id;
		tasks[0].Subject = CampaignContactAssignmentConstants.TASK_SUBJECT;
		tasks[0].status = CampaignContactAssignmentConstants.TASK_NOTSTARTED;
		tasks[1].ownerId = users[0].Id;
		tasks[1].Subject = CampaignContactAssignmentConstants.TASK_SUBJECT;
		tasks[1].status = CampaignContactAssignmentConstants.TASK_NOTSTARTED;			
		
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		AccountsSelector accountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		TasksSelector tasksSelector = (TasksSelector)MockUtility.mockSelector(TasksSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(accountsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>(accounts));
		MockUtility.Mocks.when(tasksSelector.search((Map<String, Set<Id>>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(),fflib_Match.anyBoolean())).thenReturn(new Map<Id, Task>());
		MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignAssignCampaignMembersModule module = CampaignAssignCampaignMembersModule.newInstance();
		module.createTask( (List<SObject>)campaignContactAssignments, null, mockUow);
		Test.stopTest();
		((AccountsSelector)MockUtility.Mocks.verify(AccountsSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.anyObject());
		((TasksSelector)MockUtility.Mocks.verify(TasksSelector, MockUtility.Mocks.times(1))).search((Map<String, Set<Id>>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(),fflib_Match.anyBoolean());
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<SObject>)fflib_Match.anyObject());
		System.assertEquals(2, MockUtility.mockUnitOfWorkDMLs.size());		
		System.assertEquals(users[0].Id, ((Task)MockUtility.mockUnitOfWorkDMLs[0]).OwnerId, 'Expected task to be created for the account owner');
		System.assertEquals(CampaignContactAssignmentConstants.TASK_NOTSTARTED, ((Task)MockUtility.mockUnitOfWorkDMLs[0]).Status, 'Expected task to be created with In Progress for the account owner');
		System.assertEquals(CampaignContactAssignmentConstants.TASK_NOTSTARTED, ((Task)MockUtility.mockUnitOfWorkDMLs[1]).Status, 'Expected task to be created with In Progress for the account owner');		
		
	
		
	}

	/**
	 * Test:
	 *  Ensures that a task is created for an account manager after the initial contact assignment record creation
	 *  The task should be marked as In Progress since the initial record is created with a contact id already assigned
	 *  NOTE: This should handle at least 2 different accounts / campaigns / contacts
	 */
	@IsTest
	private static void testEnsureTaskCreatedInProgressForAccountManagerOnContactAssignmentRecordCreation() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		//Two different accounts
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].ownerId = users[0].Id;
		accounts[1].ownerId = users[0].Id;
		//Two campaigns
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(2, true);
		//Two new contacts
		List<Contact> contacts  = new List<Contact>{ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true)[0],ApplicationTestDataFactory.getContacts(1, accounts[1].Id, true)[0]};
		//Two separate contact assignments.
		List<CampaignContactAssignment__c> campaignContactAssignments = new List<CampaignContactAssignment__c>{ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[0].Id,campaigns[0].Id, true)[0],
																												ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[1].Id,campaigns[1].Id, true)[0]};		
		campaignContactAssignments[0].Contact__c = contacts[0].Id;
		campaignContactAssignments[1].Contact__c = contacts[1].Id;			
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		AccountsSelector accountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		TasksSelector tasksSelector = (TasksSelector)MockUtility.mockSelector(TasksSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(accountsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>(accounts));
		MockUtility.Mocks.when(tasksSelector.search((Map<String, Set<Id>>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(),fflib_Match.anyBoolean())).thenReturn(new Map<Id, Task>());
		MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignAssignCampaignMembersModule module = CampaignAssignCampaignMembersModule.newInstance();
		module.createTask( (List<SObject>)campaignContactAssignments, null, mockUow);
		Test.stopTest();
		((AccountsSelector)MockUtility.Mocks.verify(AccountsSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.anyObject());
		((TasksSelector)MockUtility.Mocks.verify(TasksSelector, MockUtility.Mocks.times(1))).search((Map<String, Set<Id>>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(),fflib_Match.anyBoolean());
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<SObject>)fflib_Match.anyObject());
		// verify the task created for the owner
		System.assertEquals(2, MockUtility.mockUnitOfWorkDMLs.size());		
		System.assertEquals(users[0].Id, ((Task)MockUtility.mockUnitOfWorkDMLs[0]).OwnerId, 'Expected task1 to be created for the account owner');	
		System.assertEquals(users[0].Id, ((Task)MockUtility.mockUnitOfWorkDMLs[1]).OwnerId, 'Expected task2 to be created for the account owner');			
		System.assertEquals(CampaignContactAssignmentConstants.TASK_INPROGRESS, ((Task)MockUtility.mockUnitOfWorkDMLs[0]).Status, 'Expected task to be created with In Progress for the account owner');
		System.assertEquals(CampaignContactAssignmentConstants.TASK_INPROGRESS, ((Task)MockUtility.mockUnitOfWorkDMLs[1]).Status, 'Expected task to be created with In Progress for the account owner');

	}

	/**
	 * Test:
	 *  Ensures that a task is updated to in progress for an account manager after updating the contact assignment record to include the contact id
	 *  The existing task is Not Started and the task should be updated to be marked as In Progress
	 *  NOTE: This should handle at least 2 different accounts / campaigns / contacts
	 */
	@IsTest
	private static void testEnsureTaskUpdatedInProgressForAccountManagerOnContactAssignmentRecordUpdate() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		//Two accounts
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].ownerId = users[0].Id;
		accounts[1].ownerId = users[0].Id;
		//Two campaigns
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(2, true);
		//Two new contacts
		List<Contact> contacts  = new List<Contact>{ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true)[0],ApplicationTestDataFactory.getContacts(1, accounts[1].Id, true)[0]};
		
		List<CampaignContactAssignment__c> oldCampaignContactAssignments = new List<CampaignContactAssignment__c>{ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[0].Id,campaigns[0].Id, true)[0],
																													ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[1].Id,campaigns[1].Id, true)[0]};	
		Map<Id,CampaignContactAssignment__c>campaignContactAssignmentsOldMap = new Map<Id,CampaignContactAssignment__c>(oldCampaignContactAssignments);
		//Set contact__c value on the new values
		List<CampaignContactAssignment__c> newCampaignContactAssignments= new List<CampaignContactAssignment__c>{oldCampaignContactAssignments[0].clone(true),oldCampaignContactAssignments[1].clone(true)};
		newCampaignContactAssignments[0].Contact__c = contacts[0].Id;
		newCampaignContactAssignments[1].Contact__c = contacts[1].Id;

		//Expected task output from SOQL
		List<Task>tasks = new List<Task>{ApplicationTestDataFactory.getTasks(1, campaigns[0].Id,  true)[0],ApplicationTestDataFactory.getTasks(1, campaigns[1].Id,  true)[0]};
		tasks[0].ownerId = users[0].Id;
		tasks[0].Subject = CampaignContactAssignmentConstants.TASK_SUBJECT;
		tasks[0].status = CampaignContactAssignmentConstants.TASK_NOTSTARTED;
		tasks[1].ownerId = users[0].Id;
		tasks[1].Subject = CampaignContactAssignmentConstants.TASK_SUBJECT;
		tasks[1].status = CampaignContactAssignmentConstants.TASK_NOTSTARTED;					
		Map<Id,Task>tasksMap = new Map<Id,Task>(tasks);		
		
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		AccountsSelector accountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		TasksSelector tasksSelector = (TasksSelector)MockUtility.mockSelector(TasksSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(accountsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>(accounts));
		MockUtility.Mocks.when(tasksSelector.search((Map<String, Set<Id>>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(),fflib_Match.anyBoolean())).thenReturn(tasksMap);
		MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignAssignCampaignMembersModule module = CampaignAssignCampaignMembersModule.newInstance();
		module.createTask( (List<SObject>)newCampaignContactAssignments, (Map<Id,SObject>)campaignContactAssignmentsOldMap, mockUow);
		Test.stopTest();
		((AccountsSelector)MockUtility.Mocks.verify(AccountsSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.anyObject());
		((TasksSelector)MockUtility.Mocks.verify(TasksSelector, MockUtility.Mocks.times(1))).search((Map<String, Set<Id>>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(),fflib_Match.anyBoolean());
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<SObject>)fflib_Match.anyObject());
		System.assertEquals(2, MockUtility.mockUnitOfWorkDMLs.size());	
		System.assertEquals(CampaignContactAssignmentConstants.TASK_INPROGRESS, ((Task)MockUtility.mockUnitOfWorkDMLs[0]).Status, 'Expected task1 to be updated to In Progress for the account owner');
		System.assertEquals(CampaignContactAssignmentConstants.TASK_INPROGRESS, ((Task)MockUtility.mockUnitOfWorkDMLs[1]).Status, 'Expected task2 to be updated to In Progress for the account owner');

	}

	/**
	 * Test:
	 *  Ensures that a NEW task record is created where an already existing 'Closed' record exists for an Account Manager after inserting the contact assignment record which includes the contact id
	 *  The task should be marked as In Progress since the initial record is created with a contact id already assigned
	 *  NOTE: This should handle at least 2 different accounts / campaigns / contacts
	 */
	@IsTest
	private static void testEnsureNewTaskCreatedInProgressForAccountManagerOnNewContactAssignmentRecord() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<User> users = ApplicationTestDataFactory.getUsers(1,false);
		insert users;
		//Two accounts
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].ownerId = users[0].Id;
		accounts[1].ownerId = users[0].Id;
		//Two campaigns
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(2, false);
		insert campaigns;
		//Two new contacts
		List<Contact> contacts  = new List<Contact>{ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true)[0],ApplicationTestDataFactory.getContacts(1, accounts[1].Id, true)[0]};
		
		//Set contact__c value on the new values
		List<CampaignContactAssignment__c> newCampaignContactAssignments = new List<CampaignContactAssignment__c>{ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[0].Id,campaigns[0].Id, true)[0],
																													ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[1].Id,campaigns[1].Id, true)[0]};	
		newCampaignContactAssignments[0].Contact__c = contacts[0].Id;
		newCampaignContactAssignments[1].Contact__c = contacts[1].Id;
		//Prepare existing task for the AM for two different campaigns.
		List<Task>tasks = new List<Task>{ApplicationTestDataFactory.getTasks(1, campaigns[0].Id,  false)[0], ApplicationTestDataFactory.getTasks(1, campaigns[1].Id,  false)[0]};
		tasks[0].ownerId = users[0].Id;
		tasks[0].Subject = CampaignContactAssignmentConstants.TASK_SUBJECT;
		tasks[0].status = CampaignContactAssignmentConstants.TASK_COMPLETED;
		tasks[0] = (Task)ApplicationTestDataFactory.setUnwritableFields(Tasks[0], new Map<String, Object>{'IsClosed' => true});
		tasks[1].ownerId = users[0].Id;
		tasks[1].Subject = CampaignContactAssignmentConstants.TASK_SUBJECT;
		tasks[1].status = CampaignContactAssignmentConstants.TASK_COMPLETED;
		tasks[1] = (Task)ApplicationTestDataFactory.setUnwritableFields(Tasks[0], new Map<String, Object>{'IsClosed' => true});		
		insert tasks;		
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		AccountsSelector accountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(accountsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>(accounts));
		MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignAssignCampaignMembersModule module = CampaignAssignCampaignMembersModule.newInstance();
		module.createTask( (List<SObject>)newCampaignContactAssignments, null , mockUow);
		Test.stopTest();
		((AccountsSelector)MockUtility.Mocks.verify(AccountsSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.anyObject());
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<SObject>)fflib_Match.anyObject());
		// verify the task created for the owner
		System.assertEquals(2, MockUtility.mockUnitOfWorkDMLs.size());		
		System.assertEquals(CampaignContactAssignmentConstants.TASK_INPROGRESS, ((Task)MockUtility.mockUnitOfWorkDMLs[0]).Status, 'Expected task to be created with In Progress for the account owner');
		System.assertEquals(CampaignContactAssignmentConstants.TASK_INPROGRESS, ((Task)MockUtility.mockUnitOfWorkDMLs[1]).Status, 'Expected task to be created with In Progress for the account owner');	
	
	}

	/**
	 * Test:
	 *  Ensures that a NEW task record is created where an already existing 'Open' task record exists for a different purpose for an Account Manager after inserting the contact assignment record which includes the contact id
	 *  The task should be marked as In Progress since the initial record is created with a contact id already assigned
	 *  NOTE: This should handle at least 2 different accounts / campaigns / contacts
	 */
	@IsTest
	private static void testEnsureExistingIrrelevantTaskIgnoredNewTaskCreated() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<User> users = ApplicationTestDataFactory.getUsers(1,false);
		insert users;
		//Two accounts
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].ownerId = users[0].Id;
		accounts[1].ownerId = users[0].Id;
		//Two campaigns
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(2, false);
		insert campaigns;
		//Two new contacts
		List<Contact> contacts  = new List<Contact>{ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true)[0],ApplicationTestDataFactory.getContacts(1, accounts[1].Id, true)[0]};
		
		//Set contact__c value on the new values
		List<CampaignContactAssignment__c> newCampaignContactAssignments = new List<CampaignContactAssignment__c>{ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[0].Id,campaigns[0].Id, true)[0],
																											ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[1].Id,campaigns[1].Id, true)[0]};	
		newCampaignContactAssignments[0].Contact__c = contacts[0].Id;
		newCampaignContactAssignments[1].Contact__c = contacts[1].Id;
		//Insert a task not relevant to the contact assignment (different subject line) and with status in progress.
		List<Task>tasks = new List<Task>{ApplicationTestDataFactory.getTasks(1, campaigns[0].Id,  false)[0],ApplicationTestDataFactory.getTasks(1, campaigns[0].Id,  false)[0]};
		tasks[0].ownerId = users[0].Id;
		tasks[0].Subject = 'Test';
		tasks[0].status = CampaignContactAssignmentConstants.TASK_INPROGRESS;
		tasks[1].ownerId = users[0].Id;
		tasks[1].Subject = 'Test 2';
		tasks[1].status = CampaignContactAssignmentConstants.TASK_INPROGRESS;		
		insert tasks;		
		// =====================================
		// Stubbing
		// =====================================
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		AccountsSelector accountsSelector = (AccountsSelector)MockUtility.mockSelector(AccountsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(accountsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Account>(accounts));
		MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignAssignCampaignMembersModule module = CampaignAssignCampaignMembersModule.newInstance();
		module.createTask( (List<SObject>)newCampaignContactAssignments, null , mockUow);
		Test.stopTest();
		((AccountsSelector)MockUtility.Mocks.verify(AccountsSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.anyObject());
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<SObject>)fflib_Match.anyObject());
		// verify the task created for the owner
		System.assertEquals(2, MockUtility.mockUnitOfWorkDMLs.size());		
		System.assertEquals(CampaignContactAssignmentConstants.TASK_INPROGRESS, ((Task)MockUtility.mockUnitOfWorkDMLs[0]).Status, 'Expected task to be created with In Progress for the account owner');	
		System.assertEquals(CampaignContactAssignmentConstants.TASK_INPROGRESS, ((Task)MockUtility.mockUnitOfWorkDMLs[1]).Status, 'Expected task to be created with In Progress for the account owner');	

	}

	/**
	 * Test:
	 *  Tests the DML end-to-end flow for task creation when a new contact assignment record is created with a Contact Id
	 */
	@IsTest
	private static void testEndToEndTaskCreationOnContactAssignmentRecordWithContactId() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<User> users = ApplicationTestDataFactory.getUsers(1,false);
		insert users;
		//Two accounts
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, false);
		insert accounts;
		
		//change account ownership
		accounts[0].ownerId = users[0].Id;
		accounts[1].ownerId = users[0].Id;
		update accounts;
		
		//Two campaigns
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(2, false);
		insert campaigns;
		Map<Id,Campaign>campaignsMap = new Map<Id,Campaign>(campaigns);
		//Two new contacts
		List<Contact> contacts  = new List<Contact>{ApplicationTestDataFactory.getContacts(1, accounts[0].Id, false)[0],ApplicationTestDataFactory.getContacts(1, accounts[1].Id, false)[0]};
		insert contacts;
		
		//Set contact__c value on the new values
		List<CampaignContactAssignment__c> newCampaignContactAssignments = new List<CampaignContactAssignment__c>{ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[0].Id,campaigns[0].Id, false)[0],
																											ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[1].Id,campaigns[1].Id, false)[0]};	
		newCampaignContactAssignments[0].Contact__c = contacts[0].Id;
		newCampaignContactAssignments[1].Contact__c = contacts[1].Id;
		// =====================================
		// Stubbing
		// =====================================


		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		//Insert assignments with contact Id's populated.
		insert newCampaignContactAssignments;
		Test.stopTest();
		// verify the task created for the owner
		System.debug('Keyset :'+campaignsMap.keySet());
		List<Task>newTaskList = new List<Task>([Select Id,Status from Task where whatId IN :campaignsMap.keySet() and ownerId =:users[0].Id]);
		System.assertEquals(newTaskList.Size(), 2, 'Expected two new tasks to be created with In Progress for the account owner');	
		System.assertEquals(CampaignContactAssignmentConstants.TASK_INPROGRESS, newTaskList[0].Status, 'Expected task to be created with In Progress for the account owner');	
		System.assertEquals(CampaignContactAssignmentConstants.TASK_INPROGRESS, newTaskList[1].Status, 'Expected task to be created with In Progress for the account owner');	

	}

	/**
	 * Test:
	 *  Ensures that a campaign member record is created when a Contact is assigned to a Contact Assignment record
	 *  The Campaign Member record status should be set to the Default Status stored in the Campaign record
	 *  NOTE: This should handle at least 2 different contacts / campaigns
	 */
	@IsTest
	private static void testEnsureCampaignMemberCreatedWhenContactAssigned() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();		
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		//Two accounts
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].ownerId = users[0].Id;
		accounts[1].ownerId = users[0].Id;
		//Two campaigns
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(2, true);
		campaigns[0].ContactAssignmentDefaultStatus__c = 'Default Status';
		campaigns[1].ContactAssignmentDefaultStatus__c = 'Default Status';
		//Two new contacts
		List<Contact> contacts  = new List<Contact>{ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true)[0],ApplicationTestDataFactory.getContacts(1, accounts[1].Id, true)[0]};
		//Set contact__c value on the new values
		List<CampaignContactAssignment__c> newCampaignContactAssignments = new List<CampaignContactAssignment__c>{ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[0].Id,campaigns[0].Id, true)[0],
																													ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[1].Id,campaigns[1].Id, true)[0]};	
		newCampaignContactAssignments[0].Contact__c = contacts[0].Id;
		newCampaignContactAssignments[1].Contact__c = contacts[1].Id;	
		newCampaignContactAssignments[0].Description__c = 'Test';
		newCampaignContactAssignments[1].Description__c = 'Test';				
		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CampaignsSelector CampaignsSelector = (CampaignsSelector)MockUtility.mockSelector(CampaignsSelector.class);
		CampaignMembersSelector CampaignMembersSelector = (CampaignMembersSelector)MockUtility.mockSelector(CampaignMembersSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(CampaignsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(campaigns);
		MockUtility.Mocks.when(CampaignMembersSelector.search((Map<String, Set<Id>>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(),fflib_Match.anyBoolean())).thenReturn(new List<CampaignMember>());
		MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignAssignCampaignMembersModule module = CampaignAssignCampaignMembersModule.newInstance();
		module.saveCampaignMembers( (List<SObject>)newCampaignContactAssignments, null, mockUow);
		Test.stopTest();
		((CampaignsSelector)MockUtility.Mocks.verify(CampaignsSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.anyObject());
		((CampaignMembersSelector)MockUtility.Mocks.verify(CampaignMembersSelector, MockUtility.Mocks.times(1))).search((Map<String, Set<Id>>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(),fflib_Match.anyBoolean());
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<SObject>)fflib_Match.anyObject());
		System.assertEquals(2, MockUtility.mockUnitOfWorkDMLs.size());		
		System.assertEquals('Default Status', ((CampaignMember)MockUtility.mockUnitOfWorkDMLs[0]).Status, 'Expected campaign member with default status');
		System.assertEquals('Test', ((CampaignMember)MockUtility.mockUnitOfWorkDMLs[0]).Campaign_Member_Notes__c, 'Expected campaign member status to match the description on the campaign contact assignment');
	
	}

	/**
	 * Test:
	 *  Ensures that a campaign member record is not created when a Contact is assigned to a Contact Assignment record where a Campaign Member record already exists
	 *  NOTE: This should handle at least 2 different contacts / campaigns
	 */
	@IsTest
	private static void testEnsureCampaignMemberCreationIgnoredWhenContactAssigned() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		//Two accounts
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, true);
		accounts[0].ownerId = users[0].Id;
		accounts[1].ownerId = users[0].Id;
		//Two campaigns
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(2, true);
		campaigns[0].ContactAssignmentDefaultStatus__c = 'Default Status';
		campaigns[1].ContactAssignmentDefaultStatus__c = 'Default Status';
		//Two new contacts
		List<Contact> contacts  = new List<Contact>{ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true)[0],ApplicationTestDataFactory.getContacts(1, accounts[1].Id, true)[0]};		
		//Set contact__c value on the new values
		List<CampaignContactAssignment__c> newCampaignContactAssignments = new List<CampaignContactAssignment__c>{ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[0].Id,campaigns[0].Id, true)[0],
																										ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[1].Id,campaigns[1].Id, true)[0]};	
		newCampaignContactAssignments[0].Contact__c = contacts[0].Id;
		newCampaignContactAssignments[1].Contact__c = contacts[1].Id;	
		
		List<CampaignMember> campaignMembers = new List<CampaignMember>{ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, true, campaigns[0].Id, contacts[0].Id)[0],
														ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, true, campaigns[1].Id, contacts[1].Id)[0]};
		campaignMembers[0] = (CampaignMember)ApplicationTestDataFactory.setUnwritableFields(CampaignMembers[0], new Map<String, Object>{'Contact' => contacts[0]});	
		campaignMembers[1] = (CampaignMember)ApplicationTestDataFactory.setUnwritableFields(CampaignMembers[1], new Map<String, Object>{'Contact' => contacts[1]});		
	
		
		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CampaignsSelector CampaignsSelector = (CampaignsSelector)MockUtility.mockSelector(CampaignsSelector.class);
		CampaignMembersSelector CampaignMembersSelector = (CampaignMembersSelector)MockUtility.mockSelector(CampaignMembersSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(CampaignsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(campaigns);
		MockUtility.Mocks.when(CampaignMembersSelector.search((Map<String, Set<Id>>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(),fflib_Match.anyBoolean())).thenReturn(campaignMembers);
		MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignAssignCampaignMembersModule module = CampaignAssignCampaignMembersModule.newInstance();
		module.saveCampaignMembers( (List<SObject>)newCampaignContactAssignments, null, mockUow);
		Test.stopTest();
		((CampaignsSelector)MockUtility.Mocks.verify(CampaignsSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.anyObject());
		((CampaignMembersSelector)MockUtility.Mocks.verify(CampaignMembersSelector, MockUtility.Mocks.times(1))).search((Map<String, Set<Id>>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(),fflib_Match.anyBoolean());
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerNew((List<SObject>)fflib_Match.anyObject());
		System.assertEquals(0, MockUtility.mockUnitOfWorkDMLs.size());		
	}

	/**
	 * Test:
	 *  Ensures that a campaign member record status is updated when a Contact is assigned to a Contact Assignment record where a Campaign Member record already exists with a status of CampaignContactAssignmentConstants.CONTACT_ASSIGNMENT_CHANGED
	 *  NOTE: This should handle at least 2 different contacts / campaigns
	 */
	@IsTest
	private static void testEnsureCampaignMemberStatusUpdatedWhenContactAssigned() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		List<User> users = ApplicationTestDataFactory.getUsers(1,true);
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		accounts[0].ownerId = users[0].Id;
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(1, true);
		campaigns[0].ContactAssignmentDefaultStatus__c = 'Default Status';
		List<CampaignContactAssignment__c> campaignContactAssignments = ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[0].Id,campaigns[0].Id, true);
		List<Contact> contacts  = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, true);
		campaignContactAssignments[0].Contact__c = contacts[0].Id;
		List<CampaignMember> campaignMembers = ApplicationTestDataFactoryCampaigns.getCampaignMembers(1, true, campaigns[0].Id, contacts[0].Id);
		campaignMembers[0] = (CampaignMember)ApplicationTestDataFactory.setUnwritableFields(CampaignMembers[0], new Map<String, Object>{'Contact' => contacts[0], 'Status' => CampaignContactAssignmentConstants.CONTACT_ASSIGNMENT_CHANGED});		
		
		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		CampaignsSelector CampaignsSelector = (CampaignsSelector)MockUtility.mockSelector(CampaignsSelector.class);
		CampaignMembersSelector CampaignMembersSelector = (CampaignMembersSelector)MockUtility.mockSelector(CampaignMembersSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		
		MockUtility.Mocks.when(CampaignsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(campaigns);
		MockUtility.Mocks.when(CampaignMembersSelector.search((Map<String, Set<Id>>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(),fflib_Match.anyBoolean())).thenReturn(campaignMembers);
		MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CampaignAssignCampaignMembersModule module = CampaignAssignCampaignMembersModule.newInstance();
		module.saveCampaignMembers( (List<SObject>)campaignContactAssignments, null, mockUow);
		Test.stopTest();
		((CampaignsSelector)MockUtility.Mocks.verify(CampaignsSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.anyObject());
		((CampaignMembersSelector)MockUtility.Mocks.verify(CampaignMembersSelector, MockUtility.Mocks.times(1))).search((Map<String, Set<Id>>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(),fflib_Match.anyBoolean());
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<SObject>)fflib_Match.anyObject());
		System.assertEquals(1, MockUtility.mockUnitOfWorkDMLs.size());
		System.assertEquals('Default Status', ((CampaignMember)MockUtility.mockUnitOfWorkDMLs[0]).Status, 'Expected campaign member with default status');
	}

	/**
	 * Test:
	 *  Ensures end to end flow completed successfully with DML statements
	 *  A campaign member record shoudl be createdwhen a Contact is assigned to a Contact Assignment record
	 *  NOTE: This should handle at least 2 different contacts / campaigns
	 */
	@IsTest
	private static void testEndToEndCampaignMemberCreationWhenContactAssigned() {
		// =====================================
		// Data Preparation
		// =====================================
		List<User> users = ApplicationTestDataFactory.getUsers(1,false);
		insert users;
		//Two accounts
		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, false);
		insert accounts;
		
		accounts[0].ownerId = users[0].Id;
		accounts[1].ownerId = users[0].Id;
		update accounts;
		//Two campaigns
		List<Campaign> campaigns = ApplicationTestDataFactoryCampaigns.getCampaigns(2, false);
		campaigns[0].ContactAssignmentDefaultStatus__c = 'Default Status';
		campaigns[1].ContactAssignmentDefaultStatus__c = 'Default Status';
		insert campaigns;
		Map<Id,Campaign> campaignsMap = new Map<Id,Campaign>(campaigns);
		
		List<CampaignMemberStatus>cmsList = new List<CampaignMemberStatus>();
		//Create campaign member status
		CampaignMemberStatus cms1 = new CampaignMemberStatus(CampaignId = campaigns[0].Id, IsDefault = true,
											Label = 'Default Status');
		//Create campaign member status
		CampaignMemberStatus cms2 = new CampaignMemberStatus(CampaignId = campaigns[1].Id, IsDefault = true,
											Label = 'Default Status');											
		cmsList.add(cms1);
		cmsList.add(cms2);
		insert cmsList;		
		//Two new contacts
		List<Contact> contacts  = new List<Contact>{ApplicationTestDataFactory.getContacts(1, accounts[0].Id, false)[0],ApplicationTestDataFactory.getContacts(1, accounts[1].Id, false)[0]};
		insert contacts;
		Map<Id,Contact> contactsMap = new Map<Id,Contact>(Contacts);	
		//Set contact__c value on the new values
		List<CampaignContactAssignment__c> newCampaignContactAssignments = new List<CampaignContactAssignment__c>{ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[0].Id,campaigns[0].Id, false)[0],
																										ApplicationTestDataFactoryCampaigns.getCampaignContactAssignments(1,accounts[1].Id,campaigns[1].Id, false)[0]};	
		newCampaignContactAssignments[0].Contact__c = contacts[0].Id;
		newCampaignContactAssignments[0].Description__c = 'Test';
		newCampaignContactAssignments[1].Contact__c = contacts[1].Id;
		newCampaignContactAssignments[1].Description__c = 'Test';	

		// =====================================
		// Stubbing
		// =====================================


		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		//Insert assignments with contact Id's populated.
		insert newCampaignContactAssignments;
		Test.stopTest();
		// verify the campaign members created for the contacts
		List<CampaignMember>cmbrList = new List<CampaignMember>([Select Id,ContactId,Status,Campaign_Member_Notes__c from CampaignMember where ContactId IN :contactsMap.keySet() and CampaignId =:campaignsMap.keySet()]);
		System.assertEquals(cmbrList.Size(), 2, 'Expected 2 campaign member records created based on two assignments');	
		System.assertEquals(campaigns[0].ContactAssignmentDefaultStatus__c, cmbrList[0].Status, 'Expected campaign member records created based on two assignments');	
		System.assertEquals('Test', cmbrList[0].Campaign_Member_Notes__c, 'Expected campaign member description matches the description provided on assignment');
		System.assertEquals('Test', cmbrList[1].Campaign_Member_Notes__c, 'Expected campaign member description matches the description provided on assignment');	
	

	}

}