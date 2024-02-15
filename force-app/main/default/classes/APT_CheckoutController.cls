/**
*@description       : A class which performs various Validations and Actions when Checkout button
						 is clicked in shopping cart
*@author            : Yatika Bansal
*Modifications Log
*1.0 : 09-03-2023 : Bharat Patel : Added method for OOTB finalize API to finalize the Proposal on 'Checkout Only' action from LWC
*1.0 : 19-04-2023 : Nasir Jawed: Added method checkWorkVerification to check work Verification product added on the cart
*1.0 : 24-05-2023 : Yatika Bansal: Modified method checkCreditAssessmentAndExecuteRateCardLogic to check only approved credit assessments
*1.0 : 14-08-2023 : Yatika Bansal: Added method docGenerationRequired to check if document generation is required before agreement generation
*1.0 : 22-08-2023 : Bharat Patel: Added method getProposalDocGenerationProgress() to
*	 : 15-02-2024 : Bharat Patel: Modified method docGenerationRequired(), add logic related to APT_Document_Notification_Off__c
**/
public without sharing class APT_CheckoutController{

	public String configId {get; set;}
	public String proposalId {get; set;}

	public APT_CheckoutController(){
		// get parameters from VF Page
		configId = apexpages.currentPage().getParameters().get('id');
		proposalId = apexpages.currentPage().getParameters().get('businessObjectId');
	}

	public String checkoutAttributes{
		get {
			// build attributes map pf VF paramters to pass into LWC
			Map<String, Object> componentAttributes = new Map<String, Object> {
				'configId' => configId,
				'proposalId' => proposalId
			};
			return JSON.serialize(componentAttributes);
		}
		private set;
	}

	 /**
	* @description: This method will call the OOTB finalize API to finalize the Proposal.
	* @author Bharat Patel | 09-03-2023
	* @param String configId
	* @return Finalize Cart Operation Output
	**/
	@AuraEnabled
	public static String validateConfiguration(String configId){
		try{
			List<Apttus_Config2__LineItem__c> configLIs = LineItemsSelector.newInstance(1)
				.selectByProdConfigLineTypeAndStatus(new Set<Id>{configId},
													 new Set<String> {APT_Constants.LABEL_LINE_TYPE_OPTION},
													 new Set<String> {APT_Constants.LABEL_LINE_STATUS,
														 APT_Constants.LABEL_LINE_STATUS_DEF_PENDING});

			if(configLIs == null || configLIs.isEmpty()){
				return APT_Constants.SUCCESS_LABEL_SMALL;
			}
			return '';
		}
		catch(Exception ex){
			return APT_Constants.ERROR_PREFIX + ex.getMessage();
		}
	}

	/**
	* @description: This method will call the OOTB finalize API to finalize the Proposal.
	* @author Bharat Patel | 09-03-2023
	* @param String configId
	* @return Finalize Cart Operation Output
	**/
	@AuraEnabled
	public static String checkoutOnly(String configId){
		try{
			Id configurationId = Id.valueOf(configId);
			Apttus_CpqApi.CPQ.FinalizeCartRequestDO request = new Apttus_CpqApi.CPQ.FinalizeCartRequestDO();
			// add request parameters
			request.CartId = configurationId;
			// finalize the cart
			Apttus_CpqApi.CPQ.FinalizeCartResponseDO response = Apttus_CpqApi.CPQWebService.finalizeCart(request);
			return APT_Constants.SUCCESS_LABEL_SMALL;
		}
		Catch(Exception ex){
			return APT_Constants.ERROR_PREFIX + ex.getMessage() ;
		}
	}

	/**
	* @description: This method will use to check the current status of proposal doc generation progress
	* @author Bharat Patel
	* @param String proposalId
	* @return boolean
	**/
	@AuraEnabled
	public static boolean getProposalDocGenerationProgress(String proposalId){
		List<Apttus_Proposal__Proposal__c> proposalDetails = APT_ProposalObjectsSelector.newInstance().selectByConfigIds(new set<ID>{(ID)proposalId});
		Boolean isDocGenerationRunning = false;
		if(proposalDetails != null)
			isDocGenerationRunning = proposalDetails[0].APT_Document_Generation_in_Progress__c;
		return isDocGenerationRunning;
	}

	/**
	* @description: This method will initiate rate card execution
	* @author Yatika Bansal
	* @param String proposalId
	* @return boolean
	**/
	@AuraEnabled
	public static boolean initiateRateCardGeneration(String proposalId){
		//rate card execution; to initiate Proposal Document Generation request
		boolean result;
		APT_ViewRatecardBatchExecute rateCardBatch = new APT_ViewRatecardBatchExecute(proposalId, false);
		PageReference redirectPage = rateCardBatch.init();
		if(redirectPage != null){
			result =true; //returns true if it gets redirected to page
		}else{
			result =false; //returns false if it has an error
		}
		return result;
	}

	/**
	* @description: This method checks credit assessment status and performs rate card execution.
	* @author Yatika Bansal
	* @param String proposalId
	* @return Status
	**/
	@AuraEnabled
	public static String checkCreditAssessmentAndExecuteRateCardLogic(String proposalId){
		try{
			ID propId = (ID)proposalId;
			//checks credit assesment
		   List<APT_Credit_Assessment__c> creditAssess = APT_CreditAssessmentSelector.newInstance(1)
			   .selectByProposalAndAssessStatus(new Set<Id>{proposalId},
														new Set<String> {APT_Constants.CREDIT_ASSESSMENT_STATUS_APPROVED, APT_Constants.CREDIT_ASSESSMENT_STATUS_AUTO_APPROVED});

			if(creditAssess.size() > 0){
				initiateRateCardGeneration(propId);
				return APT_Constants.STRING_RESPONSE_COMPLETE;
			}else{
				return APT_Constants.STRING_RESPONSE_INCOMPLETE;
			}
		}
		Catch(Exception ex){
			return APT_Constants.ERROR_PREFIX + ex.getMessage() ;
		}
	}

	/**
	*@description: This method checks Workforce Verification product.
	*@author Nasir Jawed
	*@param String configId
	*@return boolean
	**/
	@AuraEnabled
	public static boolean checkWorkVerification(string configId){
		boolean checkWorkVerification = false;
		ID quoteConfigurationId = (ID)configId;
		List<Apttus_Config2__LineItem__c> lineItem = LineItemsSelector.newInstance().selectByProdConfId(new set<ID>{(ID)quoteConfigurationId});
		for(Apttus_Config2__LineItem__c li : lineItem){
			if(li.APT_Product_Code__c == 'Workforce Verification'){
				checkWorkVerification = true;
				return checkWorkVerification;
			}
		}
		return checkWorkVerification;
	}


	/**
	*@description: This method checks if document generation is required before agreement generation.
	*@author Yatika Bansal
	*@param String configId
	*@return boolean
	**/
	@AuraEnabled
	public static Boolean docGenerationRequired(string configId, Id proposalId, Boolean notificationDisabled){
        Set<String> productNames = new Set<String>();
        for(APT_Proposal_Doc_Generation_Products__mdt proposalProduct : [SELECT APT_Product_Name__c FROM APT_Proposal_Doc_Generation_Products__mdt]){
            productNames.add(proposalProduct.APT_Product_Name__c);
        }

		List<Apttus_Config2__LineItem__c> lineItem = LineItemsSelector.newInstance().selectByProdConfIdAndProductName(new set<ID>{(ID)configId}, productNames);
        if(lineItem != null && lineItem.size() > 0){
			if(notificationDisabled == true) {
				Apttus_Proposal__Proposal__c proposalRecord = new Apttus_Proposal__Proposal__c();
				proposalRecord.Id= proposalId;
				proposalRecord.APT_Document_Notification_Off__c = true;
				List<Apttus_Proposal__Proposal__c> proposalsToBeUpdatedList = new List<Apttus_Proposal__Proposal__c>();
				proposalsToBeUpdatedList.add(proposalRecord);
				ApplicationDatabase.getInstance().dmlUpdate(proposalsToBeUpdatedList);
			}
            return true;
        }

		return false;
	}
}