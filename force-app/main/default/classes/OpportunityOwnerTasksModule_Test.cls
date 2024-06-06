/**
 * @description Test class for OpportunityOwnerTasksModule
 * @author Ranjeewa Silva
 * @group Tests
 * @changelog
 * 2024-05-028 - Ranjeewa Silva - Created
 */
@IsTest
private class OpportunityOwnerTasksModule_Test {

	/**
	 * Ensure async work is enqueued only for opportunities meeting the criteria:
	 *  - Owner is changing
	 *  - In one of the monitored stages
	 *  - Opportunity created via lead conversion
	 */
	@IsTest
	static void testAsyncWorkEnqueuedOnlyWhenOwnerChangesForConvertedOpportunitiesInMonitoredStages() {
		// =====================================
		// Data Preparation
		// =====================================
		List<User> opportunityOwners = ApplicationTestDataFactory.getUsers(2, true);
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(4, organisation.Id, true);

		// opportunities[0] => owner is changing. opportunity in a monitored stage. However opportunity is not created by converting a lead.
		opportunities[0].Lead_ID__c = null;
		opportunities[0].StageName = OpportunityOwnerTasksModule.MONITORED_OPPORTUNITY_STAGES.iterator().next();
		opportunities[0].OwnerId = opportunityOwners[0].Id;

		// opportunities[1] => owner is changing. opportunity is created by converting a lead. However opportunity is not in a monitored stage.
		opportunities[1].Lead_ID__c = 'Lead00000';
		opportunities[1].StageName = 'Negotiate';
		opportunities[1].OwnerId = opportunityOwners[0].Id;

		// opportunities[2] => opportunity is created by converting a lead and in a monitored stage. However owner is NOT changing.
		opportunities[2].Lead_ID__c = 'Lead00000';
		opportunities[2].StageName = OpportunityOwnerTasksModule.MONITORED_OPPORTUNITY_STAGES.iterator().next();
		opportunities[2].OwnerId = opportunityOwners[0].Id;

		// opportunities[3] => owner is changing. opportunity is created by converting a lead and in a monitored stage
		opportunities[3].Lead_ID__c = 'Lead00000';
		opportunities[3].StageName = OpportunityOwnerTasksModule.MONITORED_OPPORTUNITY_STAGES.iterator().next();
		opportunities[3].OwnerId = opportunityOwners[0].Id;

		List<Opportunity> updatedOpportunities = opportunities.deepClone(true);
		// owner changing on opportunities[0], opportunities[1] and opportunities[3]
		updatedOpportunities[0].OwnerId = opportunityOwners[1].Id;
		updatedOpportunities[1].OwnerId = opportunityOwners[1].Id;
		updatedOpportunities[3].OwnerId = opportunityOwners[1].Id;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		new OpportunityOwnerTasksModule().onAfterUpdate(updatedOpportunities, new Map<Id, Opportunity>(opportunities), mockUow);
		Test.stopTest();

		// verify async operation registered with expected parameters
		fflib_ArgumentCaptor asyncWorkerCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.capture());
		ApplicationUnitOfWork.AsyncStagingWorker asyncStagingWorker = (ApplicationUnitOfWork.AsyncStagingWorker) asyncWorkerCaptor.getValue();

		Assert.areEqual(OpportunityOwnerTasksModule.AsyncCreateOpportunityOwnerTasksWorker.class, asyncStagingWorker.classType,
				'Expected AsyncWorker type that handle opportunity owner tasks, but got something else');

		Assert.isTrue(asyncStagingWorker.params != null, 'Expected valid AsyncWorker parameters, but was null');
		Assert.isTrue(asyncStagingWorker.params instanceof Map<Id, OpportunityOwnerTasksModule.CreateOpportunityOwnerTasksWorkerParam>, 'AsyncWorker parameters are not of the expected type');

		Map<Id, OpportunityOwnerTasksModule.CreateOpportunityOwnerTasksWorkerParam> params = (Map<Id, OpportunityOwnerTasksModule.CreateOpportunityOwnerTasksWorkerParam>)asyncStagingWorker.params;
		Assert.areEqual(1, params.size(), 'Expected parameters not passed into async process');
		Assert.isTrue(params.containsKey(opportunities[3].Id), 'Expected opportunity not passed into async process for reconciliation');
		Assert.areEqual(opportunities[3].Id, params.get(opportunities[3].Id).opportunityId, 'Opportunity Id is not populated in the parameters passed into async operation.');
		Assert.areEqual(opportunities[3].OwnerId, params.get(opportunities[3].Id).previousOwnerId, 'Previous Opportunity Owner Id is not populated in the parameters passed into async operation.');
	}

	/**
	 * Ensure async worker creates task and assign to opportunity owner when transferred from lead verification team to
	 * a sales manager.
	 */
	@IsTest
	static void testTaskCreatedForSalesManagerWhenOpportunitiesTransferredFromLeadVerificationTeam() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		User leadVerificationUser = ApplicationTestDataFactory.getUsers(1, true)[0];
		User salesManagerUser = ApplicationTestDataFactory.getUsers(1, true)[0];
		User otherSalesUser = ApplicationTestDataFactory.getUsers(1, true)[0];
		// setup public group membership.
		Map<String, Set<Id>> groupMembershipMap = new Map<String, Set<Id>>{
				OpportunityOwnerTasksModule.LEAD_VERIFICATION_PUBLIC_GROUP => new Set<Id>{leadVerificationUser.Id},
				OpportunityOwnerTasksModule.SALES_MANAGERS_PUBLIC_GROUP => new Set<Id>{salesManagerUser.Id}
		};

		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(3, organisation.Id, true);
		// set up new owners of opportunity where the records are transferred to.
		opportunities[0].OwnerId = salesManagerUser.Id;
		opportunities[1].OwnerId = otherSalesUser.Id;
		opportunities[2].OwnerId = salesManagerUser.Id;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		OpportunitiesSelector opportunitiesSelector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);
		GroupMembershipService groupMembershipService = (GroupMembershipService)MockUtility.mockUtility(GroupMembershipService.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(opportunitiesSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Opportunity>(opportunities));
		MockUtility.Mocks.when(groupMembershipService.expandGroupMembership((Set<String>)fflib_Match.anyObject(), (Set<GroupMembershipService.MemberTypes>)fflib_Match.anyObject())).thenReturn(groupMembershipMap);
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id, OpportunityOwnerTasksModule.CreateOpportunityOwnerTasksWorkerParam> params = new Map<Id, OpportunityOwnerTasksModule.CreateOpportunityOwnerTasksWorkerParam>();
		// opportunities[0] is transferred from leadVerificationUser to salesManagerUser. expected to create a task assigned to sales manager user.
		params.put(opportunities[0].Id, new OpportunityOwnerTasksModule.CreateOpportunityOwnerTasksWorkerParam(opportunities[0].Id, leadVerificationUser.Id));
		// opportunities[1] is transferred from leadVerificationUser to other sales user. task should not be created in this scenario.
		params.put(opportunities[1].Id, new OpportunityOwnerTasksModule.CreateOpportunityOwnerTasksWorkerParam(opportunities[1].Id, leadVerificationUser.Id));
		// opportunities[2] is transferred from other sales user to sales manager user. task should not be created in this scenario.
		params.put(opportunities[2].Id, new OpportunityOwnerTasksModule.CreateOpportunityOwnerTasksWorkerParam(opportunities[2].Id, otherSalesUser.Id));

		OpportunityOwnerTasksModule.AsyncCreateOpportunityOwnerTasksWorker worker = new OpportunityOwnerTasksModule.AsyncCreateOpportunityOwnerTasksWorker();
		worker.deserialiseParams(Json.serialize(params));
		worker.execute(mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor insertedTasksArgCaptor = fflib_ArgumentCaptor.forClass(SObject.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((SObject)insertedTasksArgCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		SObject insertedRecord = (SObject) insertedTasksArgCaptor.getValue();

		Assert.isTrue(insertedRecord instanceof Task, 'Expected to create task record, but created some other type');
		Task insertedTask = (Task) insertedRecord;
		Assert.areEqual(opportunities[0].OwnerId, insertedTask.OwnerId, 'Task is expected to be assigned to new opportunity owner.');
		Assert.areEqual(opportunities[0].Id, insertedTask.WhatId, 'Task is expected to be related to opportunity transferred from lead verification user to sales manager user.');
	}

	/**
	 * Ensure async worker creates task and assign to opportunity owner when transferred from sales manager to an account
	 * manager.
	 */
	@IsTest
	static void testTaskCreatedForAccountManagerWhenConvertedOpportunitiesTransferredFromSalesManager() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		User salesManagerUser = ApplicationTestDataFactory.getUsers(1, true)[0];
		User accountManagerUser = ApplicationTestDataFactory.getUsers(1, true)[0];
		User otherSalesUser = ApplicationTestDataFactory.getUsers(1, true)[0];
		// setup public group membership.
		Map<String, Set<Id>> groupMembershipMap = new Map<String, Set<Id>>{
				OpportunityOwnerTasksModule.SALES_MANAGERS_PUBLIC_GROUP => new Set<Id>{salesManagerUser.Id},
				OpportunityOwnerTasksModule.ACCOUNT_MANAGERS_PUBLIC_GROUP => new Set<Id>{accountManagerUser.Id}
		};

		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(3, organisation.Id, true);
		// set up new owners of opportunity where the records are transferred to.
		opportunities[0].OwnerId = accountManagerUser.Id;
		opportunities[1].OwnerId = otherSalesUser.Id;
		opportunities[2].OwnerId = accountManagerUser.Id;

		// set up existing sales manager task
		Task salesManagerTask = ApplicationTestDataFactory.getTasks(1, opportunities[0].Id, true)[0];
		salesManagerTask.OwnerId = salesManagerUser.Id;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		OpportunitiesSelector opportunitiesSelector = (OpportunitiesSelector)MockUtility.mockSelector(OpportunitiesSelector.class);
		GroupMembershipService groupMembershipService = (GroupMembershipService)MockUtility.mockUtility(GroupMembershipService.class);
		TasksSelector tasksSelector = (TasksSelector)MockUtility.mockSelector(TasksSelector.class);

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(opportunitiesSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id, Opportunity>(opportunities));
		MockUtility.Mocks.when(groupMembershipService.expandGroupMembership((Set<String>)fflib_Match.anyObject(), (Set<GroupMembershipService.MemberTypes>)fflib_Match.anyObject())).thenReturn(groupMembershipMap);
		MockUtility.Mocks.when(tasksSelector.search((Map<String,Object>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true))).thenReturn(new Map<Id, Task>{
				salesManagerTask.Id => salesManagerTask
		});
		MockUtility.Mocks.stopStubbing();


		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id, OpportunityOwnerTasksModule.CreateOpportunityOwnerTasksWorkerParam> params = new Map<Id, OpportunityOwnerTasksModule.CreateOpportunityOwnerTasksWorkerParam>();
		// opportunities[0] is transferred from sales manager to account manager. expected to create a task assigned to account manager.
		params.put(opportunities[0].Id, new OpportunityOwnerTasksModule.CreateOpportunityOwnerTasksWorkerParam(opportunities[0].Id, salesManagerUser.Id));
		// opportunities[1] is transferred from sales manager to other sales user. task should not be created in this scenario.
		params.put(opportunities[1].Id, new OpportunityOwnerTasksModule.CreateOpportunityOwnerTasksWorkerParam(opportunities[1].Id, salesManagerUser.Id));
		// opportunities[2] is transferred from other sales user to account manager user. task should not be created in this scenario.
		params.put(opportunities[2].Id, new OpportunityOwnerTasksModule.CreateOpportunityOwnerTasksWorkerParam(opportunities[2].Id, otherSalesUser.Id));

		OpportunityOwnerTasksModule.AsyncCreateOpportunityOwnerTasksWorker worker = new OpportunityOwnerTasksModule.AsyncCreateOpportunityOwnerTasksWorker();
		worker.deserialiseParams(JSON.serialize(params));
		worker.execute(mockUow);

		Test.stopTest();

		fflib_ArgumentCaptor insertedTasksArgCaptor = fflib_ArgumentCaptor.forClass(SObject.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((SObject)insertedTasksArgCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		SObject insertedRecord = (SObject) insertedTasksArgCaptor.getValue();

		Assert.isTrue(insertedRecord instanceof Task, 'Expected to create task record, but created some other type');
		Task insertedTask = (Task) insertedRecord;
		Assert.areEqual(opportunities[0].OwnerId, insertedTask.OwnerId, 'Task is expected to be assigned to new opportunity owner.');
		Assert.areEqual(opportunities[0].Id, insertedTask.WhatId, 'Task is expected to be related to opportunity transferred from sales manager user to account manager user.');

		fflib_ArgumentCaptor updatedTasksArgCaptor = fflib_ArgumentCaptor.forClass(SObject.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((SObject)updatedTasksArgCaptor.capture(), fflib_Match.eqBoolean(false), fflib_Match.anyString());
		SObject updatedRecord = (SObject) updatedTasksArgCaptor.getValue();

		Assert.isTrue(updatedRecord instanceof Task, 'Expected to update task record, but updated some other type');
		Task updatedTask = (Task) updatedRecord;
		Assert.areEqual('Completed', updatedTask.Status, 'Expected the existing sales manager task to be updated to \'Completed\', but is in status: ' + updatedTask.Status);
	}
}