/**
 * @description       : This is the helper class for Proposal Trigger
 * @author            : Mansi Shah
 * @group             : 
 * @last modified on  : 06-10-2021
 * @last modified by  : Mansi Shah
 * Modifications Log 
 * Ver   Date         Author       Modification
 * 1.0   06-10-2021   Mansi Shah   Initial Version
 * Ken McGuire 2023.04.19 Proposal field migration to opportunity
**/
public with sharing class APT_ProposalTriggerHelper {

    /**
    * @description : This method will blank the Approvla related fields on Approval Rejection/Cancellation.
    * @author Mansi Shah | 06-10-2021
    * @param oldProposalMap
    * @param newProposalMap
    **/
    public static void updateApprovalFields(Map<Id,Apttus_Proposal__Proposal__c> oldProposalMap,Map<Id,Apttus_Proposal__Proposal__c> newProposalMap){
        if(newProposalMap != null){
            for(Apttus_Proposal__Proposal__c oProposal : newProposalMap.values()){
                if(oProposal.Apttus_Proposal__Opportunity__r.IsStartrackProposal__c != null &&
                   oProposal.Apttus_QPApprov__Approval_Status__c != null &&
                    oProposal.Apttus_Proposal__Opportunity__r.IsStartrackProposal__c.equalsIgnoreCase(APT_Constants.OPTION_YES) &&
                   (oProposal.Apttus_QPApprov__Approval_Status__c.equalsIgnoreCase(APT_Constants.APPROVAL_STATUS_REJECTED) ||
                    oProposal.Apttus_QPApprov__Approval_Status__c.equalsIgnoreCase(APT_Constants.APPROVAL_STATUS_CANCELLED)) &&
                    oldProposalMap.containsKey(oProposal.Id) &&
                    oldProposalMap.get(oProposal.Id).Apttus_QPApprov__Approval_Status__c != oProposal.Apttus_QPApprov__Approval_Status__c)
                {
                    oProposal.APT_Tier_Adjustment_Type__c = '';
                    oProposal.APT_Pricing_Request_Type__c = '';
                    oProposal.APT_Tier_Adjustment_Justification__c = '';
                    oProposal.APT_Intermediary__c = '';
                    oProposal.APT_Customer_Background__c = '';
                    oProposal.APT_Conversation__c = '';
                    oProposal.APT_Name_of_Intermediary_s_Client__c = null;
                    oProposal.APT_competitor__c = '';
                }

				//Added By Yatika - STP-8804
				if(oldProposalMap.get(oProposal.Id).Apttus_Proposal__Approval_Stage__c == APT_Constants.APPROVAL_STAGE_ACCEPTED_WITHOUT_PROP_DOC && 
					oProposal.Apttus_Proposal__Approval_Stage__c == APT_Constants.APPROVAL_STAGE_GENERATED){
				 	oProposal.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_ACCEPTED_WITHOUT_PROP_DOC;
				}

                if(oldProposalMap.get(oProposal.Id).Apttus_Proposal__Approval_Stage__c == APT_Constants.APPROVAL_STAGE_ACCEPTED && 
					oProposal.Apttus_Proposal__Approval_Stage__c == APT_Constants.APPROVAL_STAGE_ACCEPTED_WITHOUT_PROP_DOC){
				 	oProposal.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_ACCEPTED;
				}
            }
        }
    }
    
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