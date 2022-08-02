/**
 * @File Name          : SthsCommunityUtilityTest.cls
 * @Description        : Test class for SthsCommunityUtility
 * @Author             : Mahesh Parvathaneni
 **/

@isTest
public with sharing class SthsCommunityUtilityTest {

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
        // None

		// =====================================
		// Testing
		// =====================================
        Test.startTest();
        
        Case caseObj = new Case();
        SthsCommunityUtility.getCaseDefaultValues(caseObj);

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
        SthsCommunityUtility.getFormCaseData(caseObj, formData);

        Test.stopTest();

        System.assertNotEquals(null, caseObj.SuppliedEmail, 'Expected Supplied Email of the case to be populated but instead got null.');

	}

}
