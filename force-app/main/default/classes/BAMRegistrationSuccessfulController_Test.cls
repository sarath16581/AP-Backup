/**************************************************
Description:    Tests BAMRegistrationSuccessfulController
History:
--------------------------------------------------
2019-08-10  nathan.franklin@auspost.com.au  Created
**************************************************/
@isTest
public class BAMRegistrationSuccessfulController_Test {
	public class SuccessfulResponseMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(204);
			return response;
		}
	}
	public class FailureResponseMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(500);
			return response;
		}
	}

	@testSetup
	public static void testSetup() {
		AusPostSettings__c testSetting = new AusPostSettings__c(Name = 'BAM-CSSO-Completion', URL2__c = 'callout:nothing');
		insert testSetting;
	}

	/**
	 * Scenario:
	 * Very simple test for code coverage since we do not need to process the result of the callout
	 */
	public static testMethod void testCalloutCodeSuccess() {
		Test.setMock(HttpCalloutMock.class, new SuccessfulResponseMock());
		Test.startTest();
		BAMRegistrationSuccessfulController.triggerRegistrationCompleteIntegration('{}');
		Test.stopTest();
	}

	/**
	 * Scenario:
	 * Very simple test for code coverage since we do not need to process the result of the callout
	 */
	public static testMethod void testCalloutCodeFailure() {
		Test.setMock(HttpCalloutMock.class, new FailureResponseMock());
		Test.startTest();
		BAMRegistrationSuccessfulController.triggerRegistrationCompleteIntegration('{}');
		Test.stopTest();
	}

}