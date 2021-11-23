/**************************************************
Description:  Onboarding request trigger Handler class

History:
--------------------------------------------------
2019-05-16  hasantha.liyanage@auspost.com.au Created
2019-08-19  hasantha.liyanage@auspost.com.au Modified to use a static method for toggle delete on contact functionality, so that we can use a future method.
**************************************************/
public without sharing class pso_OnboardingRequestTriggerHandler {
    /**
      * @description       This method is invoked from trigger which in-turn calls the handlers
                           for before and after event.
      * @param             NA
      * @return            Void
      * @throws            NA
      */
    public static void execute() {
        if(!System.isFuture()) {
            // Check for event type of trigger
            if(Trigger.isAfter) {
                afterHandler();         // invoke of after handler
            }
            if(Trigger.isBefore){
                beforeHandler();
            }
        }
    }

    /**
      * @description       This method is handler for after events invoked by execute method.
                           Method invokes the helper class methods based on the scenario.
      * @param             NA
      * @return            Void
      * @throws            NA
      */
    private static void afterHandler() {
        // Check for type of operation
        if (Trigger.isInsert || Trigger.isUpdate) {
            pso_OnboardingRequestTriggerHelper.toggleDeleteLockContact((List<BAMExternalOnboardingRequest__c>) Trigger.New);
        }
    }
    
     /**
      * @description       This method is handler for before events invoked by execute method.
                           Method invokes the helper class methods based on the scenario.
      * @param             NA
      * @return            Void
      * @throws            NA
      */
    private static void beforeHandler() {
        // Check for type of operation
        if (Trigger.isInsert) {
            pso_OnboardingRequestTriggerHelper.createParcelSendAsset(Trigger.New);
        }
    }
}