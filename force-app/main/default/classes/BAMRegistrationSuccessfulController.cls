/**************************************************
Description:    Controller class to handle the registration successful page for Merchant Portal / BAM
				[There is no user context here since the page is public]
History:
--------------------------------------------------
2019-05-27  nathan.franklin@auspost.com.au  Created
**************************************************/
public with sharing class BAMRegistrationSuccessfulController {

	/**
	 * This is used to fire a call back to Camunda to notify that the provision process was completed successfully
	 * We don't know any details about which user the registration was for, we only receive an Id from which is passed from OneReg back to Salesforce
	 */
	@AuraEnabled(cacheable=true)
	public static Boolean triggerRegistrationCompleteIntegration(String correlationId) {

		System.debug('>>triggerRegistrationCompleteIntegration');
		if(!String.isEmpty(correlationId)) {
			try {
				HttpResponse response = BAMIntegrationUtility.postRequest('BAM-CSSO-Completion', new Map<String, String>{'id' => correlationId, 'status' => 'Fulfilled'});
				Integer statusCode = response.getStatusCode();

				// 204 = successful (OK - No content)
				if(statusCode != 204) {
					// the request failed
					String bodyResponse = response.getBody();
					System.debug('The request failed: ' + bodyResponse);
					//					Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(bodyResponse);
					//					if(!'Success'.equalsIgnoreCase(String.valueOf(jsonResponse.get('Status')))) {
					//						// Camunda returned an error when pushing the CSSO notification
					//						// ignore since there is nothing that can be done about it
					//					}
				} else {
					String bodyResponse = response.getBody();
					System.debug('Request was successful.');
				}
			} catch(Exception ex) {
				System.debug('triggerRegistrationCompleteIntegration: error: ' + ex);
				// Error Logged to Exception object for analysis
				UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'BAM', BAMRegistrationSuccessfulController.class.getName(), 'triggerRegistrationCompleteIntegration', 'BAMRegistrationSuccessfulController', LoggingLevel.ERROR);
			}
		}

		return true;

	}



}