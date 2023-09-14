/**
 * @description
 * Test class for OpportunitySalesPipelineModule
 * @author Ranjeewa Silva
 * @group Tests
 * @changelog
 * 2023-08-08 - Ranjeewa Silva - Created
 */
@IsTest
private class OpportunitySalesPipelineModule_Test {

	/**
	 * Test to ensure related records on opportunity are validated only for opportunities moving into monitored stages.
	 */
	@IsTest
	static void testRelatedRecordAreValidatedOnlyForMonitoredOpportunityStages() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(2, organisation.Id, true);

		List<Opportunity> updatedOpportunities = opportunities.deepClone(true);
		// opportunities[0] stage is not changing
		updatedOpportunities[0].Description = 'updated description';
		//opportunities[1] is moving from 'Identify' => 'Qualify'
		updatedOpportunities[1].StageName = 'Qualify';

		// =====================================
		// Stubbing
		// =====================================
		OpportunitiesSelector mockOpportunitiesSelector = ((OpportunitiesSelector) MockUtility.mockSelector(OpportunitiesSelector.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		new OpportunitySalesPipelineModule().onBeforeUpdate(updatedOpportunities, new Map<Id, Opportunity>(opportunities), mockUow);
		Test.stopTest();

		// verify selector methods are not invoked to query related records.
		((OpportunitiesSelector)MockUtility.Mocks.verify(mockOpportunitiesSelector, 0)).selectById((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject());

		for (Opportunity record: updatedOpportunities) {
			System.assert(!record.hasErrors(), 'Errors should not be added when opportunity stage is not changing or stage is not changing to a monitored stage.');
		}
	}

	/**
	 * Test to ensure related competitors on opportunity are validated for opportunities moving into monitored stages.
	 */
	@IsTest
	static void testCompetitorDetailsAreValidatedOnOpportunityStageChangeBeforeUpdate() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(2, organisation.Id, true);

		// only one opportunity record has competitors populated
		List<Competitor__c> competitors = ApplicationTestDataFactorySales.getCompetitors(1, opportunities[0].Id, true);
		opportunities[0] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[0], new Map<String, List<SObject>>{'Competitors__r' => competitors});

		// update stage on both opportunities from 'Identify'
		List<Opportunity> updatedOpportunities = opportunities.deepClone(true);
		updatedOpportunities[0].StageName = OpportunitySalesPipelineModule.OPPORTUNITY_STAGES_VALIDATE_COMPETITORS.iterator().next();
		updatedOpportunities[1].StageName = OpportunitySalesPipelineModule.OPPORTUNITY_STAGES_VALIDATE_COMPETITORS.iterator().next();

		// =====================================
		// Stubbing
		// =====================================
		OpportunitiesSelector mockOpportunitiesSelector = ((OpportunitiesSelector) MockUtility.mockSelector(OpportunitiesSelector.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockOpportunitiesSelector.selectById((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Opportunity>(opportunities));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		new OpportunitySalesPipelineModule().onBeforeUpdate(updatedOpportunities, new Map<Id, Opportunity>(opportunities), mockUow);
		Test.stopTest();

		// verify selector method invoked to query opportunities with related records.
		fflib_ArgumentCaptor opportunityIdCaptor = fflib_ArgumentCaptor.forClass(Set<Id>.class);
		((OpportunitiesSelector)MockUtility.Mocks.verify(mockOpportunitiesSelector, 1)).selectById((Set<Id>)opportunityIdCaptor.capture(),(Set<Object>)fflib_Match.anyObject());

		Set<Id> queriedOpportunityIds = (Set<Id>) opportunityIdCaptor.getValue();
		System.assertEquals(2, queriedOpportunityIds.size(), 'Opportunities moving to a monitored stage must be queried to retrieve related records');

		// verify errors are added to opportunity record
		System.assert(!updatedOpportunities[0].hasErrors(), 'No errors expected on opportunity with related competitors.');
		System.assert(updatedOpportunities[1].hasErrors(), 'Error expected on opportunity without related competitors.');
	}

	/**
	 * Test to ensure related DSRs on opportunity are completed / closed for opportunities moving into Closed Won stage.
	 */
	@IsTest
	static void testOpportunitiesWithOpenDSRsCannotBeMovedToClosedWonStage() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(3, organisation.Id, true);

		// populate competitors on opportunity records
		List<Competitor__c> competitors = ApplicationTestDataFactorySales.getCompetitors(1, opportunities[0].Id, true);

		Deal_Support_Request__c closedDSR = ApplicationTestDataFactory.getDealSupportRequests(1, opportunities[0].Id, organisation.Id, true)[0];
		closedDSR.Stage__c = 'Closed';

		Deal_Support_Request__c completedDSR = ApplicationTestDataFactory.getDealSupportRequests(1, opportunities[1].Id, organisation.Id, true)[0];
		completedDSR.Stage__c = 'Completed';

		Deal_Support_Request__c openDSR = ApplicationTestDataFactory.getDealSupportRequests(1, opportunities[2].Id, organisation.Id, true)[0];
		openDSR.Stage__c = 'Submitted';

		// setup child records for opportunity[0]. child DSR is closed.
		opportunities[0] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[0], new Map<String, List<SObject>>{
				'Competitors__r' => competitors,
				'Deal_Support_Request__r' => new List<Deal_Support_Request__c>{closedDSR}
		});

		// setup child records for opportunity[1]. child DSR is completed.
		opportunities[1] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[1], new Map<String, List<SObject>>{
				'Competitors__r' => competitors,
				'Deal_Support_Request__r' => new List<Deal_Support_Request__c>{completedDSR}
		});

		// setup child records for opportunity[2]. child DSR is still open.
		opportunities[2] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[2], new Map<String, List<SObject>>{
				'Competitors__r' => competitors,
				'Deal_Support_Request__r' => new List<Deal_Support_Request__c>{openDSR}
		});

		// attempt to update opportunity stage to Closed Won
		List<Opportunity> updatedOpportunities = opportunities.deepClone(true);
		updatedOpportunities[0].StageName = 'Closed Won';
		updatedOpportunities[1].StageName = 'Closed Won';
		updatedOpportunities[2].StageName = 'Closed Won';

		// =====================================
		// Stubbing
		// =====================================
		OpportunitiesSelector mockOpportunitiesSelector = ((OpportunitiesSelector) MockUtility.mockSelector(OpportunitiesSelector.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockOpportunitiesSelector.selectById((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Opportunity>(opportunities));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		new OpportunitySalesPipelineModule().onBeforeUpdate(updatedOpportunities, new Map<Id, Opportunity>(opportunities), mockUow);
		Test.stopTest();

		// verify selector method invoked to query opportunities with related records.
		fflib_ArgumentCaptor opportunityIdCaptor = fflib_ArgumentCaptor.forClass(Set<Id>.class);
		((OpportunitiesSelector)MockUtility.Mocks.verify(mockOpportunitiesSelector, 1)).selectById((Set<Id>)opportunityIdCaptor.capture(),(Set<Object>)fflib_Match.anyObject());

		Set<Id> queriedOpportunityIds = (Set<Id>) opportunityIdCaptor.getValue();
		System.assertEquals(3, queriedOpportunityIds.size(), 'Opportunities moving to a monitored stage must be queried to retrieve related records');

		// verify errors are added to opportunity record
		System.assert(!updatedOpportunities[0].hasErrors(), 'No errors expected on opportunity moving to Closed Won when child DSRs are closed.');
		System.assert(!updatedOpportunities[1].hasErrors(), 'No errors expected on opportunity moving to Closed Won when child DSRs are completed.');
		System.assert(updatedOpportunities[2].hasErrors(), 'Error expected on opportunity moving to Closed Won when child DSRs are still open.');
	}

	/**
	 * Test to ensure related Apttus Contracts on opportunity cannot be active for opportunities moving into
	 * Closed Lost / Disqualified / Duplicate stage.
	 */
	@IsTest
	static void testOpportunitiesWithActiveApttusContractsCannotBeMovedToClosedLostStage() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Contact primaryContact = ApplicationTestDataFactory.getContacts(1, organisation.Id, true)[0];
		List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(3, organisation.Id, true);

		// opportunities[0] has an active apttus contract
		Apttus__APTS_Agreement__c activeContract = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunities[0].Id, true)[0];
		activeContract.Apttus__Status_Category__c = 'In Effect';
		activeContract.Apttus__Status__c = 'Activated';
		opportunities[0] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[0], new Map<String, List<SObject>>{
				'Apttus__R00N50000001Xl0FEAS__r' => new List<Apttus__APTS_Agreement__c>{activeContract}
		});

		// opportunities[1] has an apttus contract in "Request" status
		Apttus__APTS_Agreement__c requestedContract = ApplicationTestDataFactory.getApttusContracts(1, primaryContact.Id, opportunities[0].Id, true)[0];
		requestedContract.Apttus__Status_Category__c = 'Request';
		requestedContract.Apttus__Status__c = 'Request';
		opportunities[1] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[1], new Map<String, List<SObject>>{
				'Apttus__R00N50000001Xl0FEAS__r' => new List<Apttus__APTS_Agreement__c>{requestedContract}
		});

		// opportunities[2] has no apttus contract

		// update stage on all opportunities to Closed Lost
		List<Opportunity> updatedOpportunities = opportunities.deepClone(true);
		updatedOpportunities[0].StageName = 'Closed Lost';
		updatedOpportunities[1].StageName = 'Closed Lost';
		updatedOpportunities[2].StageName = 'Closed Lost';

		// =====================================
		// Stubbing
		// =====================================
		OpportunitiesSelector mockOpportunitiesSelector = ((OpportunitiesSelector) MockUtility.mockSelector(OpportunitiesSelector.class));
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

		// set up responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockOpportunitiesSelector.selectById((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Opportunity>(opportunities));
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		new OpportunitySalesPipelineModule().onBeforeUpdate(updatedOpportunities, new Map<Id, Opportunity>(opportunities), mockUow);
		Test.stopTest();

		// verify selector method invoked to query opportunities with related records.
		fflib_ArgumentCaptor opportunityIdCaptor = fflib_ArgumentCaptor.forClass(Set<Id>.class);
		((OpportunitiesSelector)MockUtility.Mocks.verify(mockOpportunitiesSelector, 1)).selectById((Set<Id>)opportunityIdCaptor.capture(),(Set<Object>)fflib_Match.anyObject());

		Set<Id> queriedOpportunityIds = (Set<Id>) opportunityIdCaptor.getValue();
		System.assertEquals(3, queriedOpportunityIds.size(), 'Opportunities moving to a monitored stage must be queried to retrieve related records');

		// verify errors are added to opportunity record
		System.assert(updatedOpportunities[0].hasErrors(), 'Error expected on opportunity moving to closed lost with an active apttus contract.');
		System.assert(!updatedOpportunities[1].hasErrors(), 'No errors expected on opportunity moving to closed lost with an apttus contract not active.');
		System.assert(!updatedOpportunities[2].hasErrors(), 'No errors expected on opportunity moving to closed lost with no apttus contract.');
	}
}