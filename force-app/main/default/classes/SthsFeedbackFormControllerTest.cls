/**
 * @File Name          : STHSFeedbackFormControllerTest.cls
 * @Description        : Test class for STHSFeedbackFormController
 * @Author             : Mahesh Parvathaneni
 **/

@isTest
public with sharing class STHSFeedbackFormControllerTest {

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
		Case caseRecord = ApplicationTestDataFactory.getCases(1, true)[0];
        caseRecord = (Case)ApplicationTestDataFactory.setUnwritableFields(caseRecord, new Map<String, Object>{'CaseNumber' => '475123'});

		// =====================================
		// Stubbing
		// =====================================
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		CasesSelector mockCasesSelector = (CasesSelector)MockUtility.mockSelector(CasesSelector.class);

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new AnswerGenericDMLInserted(caseRecord.Id));
		MockUtility.Mocks.when(mockCasesSelector.selectById(new Set<Id>{caseRecord.Id})).thenReturn(new Map<Id, Case>{caseRecord.Id => caseRecord});
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();

        String result = STHSFeedbackFormController.createFeedbackFormCase(formData);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected CaseNumber of the newly inserted case to be populated but instead got null.');

        // should have inserted a new case
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
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
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenThrow(new MockException());
        MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
        Test.startTest();

		String result;
		try {
			result = STHSFeedbackFormController.createFeedbackFormCase(formData);
		} catch (Exception ex) {
			System.assertEquals(null, result, 'Expected CaseNumber to be null when there is a DML error.');
		}

        Test.stopTest();

        // should have attempted to insert a new case
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert((List<SObject>)fflib_Match.anyObject());
	}

    /**
	 * A simple Answer class to set an Id on the record to simulate a DML insert operation
	 */
	private class AnswerGenericDMLInserted implements fflib_Answer {
		private Id caseId;

		public AnswerGenericDMLInserted(Id caseId) {
			this.caseId = caseId;
		}

		public Object answer(fflib_InvocationOnMock invocation) {
			List<Map<String, Object>> saveResults = new List<Map<String, Object>>();
			List<SObject> records = (List<SObject>)invocation.getArgument(0);
			for(SObject record : records) {
				record.Id = this.caseId;

				Map<String, Object> result = new Map<String, Object> {
						'success' => true,
						'id' => record.Id
				};
				saveResults.add(result);
			}
			List<Database.SaveResult> result = (List<Database.SaveResult>)JSON.deserialize(JSON.serialize(saveResults), List<Database.SaveResult>.class);
			return result;
		}
	}

    private class MockException extends Exception {
    }
    
}