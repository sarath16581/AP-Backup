/**
 * @description Test class to cover Deal Support Survey Invitation Module
 * @author Ken McGuire
 * @date 2022-04-26
 * @changelog
 */
@IsTest
public class DealSupportSurveyInvitationModule_Test {
@IsTest
	static void testAfterInsertTriggerDispatchSurveyInvitations() {
        List<Account> accountRecords = ApplicationTestDataFactory.getAccounts(1,true);
        List<Opportunity> opportunityRecords = ApplicationTestDataFactory.getOpportunities(1,new Set<Id>{accountRecords[0].id},true);
        List<Deal_Support_Request__c> supportRecords = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecords[0].id, accountRecords[0].id, true);
        Set<Id> enqueReturnResult = new Set<Id>{supportRecords[0].id};


        // =====================================
		// Stubbing
		// =====================================
		SurveyService mockService = (SurveyService)MockUtility.mockUtility(SurveyService.class);
		MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockService.enqueSurveyInvitations((List<SObject>)fflib_Match.anyObject(),(Map<Id,SObject>)fflib_Match.isNot(fflib_Match.anyObject()))).thenReturn(enqueReturnResult);
		MockUtility.Mocks.stopStubbing();

        Test.startTest();

        	// Given
        	DealSupportSurveyInvitationModule module = DealSupportSurveyInvitationModule.newInstance();

			// When
        	module.onAfterInsert( supportRecords, null);

        Test.stopTest();

        // Then ???
    }
    
    @IsTest
	static void testAfterUpdateTriggerDispatchSurveyInvitations() {
		
        List<Account> accountRecords = ApplicationTestDataFactory.getAccounts(1,true);
        List<Opportunity> opportunityRecords = ApplicationTestDataFactory.getOpportunities(1,new Set<Id>{accountRecords[0].id},true);
        List<Deal_Support_Request__c> supportRecords = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecords[0].id, accountRecords[0].id, true);
        Set<Id> enqueReturnResult = new Set<Id>{supportRecords[0].id};
		Map<Id,Deal_Support_Request__c> existingRecords = new Map<Id,Deal_Support_Request__c>{supportRecords[0].id => supportRecords[0]};   
        // =====================================
		// Stubbing
		// =====================================
		SurveyService mockService = (SurveyService)MockUtility.mockUtility(SurveyService.class);
		MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockService.enqueSurveyInvitations((List<SObject>)fflib_Match.anyObject(),(Map<Id, SObject>)fflib_Match.anyObject())).thenReturn(enqueReturnResult);
		MockUtility.Mocks.stopStubbing();
        Test.startTest();

        	//Given
        	DealSupportSurveyInvitationModule module = DealSupportSurveyInvitationModule.newInstance();

			// When
        	module.onAfterUpdate( supportRecords, existingRecords,null);

        Test.stopTest();

        // Then ???
    }
}