/**
* @author Ashapriya Gadi
* @date 2021-12-08
* @group Tests
* @tag module
* @tag case
* @domain CasesDomain
* @description Test class covering CaseOwnerMetricsModule
* @changelog
* 2021-12-08 - Ashapriya Gadi - Created
* 2023-06-19 - Nathan Franklin - updated unit of work source to CaseAutomationTriggerHandler
*/
@IsTest
Private class CaseOwnerMetricsModule_Test {
	/**
	* Test:
	*  When a case is inserted and is assigned to a queue
	**/
	@IsTest
	private static void testEnsureBeforeInsertAssignQueue() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseAutomationTriggerHandler.getUnitOfWorkSObjectTypes());
		//get a queue
		List<Group> queues = ApplicationTestDataFactory.getGroups(1,true);
		queues[0].Name = 'BGS Amazon';
		//insert case with queue as owner
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].ownerId = queues[0].Id;
		cases[0].Last_Assigned_Queue_ID__c = queues[0].Id;
		// =====================================
		// Stubbing
		// =====================================
		GroupsSelector mockGroupsSelector = (GroupsSelector)MockUtility.mockSelector(GroupsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockGroupsSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Group>(queues));
		MockUtility.Mocks.stopStubbing();
		Test.startTest();
		CaseOwnerMetricsModule module = CaseOwnerMetricsModule.newInstance();
		module.onBeforeInsert( (List<SObject>)cases, uow);
		Test.stopTest();
		system.assertEquals(cases[0].Last_Assigned_Queue_ID__c,queues[0].Id,'case last assigned queue id is not equal to queue id');
	}
	/**
	* Test:
	*  When a case is updated and is not assigned to a queue that is present in case_Entitlements metadata
	**/
	@IsTest
	private static void testEnsureBeforeUpdateAssignQueue() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseAutomationTriggerHandler.getUnitOfWorkSObjectTypes());
		//get a queue that is not in custom metadata
		List<Group> queues = ApplicationTestDataFactory.getGroups(1,true);
		queues[0].Name = 'BAU Users';
		//insert case with a queue as owner
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].ownerId = queues[0].Id;
		cases[0].Last_Assigned_Queue_ID__c = queues[0].Id;
		cases[0].Status = 'new';
		cases[0].ClosureOwnerRole__c = 'new';
		//clone old case with diff status
		List<Case> oldCases = new List<Case>{cases[0].clone(true)};
		oldCases[0].Status = 'Closed';
		List<Case> oldCasesList = new List<Case>{oldCases[0]};
		//get userrole
		List<UserRole> userRoles = ApplicationTestDataFactory.getUserRoles(1, true);
		userRoles[0].Name = 'Architect';
		userRoles[0].RollupDescription = 'Architect';
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// =====================================
		// Stubbing
		// =====================================
		UserRolesSelector mockUserRoleSelector = (UserRolesSelector)MockUtility.mockSelector(UserRolesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUserRoleSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, UserRole>(userRoles));
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseOwnerMetricsModule module = CaseOwnerMetricsModule.newInstance();
		module.onBeforeUpdate( (List<SObject>)cases, new Map<Id, SObject>(oldCasesList), uow);
		Test.stopTest();
		system.assertEquals(cases[0].Last_Assigned_Queue_ID__c,queues[0].Id,'case last assigned queue id is not equal to queue id');
	}
	/**
	* Test:
	*  When a case is updated to change the status
	**/
	@IsTest
	private static void testEnsureBeforeUpdateAssignRole() {
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CaseAutomationTriggerHandler.getUnitOfWorkSObjectTypes());
		//get a queue that is not in custom metadata
		List<Group> queues = ApplicationTestDataFactory.getGroups(1,true);
		queues[0].Name = 'BAU Users';
		//insert case with a queue as owner
		List<Case> cases = ApplicationTestDataFactory.getCases(1, true);
		cases[0].ownerId = queues[0].Id;
		cases[0].Last_Assigned_Queue_ID__c = queues[0].Id;
		cases[0].Status = 'Closed';
		cases[0].ClosureOwnerRole__c = 'new';
		//clone old case with diff status
		List<Case> oldCases = new List<Case>{cases[0].clone(true)};
		oldCases[0].Status = 'New';
		List<Case> oldCasesList = new List<Case>{oldCases[0]};
		//get userrole
		List<UserRole> userRoles = ApplicationTestDataFactory.getUserRoles(1, true);
		userRoles[0].Name = 'Architect';
		userRoles[0].RollupDescription = 'Architect';
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		// =====================================
		// Stubbing
		// =====================================
		UserRolesSelector mockUserRoleSelector = (UserRolesSelector)MockUtility.mockSelector(UserRolesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockUserRoleSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, UserRole>(userRoles));
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		CaseOwnerMetricsModule module = CaseOwnerMetricsModule.newInstance();
		module.onBeforeUpdate( (List<SObject>)cases, new Map<Id, SObject>(oldCasesList), uow);
		Test.stopTest();
		system.assertEquals(cases[0].ClosureOwnerRole__c,userRoles[0].RollupDescription,'case last assigned queue id is not equal to queue id');
	}
}