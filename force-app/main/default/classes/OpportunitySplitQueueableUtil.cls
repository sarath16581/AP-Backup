/*
 * @date 2021-02-22
 * @group Opportunities
 * @tag OpportunitySplit
 * @domain Core
 * @description queueable job for updating the direct contribution details on closed opportunity owner change
 * @changelog
 * 2021-02-22 - arjun.singh@auspost.com.au - Created
 */
/**
 * @Description: queable job to update the Direct Contribution percent value on closed opportunity.
 * 			     Note: without sharing is used since update/delete needs to happen in system mode
 */
public without sharing class OpportunitySplitQueueableUtil implements Queueable{
   
	Map<Id, Opportunity> toBeProcessedOpportuityMap = new Map<Id,Opportunity>();
    public OpportunitySplitQueueableUtil(Map<Id, Opportunity> toBeProcessedOpportuityMap){
        this.toBeProcessedOpportuityMap = toBeProcessedOpportuityMap ;  
    }	
	public void execute(QueueableContext context) {
		try{
			Map<Id, Opportunity> newOpportunityOwnerMap = new Map<Id, Opportunity>();
			Map<Id,List<OpportunitySplit>> opportunityWithSplits = new Map<Id,List<OpportunitySplit>>();		
			List<OpportunitySplit> splitToBeUpdated = new List<OpportunitySplit>();
			List<OpportunitySplit> splitToBeDeleted = new List<OpportunitySplit>();
			Set<Id> userIds = new Set<Id>();
			Set<Id> opportunityIds = new Set<Id>();

			for(Opportunity opp: toBeProcessedOpportuityMap.values()){
				newOpportunityOwnerMap.put(opp.ownerId, opp);
				opportunityIds.add(opp.Id);
			}
			OpportunitySplitType directContributionSplitType = [Select Id, MasterLabel From OpportunitySplitType Where  MasterLabel =: OpportunitySplitUtility.DIRECT_CONTRIBUTION];

			Map<Id, OpportunitySplit> splitsRecords = OpportunitiesSplitSelector.newInstance().selectByOpportunity(opportunityIds);
			for(OpportunitySplit oSplit: splitsRecords.values()){
				if(oSplit.splitTypeId == directContributionSplitType.Id){
					if(opportunityWithSplits.containsKey(oSplit.OpportunityId)){
						List<OpportunitySplit> opportunitySplitTemp = new List<OpportunitySplit>();
						opportunitySplitTemp = opportunityWithSplits.get(oSplit.OpportunityId);
						opportunitySplitTemp.add(oSplit);
					}else{
						opportunityWithSplits.put(oSplit.OpportunityId, new List<OpportunitySplit>{oSplit});
					}
				}
				userIds.add(oSplit.splitOwnerId);
			}
			if(!userIds.isEmpty()){
				Map<Id, User> userMap = OpportunityUtility_part2.getRequestedUsers(userIds);
				for(Id oppId : opportunityWithSplits.keySet()){ 
					OpportunitySplit oldOwnerSplitRecord = new OpportunitySplit();
					OpportunitySplit newOwnerSplitRecord = new OpportunitySplit();
					for(OpportunitySplit oSplit: opportunityWithSplits.get(oppId)){
						if(toBeProcessedOpportuityMap.containsKey(oSplit.SplitOwnerId) && oSplit.OpportunityId == toBeProcessedOpportuityMap.get(oSplit.SplitOwnerId).Id){
							oldOwnerSplitRecord = oSplit ;
						}
						if(newOpportunityOwnerMap.containsKey(oSplit.SplitOwnerId) && oSplit.OpportunityId == newOpportunityOwnerMap.get(oSplit.SplitOwnerId).Id){
							newOwnerSplitRecord = oSplit ;
						}
					}

					if(newOwnerSplitRecord.Id != null && oldOwnerSplitRecord.Id != null){
						OpportunitySplit OpportunitySplitTemp = newOwnerSplitRecord;
						OpportunitySplitTemp.SplitPercentage = oldOwnerSplitRecord.SplitPercentage;
						if(userMap.containsKey(newOwnerSplitRecord.SplitOwnerId)){
							OpportunitySplitTemp.Role_Name_at_Opportunity_Closure__c = userMap.get(newOwnerSplitRecord.SplitOwnerId).UserRole.Name;
						}
						oldOwnerSplitRecord.SplitPercentage = 0;

						splitToBeUpdated.add(OpportunitySplitTemp);
						splitToBeUpdated.add(oldOwnerSplitRecord);

						splitToBeDeleted.add(oldOwnerSplitRecord);
					}			
				}
				if(!splitToBeUpdated.isEmpty()){
					ApplicationDatabase.getInstance().dmlUpdate(splitToBeUpdated);
				}
				if(!splitToBeDeleted.isEmpty()){
					ApplicationDatabase.getInstance().dmlDelete(splitToBeDeleted);
				}
			}
		}catch(Exception err){
			GlobalUtility.logMessage('ERROR', 'updateDirectContributorPercentage', 'opportunitySplit', '', '', err.getMessage(), '', null, 0);
		}	

	}
}