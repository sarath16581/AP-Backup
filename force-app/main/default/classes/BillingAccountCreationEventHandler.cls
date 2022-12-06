/*
 * @date 2020-11-18
 * @group BillingAccounts
 * @tag BillingAccount
 * @domain Core
 * @description This is the Handler class for BillingAccountCreationEvent__e Trigger .Execute Method is called
 *              from the trigger .
 * @changelog
 * 2020-11-18 - shashwat.nath@auspost.com.au - Created
 * 2022-08-04 - Seth Heang - Updated to handle Rating Plan platform event
*/
public with sharing class BillingAccountCreationEventHandler {
    // Checks for the trigger Event and calls the respective handler method
    public static void execute() {
        if(Trigger.isAfter) {
            afterHandler();        
        }
    }
	//Method to handle after Trigger Events
	private static void afterHandler() {
		// Check for type of operation
		if (Trigger.isInsert) {
			List<BillingAccountCreationEvent__e> billingAccPEs = new List<BillingAccountCreationEvent__e>();
			List<BillingAccountCreationEvent__e> ratingPlanPEs = new List<BillingAccountCreationEvent__e>();
			for(BillingAccountCreationEvent__e platformEvent : (List<BillingAccountCreationEvent__e>)Trigger.New){
				// Rating Plan Platform event has Additional Info set to RatingPlanActivation or RateCardActivation
				if(platformEvent.Additional_Info__c == APT_Constants.RATING_PLAN_ACTIVATION_LABEL || platformEvent.Additional_Info__c == APT_Constants.RATING_CARD_ACTIVATION_LABEL){
					ratingPlanPEs.add(platformEvent);
				}
				// Billing Account Platform Event
				else{
					billingAccPEs.add(platformEvent);
				}
			}
			// Process Rating Plan Platform Event
			if(ratingPlanPEs.size() > 0){
				BillingAccountCreationEventTriggerHelper.activateRatingPlan(ratingPlanPEs);
			}
			// Process Billing Account Platform Event
			if(billingAccPEs.size() > 0){
				BillingAccountCreationEventTriggerHelper.createBillingAccount(billingAccPEs);
			}
		}
	}
}