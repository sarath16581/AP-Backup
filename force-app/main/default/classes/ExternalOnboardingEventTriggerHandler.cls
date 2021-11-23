/**************************************************
Description:    Handles the platform event fired by Camunda from both Parcel Send Onboarding and BAM capbility
				Tests:
					BAMExternalOnboardingEventHandler_Test
History:
--------------------------------------------------
2019-05-30  nathan.franklin@auspost.com.au  Created
2019-08-05  hasantha.liyanage@auspost.com.au  Added pso updateExternalOnboardingRequests
**************************************************/
public with sharing class ExternalOnboardingEventTriggerHandler {
	/**
	  * This method is invoked from trigger which in-turn calls the handlers for before and after event.
	  */
	public static void execute() {
		if(!System.isFuture()) {

			// Check for event type of trigger
			if(Trigger.isBefore) {
				beforeHandler();        // invoke of before handler
			} else if(Trigger.isAfter) {
				afterHandler();         // invoke of after handler
			}
		}
	}

	/**
	  * This method is handler for before events invoked by execute method. Method invokes the helper class methods based on the scenario.
	  */
	private static void beforeHandler() {
		// Check for type of operation
		if(Trigger.isInsert) {

		}
	}

	/**
	  * This method is handler for after events invoked by execute method. Method invokes the helper class methods based on the scenario.
	  */
	private static void afterHandler() {
		// Check for type of operation
		if (Trigger.isInsert) {
			pso_OnboardingEventTriggerHelper.updateExternalOnboardingRequests((List<ExternalOnboardingEvent__e>) Trigger.New);

			BAMExternalOnboardingEventHandler.processBAMResponses(Trigger.new);

		}
	}
}