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
    


    /**
	 * Test:
	 *  When a deal support request is being updated, the before update will try to update Last Implementation Stage timestamp
     *  if Implementation Stage is changed.
	 */
    @IsTest
    static void testOnBeforeUpdate(){
        MockUtility.disableTriggerExecution();


        DealSupportRequestMilestonesTrackModule module = DealSupportRequestMilestonesTrackModule.newInstance();

        // =====================================
		// Data Preparation
		// =====================================
        List<Account> organisations = ApplicationTestDataFactory.getAccounts(1, true);
        List<Deal_Support_Request__c> dealSupportRequests = ApplicationTestDataFactory.getDealSupportRequests(1, null, organisations[0].Id, true);
        dealSupportRequests[0].Implementation_Stage__c = 'Idea - Sales';
        dealSupportRequests[0].LastImplementationStageUpdate__c = System.now().addMinutes(-60);


        //update existing record and change implementation stage
        Deal_Support_Request__c updatedDSR = dealSupportRequests[0].clone(true, true, false, true);
        updatedDSR.Implementation_Stage__c = 'Scope - Onboarding';

        Map<Id, Deal_Support_Request__c> existingRecords = new Map<Id, Deal_Support_Request__c>{ dealSupportRequests[0].Id =>  dealSupportRequests[0]};
        List<Deal_Support_Request__c> updatedDSRlist = new List<Deal_Support_Request__c>{updatedDSR};
        


        // =====================================
		// Stubbing
		// =====================================
        // not required
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();


        // =====================================
		// Testing
		// =====================================
        Test.startTest();
        module.onBeforeUpdate(updatedDSRlist, existingRecords, mockUow);
        Test.stopTest();

        //assert that Last Implementation Stage Update field is updated.
       system.assertNotEquals(dealSupportRequests[0].LastImplementationStageUpdate__c, updatedDSR.LastImplementationStageUpdate__c);

        //beforeUpdate does not perform any DML hence not testing register methods.
    }


    /**
	 * Test:
	 *  When a deal support request is being inserted, the before insert will try to set Last Implementation Stage timestamp
     *  if Implementation Stage is populated.
	 */

    @IsTest
    static void testOnBeforeInsert(){
        MockUtility.disableTriggerExecution();
        
        DealSupportRequestMilestonesTrackModule module = DealSupportRequestMilestonesTrackModule.newInstance();

        // =====================================
		// Data Preparation
		// =====================================
        List<Account> organisations = ApplicationTestDataFactory.getAccounts(1, true);
        List<Deal_Support_Request__c> newDealSupportRequests = ApplicationTestDataFactory.getDealSupportRequests(1, null, organisations[0].Id, true);
        newDealSupportRequests[0].Implementation_Stage__c = 'Idea - Sales';
        

        // =====================================
		// Stubbing
		// =====================================
        // not required
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

        // =====================================
		// Testing
		// =====================================
        
        Test.startTest();
        module.onBeforeInsert(newDealSupportRequests, mockUow);
        Test.stopTest();

        //assert that LastImplementationStageUpdate__c is populated when a new record is being created
       system.assertNotEquals(null, newDealSupportRequests[0].LastImplementationStageUpdate__c);

        //beforeInsert does not perform any DML hence not testing register methods.

    }

    /**
	 * Test:
	 *  After a deal support request is updated, the after update will try to create/update Deal Support Request Milestone record.
     *  If Deal Support Mileestone record exists for a changed implementation stage, then record will be updated with the time difference between
     * current time and last time DSR was updated will be calculated based on business hours.   
	 */
    @IsTest
    static void testOnAfterUpdateExistingMilestoneRecord(){
        MockUtility.disableTriggerExecution();
        
        DealSupportRequestMilestonesTrackModule module = DealSupportRequestMilestonesTrackModule.newInstance();

        // =====================================
		// Data Preparation
		// =====================================
        Id dsrMilestoneStageGateRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('DealSupportRequestMilestone__c', new Set<String>{'StageGates'}).values()[0].Id;

        List<Account> organisations = ApplicationTestDataFactory.getAccounts(1, true);
        List<Deal_Support_Request__c> dealSupportRequests = ApplicationTestDataFactory.getDealSupportRequests(1, null, organisations[0].Id, true);
        dealSupportRequests[0].Implementation_Stage__c = 'Idea - Sales';
        dealSupportRequests[0].LastImplementationStageUpdate__c = System.now().addDays(-1);

        Deal_Support_Request__c updatedDSR = dealSupportRequests[0].clone(true, true, false, true);
        updatedDSR.Implementation_Stage__c = 'Scope - Onboarding';
        updatedDSR.LastImplementationStageUpdate__c = System.now();

        //expected record to be updated
        List<DealSupportRequestMilestone__c> newDsrMilestones = ApplicationTestDataFactorySales.getDealSupportRequestMilestones(1, dealSupportRequests[0].Id, true);
        DealSupportRequestMilestone__c newDsrMilestone = newDsrMilestones[0];
        newDsrMilestone.Timeinminutes__c = 400;
        newDsrMilestone.Stage__c = 'Idea - Sales';
        newDsrMilestone.RecordTypeId = dsrMilestoneStageGateRecordTypeId;

        
        Map<Id, Deal_Support_Request__c> existingRecords = new Map<Id, Deal_Support_Request__c>{ dealSupportRequests[0].Id =>  dealSupportRequests[0]};
        List<Deal_Support_Request__c> updatedDSRlist = new List<Deal_Support_Request__c>{updatedDSR};

        

        //set selectors and mock unit of work and database
        DealSupportRequestMilestonesSelector dsrMilestoneSelector = (DealSupportRequestMilestonesSelector)MockUtility.mockSelector(DealSupportRequestMilestonesSelector.class);
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

        // =====================================
		// Stubbing
		// =====================================

        MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(dsrMilestoneSelector.selectByDSRId((Set<Id>)fflib_Match.eq(new Set<Id>{dealSupportRequests[0].Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<DealSupportRequestMilestone__c>{newDsrMilestone});

        MockUtility.Mocks.when(mockUow.registerDirty((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true), (String)fflib_Match.eq('DealSupportRequestMilestonesTrackModule'))).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());
        
        MockUtility.Mocks.stopStubbing();

        // =====================================
		// Testing
		// =====================================
        Test.startTest();
        module.onAfterUpdate(updatedDSRlist, existingRecords, mockUow);
        Test.stopTest();


        //asserting time in minutes changed after DSR Implementation stage is updated.
        System.assertNotEquals(newDsrMilestone.Timeinminutes__c,(  (DealSupportRequestMilestone__c)MockUtility.mockUnitOfWorkDMLs[0]).Timeinminutes__c);
        
        ((DealSupportRequestMilestonesSelector)MockUtility.Mocks.verify(dsrMilestoneSelector, 1)).selectByDSRId((Set<Id>)fflib_Match.eq(new Set<Id>{dealSupportRequests[0].Id}), (Set<Object>)fflib_Match.anyObject());
        
        //verify registerDirty() is called.
        ((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerDirty((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(true), (String)fflib_Match.eq('DealSupportRequestMilestonesTrackModule'));


    }


    
    /**
	 * Test:
	 *  After a deal support request is updated, the after update will try to update Deal Support Request Milestone record.
     *  If Deal Support Milestone record does not exists for a changed Implementation Stage, then record will be created and time difference between
     * current time and last time DSR was updated will be calculated based on business hours. 
	 */
    @IsTest
    static void testOnAfterUpdateNewMilestoneRecord(){
        MockUtility.disableTriggerExecution();
        
        DealSupportRequestMilestonesTrackModule module = DealSupportRequestMilestonesTrackModule.newInstance();

        // =====================================
		// Prepare Data
		// =====================================
        List<Account> organisations = ApplicationTestDataFactory.getAccounts(1, true);
        List<Deal_Support_Request__c> dealSupportRequests = ApplicationTestDataFactory.getDealSupportRequests(1, null, organisations[0].Id, true);
        dealSupportRequests[0].Implementation_Stage__c = 'Idea - Sales';
        dealSupportRequests[0].LastImplementationStageUpdate__c = System.now().addDays(-1);

        Deal_Support_Request__c updatedDSR = dealSupportRequests[0].clone(true, true, false, true);
        updatedDSR.Implementation_Stage__c = 'Scope - Onboarding';
        updatedDSR.LastImplementationStageUpdate__c = System.now();

        Map<Id, Deal_Support_Request__c> existingRecords = new Map<Id, Deal_Support_Request__c>{ dealSupportRequests[0].Id =>  dealSupportRequests[0]};
        List<Deal_Support_Request__c> updatedDSRlist = new List<Deal_Support_Request__c>{updatedDSR};


        //set selectors and mock unit of work and database
        DealSupportRequestMilestonesSelector dsrMilestoneSelector = (DealSupportRequestMilestonesSelector)MockUtility.mockSelector(DealSupportRequestMilestonesSelector.class);
        ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();

        // =====================================
		// Stubbing
		// =====================================
        MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(dsrMilestoneSelector.selectByDSRId((Set<Id>)fflib_Match.eq(new Set<Id>{dealSupportRequests[0].Id}), (Set<Object>)fflib_Match.anyObject())).thenReturn(new List<DealSupportRequestMilestone__c>{});

        MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

        MockUtility.Mocks.stopStubbing();

        // =====================================
		// Testing
		// =====================================
        Test.startTest();
        module.onAfterUpdate(updatedDSRlist, existingRecords, mockUow);
        Test.stopTest();

        ((ApplicationUnitOfWork)MockUtility.Mocks.verify(mockUow, 1)).registerNew((List<SObject>)fflib_Match.anyObject());
        ((DealSupportRequestMilestonesSelector)MockUtility.Mocks.verify(dsrMilestoneSelector, 1)).selectByDSRId((Set<Id>)fflib_Match.eq(new Set<Id>{dealSupportRequests[0].Id}), (Set<Object>)fflib_Match.anyObject());
    }
}