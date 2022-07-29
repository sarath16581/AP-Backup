/**
 * @File Name          : SthsFeedbackFormControllerTest.cls
 * @Description        : Test class for SthsFeedbackFormController
 * @Author             : Mahesh Parvathaneni
 **/

@isTest
public with sharing class SthsFeedbackFormControllerTest {

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
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();

        String result = SthsFeedbackFormController.createFeedbackFormCase(formData);

        Test.stopTest();

        System.debug('records==>'+ MockUtility.mockDMLInsertedRecords);

        System.assertNotEquals(null, result, 'Expected id of the newly inserted case to be populated but instead got null.');

        // should have inserted a new case and related contact
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlInsert((List<SObject>)fflib_Match.anyObject());
	}
    
}
