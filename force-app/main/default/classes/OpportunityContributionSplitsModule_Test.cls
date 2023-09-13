/**
 * @description
 * Test class for SalesOpportunityContributionSplitsModule
 * @author Ranjeewa Silva
 * @group Tests
 * @domain Sales
 * @changelog
 * 2023-05-04 - Ranjeewa Silva - Created
 */
@IsTest
private class OpportunityContributionSplitsModule_Test {

	/**
	 * Test to ensure async operation is registered on opportunity insert to auto assign overlay contribution splits
	 * to opportunity owner when opportunity owner is also a member of specialist sales teams
	 * (e.g. Product Specialist, International Specialist).
	 */
	@IsTest
	static void testAsyncOperationRegisteredToCreateSplitsOnOpportunityAfterInsert() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		List<User> opportunityOwners = ApplicationTestDataFactory.getUsers(3, true);
		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(4, organisation.Id, true);
		// set up opportunity owners. opportunityOwners[2] owns two separate opportunities.
		opportunities[0].OwnerId = opportunityOwners[0].Id;
		opportunities[1].OwnerId = opportunityOwners[1].Id;
		opportunities[2].OwnerId = opportunityOwners[2].Id;
		opportunities[3].OwnerId = opportunityOwners[2].Id;

		// =====================================
		// Stubbing
		// =====================================
		OpportunitySplitUtility mockOppSplitUtility = ((OpportunitySplitUtility) MockUtility.mockUtility(OpportunitySplitUtility.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		Map<Id, Set<String>> eligibleOverlayTypesResponse = new Map<Id, Set<String>>{
				opportunityOwners[0].Id => new Set<String>{'overlay type1', 'overlay type2'}, // opportunityOwners[0] is eligible on 2 overlay types.
				opportunityOwners[2].Id => new Set<String>{'overlay type1'} // opportunityOwners[2] owns 2 opportunities and eligible on 1 overlay type
		};

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockOppSplitUtility.getEligibleOverlayContributionTypes((Set<Id>)fflib_Match.anyObject(),(Set<OpportunitySplitUtility.OverlayTypeFilters>)fflib_Match.anyObject())).thenReturn(eligibleOverlayTypesResponse);
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		SalesOpportunityContributionSplitsModule.newInstance().onAfterInsert(opportunities, mockUow);
		Test.stopTest();

		// verify async operation registered with expected parameters
		fflib_ArgumentCaptor asyncWorkerCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.capture());
		ApplicationUnitOfWork.AsyncStagingWorker asyncStagingWorker = (ApplicationUnitOfWork.AsyncStagingWorker) asyncWorkerCaptor.getValue();

		System.assertEquals(OpportunitySplitUtility.AsyncAutoAssignOpportunitySplitsWorker.class, asyncStagingWorker.classType,
				'Expected AsyncWorker type that handle auto assignment of opportunity splits, but got something else');

		System.assert(asyncStagingWorker.params != null, 'Expected valid AsyncWorker parameters, but was null');
		System.assert(asyncStagingWorker.params instanceof List<OpportunitySplitUtility.AutoAssignOpportunitySplitsWorkerParam>, 'AsyncWorker parameters are not of the expected type');

		List<OpportunitySplitUtility.AutoAssignOpportunitySplitsWorkerParam> params = (List<OpportunitySplitUtility.AutoAssignOpportunitySplitsWorkerParam>)asyncStagingWorker.params;
		System.assertEquals(3, params.size(), 'Expected parameters not passed into async process');

		for (OpportunitySplitUtility.AutoAssignOpportunitySplitsWorkerParam param: params) {
			if (param.opportunityId == opportunities[0].Id) {
				System.assertEquals(opportunityOwners[0].Id, param.ownerId, 'Expected splits to be assigned to opportunity owner');
				System.assert(param.overlayTypes.containsAll(new Set<String>{'overlay type1', 'overlay type2'}), 'Expected splits not assigned to opportunity owner');
			} else if (param.opportunityId == opportunities[2].Id || param.opportunityId == opportunities[3].Id) {
				System.assertEquals(opportunityOwners[2].Id, param.ownerId, 'Expected splits to be assigned to opportunity owner');
				System.assert(param.overlayTypes.contains('overlay type1'), 'Expected splits not assigned to opportunity owner');
			} else{
				//fail
				System.assert(false, 'Opportunity splits not expected to be created for this opportunity');
			}
		}
	}

	/**
	 * Test to ensure exceptions encountered during after insert operation are logged
	 */
	@IsTest
	static void testAnyExceptionsAreLoggedOnOpportunityAfterInsert() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		User opportunityOwner = ApplicationTestDataFactory.getUsers(1, true)[0];
		Opportunity opportunity = ApplicationTestDataFactory.getOpportunities(1, organisation.Id, true)[0];
		// set up opportunity owners.
		opportunity.OwnerId = opportunityOwner.Id;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);
		OpportunitySplitUtility mockOppSplitUtility = ((OpportunitySplitUtility) MockUtility.mockUtility(OpportunitySplitUtility.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockOppSplitUtility.getEligibleOverlayContributionTypes((Set<Id>)fflib_Match.anyObject(),(Set<OpportunitySplitUtility.OverlayTypeFilters>)fflib_Match.anyObject())).thenThrow(new MockException());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		SalesOpportunityContributionSplitsModule.newInstance().onAfterInsert(new List<Opportunity>{opportunity}, mockUow);
		Test.stopTest();

		// verify exception is logged
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 1)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(),
				fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(),
				(ApplicationLogger.LoggingLevel)fflib_Match.anyObject());

	}

	/**
	 * Test to ensure async operation is registered on opportunity transfer when previous owner also owned
	 * overlay contribution splits.
	 */
	@IsTest
	static void testAsyncOperationRegisteredToReconcileSplitsOnOpportunityBeforeUpdate() {
		// =====================================
		// Data Preparation
		// =====================================

		// Test scenario - 4 opportunities
		// opportunities[0] => owner not changing
		// opportunities[1] => owner changing, no splits
		// opportunities[2] => owner changing, has splits, but not owned by previous owner
		// opportunities[3] => owner changing, has splits owned by previous owner.
		// only opportunities[3] should cause an async operation to be registered

		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		List<User> priorOwners = ApplicationTestDataFactory.getUsers(4, true);
		List<User> newOwners = ApplicationTestDataFactory.getUsers(4, true);

		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(4, organisation.Id, true);
		// set up opportunity owners.
		opportunities[0].OwnerId = priorOwners[0].Id;
		opportunities[1].OwnerId = priorOwners[1].Id;
		opportunities[2].OwnerId = priorOwners[2].Id;
		opportunities[3].OwnerId = priorOwners[3].Id;

		// setup opportunity splits
		// opportunity[0] has one split owned by it's owner
		List<OpportunitySplit> opportunity0_splits = ApplicationTestDataFactory.getOpportunitySplits(1, opportunities[0].Id, opportunities[0].OwnerId, null, 'test', true);
		opportunities[0] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[0], new Map<String, List<SObject>>{'OpportunitySplits' => opportunity0_splits});

		// opportunity[1] has no splits

		// opportunity[2] has one split owned by a user other than the opportunity owner
		List<OpportunitySplit> opportunity2_splits = ApplicationTestDataFactory.getOpportunitySplits(1, opportunities[2].Id, priorOwners[0].Id, null, 'test', true);
		opportunities[2] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[2], new Map<String, List<SObject>>{'OpportunitySplits' => opportunity2_splits});

		// opportunity[3] has two splits. one of them is owned by the opportunity owner
		OpportunitySplit opportunity3_split1 = ApplicationTestDataFactory.getOpportunitySplits(1, opportunities[3].Id, opportunities[3].OwnerId, null, 'test', true)[0];
		OpportunitySplit opportunity3_split2 = ApplicationTestDataFactory.getOpportunitySplits(1, opportunities[3].Id, priorOwners[0].Id, null, 'test', true)[0];
		opportunities[3] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[3], new Map<String, List<SObject>>{'OpportunitySplits' => new List<SObject>{opportunity3_split1, opportunity3_split2}});

		// setup new versions of the opportunities
		List<Opportunity> newOpportunities = opportunities.deepClone(true);
		// owner is not changing on opportunity[0]. opportunity owner owns overlay contribution splits.
		newOpportunities[0].Amount = 10000;
		// owner is  changing on opportunity[1]. no splits on opportunity[1].
		newOpportunities[1].OwnerId = newOwners[1].Id;
		// owner is  changing on opportunity[2]. contains one split, but not owned by the previous opportunity owner.
		newOpportunities[2].OwnerId = newOwners[2].Id;
		// owner is  changing on opportunity[3]. contains two splits, one of them is owned by the previous opportunity owner.
		newOpportunities[3].OwnerId = newOwners[3].Id;

		// =====================================
		// Stubbing
		// =====================================
		OpportunitiesSelector mockOpportunitySelector = ((OpportunitiesSelector) MockUtility.mockSelector(OpportunitiesSelector.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockOpportunitySelector.selectById((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Opportunity>{
				opportunities[1].Id => opportunities[1],
				opportunities[2].Id => opportunities[2],
				opportunities[3].Id => opportunities[3]
		});
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		SalesOpportunityContributionSplitsModule.newInstance().onBeforeUpdate(newOpportunities, new Map<Id, Opportunity>(opportunities), mockUow);
		Test.stopTest();

		// verify async operation registered with expected parameters
		fflib_ArgumentCaptor asyncWorkerCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)asyncWorkerCaptor.capture());
		ApplicationUnitOfWork.AsyncStagingWorker asyncStagingWorker = (ApplicationUnitOfWork.AsyncStagingWorker) asyncWorkerCaptor.getValue();

		System.assertEquals(OpportunitySplitUtility.AsyncReconcileOpportunitySplitsWorker.class, asyncStagingWorker.classType,
				'Expected AsyncWorker type that handle auto assignment of opportunity splits, but got something else');

		System.assert(asyncStagingWorker.params != null, 'Expected valid AsyncWorker parameters, but was null');
		System.assert(asyncStagingWorker.params instanceof Map<Id, OpportunitySplitUtility.ReconcileOpportunitySplitsWorkerParam>, 'AsyncWorker parameters are not of the expected type');

		Map<Id, OpportunitySplitUtility.ReconcileOpportunitySplitsWorkerParam> params = (Map<Id, OpportunitySplitUtility.ReconcileOpportunitySplitsWorkerParam>)asyncStagingWorker.params;
		System.assertEquals(1, params.size(), 'Expected parameters not passed into async process');
		System.assert(params.containsKey(opportunities[3].Id), 'Expected opportunity not passed into async process for reconciliation');
		System.assertEquals(opportunities[3].Id, params.get(opportunities[3].Id).opportunityId, 'Opportunity Id is not populated in the parameters passed into async operation.');
		System.assertEquals(opportunities[3].OwnerId, params.get(opportunities[3].Id).previousOwnerId, 'Opportunity Id is not populated in the parameters passed into async operation.');
		System.assertEquals(1, params.get(opportunities[3].Id).splitsOwnedByPreviousOpportunityOwner.size(), 'Expected only the splits owned by previous opportunity owner, but got more');
		OpportunitySplitUtility.OpportunitySplitSnapshot snapshot = params.get(opportunities[3].Id).splitsOwnedByPreviousOpportunityOwner[0];
		System.assertEquals(opportunity3_split1.Id, snapshot.splitId, 'Expected to snapshot only the split owned by previous opportunity owner, but got some other split');
		System.assertEquals(opportunities[3].OwnerId, snapshot.splitOwnerId, 'Expected to snapshot only the split owned by previous opportunity owner, but owner id is incorrect on snapshot.');
		System.assertEquals(opportunity3_split1.Overlay_Type__c, snapshot.overlayType, 'Expected to snapshot only the split owned by previous opportunity owner, but overlay type is incorrect on snapshot.');
	}

	/**
	 * Test to ensure async operation is not registered again if already enqueued in current transaction.
	 */
	@IsTest
	static void testAsyncOperationNotRegisteredAgainOnAlreadyEnqueuedOpportunities() {
		// =====================================
		// Data Preparation
		// =====================================

		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		List<User> priorOwners = ApplicationTestDataFactory.getUsers(1, true);
		List<User> newOwners = ApplicationTestDataFactory.getUsers(1, true);

		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(1, organisation.Id, true);
		// set up opportunity owners.
		opportunities[0].OwnerId = priorOwners[0].Id;

		// opportunity[0] has one split owned by the opportunity owner
		OpportunitySplit opportunitySplit = ApplicationTestDataFactory.getOpportunitySplits(1, opportunities[0].Id, opportunities[0].OwnerId, null, 'test', true)[0];
		opportunities[0] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[0], new Map<String, List<SObject>>{'OpportunitySplits' => new List<SObject>{opportunitySplit}});

		// setup new version of the opportunity
		List<Opportunity> newOpportunities = opportunities.deepClone(true);
		// owner is  changing on opportunity[0].
		newOpportunities[0].OwnerId = newOwners[0].Id;

		// =====================================
		// Stubbing
		// =====================================
		OpportunitiesSelector mockOpportunitySelector = ((OpportunitiesSelector) MockUtility.mockSelector(OpportunitiesSelector.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// populate 'SalesOpportunityContributionSplitsModule.enqueuedOpportunityIds' with opportunities[0].Id. this is to
		// simulate the scenario when this opportunity has already been processed by the module and async operation
		// already registered.
		SalesOpportunityContributionSplitsModule.enqueuedOpportunityIds = new Set<Id>{opportunities[0].Id};

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		SalesOpportunityContributionSplitsModule.newInstance().onBeforeUpdate(newOpportunities, new Map<Id, Opportunity>(opportunities), mockUow);
		Test.stopTest();

		// make sure selector is not invoked to query opportunities with splits
		((OpportunitiesSelector)MockUtility.Mocks.verify(mockOpportunitySelector, 0)).selectById((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject());

		// verify no async operation is registered
		((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 0)).registerAsyncWork((ApplicationUnitOfWork.AsyncStagingWorker)fflib_Match.anyObject());
	}

	/**
	 * Test to ensure exceptions encountered during before update are logged
	 */
	@IsTest
	static void testAnyExceptionsAreLoggedOnOpportunityBeforeUpdate() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		List<User> opportunityOwners = ApplicationTestDataFactory.getUsers(2, true);
		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(1, organisation.Id, true);
		// set up opportunity owners.
		opportunities[0].OwnerId = opportunityOwners[0].Id;

		// setup new version of the opportunity
		List<Opportunity> newOpportunities = opportunities.deepClone(true);
		// owner is  changing on opportunity[0].
		newOpportunities[0].OwnerId = opportunityOwners[1].Id;

		// =====================================
		// Stubbing
		// =====================================
		ApplicationLogger mockLogger = (ApplicationLogger)MockUtility.mockUtility(ApplicationLogger.class);
		OpportunitiesSelector mockOpportunitySelector = ((OpportunitiesSelector) MockUtility.mockSelector(OpportunitiesSelector.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockOpportunitySelector.selectById((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenThrow(new MockException());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		SalesOpportunityContributionSplitsModule.newInstance().onBeforeUpdate(newOpportunities, new Map<Id, Opportunity>(opportunities), mockUow);
		Test.stopTest();

		// verify exception is logged
		((ApplicationLogger)MockUtility.Mocks.verify(mockLogger, 1)).logException((ApplicationLogger.ExceptionWrapper)fflib_Match.anyObject(),
				fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(), fflib_Match.anyString(),
				(ApplicationLogger.LoggingLevel)fflib_Match.anyObject());
	}

	private class MockException extends Exception {}
}