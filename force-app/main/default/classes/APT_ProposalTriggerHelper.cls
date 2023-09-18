/**
 * @description: This is the helper class for Proposal Trigger
 * @author: Mansi Shah
 * @last modified on: 06-10-2021
 * @last modified by: Mansi Shah
 * Modifications Log
 * Ver Date Author Modification
 * 1.0   06-10-2021 Mansi Shah Initial Version
 * Ken McGuire 2023.04.19 Proposal field migration to opportunity
 * Paul Perry	2023-09-14 Decommissioned StarTrek Pricing Matrix logic MW0005472
**/
public with sharing class APT_ProposalTriggerHelper {
	/**
	* @description : This method will set Proposal based on Opportunity driver on Opportunity Object - (Opportunity'owner)
	* @author Mansi Shah | 07-14-2021
	* @param newProposalList
	**/
	public static void updateProposalOwner(list<Apttus_Proposal__Proposal__c> newProposalList)
	{
		if(newProposalList != null && !newProposalList.isEmpty())
		{
			Set<Id> setOfOpportunityIds = new Set<Id>();
			for(Apttus_Proposal__Proposal__c oProposal : newProposalList){
				if(oProposal.Apttus_Proposal__Opportunity__c != null){
					setOfOpportunityIds.add(oProposal.Apttus_Proposal__Opportunity__c);
				}
			}

			if(setOfOpportunityIds != null){
				List<Opportunity> listOfOpportunities = new List<Opportunity>();
				Map<Id,Opportunity> mapOfOpportunities = new Map<Id,Opportunity>();
				listOfOpportunities = [SELECT Id,OwnerID
									  FROM Opportunity
									  WHERE ID IN: setOfOpportunityIds];

				if(listOfOpportunities != null && !listOfOpportunities.isEmpty()){

					for(Opportunity opp : listOfOpportunities){
						mapOfOpportunities.put(opp.Id,opp);
					}

					for(Apttus_Proposal__Proposal__c oProposal : newProposalList){
						if(oProposal.Apttus_Proposal__Opportunity__c != null && mapOfOpportunities != null && mapOfOpportunities.containsKey(oProposal.Apttus_Proposal__Opportunity__c)){
							oProposal.OwnerID = mapOfOpportunities.get(oProposal.Apttus_Proposal__Opportunity__c).OwnerID;
						}
					}
				}
			}
		}
	}
}