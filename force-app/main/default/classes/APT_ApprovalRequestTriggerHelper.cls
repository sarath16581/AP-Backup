/**
 * @description       : 
 * @author            : Mansi Shah
 * @group             : 
 * @last modified on  : 07-14-2021
 * @last modified by  : Mansi Shah
 * Modifications Log 
 * Ver   Date         Author       Modification
 * 1.0   07-14-2021   Mansi Shah   Initial Version
**/
public with sharing class APT_ApprovalRequestTriggerHelper {
    /**
    * @description : This method will populate Adjustment fields on Approval Request from Proposal for startrack Approvals
    * @author Mansi Shah | 07-14-2021 
    * @param approvalrequestNew 
    **/
    public static void updateAdjustmentFields(List<Apttus_Approval__Approval_Request__c> listOfNewApprovalRequest,Map<Id,Apttus_Approval__Approval_Request__c> oldApprovalRequestMap,Boolean isNew){
        
        if(listOfNewApprovalRequest != null && !listOfNewApprovalRequest.isEmpty()){
            Set<Id> setOfProposalIds = new Set<Id>();
            Map<Id,Apttus_Proposal__Proposal__c> mapOfProposal = new Map<Id,Apttus_Proposal__Proposal__c>();

            for(Apttus_Approval__Approval_Request__c oApprovalRequest : listOfNewApprovalRequest){
                System.debug(oApprovalRequest.Apttus_Approval__Object_Type__c);
                if(oApprovalRequest.Apttus_Approval__Object_Type__c.equalsIgnoreCase(APT_Constants.PRODUCT_CONFIGURATION_OBJECT) && oApprovalRequest.Apttus_QPApprov__ProposalId__c != null)
                {
                    setOfProposalIds.add(oApprovalRequest.Apttus_QPApprov__ProposalId__c);
                }
            }
        
            if(setOfProposalIds != null)
            {
                for(Apttus_Proposal__Proposal__c oProposal : [SELECT Id,Name,APT_Tier_Adjustment_Type__c,APT_Customer_Background__c,APT_Conversation__c,APT_Tier_Adjustment_Justification__c 
                                                              FROM Apttus_Proposal__Proposal__c
                                                              WHERE Id IN :setOfProposalIds])
                {  
                    mapOfProposal.put(oProposal.Id,oProposal);
                }
        
                for(Apttus_Approval__Approval_Request__c oApprovalRequest : listOfNewApprovalRequest)
                {
                    if(mapOfProposal != null && 
                       mapOfProposal.containsKey(oApprovalRequest.Apttus_QPApprov__ProposalId__c) && 
                       mapOfProposal.get(oApprovalRequest.Apttus_QPApprov__ProposalId__c).APT_Tier_Adjustment_Type__c != null)
                    {
                        if(mapOfProposal.get(oApprovalRequest.Apttus_QPApprov__ProposalId__c).APT_Customer_Background__c != null){
                            oApprovalRequest.APT_CustomerBackground__c = mapOfProposal.get(oApprovalRequest.Apttus_QPApprov__ProposalId__c).APT_Customer_Background__c;
                        }
                        if(mapOfProposal.get(oApprovalRequest.Apttus_QPApprov__ProposalId__c).APT_Conversation__c != null){
                            oApprovalRequest.APT_Conversation_with_customer__c = mapOfProposal.get(oApprovalRequest.Apttus_QPApprov__ProposalId__c).APT_Conversation__c;
                        }
                        if(mapOfProposal.get(oApprovalRequest.Apttus_QPApprov__ProposalId__c).APT_Tier_Adjustment_Justification__c != null){
                            oApprovalRequest.APT_Sales_Justification__c = mapOfProposal.get(oApprovalRequest.Apttus_QPApprov__ProposalId__c).APT_Tier_Adjustment_Justification__c;
                        }
                    }
                }
            }
        }
    }
}