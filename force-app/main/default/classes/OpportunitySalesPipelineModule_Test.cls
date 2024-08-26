/**
 * @description
 * Test class for OpportunitySalesPipelineModule
 * @author Ranjeewa Silva
 * @group Tests
 * @changelog
 * 2023-08-08 - Ranjeewa Silva - Created
 * 2023-10-16 - Mahesh Parvathaneni - Added test method testOpportunitySplitsAreValidatedOnOpportunityStageChangeBeforeUpdate
 * 2023-10-26 - Mahesh Parvathaneni - Added test method testOpportunityProductsQuantityIsValidOnOpportunityStageChangeBeforeUpdate
 * 2024-01-22 - Mahesh Parvathaneni - Added test method testOpportunityProductsRevenueStartDateIsValidOnOpportunityStageChangeBeforeUpdate
 * 2024-01-25 - Mahesh Parvathaneni - Added test method testByPassErrorsForOpportunityValidationsPermissionOnBeforeUpdate
 * 2024-02-02 - Mahesh Parvathaneni - Added test method testByPassErrorForOpportunityLineItemQuantityValidationPermissionOnBeforeUpdate
 * 2024-06-16 - Sarath Burra - Added test method testAccountFieldUpdateOnAfterInsertUpdate
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
        //opportunities[1] is moving from 'Identify' => 'Test Qualify'
        updatedOpportunities[1].StageName = 'Test Qualify';

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

    /**
     * Test to ensure related opportunity splits on opportunity are assigned to correct role of team member before progressing to
     * next stage
     */
    @IsTest
    static void testOpportunitySplitsAreValidatedOnOpportunityStageChangeBeforeUpdate() {
        // =====================================
        // Data Preparation
        // =====================================
        Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
        List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(2, organisation.Id, true);
        List<User> teamMembers = ApplicationTestDataFactory.getUsers(4, true);

        //two overlay opportunity split records are assigned to first opportunity record
        //one for sales specialist and other for product specialist which are correct role for users
        List<OpportunitySplit> opportunity0Splits = ApplicationTestDataFactory.getOpportunitySplits(1, opportunities[0].Id, teamMembers[0].Id, ApplicationTestDataFactory.overlayContributionOverlayType, 'Sales Specialist', true);
        opportunity0Splits.addAll(ApplicationTestDataFactory.getOpportunitySplits(1, opportunities[0].Id, teamMembers[1].Id, ApplicationTestDataFactory.overlayContributionOverlayType, 'Product Specialist', true));
        opportunities[0] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[0], new Map<String, List<SObject>>{'OpportunitySplits' => opportunity0Splits});

        //three overlay opportunity split records are assigned to second opportunity record
        //one for sales specialist
        //one for product specialist where the product specialist role is incorrect
        //one for international specialist where the user doesn't belong to any group
        List<OpportunitySplit> opportunity1Splits = ApplicationTestDataFactory.getOpportunitySplits(1, opportunities[1].Id, teamMembers[0].Id, ApplicationTestDataFactory.overlayContributionOverlayType, 'Sales Specialist', true);
        opportunity1Splits.addAll(ApplicationTestDataFactory.getOpportunitySplits(1, opportunities[1].Id, teamMembers[2].Id, ApplicationTestDataFactory.overlayContributionOverlayType, 'Product Specialist', true));
        opportunity1Splits.addAll(ApplicationTestDataFactory.getOpportunitySplits(1, opportunities[1].Id, teamMembers[3].Id, ApplicationTestDataFactory.overlayContributionOverlayType, 'International Specialist', true));
        opportunities[1] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[1], new Map<String, List<SObject>>{'OpportunitySplits' => opportunity1Splits});

        // attempt to update opportunity stage to Qualify
        List<Opportunity> updatedOpportunities = opportunities.deepClone(true);
        updatedOpportunities[0].StageName = 'Qualify';
        updatedOpportunities[1].StageName = 'Qualify';

        // =====================================
        // Stubbing
        // =====================================
        OpportunitiesSelector mockOpportunitiesSelector = ((OpportunitiesSelector) MockUtility.mockSelector(OpportunitiesSelector.class));
        OpportunitySplitUtility mockOppSplitUtility = ((OpportunitySplitUtility) MockUtility.mockUtility(OpportunitySplitUtility.class));
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

        // set up responses
        Map<Id, Set<String>> eligibleOverlayTypesResponse = new Map<Id, Set<String>>{
                teamMembers[0].Id => new Set<String>{'Sales Specialist', 'Solutions Specialist'}, // teamMembers[0] is eligible on Sales Specialist, Solutions Specialist overlay types.
                teamMembers[1].Id => new Set<String>{'Product Specialist'}, // teamMembers[1] is eligible on Product Specialist overlay types.
                teamMembers[2].Id => new Set<String>{'Sales Specialist'} // teamMembers[2] is eligible on Product Specialist overlay types.
        };
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockOpportunitiesSelector.selectById((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, Opportunity>(opportunities));
        MockUtility.Mocks.when(mockOppSplitUtility.getEligibleOverlayContributionTypes((Set<Id>)fflib_Match.anyObject(),(Set<OpportunitySplitUtility.OverlayTypeFilters>)fflib_Match.isNull())).thenReturn(eligibleOverlayTypesResponse);
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
        System.assert(!updatedOpportunities[0].hasErrors(), 'No errors expected on opportunity moving to Qualify as the overlay splits are correctly assigned.');
        System.assert(updatedOpportunities[1].hasErrors(), 'Error expected on opportunity moving to Qualify as the Product Specialist overlay split are incorrectly assigned to user');
    }

    /**
     * Test to ensure related opportunity products quantity is validated on opportunity before progressing to
     * next stage
     */
    @IsTest
    static void testOpportunityProductsQuantityIsValidOnOpportunityStageChangeBeforeUpdate() {
        // =====================================
        // Data Preparation
        // =====================================
        Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
        List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(2, organisation.Id, true);
        List<Product2> products = ApplicationTestDataFactory.getProducts(2, true);
        Id priceBookId = Test.getStandardPricebookId();
        List<PricebookEntry> pricebookEntries = ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, products[0].Id, true);
        pricebookEntries.addAll(ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, products[1].Id, true));

        //two opportunity product records are assigned to first opportunity record
        //both of them have quantity = 1
        List<OpportunityLineItem> opportunity0OppLineItems = ApplicationTestDataFactorySales.getOpportunityLineItems(2, opportunities[0].Id, pricebookEntries[0].Id, true);
        opportunities[0] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[0], new Map<String, List<SObject>>{'OpportunityLineItems' => opportunity0OppLineItems});

        //two opportunity product records are assigned to second opportunity record
        //one of them have quantity = 1000 and other quantity = 1
        List<OpportunityLineItem> opportunity1OppLineItems = ApplicationTestDataFactorySales.getOpportunityLineItems(2, opportunities[1].Id, pricebookEntries[1].Id, true);
        opportunity1OppLineItems[0].Quantity = 1000;
        opportunities[1] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[1], new Map<String, List<SObject>>{'OpportunityLineItems' => opportunity1OppLineItems});

        // attempt to update opportunity stage to Qualify
        List<Opportunity> updatedOpportunities = opportunities.deepClone(true);
        updatedOpportunities[0].StageName = 'Qualify';
        updatedOpportunities[1].StageName = 'Qualify';

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

        // verify both the opportunity record ids are passed to the mock opportunity selector
        Set<Id> queriedOpportunityIds = (Set<Id>) opportunityIdCaptor.getValue();
        System.assertEquals(2, queriedOpportunityIds.size(), 'Opportunities moving to a monitored stage must be queried to retrieve related records');

        // verify errors are added to opportunity record
        System.assert(updatedOpportunities[0].hasErrors(), 'Error expected on opportunity moving to Qualify as the Product quantity is 1 for both the products');
        // no errors will be added to this opportunity here as the quantity is set to 1000 for one of the products in the above
        System.assert(!updatedOpportunities[1].hasErrors(), 'No errors expected on opportunity moving to Qualify as one of the product has quantity more than 1.');
    }

    /**
     * Test to ensure related opportunity products revenue start date is validated on opportunity before progressing to
     * next stage
     */
    @IsTest
    static void testOpportunityProductsRevenueStartDateIsValidOnOpportunityStageChangeBeforeUpdate() {
        // =====================================
        // Data Preparation
        // =====================================
        Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
        List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(2, organisation.Id, true);
        //opportunity 1 has pre entry scenario checked
        opportunities[0].Pre_Entry__c = true;
        //set close date for opportunity 3
        opportunities[1].CloseDate = Date.today().addDays(10);
        List<Product2> products = ApplicationTestDataFactory.getProducts(2, true);
        Id priceBookId = Test.getStandardPricebookId();
        List<PricebookEntry> pricebookEntries = ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, products[0].Id, true);
        pricebookEntries.addAll(ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, products[1].Id, true));

        //Scenario #1
        //two opportunity product records are assigned to first opportunity record
        //one of the product has revenue start date in the past
        //opportunity has pre-entry scenario checked, so the validation is not applicable
        List<OpportunityLineItem> opportunity0OppLineItems = ApplicationTestDataFactorySales.getOpportunityLineItems(2, opportunities[0].Id, pricebookEntries[0].Id, true);
        opportunity0OppLineItems[0].Quantity = 1000;
        opportunity0OppLineItems[0].Contract_Start_Date__c = Date.today().addDays(-10);
        opportunities[0] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[0], new Map<String, List<SObject>>{'OpportunityLineItems' => opportunity0OppLineItems});

        //Scenario #2
        //two opportunity product records are assigned to second opportunity record
        //one of the product has revenue start date less than the opportunity close date
        //opportunity has pre-entry scenario unchecked, so the validation is applicable
        List<OpportunityLineItem> opportunity1OppLineItems = ApplicationTestDataFactorySales.getOpportunityLineItems(2, opportunities[1].Id, pricebookEntries[1].Id, true);
        opportunity1OppLineItems[0].Quantity = 1000;
        opportunity1OppLineItems[0].Contract_Start_Date__c = Date.today().addDays(5);
        opportunities[1] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[1], new Map<String, List<SObject>>{'OpportunityLineItems' => opportunity1OppLineItems});

        // attempt to update opportunity stage to Qualify
        List<Opportunity> updatedOpportunities = opportunities.deepClone(true);
        updatedOpportunities[0].StageName = 'Qualify';
        updatedOpportunities[1].StageName = 'Qualify';

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

        // verify both the opportunity record ids are passed to the mock opportunity selector
        Set<Id> queriedOpportunityIds = (Set<Id>) opportunityIdCaptor.getValue();
        System.assertEquals(2, queriedOpportunityIds.size(), 'Opportunities moving to a monitored stage must be queried to retrieve related records');

        // no errors will be added to this opportunity here as the pre-entry scenario is valid for this opportunity
        System.assert(!updatedOpportunities[0].hasErrors(), 'No errors expected on opportunity moving to Qualify as pre-entry scenario is set to true');

        // verify errors are added to opportunity record
        System.assert(updatedOpportunities[1].hasErrors(), 'Error expected on opportunity moving to Qualify as the Revenue Start Date is less than the opportunity close date for one of the product');
    }

    /**
     * Test to ensure user with custom permission ByPassErrorsForOpportunityValidationsPermission is bypassed for custom validations 
     * when opportunities are moved into monitored stages.
     */
    @IsTest
    static void testByPassErrorsForOpportunityValidationsPermissionOnBeforeUpdate() {
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
        //get permission set 
        Id byPassErrorsPermissionSetId = [SELECT Id FROM PermissionSet WHERE Name='BypassErrorsForOpportunityValidations' LIMIT 1].Id ;
        //insert sales admin user
        User salesAdminUser = ApplicationTestDataFactory.getUsers(1, false)[0];
        insert salesAdminUser;

        //assign BypassErrorsForOpportunityValidations to sales admin user
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSetAssignment psa = new PermissionSetAssignment (PermissionSetId = byPassErrorsPermissionSetId, AssigneeId = salesAdminUser.Id);
            insert psa;
        }
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
        System.runAs(salesAdminUser) {
            Test.startTest();
            new OpportunitySalesPipelineModule().onBeforeUpdate(updatedOpportunities, new Map<Id, Opportunity>(opportunities), mockUow);
            Test.stopTest();
        }
        // verify selector method is invoked to query opportunities with related records.
        fflib_ArgumentCaptor opportunityIdCaptor = fflib_ArgumentCaptor.forClass(Set<Id>.class);
        ((OpportunitiesSelector)MockUtility.Mocks.verify(mockOpportunitiesSelector, 1)).selectById((Set<Id>)opportunityIdCaptor.capture(),(Set<Object>)fflib_Match.anyObject());
        // verify no errors are added to opportunity record as custom permission is added to sales admin user
        System.assert(!updatedOpportunities[0].hasErrors(), 'No errors expected on opportunity with related competitors.');
        System.assert(!updatedOpportunities[1].hasErrors(), 'No errors expected on opportunity without related competitors.');
    }

    /**
     * Test to ensure user with custom permission ByPassErrorForOpportunityLineItemQuantityValidationPermission is bypassed for opportunity line item 
     * quantity custom validation
     */
    @IsTest
    static void testByPassErrorForOpportunityLineItemQuantityValidationPermissionOnBeforeUpdate() {
        // =====================================
        // Data Preparation
        // =====================================
        Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
        List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(2, organisation.Id, true);
        List<Product2> products = ApplicationTestDataFactory.getProducts(2, true);
        Id priceBookId = Test.getStandardPricebookId();
        List<PricebookEntry> pricebookEntries = ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, products[0].Id, true);
        pricebookEntries.addAll(ApplicationTestDataFactorySales.getPriceBookEntries(1, priceBookId, products[1].Id, true));

        //two opportunity product records are assigned to first opportunity record
        //both of them have quantity = 1
        List<OpportunityLineItem> opportunity0OppLineItems = ApplicationTestDataFactorySales.getOpportunityLineItems(2, opportunities[0].Id, pricebookEntries[0].Id, true);
        opportunities[0] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[0], new Map<String, List<SObject>>{'OpportunityLineItems' => opportunity0OppLineItems});

        //two opportunity product records are assigned to second opportunity record
        //one of them have quantity = 1000 and other quantity = 1
        List<OpportunityLineItem> opportunity1OppLineItems = ApplicationTestDataFactorySales.getOpportunityLineItems(2, opportunities[1].Id, pricebookEntries[1].Id, true);
        opportunity1OppLineItems[0].Quantity = 1000;
        opportunities[1] = (Opportunity) ApplicationTestDataFactory.setChildRelationships(opportunities[1], new Map<String, List<SObject>>{'OpportunityLineItems' => opportunity1OppLineItems});

        // attempt to update opportunity stage to Qualify
        List<Opportunity> updatedOpportunities = opportunities.deepClone(true);
        updatedOpportunities[0].StageName = 'Qualify';
        updatedOpportunities[1].StageName = 'Qualify';

        //get permission set 
        Id byPassOppLineItemQuantityPermissionSetId = [SELECT Id FROM PermissionSet WHERE Name='BypassErrorForOpportunityLineItemQuantityValidation' LIMIT 1].Id ;
        //insert securepay user
        User securePayUser = ApplicationTestDataFactory.getUsers(1, false)[0];
        insert securePayUser;

        //assign ByPassErrorForOpportunityLineItemQuantityValidation to secure pay user
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSetAssignment psa = new PermissionSetAssignment (PermissionSetId = byPassOppLineItemQuantityPermissionSetId, AssigneeId = securePayUser.Id);
            insert psa;
        }
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
        System.runAs(securePayUser) {
            Test.startTest();
            new OpportunitySalesPipelineModule().onBeforeUpdate(updatedOpportunities, new Map<Id, Opportunity>(opportunities), mockUow);
            Test.stopTest();
        }
        // verify selector method is invoked to query opportunities with related records.
        fflib_ArgumentCaptor opportunityIdCaptor = fflib_ArgumentCaptor.forClass(Set<Id>.class);
        ((OpportunitiesSelector)MockUtility.Mocks.verify(mockOpportunitiesSelector, 1)).selectById((Set<Id>)opportunityIdCaptor.capture(),(Set<Object>)fflib_Match.anyObject());
        // verify no errors are added to opportunity record as custom permission is added to secure pay user
        System.assert(!updatedOpportunities[0].hasErrors(), 'No errors expected on opportunity as permission set is assigned to user.');
        System.assert(!updatedOpportunities[1].hasErrors(), 'No errors expected on opportunity as permission set is assigned to user.');
    }
    @IsTest
    static void testAccountFieldUpdateOnAfterInsertUpdate() {
        // Disable trigger execution
        MockUtility.disableTriggerExecution();
        // =====================================
        // Data Preparation
        // =====================================
        Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
        List<Opportunity> opportunities = ApplicationTestDataFactory.getOpportunities(2, organisation.Id, true);
        List<Opportunity> updatedOpportunities = new List<Opportunity>();
        for(Opportunity opp :opportunities){
            opp.FreightOwnership__c='Yes';
            opp.ControlsLodgement__c='Yes';
            opp = (Opportunity)ApplicationTestDataFactory.setUnwritableFields(opp,new Map<String, Object>{'IndirectCustomer__c' => 'Yes'});
            updatedOpportunities.add(opp);
        }
        Map<Id,Opportunity> existingRecords = new Map<Id,Opportunity>();
        for(Opportunity opp : updatedOpportunities.deepClone(true,true,true)){
            opp = (Opportunity)ApplicationTestDataFactory.setUnwritableFields(opp,new Map<String, Object>{'IndirectCustomer__c' => 'No (or unknown)'});
            existingRecords.put(opp.id,opp);
        }

        // setup child records for Account
        organisation = (Account) ApplicationTestDataFactory.setChildRelationships(organisation, new Map<String, List<SObject>>{
            'Opportunities' => updatedOpportunities
        });
        // =====================================
        // Stubbing
        // =====================================
        AccountsSelector mockAccountsSelector = ((AccountsSelector) MockUtility.mockSelector(AccountsSelector.class));
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
        // Set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockAccountsSelector.selectById(new Set <Id> {organisation.Id})).thenReturn(new Map <Id, Account> { organisation.Id => organisation});
        MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>) fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
        MockUtility.Mocks.stopStubbing();
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        new OpportunitySalesPipelineModule().onAfterInsert(updatedOpportunities,mockUow);
        new OpportunitySalesPipelineModule().onAfterUpdate(updatedOpportunities,existingRecords,mockUow);
        Test.stopTest();        

        //Assert or Verify
        // Verify that only one DML is to be inserted
        ((AccountsSelector) MockUtility.Mocks.verify(mockAccountsSelector, MockUtility.Mocks.times(2))).selectById((Set<Id>) fflib_Match.anyObject());
        system.assertEquals(2, MockUtility.mockUnitOfWorkDMLs.size());
        // Verify in DML that IndirectCustomer__c for Account is set from Opportunity 
        System.assertEquals(
            updatedOpportunities[0].IndirectCustomer__c,
            ((Account) MockUtility.mockUnitOfWorkDMLs[0]).IndirectCustomer__c,
            'Expected IndirectCustomer to be updated from Opportunity'
        );

    }   
}