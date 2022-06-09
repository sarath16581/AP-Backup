/***
 * @author Dattaraj Deshmukh
 * @date 2022-06-06
 * @domain Core
 * @description Test class for DealSupportRequestMilestonesTrackModule. Class name truncated as reached out max char limit.
 * @changelog
 * 2022-06-06 - Dattaraj Deshmukh - Created
 */
@IsTest
public with sharing class DealSpprtReqsMilestonesTrackModule_Test {
    

    @IsTest
    static void testOnBeforeUpdate(){
        MockUtility.disableTriggerExecution();


        DealSupportRequestMilestonesTrackModule module = DealSupportRequestMilestonesTrackModule.newInstance();

        //prepare data
        List<Account> organisations = ApplicationTestDataFactory.getAccounts(1, true);
        List<Deal_Support_Request__c> dealSupportRequests = ApplicationTestDataFactory.getDealSupportRequests(1, null, organisations[0].Id, true);
        dealSupportRequests[0].Implementation_Stage__c = 'Idea - Sales';
        dealSupportRequests[0].Last_Implementation_Stage_Update__c = System.now().addMinutes(-60);


        Deal_Support_Request__c updatedDSR = dealSupportRequests[0].clone(true, true, false, true);
        updatedDSR.Implementation_Stage__c = 'Scope - Onboarding';

        Map<Id, Deal_Support_Request__c> existingRecords = new Map<Id, Deal_Support_Request__c>{ dealSupportRequests[0].Id =>  dealSupportRequests[0]};
        List<Deal_Support_Request__c> updatedDSRlist = new List<Deal_Support_Request__c>{updatedDSR};



        

        // =====================================
		// Stubbing
		// =====================================
        // not required
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();


        Test.startTest();
        module.onBeforeUpdate(updatedDSRlist, existingRecords, mockUow);
        Test.stopTest();

        //system asserts
        system.assertEquals(System.now(),updatedDSR.Last_Implementation_Stage_Update__c);

    }

    @IsTest
    static void testOnBeforeInsert(){
        MockUtility.disableTriggerExecution();
        
        DealSupportRequestMilestonesTrackModule module = DealSupportRequestMilestonesTrackModule.newInstance();

        //prepare data
        List<Account> organisations = ApplicationTestDataFactory.getAccounts(1, true);
        List<Deal_Support_Request__c> newDealSupportRequests = ApplicationTestDataFactory.getDealSupportRequests(1, null, organisations[0].Id, true);
        newDealSupportRequests[0].Implementation_Stage__c = 'Idea - Sales';
        

        // =====================================
		// Stubbing
		// =====================================
        // not required
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();


        Test.startTest();
        module.onBeforeInsert(newDealSupportRequests, mockUow);
        Test.stopTest();

        //system asserts
        system.assertEquals(System.now(), newDealSupportRequests[0].Last_Implementation_Stage_Update__c);
    }

    @IsTest
    static void testOnAfterUpdateExistingMilestoneRecord(){
        MockUtility.disableTriggerExecution();
        
        DealSupportRequestMilestonesTrackModule module = DealSupportRequestMilestonesTrackModule.newInstance();

        //prepare data
        Id dsrMilestoneStageGateRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('DealSupportRequestMilestones__c', new Set<String>{'Stage_Gates'}).values()[0].Id;

        List<Account> organisations = ApplicationTestDataFactory.getAccounts(1, true);
        List<Deal_Support_Request__c> dealSupportRequests = ApplicationTestDataFactory.getDealSupportRequests(1, null, organisations[0].Id, true);
        dealSupportRequests[0].Implementation_Stage__c = 'Idea - Sales';
        dealSupportRequests[0].Last_Implementation_Stage_Update__c = System.now().addDays(-1);

        Deal_Support_Request__c updatedDSR = dealSupportRequests[0].clone(true, true, false, true);
        updatedDSR.Implementation_Stage__c = 'Scope - Onboarding';
        updatedDSR.Last_Implementation_Stage_Update__c = System.now();


        List<DealSupportRequestMilestones__c> newDsrMilestones = ApplicationTestDataFactory.getDealSupportRequestMilestones(1, dealSupportRequests[0].Id, true);
        DealSupportRequestMilestones__c newDsrMilestone = newDsrMilestones[0];
        newDsrMilestone.Time_in_minutes__c = 400;
        newDsrMilestone.Stage__c = 'Idea - Sales';
        newDsrMilestone.RecordTypeId = dsrMilestoneStageGateRecordTypeId;


        Map<Id, Deal_Support_Request__c> existingRecords = new Map<Id, Deal_Support_Request__c>{ dealSupportRequests[0].Id =>  dealSupportRequests[0]};
        List<Deal_Support_Request__c> updatedDSRlist = new List<Deal_Support_Request__c>{updatedDSR};

        

        //set selectors and mock unit of work and database
        DealSupportRequestMilestonesSelector dsrMilestoneSelector = (DealSupportRequestMilestonesSelector)MockUtility.mockSelector(DealSupportRequestMilestonesSelector.class);
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();


        MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(dsrMilestoneSelector.selectByDSRId((Set<Id>)fflib_Match.eq(new Set<Id>{dealSupportRequests[0].Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, DealSupportRequestMilestones__c>{newDsrMilestone.Id => newDsrMilestone});

        MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true), (String)fflib_Match.eq('DealSupportRequestMilestonesTrackModule'))).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
        
        MockUtility.Mocks.stopStubbing();

        Test.startTest();
        module.onAfterUpdate(updatedDSRlist, existingRecords, mockUow);
        Test.stopTest();

        System.assertEquals(1, MockUtility.mockUnitOfWorkDMLs.size());

        //asserting time in minutes changed after DSR Implementation stage is updated.
        System.assertNotEquals(newDsrMilestone.Time_in_minutes__c,(  (DealSupportRequestMilestones__c)MockUtility.mockUnitOfWorkDMLs[0]).Time_in_minutes__c);
    }

    @IsTest
    static void testOnAfterUpdateNewMilestoneRecord(){
        MockUtility.disableTriggerExecution();
        
        DealSupportRequestMilestonesTrackModule module = DealSupportRequestMilestonesTrackModule.newInstance();

        //prepare data
        List<Account> organisations = ApplicationTestDataFactory.getAccounts(1, true);
        List<Deal_Support_Request__c> dealSupportRequests = ApplicationTestDataFactory.getDealSupportRequests(1, null, organisations[0].Id, true);
        dealSupportRequests[0].Implementation_Stage__c = 'Idea - Sales';
        dealSupportRequests[0].Last_Implementation_Stage_Update__c = System.now().addDays(-1);

        Deal_Support_Request__c updatedDSR = dealSupportRequests[0].clone(true, true, false, true);
        updatedDSR.Implementation_Stage__c = 'Scope - Onboarding';
        updatedDSR.Last_Implementation_Stage_Update__c = System.now();

        Map<Id, Deal_Support_Request__c> existingRecords = new Map<Id, Deal_Support_Request__c>{ dealSupportRequests[0].Id =>  dealSupportRequests[0]};
        List<Deal_Support_Request__c> updatedDSRlist = new List<Deal_Support_Request__c>{updatedDSR};


        //set selectors and mock unit of work and database
        DealSupportRequestMilestonesSelector dsrMilestoneSelector = (DealSupportRequestMilestonesSelector)MockUtility.mockSelector(DealSupportRequestMilestonesSelector.class);
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();


        MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(dsrMilestoneSelector.selectByDSRId((Set<Id>)fflib_Match.eq(new Set<Id>{dealSupportRequests[0].Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new Map<Id, DealSupportRequestMilestones__c>{});

        MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

        MockUtility.Mocks.stopStubbing();

        Test.startTest();
        module.onAfterUpdate(updatedDSRlist, existingRecords, mockUow);
        Test.stopTest();

       ((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<SObject>)fflib_Match.anyObject());
        System.assertEquals(1, MockUtility.mockUnitOfWorkDMLs.size());



    }
}