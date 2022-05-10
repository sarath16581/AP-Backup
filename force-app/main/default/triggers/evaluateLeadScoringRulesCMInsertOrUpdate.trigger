/*
 * @changelog
 * 2021-08-11 - Seth Heang - Uplift API version to 52
 * 2022-04-11 Naveen Rajanna REQ2804764 - Added check for whether Batch/Future invoked call before making future call
 */
trigger evaluateLeadScoringRulesCMInsertOrUpdate on CampaignMember (after insert, after update) {
    Set<Id> CampaignMemberIds=new Set<Id>();
     
    //Loop needed as asynch apex does not allow passage of Sobjects, only Set's
    for (CampaignMember cm:trigger.new){
        CampaignMemberIds.add(cm.Id); 
    }

    //Send that list of created or updated campaign members to the apex class for processing
    if (LeadScoring.leadScoringClassAlreadyCalled()==False){
        Integer limit1 = Limits.getLimitFutureCalls() - Limits.getFutureCalls();
        if (limit1>0 && !CampaignMemberIds.isEmpty() && !System.IsBatch() && !System.isFuture()){
            LeadScoring.evaluateCMs(CampaignMemberIds);    
        }    
    }
}