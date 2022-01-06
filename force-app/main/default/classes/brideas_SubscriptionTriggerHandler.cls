public with sharing class brideas_SubscriptionTriggerHandler {
    public static Boolean hasFiredIdeaTrigger = false;
    public void addReputationPointOnSubscriptionIdea(Integer countVotes) {
        if(!hasFiredIdeaTrigger) {
            brideas_Helper.updateMemberReputation('votePoints', countVotes);
        }
    }
}