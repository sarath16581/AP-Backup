@isTest
public class SafeDropImageComponentController_Test {

	/************************************************************************************************
	 *	SCENARIO:
	 *		Api call to Safe Drop is made and returns a successful response.
	 *************************************************************************************************/
	public static testMethod void testSuccessResponse() {
		SafeDropUtility_Test.insertAuthSettings();

		Test.startTest();

		// Invoke the continuation
		Object continuation = SafeDropImageComponentController.getArticleImage('TEST');

		String requestLabel = SafeDropUtility_Test.getInvokedContinuationLabel(continuation);
		SafeDropUtility_Test.setSuccessContinuationResponse(requestLabel);

		SafeDropUtility.SafeDropApiResponse response = (SafeDropUtility.SafeDropApiResponse)SafeDropImageComponentController.callback(SafeDropImageComponentController.requestLabel);
		Test.stopTest();

		System.assertEquals(false, response.isError);
		System.assertNotEquals('', response.imageBody);
	}

	/************************************************************************************************
	 *	SCENARIO:
	 *		Api call to Safe Drop is made and returns a error response.
	 *************************************************************************************************/
	public static testMethod void testErrorResponse() {
		SafeDropUtility_Test.insertAuthSettings();

		Test.startTest();

		// Invoke the continuation
		Object continuation = SafeDropImageComponentController.getArticleImage('TEST');

		String requestLabel = SafeDropUtility_Test.getInvokedContinuationLabel(continuation);
		SafeDropUtility_Test.setErrorContinuationResponse(requestLabel);

		SafeDropUtility.SafeDropApiResponse response = (SafeDropUtility.SafeDropApiResponse)SafeDropImageComponentController.callback(SafeDropImageComponentController.requestLabel);

		System.assertEquals(true, response.isError);
		System.assertNotEquals('', response.errorMessage);

		// Continuation ERROR
		// Invoke the continuation
		continuation = SafeDropImageComponentController.getArticleImage('TEST');

		requestLabel = SafeDropUtility_Test.getInvokedContinuationLabel(continuation);
		SafeDropUtility_Test.setErrorContinuationResponse(requestLabel, 2001, '');

		response = (SafeDropUtility.SafeDropApiResponse)SafeDropImageComponentController.callback(SafeDropImageComponentController.requestLabel);

		System.assertEquals(true, response.isError);
		System.assertNotEquals('', response.errorMessage);

		Test.stopTest();
	}

	/************************************************************************************************
	 *	SCENARIO:
	 *		Api call to Safe Drop is made and errors but does not return a correct response body
	 *		EXAMPLE: User authorisation errors
	 *************************************************************************************************/
	public static testMethod void testFailResponse() {
		SafeDropUtility_Test.insertAuthSettings();

		Test.startTest();

		// Invoke the continuation
		Object continuation = SafeDropImageComponentController.getArticleImage('TEST');
		String requestLabel = SafeDropUtility_Test.getInvokedContinuationLabel(continuation);
		SafeDropUtility_Test.setFailContinuationResponse(requestLabel);
		SafeDropUtility.SafeDropApiResponse response = (SafeDropUtility.SafeDropApiResponse)SafeDropImageComponentController.callback(SafeDropImageComponentController.requestLabel);
		Test.stopTest();

		System.assertEquals(true, response.isError);
		System.assertNotEquals('', response.errorMessage);
	}

}