/**
 * @File Name          : STHSFeedbackFormController_Test.cls
 * @Description        : Test class for STHSFeedbackFormController
 * @Author             : Mahesh Parvathaneni
 **/

@isTest
public with sharing class STHSFeedbackFormController_Test {

    private static Map<Object, String> formData;

    private static Map<Object, String> formDataSetup() {
        if (formData == null) {
            formData = new Map<Object, String>();
            //form data setup
            formData.put('enquiry', 'Product & Sales');
            formData.put('reference', '34TE345634562');
            formData.put('firstName', 'UserFName');
            formData.put('lastName', 'UserLName');
            formData.put('phone', '0403456456');
            formData.put('email', 'test.user@test.com');
            formData.put('feedbackDetails', 'feedbackDetails');
        }
        return formData.clone();
    }

    /**
	 * Scenario: Testing to create feedback enquiry case and related contacts.
	 */
	@IsTest
	private static void testCreateFeedbackFormCase() {

		// =====================================
		// Data Preparation
		// =====================================
		Map<Object, String> formData = formDataSetup();

		// =====================================
		// Stubbing
		// =====================================
		STHSCommunityService mockService = (STHSCommunityService)MockUtility.mockUtility(STHSCommunityService.class);
		

        MockUtility.Mocks.startStubbing();
	    ((STHSCommunityService)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockService)).getCaseDefaultValues((Case)fflib_Match.anyObject());
		((STHSCommunityService)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockService)).getFormCaseData((Case)fflib_Match.anyObject(), (Map<Object, String>)fflib_Match.eq(formData));
		((STHSCommunityService)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockService)).insertRecords((List<SObject>)fflib_Match.anyObject());
		MockUtility.Mocks.when(mockService.getCaseNumber((Id)fflib_Match.isNull())).thenReturn('475123');
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();

        String result = STHSFeedbackFormController.createFeedbackFormCase(formData);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected CaseNumber of the newly inserted case to be populated but instead got null.');

        // should have called STHSCommunityService methods
        ((STHSCommunityService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getCaseDefaultValues((Case)fflib_Match.anyObject());
		((STHSCommunityService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getFormCaseData((Case)fflib_Match.anyObject(), (Map<Object, String>)fflib_Match.eq(formData));
		((STHSCommunityService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(2))).insertRecords((List<SObject>)fflib_Match.anyObject());
		((STHSCommunityService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getCaseNumber((Id)fflib_Match.isNull());
	}

    /**
	 * Scenario: Testing to return exception from feedback enquiry case 
	 */
	@IsTest
	private static void testCreateFeedbackFormCaseException() {

		// =====================================
		// Data Preparation
		// =====================================
		Map<Object, String> formData = formDataSetup();

		// =====================================
		// Stubbing
		// =====================================
        STHSCommunityService mockService = (STHSCommunityService)MockUtility.mockUtility(STHSCommunityService.class);

        MockUtility.Mocks.startStubbing();
		((STHSCommunityService)MockUtility.Mocks.doThrowWhen(new MockException(), mockService)).getCaseDefaultValues((Case)fflib_Match.anyObject());
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();

		String result;
		try {
			result = STHSFeedbackFormController.createFeedbackFormCase(formData);
		} catch (Exception ex) {
			System.assertEquals(null, result, 'Expected CaseNumber to be null when there is an error.');
		}

        Test.stopTest();

        // should have attempted to call STHSCommunityService
        ((STHSCommunityService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getCaseDefaultValues((Case)fflib_Match.anyObject());
	}

    private class MockException extends Exception {
    }
    
}