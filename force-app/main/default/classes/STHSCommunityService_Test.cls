/**
 * @File Name          : STHSCommunityService_Test.cls
 * @Description        : Test class for STHSCommunityService
 * @Author             : Mahesh Parvathaneni
 **/

@isTest
public with sharing class STHSCommunityService_Test {

    private static Map<Object, String> formData;

    private static Map<Object, String> formDataSetup() {
        if (formData == null) {
            formData = new Map<Object, String>();
            //form data setup
            formData.put('enquiry', 'Product & Sales');
            formData.put('reference', '34TE345634562');
            formData.put('firstName', 'UserFName');
            formData.put('lastName', 'UserLName');
            formData.put('phone', '0303456456');
            formData.put('email', 'test.user@test.com');
            formData.put('feedbackDetails', 'feedbackDetails');
        }
        return formData.clone();
    }

    /**
	 * Scenario: Testing to set the default case values
	 */
	@IsTest
	private static void testGetCaseDefaultValues() {

		// =====================================
		// Data Preparation
		// =====================================
        // None

		// =====================================
		// Stubbing
		// =====================================
        AssignmentRulesSelector mockAssignmentRulesSelector = (AssignmentRulesSelector)MockUtility.mockSelector(AssignmentRulesSelector.class);
        AssignmentRule ar = ApplicationTestDataFactory.getAssignmentRules(1, STHSConstants.CASE_OBJ, true)[0];

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockAssignmentRulesSelector.selectActiveRulesBySObjectType(STHSConstants.CASE_OBJ)).thenReturn(new Map<Id, AssignmentRule>{ar.Id => ar});
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();
        
        Case caseObj = new Case();
        STHSCommunityService service = STHSCommunityService.getInstance();
        service.getCaseDefaultValues(caseObj);

        Test.stopTest();

        System.assertNotEquals(null, caseObj.Status, 'Expected Status of the case to be populated but instead got null.');

	}

    /**
	 * Scenario: Testing to set the default case object values from form data
	 */
	@IsTest
	private static void testGetFormCaseData() {

		// =====================================
		// Data Preparation
		// =====================================
        Map<Object, String> formData = formDataSetup();

		// =====================================
		// Stubbing
		// =====================================
        // None

		// =====================================
		// Testing
		// =====================================
        Test.startTest();
        
        Case caseObj = new Case();
        STHSCommunityService service = STHSCommunityService.getInstance();
        service.getFormCaseData(caseObj, formData);

        Test.stopTest();

        System.assertNotEquals(null, caseObj.SuppliedEmail, 'Expected Supplied Email of the case to be populated but instead got null.');

	}

    /**
	 * Scenario: Testing to perform the DML Insert operation
	 */
	@IsTest
	private static void testInsertRecords() {

		// =====================================
		// Data Preparation
		// =====================================
        Map<Object, String> formData = formDataSetup();
        List<Case> caseList = ApplicationTestDataFactory.getCases(1, true);

		// =====================================
		// Stubbing
		// =====================================
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();

        STHSCommunityService service = STHSCommunityService.getInstance();
        service.insertRecords(caseList);

        Test.stopTest();

        System.assertEquals(1, MockUtility.mockDMLInsertedRecords.size(), 'Expected case record has been inserted.');

        // should have inserted a new case
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
	}

    /**
	 * Scenario: Testing to query the case using CasesSelector
	 */
	@IsTest
	private static void testGetCaseNumber() {

		// =====================================
		// Data Preparation
		// =====================================
        Map<Object, String> formData = formDataSetup();
        Case caseRecord = ApplicationTestDataFactory.getCases(1, true)[0];
        caseRecord = (Case)ApplicationTestDataFactory.setUnwritableFields(caseRecord, new Map<String, Object>{'CaseNumber' => '475123'});

		// =====================================
		// Stubbing
		// =====================================
        CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCasesSelector.selectById(new Set<Id>{caseRecord.Id})).thenReturn(new Map<Id, Case>{caseRecord.Id => caseRecord});
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();

        STHSCommunityService service = STHSCommunityService.getInstance();
        String caseNumber = service.getCaseNumber(caseRecord.Id);

        Test.stopTest();

        System.assertNotEquals(null, caseNumber, 'Expected CaseNumber of the newly inserted case to be populated but instead got null.');

        // should have attempted to call CasesSelector
        ((CasesSelector)MockUtility.Mocks.verify(mockCasesSelector, MockUtility.Mocks.times(1))).selectById((Set<Id>)fflib_Match.eq(new Set<Id>{caseRecord.Id}));
	}

}