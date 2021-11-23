/*
 * @date 2021-05-10
 * @group Proposals
 * @tag Proposal
 * @domain Core
 * @description Apex class for navigating from credit assesment process to Sub Account Request LWC Component
 * @changelog
 * 2021-05-10 - Dheeraj.Mandavilli@auspost.com.au - Created
 */
public with sharing class NavigationtoSubAccountRequestFormClass {


    public String proposalId{get;set;}
    public String chargeAccountId;
    Apttus_Proposal__Proposal__c proposal;

    public NavigationtoSubAccountRequestFormClass(ApexPages.StandardController controller){
        proposalId = ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_PROPOSAL_ID);
        system.debug('recordId:::'+proposalId);
        chargeAccountId = ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_CHARGE_ACCOUNT_ID);
        system.debug('chargeAccountId:::'+chargeAccountId);
        }

}