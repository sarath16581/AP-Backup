/**
 * @description Test class to cover Survey Service functionality
 * @author Ken McGuire
 * @date 2022-04-26
 * @changelog
 */
@isTest
private class SurveyService_Test {

	@IsTest
	private static void testEntryConditionMetOnRecordInsertAndSend() {
        
		List<Case> caseRecords = ApplicationTestDataFactory.getCases(1, true);

		// =====================================
		// Stubbing
		// =====================================
		EntryConditions mockEntryConditions = (EntryConditions)MockUtility.mockUtility(EntryConditions.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockEntryConditions.isCreated((String)fflib_Match.anyString())).thenReturn(false);
        MockUtility.Mocks.when(mockEntryConditions.hasEntryConditions((String)fflib_Match.anyString())).thenReturn(true);
 		MockUtility.Mocks.when(mockEntryConditions.meetsEntryConditions((String)fflib_Match.anyString(),(Sobject)fflib_Match.eq(caseRecords[0]))).thenReturn(true);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		// Given
		insert new SurveyInvitationIdMap__c(Name = 'Test Survey Name', SurveyInvitationId__c = 123);
		SurveyService testSurveyService = SurveyService.getInstance();
        
		testSurveyService.surveysMetadataMap = new Map<String,List<SurveyInvitation__mdt>>
		{
            'Case' => new List<SurveyInvitation__mdt>{getSurveyInvitationMetadataMock()}
		};
        
        testSurveyService.staticEntryConditionsMetadataMap = new Map<String,EntryCondition__mdt> 
        {
            'Case' => getEntryConditionMetadataMock()
        } ;
            
		// When
		Test.startTest();
		Set<Id> enquedCaseObjectIds = testSurveyService.enqueSurveyInvitations(caseRecords,null);
		Map<Id,Case> recordUpdateTest = new Map<Id,Case>{caseRecords[0].id => new Case(Id = caseRecords[0].id,LastSurveySentDate__c = date.today())};

		// Then
		testSurveyService.sendInvitations(recordUpdateTest);

		System.assertEquals(1,enquedCaseObjectIds.size(),'Insert Record Meeting Entry Criteria should be enqued');
		Test.stopTest();
	}
	
	@IsTest
	private static void testEntryConditionMetForRecordChangedToMeetCriteria() {
		
		List<Case> caseRecords = ApplicationTestDataFactory.getCases(2, true);
        List<Case> records = new List<Case>{caseRecords[0]};
        Map<Id,Case> existingRecords = new Map<Id,Case>{caseRecords[1].id => caseRecords[1]};

		// =====================================
		// Stubbing
		// =====================================
		EntryConditions mockEntryConditions = (EntryConditions)MockUtility.mockUtility(EntryConditions.class);
		MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockEntryConditions.isCreated((String)fflib_Match.anyString())).thenReturn(false);
        MockUtility.Mocks.when(mockEntryConditions.meetsEntryConditions((String)fflib_Match.anyString(),(Sobject)fflib_Match.eq(caseRecords[0]))).thenReturn(true);
        MockUtility.Mocks.when(mockEntryConditions.meetsEntryConditions((String)fflib_Match.anyString(),(Sobject)fflib_Match.eq(caseRecords[1]))).thenReturn(false);
        MockUtility.Mocks.when(mockEntryConditions.hasEntryConditions((String)fflib_Match.anyString())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();

		// Given
		SurveyService testSurveyService = SurveyService.getInstance();

        // When
		testSurveyService.surveysMetadataMap = new Map<String,List<SurveyInvitation__mdt>>
		{
            'Case' => new List<SurveyInvitation__mdt>{getSurveyInvitationMetadataMock()}
		};
        
        testSurveyService.staticEntryConditionsMetadataMap = new Map<String,EntryCondition__mdt> 
        {
            'Case' => getEntryConditionMetadataMock()
        };

		// Then
		Set<Id> enquedRecordIds = testSurveyService.enqueSurveyInvitations(records,existingRecords);
		System.assertEquals(1,enquedRecordIds.size(),'Update Record to meet Entry Criteria should be enqued');
	}
	
	@IsTest
	private static void testEntryConditionNotMetForRecordChangedAndAlreadyMeetsCriteria() {
		Case caseRecord = ApplicationTestDataFactory.getCases(1, true)[0];
        List<Case> records = new List<Case>{caseRecord};
        Map<Id,Case> existingRecords = new Map<Id,Case>{caseRecord.Id => caseRecord}; 

		// =====================================
		// Stubbing
		// =====================================
		EntryConditions mockEntryConditions = (EntryConditions)MockUtility.mockUtility(EntryConditions.class);
		MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockEntryConditions.isCreated((String)fflib_Match.anyString())).thenReturn(false);
 		MockUtility.Mocks.when(mockEntryConditions.meetsEntryConditions((String)fflib_Match.anyString(),(Sobject)fflib_Match.eq(caseRecord))).thenReturn(true);
        MockUtility.Mocks.when(mockEntryConditions.hasEntryConditions((String)fflib_Match.anyString())).thenReturn(true);
		MockUtility.Mocks.stopStubbing();
        
		// Given
		SurveyService testSurveyService = SurveyService.getInstance();

       	// When
		testSurveyService.surveysMetadataMap = new Map<String,List<SurveyInvitation__mdt>>
		{
            'Case' => new List<SurveyInvitation__mdt>{getSurveyInvitationMetadataMock()}
		};
        
        testSurveyService.staticEntryConditionsMetadataMap = new Map<String,EntryCondition__mdt> 
        {
            'Case' => getEntryConditionMetadataMock()
        }; 

		// Then
		Set<Id> enquedRecordIds = testSurveyService.enqueSurveyInvitations(records,existingRecords);
		System.assertEquals(0, enquedRecordIds.size(),'Update Record already meeting Entry Criteria should not be enqued');
	}
    
	// Mock metadata for survey invitations testing
	static SurveyInvitation__mdt getSurveyInvitationMetadataMock() {
		Map<String,Object> metadataJSON = new Map<String,Object> 
		{
			'attributes'=> New Map<String,Object> 
			{
				'type' => 'SurveyInvitation__mdt'
			},
			'Label' => 'Test Survey Name',
            'DataObjectAPIName__c' => 'Case',
			'EntryCondition__r' => new Map<String,Object> {
				'attributes' => new Map<String,Object> {
					'type' => 'EntryCondition__mdt'
				},
				'ConditionRequirements__c' => 'All',
				'EntryConditionsJSON__c' => '{"Subject":"Case Subject 1","Description":"Case Description 1"}'
			}
		};
		return (SurveyInvitation__mdt)JSON.deserialize(JSON.serialize(metadataJSON), SurveyInvitation__mdt.class);
	 }
    
	// Mock metadata for static entry conditions testing
	static EntryCondition__mdt getEntryConditionMetadataMock() {
		Map<String,Object> metadataJSON = new Map<String,Object> 
		{
			'attributes' => new Map<String,Object> 
            {
				'type' => 'EntryCondition__mdt'
			},
			'ConditionRequirements__c' => 'All',
			'EntryConditionsJSON__c' => '{"Status":"New"}'
		};
		return (EntryCondition__mdt)JSON.deserialize(JSON.serialize(metadataJSON), EntryCondition__mdt.class);
	 }
}