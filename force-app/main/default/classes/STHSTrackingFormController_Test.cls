/**
 * @File Name          : STHSTrackingFormController_Test.cls
 * @Description        : Test class for STHSTrackingFormController
 * @Author             : Mahesh Parvathaneni
 **/

@isTest
public with sharing class STHSTrackingFormController_Test {

    private static Map<Object, String> formData;

    private static Map<Object, String> formDataSetup() {
        if (formData == null) {
            formData = new Map<Object, String>();
            //form data setup
            formData.put('enquiryType', 'Track & Trace');
            formData.put('reference', '34TE345634562');
            formData.put('firstName', 'UserFName');
            formData.put('lastName', 'UserLName');
            formData.put('phone', '0403456456');
            formData.put('email', 'test.user@test.com');
            formData.put('enquiry', 'trackingDetails');
        }
        return formData.clone();
    }

    /**
	 * Scenario: Testing to create tracking enquiry case and related contacts.
	 */
	@IsTest
	private static void testCreateTrackingFormCase() {

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
		MockUtility.Mocks.when(mockService.buildCaseCommentsWithFormData((String)fflib_Match.anyObject(), (Map<Object, String>)fflib_Match.eq(formData))).thenReturn('First Name - Test');
		((STHSCommunityService)MockUtility.Mocks.doAnswer(new MockUtility.AnswerVoid(), mockService)).insertRecords((List<SObject>)fflib_Match.anyObject());
		MockUtility.Mocks.when(mockService.getCaseNumber((Id)fflib_Match.isNull())).thenReturn('475123');
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();

        String result = STHSTrackingFormController.createTrackingFormCase(formData);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected CaseNumber of the newly inserted case to be populated but instead got null.');

        // should have called STHSCommunityService methods
        ((STHSCommunityService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getCaseDefaultValues((Case)fflib_Match.anyObject());
		((STHSCommunityService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getFormCaseData((Case)fflib_Match.anyObject(), (Map<Object, String>)fflib_Match.eq(formData));
		((STHSCommunityService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).buildCaseCommentsWithFormData((String)fflib_Match.anyObject(), (Map<Object, String>)fflib_Match.eq(formData));
		((STHSCommunityService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(2))).insertRecords((List<SObject>)fflib_Match.anyObject());
		((STHSCommunityService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).getCaseNumber((Id)fflib_Match.isNull());
	}

    /**
	 * Scenario: Testing to return exception from tracking enquiry case 
	 */
	@IsTest
	private static void testCreateTrackingFormCaseException() {

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
			result = STHSTrackingFormController.createTrackingFormCase(formData);
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