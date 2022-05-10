/**
 * @description Test class to cover Survey Invitation Module
 * @author Ken McGuire
 * @date 2022-04-26
 * @changelog
 */
@IsTest
private class CaseSurveyInvitationModule_Test {
	@IsTest
	static void testAfterInsertTriggerDispatchSurveyInvitations() {

        List<Case> caseRecords = ApplicationTestDataFactory.getCases(1, true);
        Set<Id> enqueReturnResult = new Set<Id>{caseRecords[0].id};
        Map<Id,SObject> caseUpdates = new Map<Id,SObject>{caseRecords[0].id =>caseRecords[0]};

        // =====================================
		// Stubbing
		// =====================================
		SurveyService mockService = (SurveyService)MockUtility.mockUtility(SurveyService.class);
		MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockService.enqueSurveyInvitations((List<SObject>)fflib_Match.anyObject(),(Map<Id,SObject>)fflib_Match.isNot(fflib_Match.anyObject()))).thenReturn(enqueReturnResult);
		MockUtility.Mocks.stopStubbing();

        Test.startTest();

        	// Given
        	CaseSurveyInvitationModule module = CaseSurveyInvitationModule.newInstance();

			// When
        	module.onAfterInsert( caseRecords, null);

        Test.stopTest();

        // Then ???
    }
    
    @IsTest
	static void testAfterUpdateTriggerDispatchSurveyInvitations() {
		
    	List<Case> caseRecords = ApplicationTestDataFactory.getCases(2, true);
        List<Case> records = new List<Case>{caseRecords[0]};
        Map<Id,Case> existingRecords = new Map<Id,Case>{caseRecords[1].id => caseRecords[1]};    
        Set<Id> enqueReturnResult = new Set<Id>{caseRecords[0].id};
		Map<Id,SObject> caseUpdates = new Map<Id,SObject>{caseRecords[0].id =>caseRecords[0]};

        // =====================================
		// Stubbing
		// =====================================
		SurveyService mockService = (SurveyService)MockUtility.mockUtility(SurveyService.class);
		MockUtility.Mocks.startStubbing();
   		MockUtility.Mocks.when(mockService.enqueSurveyInvitations((List<SObject>)fflib_Match.anyObject(),(Map<Id,SObject>)fflib_Match.isNot(fflib_Match.anyObject()))).thenReturn(enqueReturnResult);
		MockUtility.Mocks.stopStubbing();
        Test.startTest();

        	//Given
        	CaseSurveyInvitationModule module = CaseSurveyInvitationModule.newInstance();

			// When
        	module.onAfterUpdate( records, existingRecords,null);

        Test.stopTest();

        // Then ???
    }
}