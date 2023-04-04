/**
 * @description       : This Class will be called from Cart's Check Out & Redirect to Opportunity Button
 * @author            : Mansi Shah
 * @group             : 
 * @last modified on  : 05-25-2021
 * @last modified by  : Mansi Shah
 * Modifications Log 
 * Ver   Date         Author       Modification      Description
 * 1.0   05-21-2021   Mansi Shah   Initial Version   This class will be called from APT_CheckOut_RedirectToOpportunity Page.
 * 2023.03.30	Naveen Rajanna	INC1994315- Method redirectToOpportunity - Fixed System.ListException and added more null checks
**/
public class APT_CheckOutProposalController {
    public boolean isOpportunityNotPresent {get;set;}
      
    private String configurationId;
    private Apttus_Config2__ProductConfiguration__c prodConfig;
    private String instanceURL;
    
    public String proposalName{get;set;}
    public String proposalFullName{get;set;}
    public String approvalStage{get;set;}
    
    public String opportunityID{get;set;}
  
    public String redirectURL {get; set;}
    public String opportunityURL {get;set;}
     
     public APT_CheckOutProposalController() {        
        configurationId = ApexPages.currentPage().getParameters().get('id');
        instanceURL = URL.getSalesforceBaseUrl().toExternalForm();
    }
    
    /**
    * @description : This is the inital method which will be called from VF Page. This method will check if Opportunity is present on the Proposal or not. 
                     If Opportunity is present, it will call the method for finalizing the Proposal and Redirect user to Opportunity Record.
                     If Opportunity is not present, it will display the error.
    * @author Mansi Shah | 05-21-2021 
    * @return pageReference 
    **/
    public pageReference checkOpportunity()
    {
        prodConfig = [SELECT Id, Apttus_Config2__Status__c,Apttus_QPConfig__Proposald__c,Apttus_QPConfig__Proposald__r.Name,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Proposal_Name__c,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Approval_Stage__c
                      FROM Apttus_Config2__ProductConfiguration__c 
                      WHERE Id = :configurationId];
        
        pageReference ref;
        proposalName = prodConfig.Apttus_QPConfig__Proposald__r.Name;
        proposalFullName=prodConfig.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Proposal_Name__c;
        approvalStage = prodConfig.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Approval_Stage__c;

        if(prodConfig != null && prodConfig.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c != null)
        {
            opportunityID = prodConfig.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c;
            isOpportunityNotPresent = false;
            ref = redirectToOpportunity();
        }
        else
        {
            isOpportunityNotPresent = true; 
        }
        return ref;
    }
  
    /**
    * @description: This method will call the OOTB finalize API to finalize the Proposal.
    * @author Mansi Shah | 05-21-2021 
    **/
    public void finalizeProposal(){
        try{
       
            Apttus_CpqApi.CPQ.FinalizeCartRequestDO request = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
            // add request parameters
            request.CartId = configurationId;
            // finalize the cart
            Apttus_CpqApi.CPQ.FinalizeCartResponseDO response = Apttus_CpqApi.CPQWebService.finalizeCart(request);
        }
        Catch(Exception e){
            System.debug('An Exception occured while finalizing the Quote '+e);
        }
    }
       
    /**
    * @description: This method will call the finalize proposal method to finalize the proposal first and after finalization user will redirect to Opportunity. 
    * @author Mansi Shah | 05-21-2021 
    * @return PageReference 
    **/
    public PageReference redirectToOpportunity(){
		try {
			finalizeProposal();
			
			// INC1994315 - Fixed System.ListException and added more null checks
			// Update Proposal Expiration Date if Proposal Line Item exists
			List<Apttus_Proposal__Proposal_Line_Item__c> proposalLineItemList = APT_ProposalLineItemSelector.newInstance(1)
				.selectByConfigId(
					new Set<Id>{configurationId}, 
					new Set<Object>{APT_ProposalLineItemSelector.Options.WITH_PROPOSAL, APT_ProposalLineItemSelector.Options.WITH_APTTUS_CONFIG_ATTRIBUTE_VALUE})
				.values();

			if(!proposalLineItemList.isEmpty()) {
				Date quoteValidityEndDate = proposalLineItemList[0].Apttus_QPConfig__AttributeValueId__r?.Applied_PSR__r?.Quote_Validity_End_Date__c;
				// If Quote Validity End date doesn't exist, then add certain days to Proposal CreatedDate
				Date proposalExpirationDate = quoteValidityEndDate != null 
												? quoteValidityEndDate
												: (Date.valueof(proposalLineItemList[0].Apttus_Proposal__Proposal__r?.Createddate)).AddDays(APT_Constants.PARAM_CONTRACT_EXP_DAYS);

				List<Apttus_Proposal__Proposal__c> updateable = new List<Apttus_Proposal__Proposal__c>();
				updateable.add(
					new Apttus_Proposal__Proposal__c(
						Id = Id.valueOf(proposalLineItemList[0].Apttus_Proposal__Proposal__c),
						Apttus_Proposal__Proposal_Expiration_Date__c = proposalExpirationDate
					)
				);

				ApplicationDatabase.getInstance().dmlUpdate(updateable);
			}
			
			PageReference pageRef;
			if(prodConfig.Apttus_QPConfig__Proposald__r?.Apttus_Proposal__Opportunity__c != null){ // INC1994315
			pageRef = new PageReference(instanceURL+'/' + prodConfig.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c); 
			pageRef.setRedirect(true);
			}
			return pageRef;
		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
    }
}