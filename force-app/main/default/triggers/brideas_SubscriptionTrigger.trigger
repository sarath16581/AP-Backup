trigger brideas_SubscriptionTrigger on brideas_Subscription__c (after insert) {
    try {
        brideas_SubscriptionTriggerHandler hndlr = new brideas_SubscriptionTriggerHandler();

        if (Trigger.isAfter && Trigger.isInsert) {
            hndlr.addReputationPointOnSubscriptionIdea(Trigger.new.size());
        }
    } catch(Exception ex) {
        System.debug('IdeaSubscriptionTrigger error: ' + ex.getMessage());
    }
}