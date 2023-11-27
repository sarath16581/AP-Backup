/**
Description: This apex class is utility class for Amend/Renew.
Created By - Mausam Padhiyar
Created Date - 3rd Nov, 2015

Last Modified By - Mausam Padhiyar
Last Modified Date - 14th Sept, 2016 | 1310 : Copy attachments from original agreement to amended agreement

Last Modified By - Mausam Padhiyar
Last Modified Date - 21th Sept, 2016 | 1165 : Contract Pricing

Last Modified By - Mausam Padhiyar
Last Modified Date - 26th Sept, 2016 | 1397 : PBP should have new status

Last Modified By - Mausam Padhiyar
Last Modified Date - 25th Oct, 2016 | 1655 : copy SAP Contracts and versioning

Last Modified By - Mausam Padhiyar
Last Modified Date - 27th Oct, 2016 | 1310 : Copy Content Documents | Feed Item

Last Modified By - Adrian Recio
Last Modified Date - 12th Dec, 2017 | Updated to flush values in opportunity cloning

Last Modified By - Madhuri Awasthi
Last Modified Date -  18th June, 2021 | INC1739984  : Making the SAP Contract Inactive when for the old version contarcts

2022-06-08 - Naveen Rajanna - REQ2595048 - Reset Pricing Category to 'Standard' after Agreement Clone upon amend or renewal and upgrade api version to 52
2022-10-05 - seth.heang@auspost.com.au - uplift API version to 55, update copyProposalChildRecords() method to check for bundle products hierarchy and remove decommisioned products
2023-10-19 - Bharat Patel - update afterAmend(), commented copyAttachments() execution, STP-9851 changes, remove copyAttachments(originalAgreementId, amendedAgreementId)
2023-11-15 - Mahesh Parvathaneni - STP-9212 - Updated to remove the DoV: and Renewal: prefixes from the opportunity name while cloning
2023-11-22 - Bharat Patel - STP-9770 - added resetOpportunityProposalPrimary(), to reset respected opportunity's proposal's primary flag
*/
public without sharing class APT_AmendRenewUtility {


	/**
		This method will clone opportunity
		@params -
		opportunityId - id of opportunity record which needs to be cloned
	*/  
	public static Opportunity cloneOpporunity(Apttus__APTS_Agreement__c agreement, String actionType) {
		try {
			/*
			Opportunity originalOpportunity = [SELECT Id, Name, ECLM_IsRenewal__c, StageName, CloseDate,
											Type, LeadSource, Contract_Start_Date__c, Contract_End_Date__c
											FROM Opportunity 
											WHERE Id =:agreement.Apttus__Related_Opportunity__c];
			*/

			Id originalOpportunityId = agreement.Apttus__Related_Opportunity__c;
			Opportunity originalOpportunity = database.query(APT_Constants.SOQL_SELECT + getAllAgrFields(APT_Constants.STRING_OPPORTUNITY) + APT_Constants.STRING_FROM_OPPORTUNITY_WHERE);
		
			Opportunity clonedOpportunity = originalOpportunity.clone(false, true);
			// Added by Adrian Recio, 5/12/2017, Code added to flush unwanted values from opportunity cloning
			clonedOpportunity.Business_Development_Driver__c = null; //(lookup user field)
			clonedOpportunity.Supply_Chain_Optimisation_Driver__c = null; //(lookup user field)
			clonedOpportunity.Strategic_Account_Executive_Driver__c = null; //(lookup user field)
				
			if(!String.isEmpty(actionType) && actionType.equalsIgnoreCase(APT_Constants.ACTION_TYPE_RENEWAL)) {
				// Assign Opportunity SubType value to "Renewal"
				clonedOpportunity.Opportunity_SubType__c = APT_Constants.OPPORTUNITY_SUBTYPE_RENEWAL;
				clonedOpportunity.Name = APT_Constants.CLASSIFICATION_RENEWAL + APT_Constants.SEPARATOR_COLON + removeDovRenewalPartsFromOppName(originalOpportunity.Name);
				clonedOpportunity.LeadSource = APT_Constants.LEAD_SOURCE_CONTRACT_RENEWAL;
				clonedOpportunity.ECLM_IsRenewal__c = true;
			} 
			/*
				* Update the Action Type from original "DoV" to "DoV Increase"
				*/
			else if(APT_Constants.ACTION_NAME_DoV_Increase.equalsIgnoreCase(actionType)){
				//  Assign Opportunity SubType value to "DoV Increase"
				clonedOpportunity.Opportunity_SubType__c = APT_Constants.OPPORTUNITY_SUBTYPE_DoV_Increase;
				clonedOpportunity.Name = APT_Constants.ACTION_NAME_DoV + APT_Constants.SEPARATOR_COLON  + removeDovRenewalPartsFromOppName(originalOpportunity.Name);
				clonedOpportunity.LeadSource = APT_Constants.ACTION_NAME_DoV;
				} 
			/*Shashwat.Nath@Auspost.Com.au Added the below else if Condition for Decrease Revenue DOV Scenario to Set the Opportunity Sub Type , Name fields and 
				also supersede the Original Opportunity Similar to Increase Revenue Scenario */
				
			else if(APT_Constants.ACTION_NAME_DoV_Decrease.equalsIgnoreCase(actionType)){
				//Assign Opportunity SubType value to "DoV Decrease"
				clonedOpportunity.Opportunity_SubType__c = APT_Constants.ACTION_NAME_DoV_Decrease;
				clonedOpportunity.Name = APT_Constants.ACTION_NAME_DoV + APT_Constants.SEPARATOR_COLON  + removeDovRenewalPartsFromOppName(originalOpportunity.Name);
				clonedOpportunity.LeadSource = APT_Constants.ACTION_NAME_DoV;
				}
				
			/* Shashwat.Nath@Auspost.Com.au code ends */
			
			clonedOpportunity.StageName = APT_Constants.STAGE_NAME_IDENTIFY;
			clonedOpportunity.Probability = 10;
			clonedOpportunity.Type = APT_Constants.OPPORTUNITY_TYPE_EXISTING_CUSTOMER;
			
			clonedOpportunity.Contract_Start_Date__c = agreement.Apttus__Contract_End_Date__c;
			if(agreement.Apttus__Contract_End_Date__c != null) {
				clonedOpportunity.Contract_End_Date__c = agreement.Apttus__Contract_End_Date__c.addDays(365);
				clonedOpportunity.CloseDate = agreement.Apttus__Contract_End_Date__c;
			} else {
				clonedOpportunity.CloseDate = date.today().addDays(365);
			}
			clonedOpportunity.ECLM_Original_Opportunity_No__c = agreement.Apttus__Related_Opportunity__c;
			clonedOpportunity.NextStep = APT_Constants.OPPORTUNITY_NEXTSTEP_UPDATE_OPPORTUNITY_DETAILS;
			clonedOpportunity.Next_Step__c= APT_Constants.OPPORTUNITY_NEXTSTEP_UPDATE_OPPORTUNITY_DETAILS ;
			/* Shashwat.Nath@Auspost.com Added the below piece of code to make sure these two fields are not getting copied over from 
				the original Opportunity as user needs to manually populate them per opportunity basis */
				
			clonedOpportunity.Pre_Entry__c = false;
			clonedOpportunity.Offline_Contract_Received__c = false;
			clonedOpportunity.Data_Integrity_Compliance__c = false;
			clonedOpportunity.DOV_Reason__c = '';
			
			/* Shashwat.Nath@Auspost.com.code ends*/
			
			return clonedOpportunity;
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			return null;
		}
	}


	/**
		This method will clone Opportunity Products.
		@params -
		listOpportunityLineItem - list of opportunity product records
		*/
	public static list<OpportunityLineItem> cloneOpporunityProducts(Id opportunityId,
																	Apttus__APTS_Agreement__c agreement,
																	list<OpportunityLineItem> listOpportunityLineItem,
																	String actionType) {
		list<OpportunityLineItem> listClonedOpportunityLineItem = new list<OpportunityLineItem>();
		
		try {
			for(OpportunityLineItem originalOTM : listOpportunityLineItem) {
				OpportunityLineItem otm = originalOTM.clone(false, true);
				if(!String.isEmpty(actionType) && actionType.equalsIgnoreCase(APT_Constants.ACTION_TYPE_RENEWAL)) {
					otm.Classification__c = APT_Constants.CLASSIFICATION_RENEWAL;
				} else if(!String.isEmpty(actionType) && actionType.equalsIgnoreCase(APT_Constants.ACTION_NAME_DoV)) {
					otm.Classification__c = APT_Constants.CLASSIFICATION_GROWTH;
				} else {}
				
				//APOST-1394 > start
				if(agreement.Apttus__Contract_End_Date__c != null) {
					otm.Contract_Start_Date__c = agreement.Apttus__Contract_End_Date__c.addmonths(1);
				} else {
					otm.Contract_Start_Date__c = date.today().addmonths(1);
				}
				
				if(otm.Contract_Start_Date__c != null) {
					otm.Contract_End_Date__c = otm.Contract_Start_Date__c.addmonths(12).addDays(-1);
				}
				//APOST-1394 > end
				
				//otm.Contract_Start_Date__c = agreement.Apttus__Contract_End_Date__c;
				//otm.Contract_End_Date__c = null;
				otm.ProdClassFieldUpdate__c = null;
				otm.OpportunityId = opportunityId;
				otm.APT_Is_Apttus_Opportunity_Line_item__c = true;
				
				listClonedOpportunityLineItem.add(otm);
			}
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			return null;
		}
		
		return listClonedOpportunityLineItem;
	}

	/**
		This method will create new renewal opportunity.
		@params -
		agreement - agreement which is being renewed
	*/
	public static Opportunity newOpportunity(Apttus__APTS_Agreement__c agreement, String actionType) {
		Opportunity newOpportunity = new Opportunity();
		try
		{
			if(!String.isEmpty(actionType) && actionType.equalsIgnoreCase(APT_Constants.ACTION_TYPE_RENEWAL)) {
				//  Assign Opportunity SubType value to "Renewal"
				newOpportunity.Opportunity_SubType__c = APT_Constants.OPPORTUNITY_SUBTYPE_RENEWAL;
				newOpportunity.Name = APT_Constants.CLASSIFICATION_RENEWAL + APT_Constants.SEPARATOR_COLON + agreement.Name;
				newOpportunity.LeadSource = APT_Constants.LEAD_SOURCE_CONTRACT_RENEWAL;
				newOpportunity.ECLM_IsRenewal__c = true;
			}
			/*
				* Update the Action Type from original "DoV" to "DoV Increase"
				*/ 
			else if(!String.isEmpty(actionType) && actionType.equalsIgnoreCase(APT_Constants.ACTION_NAME_DoV_Increase)) {
				//  Assign Opportunity SubType value to "DoV Increase"
				newOpportunity.Opportunity_SubType__c = APT_Constants.OPPORTUNITY_SUBTYPE_DoV_Increase;
				newOpportunity.Name = APT_Constants.ACTION_NAME_DoV + APT_Constants.SEPARATOR_COLON  + agreement.Name;
				newOpportunity.LeadSource = APT_Constants.ACTION_NAME_DoV;
			} else {}
			
			newOpportunity.StageName = APT_Constants.STAGE_NAME_IDENTIFY;
			newOpportunity.Probability = 10; 
			newOpportunity.Type = APT_Constants.OPPORTUNITY_TYPE_EXISTING_CUSTOMER;
			
			newOpportunity.Contract_Start_Date__c = agreement.Apttus__Contract_End_Date__c;
			if(agreement.Apttus__Contract_End_Date__c != null) {
				newOpportunity.Contract_End_Date__c = agreement.Apttus__Contract_End_Date__c.addDays(365);
				newOpportunity.CloseDate = agreement.Apttus__Contract_End_Date__c;
			} else {
				newOpportunity.CloseDate = date.today().addDays(365);
			}  
			newOpportunity.AccountID = agreement.Apttus__Account__c;
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			return null;
		}
		
		return newOpportunity;
	}

	/**
		This method will create cloned proposal. This will should clone proposal line items also.
		@params -
		recordTypeName - proposal record type name
		opportunityId - opportunity record id
		priceListId - price list record id
		agreement - agreement record which is being renewed
		*/
	public static Apttus_Proposal__Proposal__c cloneProposal(String recordTypeName, Id opportunityId, Id priceListId, 
															Apttus__APTS_Agreement__c agreement) {
		try {
			Apttus_Proposal__Proposal__c clonedProposal = Apttus_Proposal.ProposalWebService.cloneProposal(agreement.Apttus_QPComply__RelatedProposalId__c);
			
			
			if(null != agreement.Apttus_QPComply__RelatedProposalId__r.APT_Method_of_Payment__c && String.IsNotBlank(agreement.Apttus_QPComply__RelatedProposalId__r.APT_Method_of_Payment__c )) {
				clonedProposal.Billing_Account_Type_Text__c = agreement.Apttus_QPComply__RelatedProposalId__r.APT_Method_of_Payment__c;
				
			}
			//reset fields
			String recordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
			clonedProposal.RecordTypeId = recordTypeId;
			clonedProposal.Apttus_Proposal__Proposal_Name__c = APT_Constants.CLASSIFICATION_RENEWAL + APT_Constants.SEPARATOR_COLON + agreement.Apttus_QPComply__RelatedProposalId__r.Apttus_Proposal__Proposal_Name__c;
			
			if(!String.isEmpty(opportunityId )) {
				clonedProposal.Apttus_Proposal__Opportunity__c = opportunityId;
			} else {
				clonedProposal.Apttus_Proposal__Opportunity__c = agreement.Apttus__Related_Opportunity__c;
			}
					
			clonedProposal.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_DRAFT;
			
			clonedProposal.APT_Contract_Number__c = agreement.Apttus__FF_Agreement_Number__c;
			
			//1165
			clonedProposal.APT_Contract_Id__c = agreement.Id;
			//1165
			
			clonedProposal.Apttus_QPConfig__PriceListId__c = priceListId;
			clonedProposal.Apttus_Proposal__Primary_Contact__c = agreement.Apttus__Primary_Contact__c;
			clonedProposal.Apttus_Proposal__Account__c = agreement.Apttus__Account__c;
			clonedProposal.Apttus_Proposal__Primary__c =True;
			
			//This code is as per story APOST 320
			//integer daysDiff = clonedProposal.Expected_Revenue_Start_Date__c.daysBetween(clonedProposal.Expected_Revenue_End_Date__c);
			//Updated if condition for QC-1584
			system.debug('$$$$Kushak recordTypeId '+recordTypeId + '___recordTypeName  '+recordTypeName);
			system.debug('$$$$Kushak APT_Constants.RECORD_TYPE_RENEWAL_QUOTE '+APT_Constants.RECORD_TYPE_RENEWAL_QUOTE);
			if(recordTypeName == APT_Constants.RECORD_TYPE_RENEWAL_QUOTE){
				//Updated as per APOST-475
				clonedProposal.Expected_Revenue_Start_Date__c = agreement.Apttus__Contract_End_Date__c.addmonths(1);
						
				clonedProposal.Expected_Revenue_End_Date__c = clonedProposal.Expected_Revenue_Start_Date__c.addmonths(12).addDays(-1);
				clonedProposal.Apttus_Proposal__Proposal_Expiration_Date__c= clonedProposal.Expected_Revenue_Start_Date__c.addmonths(12).addDays(-1);
				system.debug('!!!!!!'+clonedProposal.Apttus_Proposal__Proposal_Expiration_Date__c);
				//APOST-1553
				clonedProposal.Apttus_QPApprov__Approval_Status__c = null;
				clonedProposal.APT_Document_Generation_in_Progress__c =false;
			}
			//APOST-1553
			
			return clonedProposal;
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			return null;
		}
	}

	/**
		This method will copy configuration.
		@params -
		oldProposalId - original proposal id 
		newProposalId - new proposal id
		*/
	public static Boolean copyConfiguration(Id oldProposalId, Id newProposalId) {
		Boolean bResult = false;
		try {
			bResult = Apttus_Proposal.ProposalWebService.afterClone(oldProposalId, newProposalId);
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			return null;
		}

		return bResult;
	}

	/**
	 * deletes bundles and standalone products
	 * */
	private static void deleteMultiBundleAndStandaloneLines(List<Apttus_Config2__LineItem__c> bundleLinesToDelete)
	{
		String configurationId = null;
		if(bundleLinesToDelete != null)
		{
			List<Decimal> lineNumList = new List<Decimal>();
			for(Apttus_Config2__LineItem__c line:bundleLinesToDelete)
			{
				lineNumList.add(line.Apttus_Config2__LineNumber__c);
				configurationId = line.Apttus_Config2__ConfigurationId__c;
			}
			
				Apttus_CPQApi.CPQ.RemoveMultiBundlesRequestDO request = new Apttus_CPQApi.CPQ.RemoveMultiBundlesRequestDO();
				request.CartId = configurationId;
				request.LineNumbers = lineNumList;
				Apttus_CPQApi.CPQ.RemoveMultiBundlesResponseDO response = Apttus_CPQApi.CPQWebService.removeMultiBundles(request);

		}
	}


	/**
		This method will copy proposal child records i.e. proposal line item and proposal attribute value
		@params -
		oldProposalId - original proposal id 
		newProposalId - new proposal id
		*/
	public static Boolean copyProposalChildRecords(Id oldProposalId, Id newProposalId, String includedProductLines,String actionType, String ContractNumber) {
		Boolean bResult = false;
		try
		{
			bResult = Apttus_QPConfig.QPConfigWebService.copyProductConfiguration(oldProposalId, newProposalId);
			
			/*
			//1165
			system.debug('*** newProposalId ***'+newProposalId);
			list<Apttus_Config2__ProductConfiguration__c> listConfiguration = new list<Apttus_Config2__ProductConfiguration__c>();
			for(Apttus_Config2__ProductConfiguration__c configuration : [SELECT Id, Name, Apttus_Config2__ContractNumbers__c
																		FROM Apttus_Config2__ProductConfiguration__c 
																		WHERE Apttus_QPConfig__Proposald__c = :newProposalId]) {
				configuration.Apttus_Config2__ContractNumbers__c = ContractNumber;
				
				system.debug('*** configuration.Apttus_Config2__ContractNumbers__c ***'+configuration.Apttus_Config2__ContractNumbers__c);
				listConfiguration.add(configuration);
			}
			
			system.debug('*** listConfiguration > size ***'+listConfiguration.size());
			if(listConfiguration.size() > 0) {
				update listConfiguration;
			}
			//1165
			*/
			
			if(bResult) {
				List<Apttus_Config2__LineItem__c> pliList = [select id, Apttus_Config2__LineNumber__c, Apttus_Config2__ItemSequence__c, Apttus_CQApprov__Approval_Status__c,
																Apttus_Config2__ProductId__r.ProductCode, Apttus_Config2__ProductId__r.Non_contracted__c,
																Apttus_Config2__ConfigurationId__c, Apttus_Config2__ProductId__r.APT_Product_type__c, Apttus_Config2__LineType__c,
																Apttus_Config2__IsOptionRollupLine__c, Apttus_Config2__IsPrimaryLine__c, Apttus_Config2__ContractNumbers__c,
																Apttus_Config2__ProductId__r.APT_Contract_Pricing__c, Apttus_Config2__OptionId__r.APT_Contract_Pricing__c,
																APT_Rate_Card_Key__c,APT_RC_Key__c,Apttus_Config2__OptionId__c, Apttus_Config2__OptionId__r.Name, Apttus_Config2__ChargeType__c
																from Apttus_Config2__LineItem__c
																where Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c  =: newProposalId ];
				List<Apttus_Config2__LineItem__c> pliListTobeDeleted = new List<Apttus_Config2__LineItem__c>();
				List<Apttus_Config2__LineItem__c> pliListTobeUpdated = new List<Apttus_Config2__LineItem__c>();
				set<Id> setLineItemId = new set<Id>();
				System.debug('pliList --> ' + pliList);
				System.debug('includedProductLines --> ' + includedProductLines);
				//Apttus Support - Constraint Rule execution for International Bundle
				String CartID;
				/**
				//1094
				map<String, Apttus_Config2__LineItem__c> mapLineItem = new map<String, Apttus_Config2__LineItem__c>();
				for(Apttus_Config2__LineItem__c li : [SELECT Id, Apttus_Config2__LineNumber__c, Apttus_Config2__ItemSequence__c,
														Apttus_Config2__ConfigurationId__r.Apttus_CQApprov__Approval_Status__c, Apttus_CQApprov__Approval_Status__c
														FROM Apttus_Config2__LineItem__c 
														WHERE Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c  = :oldProposalId
														AND Apttus_Config2__ConfigurationId__r.Apttus_Config2__Status__c = :APT_Constants.CONFIGURATION_STATUS_FINALIZED
														AND Apttus_CQApprov__Approval_Status__c = :APT_Constants.APPROVAL_STAGE_APPROVED]){
					
					mapLineItem.put(li.Apttus_Config2__LineNumber__c + APT_Constants.SEPERATOR_SIMILARITY + li.Apttus_Config2__ItemSequence__c, li);
					system.debug('*** line number ***'+li.Apttus_Config2__LineNumber__c+ '*** item sequence ***' + li.Apttus_Config2__ItemSequence__c + '*** config approval status ***' + li.Apttus_Config2__ConfigurationId__r.Apttus_CQApprov__Approval_Status__c + '*** line item approval status ***' + li.Apttus_CQApprov__Approval_Status__c);
				}
				//1094
				**/
				
				if(pliList.size() > 0) {
					Set<Id> productOptionToFind = new Set<Id>();
					Map<Id, Apttus_Config2__LineItem__c> mapProductOptionLI= new Map<Id, Apttus_Config2__LineItem__c>();
					for(Apttus_Config2__LineItem__c pli :pliList ){
						// store option products for later processing to remove decommissioned products after the clone
						if(pli.Apttus_Config2__OptionId__c != null){				
							productOptionToFind.add(pli.Apttus_Config2__ProductId__c);
						}
						mapProductOptionLI.put(pli.Id, pli);
						
						String productType =  pli.Apttus_Config2__ProductId__r.APT_Product_type__c;
						String linetype = pli.Apttus_Config2__LineType__c;
						pli.Apttus_Config2__ConfigStatus__c = 'Pending';
						//Apttus Support - Constraint Rule execution for International Bundle
						if(CartID != ''){
							CartID = pli.Apttus_Config2__ConfigurationId__c;
						}
						//Apttus Support - commented out here and moved to the Amend part only

						//pli.Apttus_Config2__PricingStatus__c= 'Pending';
						pli.Apttus_Config2__ConstraintCheckStatus__c= 'Pending';
						
						System.debug('pli --> ' + pli);
						
						//pli.APT_Pricing_Reason__c = null;
						//pli.APT_Competitors__c = null;
						//pli.Apttus_Config2__AdjustmentAmount__c = null;
						//pli.Apttus_Config2__AdjustmentType__c = null;
						
						/**
						//1094
						system.debug('*** actionType ***'+actionType);
						
						if(String.isNotBlank(actionType) && actionType.equalsIgnoreCase(APT_Constants.ACTION_NAME_AMEND) && mapLineItem != null && mapLineItem.get(pli.Apttus_Config2__LineNumber__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Config2__ItemSequence__c) != null) {
							if(!setLineItemId.contains(pli.Id) ) {
								setLineItemId.add(pli.Id);
								//pli.Apttus_CQApprov__Approval_Status__c = mapLineItem.get(pli.Apttus_Config2__LineNumber__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Config2__ItemSequence__c).Apttus_Config2__ConfigurationId__r.Apttus_CQApprov__Approval_Status__c;
								pli.Apttus_CQApprov__Approval_Status__c = mapLineItem.get(pli.Apttus_Config2__LineNumber__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Config2__ItemSequence__c).Apttus_CQApprov__Approval_Status__c;
								system.debug('*** approval status ***'+mapLineItem.get(pli.Apttus_Config2__LineNumber__c + APT_Constants.SEPERATOR_SIMILARITY + pli.Apttus_Config2__ItemSequence__c).Apttus_CQApprov__Approval_Status__c);
								pliListTobeUpdated.add(pli);
							}
						}
						//1094
						**/
						
						//1165
						if(pli.Apttus_Config2__ProductId__r.APT_Contract_Pricing__c || pli.Apttus_Config2__OptionId__r.APT_Contract_Pricing__c) { 
							pli.Apttus_Config2__PricingStatus__c = APT_Constants.LABEL_LINE_STATUS;
							pli.Apttus_Config2__ContractNumbers__c = ContractNumber;
						}
						//1165
						
						//1084- DoV
						if(String.isNotBlank(actionType) && actionType.equalsIgnoreCase(APT_Constants.ACTION_NAME_AMEND) /** && String.isNotBlank(pli.Apttus_Config2__LineType__c) &&  pli.Apttus_Config2__LineType__c.equalsIgnoreCase(APT_Constants.LINE_TYPE_PRODUCT_SERVICE) && !pli.Apttus_Config2__IsOptionRollupLine__c **/) {
							//1397
							if(null != pli.Apttus_Config2__ProductId__r.ProductCode && String.isNotBlank(pli.Apttus_Config2__ProductId__r.ProductCode) && pli.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_POST_BILLPAY) 
								&& null != pli.Apttus_Config2__LineType__c && String.isNotBlank(pli.Apttus_Config2__LineType__c) &&  pli.Apttus_Config2__LineType__c.equalsIgnoreCase(APT_Constants.LINE_TYPE_PRODUCT_SERVICE)
								&& pli.Apttus_Config2__IsPrimaryLine__c && !pli.Apttus_Config2__IsOptionRollupLine__c) {
								pli.APT_New__c = true;
							} else {
								pli.APT_New__c = false;
							}
							
														
							//1397
							pli.APT_New_Amend__c = false;
							pli.APT_Amendment__c = true;
							pli.APT_RC_Key__c = pli.APT_Rate_Card_Key__c;
							pli.APT_Rate_Card_Key__c = null;
							pli.APT_Is_Band_Changed__c = false;
							if(!setLineItemId.contains(pli.Id) ) {
								setLineItemId.add(pli.Id);
								pliListTobeUpdated.add(pli);
							}
							
						}
						//1084- DoV
						
						//renew
						if(String.isNotBlank(actionType) && actionType.equalsIgnoreCase(APT_Constants.ACTION_NAME_RENEW)) {
							pli.APT_New__c = true;
							pli.APT_New_Renew__c = false;
							pli.APT_RC_Key__c = pli.APT_Rate_Card_Key__c;
							pli.APT_Rate_Card_Key__c = null;
							pli.APT_Is_Band_Changed__c = false;
							/**
							 //International CO
							if(String.isNotBlank(pli.Apttus_Config2__AdjustmentType__c) && pli.Apttus_Config2__AdjustmentType__c.equalsIgnoreCase(APT_Constants.OFFER_HIGHER_BAND)) {
								pli.Apttus_Config2__AdjustmentType__c = null;
							}
							//International CO
							**/
							
							if(!setLineItemId.contains(pli.Id) ) {
								setLineItemId.add(pli.Id);
								pliListTobeUpdated.add(pli);
							}
							
						}
						//renew
						
						System.debug('pli.Apttus_Config2__ProductId__r.Non_contracted__c --> ' + pli.Apttus_Config2__ProductId__r.Non_contracted__c);
						if(pli.Apttus_Config2__ProductId__r.Non_contracted__c){
							if(!setLineItemId.contains(pli.Id) ) {
								setLineItemId.add(pli.Id);
								pliListTobeUpdated.add(pli);
							}
							continue;
						}
						
						if((!(String.IsNotBlank(productType)
								&& String.isNotBlank(includedProductLines)
								&& includedProductLines.ToLowercase().contains(productType.toLowerCase())))
							&& (APT_Constants.LINE_TYPE_PRODUCT_SERVICE).equalsIgnoreCase(linetype)){
								pliListTobeDeleted.add(pli);
						} else {
							if(!setLineItemId.contains(pli.Id) ) {
								setLineItemId.add(pli.Id);
								pliListTobeUpdated.add(pli);
							}
						}
						
						System.debug('pliListTobeDeleted --> ' + pliListTobeDeleted);
						System.debug('pliListTobeUpdated --> ' + pliListTobeUpdated);
					}

					// check for decommisioned products based on latest product structure hierarchy and deleted related line items
					if(mapProductOptionLI.size() > 0) {
						List<Apttus_Config2__LineItem__c> liToBeDeleteList = checkProductComponentOptions(mapProductOptionLI, productOptionToFind);
						if(liToBeDeleteList.size() > 0) {
							// iterate over clone version, so original list can be modified during iteration
							for(Apttus_Config2__LineItem__c li: pliListTobeUpdated.clone()){
								// remove to-be-deleted line item from pliListTobeUpdated list
								if(liToBeDeleteList.contains(li)){
									Integer liIndex = pliListTobeUpdated.indexOf(li);
									pliListTobeUpdated.remove(liIndex);
								}
							}
							ApplicationDatabase.getInstance().dmlDelete(liToBeDeleteList);
						}
					}
					
					if(pliListTobeUpdated.size() > 0 ){
						update pliListTobeUpdated;
					}
					
					System.debug('pliListTobeDeleted --> ' + pliListTobeDeleted);
					if(pliListTobeDeleted != null && pliListTobeDeleted.size() > 0){
						//temporary
						deleteMultiBundleAndStandaloneLines(pliListTobeDeleted);
					}
				}
				
				//temporary
				deleteProposalLineItems(newProposalId, includedProductLines);
				
				
				//Start === Apttus Support for case CAS-02201-N2D4P3
				List<Apttus_Config2__AppliedRuleInfo__c> newPropRules= [SELECT id,Apttus_Config2__ConfigurationId__c FROM Apttus_Config2__AppliedRuleInfo__c WHERE Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c  =: newProposalId];
				/*for(Apttus_Config2__AppliedRuleInfo__c newRule: newPropRules){
					newRule.Apttus_Config2__NeedProcessing__c  = true;
				}*/
				
				List<Apttus_Config2__AppliedRuleActionInfo__c > newPropActions = [SELECT id FROM Apttus_Config2__AppliedRuleActionInfo__c WHERE  Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c  =: newProposalId];
				/*for(Apttus_Config2__AppliedRuleActionInfo__c newAction:newPropActions  ){
					newAction.Apttus_Config2__Pending__c = true;
				}*/
				//delete newPropActions;
				//delete newPropRules;
				
				
				//End === Apttus Support for case CAS-02201-N2D4P3
				
				
				
				// Updating OPC's Classifiaction based on action Type.JIRA: APOST-735
				String opcRecordTypeId = Schema.SObjectType.APT_Opportunity_Product_Line_Item__c.getRecordTypeInfosByName().get(APT_Constants.OPC_Existing_RecordType).getRecordTypeId();  
				
				List<APT_Opportunity_Product_Line_Item__c> lstOpcUpdate =new List<APT_Opportunity_Product_Line_Item__c>();  
				for(APT_Opportunity_Product_Line_Item__c opc : [select id,APT_Classification__c,APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__r.type from APT_Opportunity_Product_Line_Item__c where APT_Quote_Proposal__c=:newProposalId]) {
					opc.RecordTypeID = opcRecordTypeId;
					if(!String.isEmpty(actionType) && actionType.equalsIgnoreCase(APT_Constants.ACTION_NAME_RENEW) && !String.isEmpty(opc.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__r.type) && !String.isEmpty(APT_Constants.OPPORTUNITY_TYPE_EXISTING_CUSTOMER) && opc.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__r.type.equalsIgnoreCase(APT_Constants.OPPORTUNITY_TYPE_EXISTING_CUSTOMER)) {
							// 09/24/2019 - JPalmero: Comment out existing default classifications to make way for OPC Automation
						// opc.APT_Classification__c= APT_Constants.CLASSIFICATION_RENEWAL;
					} else if(!String.isEmpty(actionType) && actionType.equalsIgnoreCase(APT_Constants.ACTION_NAME_AMEND)  && !String.isEmpty(opc.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__r.type) && !String.isEmpty(APT_Constants.OPPORTUNITY_TYPE_EXISTING_CUSTOMER) && opc.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__r.type.equalsIgnoreCase(APT_Constants.OPPORTUNITY_TYPE_EXISTING_CUSTOMER)) {
							// 09/24/2019 - JPalmero: Comment out existing default classifications to make way for OPC Automation
						// opc.APT_Classification__c = APT_Constants.CLASSIFICATION_GROWTH;
					} else {}
					if(!String.isEmpty(actionType) && !actionType.equalsIgnoreCase(APT_Constants.ACTION_NAME_AMEND)){
						opc.APT_Revenue_End_Date__c = null;
						opc.APT_Revenue_Start_Date__c = null;
					}
					lstOpcUpdate.add(opc);   
				}
				update lstOpcUpdate;
				//Apttus Support - Constraint Rule execution for International Bundle
				if(CartID != ''){
					system.debug('**Inside Cart Validation**');
					Apttus_Config2.ConstraintWebService2.applyConstraintRulesOnAddAll(CartID);
					system.debug('**After Cart Validation**');
				}   
			}
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getLineNumber());
			return null;
		}
		return bResult;
	}  

	/*
		* deletes proposal line items specified
		* */
	private static void deleteProposalLineItems(String newProposalId, String includedProductLines){
			List<Apttus_Proposal__Proposal_Line_Item__c> pliList = [select id, Apttus_Proposal__Product__r.APT_Product_type__c, 
																	Apttus_Proposal__Product__r.Non_contracted__c
																	from Apttus_Proposal__Proposal_Line_Item__c 
																	where Apttus_Proposal__Proposal__c  =: newProposalId ];
																	
			
			List<Apttus_Proposal__Proposal_Line_Item__c> pliListTobeDeleted = new List<Apttus_Proposal__Proposal_Line_Item__c>();
			
			if(pliList.size() > 0) {
				for(Apttus_Proposal__Proposal_Line_Item__c pli :pliList ){
					String productType =  pli.Apttus_Proposal__Product__r.APT_Product_type__c;
					if(pli.Apttus_Proposal__Product__r.Non_contracted__c) {
						continue;
					}
					if(!(String.IsNotBlank(productType) 
							&& includedProductLines.ToLowercase().contains(productType.toLowerCase()))){
						pliListTobeDeleted.add(pli);
					}   
			
					}
					
					System.debug('pliListTobeDeleted --> ' + pliListTobeDeleted);
					if(pliListTobeDeleted != null && pliListTobeDeleted.size() > 0){
					delete pliListTobeDeleted;
					}
			}
		}

	/**
		This method will create new proposal record
		@params -
		recordTypeName - proposal record type name
		opportunityId - opportunity record id
		priceListId - price list record id
		agreement - agreement record which is being renewed
		*/
	public static Apttus_Proposal__Proposal__c newProposal(String recordTypeName, Id opportunityId, Id priceListId, 
															Apttus__APTS_Agreement__c agreement) {
		Apttus_Proposal__Proposal__c proposal = new Apttus_Proposal__Proposal__c();
		try{
			resetOpportunityProposalPrimary(opportunityId);
			String recordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
			proposal.RecordTypeId = recordTypeId;
			proposal.Apttus_Proposal__Proposal_Name__c = APT_Constants.CLASSIFICATION_RENEWAL + APT_Constants.SEPARATOR_COLON + agreement.Name;
			proposal.Apttus_Proposal__Opportunity__c = opportunityId;
			proposal.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_DRAFT;
			proposal.Apttus_Proposal__Proposal_Expiration_Date__c = date.Today().addDays(365);
			system.debug('!!!!!!---'+proposal.Apttus_Proposal__Proposal_Expiration_Date__c);
			//proposal.APT_Contract_Number__c = agreement.APT_Contract_Number__c;
			proposal.Apttus_QPConfig__PriceListId__c = priceListId;
			proposal.Apttus_Proposal__Primary_Contact__c = agreement.Apttus__Primary_Contact__c;
			proposal.Apttus_Proposal__Account__c = agreement.Apttus__Account__c;
			proposal.APT_Contract_Number__c = agreement.Apttus__FF_Agreement_Number__c;
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			return null;
		}
		
		return proposal;
	}

	/**
		This method will renew Agreement.
		@params -
		recordTypeName - proposal record type name
		opportunityId - opportunity record id
		priceListId - price list record id
		agreement - agreement record which is being renewed
		*/
	public static Apttus__APTS_Agreement__c renewAgreement(String recordTypeName, Id opportunityId, Id proposalId, 
														Apttus__APTS_Agreement__c agreement) {
		try {
			Apttus__APTS_Agreement__c renewedAgreement = Apttus.AgreementWebService.renewAgreement(agreement.Id); 
					
			renewedAgreement.APT_Contract_Type__c = recordTypeName;
			
			if(!String.isEmpty(opportunityId)) {
				renewedAgreement.Apttus__Related_Opportunity__c = opportunityId;
			} else {
				renewedAgreement.Apttus__Related_Opportunity__c = agreement.Apttus__Related_Opportunity__c;
			}
			
			if(!String.isEmpty(proposalId)) {
				renewedAgreement.Apttus_QPComply__RelatedProposalId__c = proposalId;
			} else {
				renewedAgreement.Apttus_QPComply__RelatedProposalId__c = agreement.Apttus_QPComply__RelatedProposalId__c;
			}
			
			renewedAgreement.Apttus__Primary_Contact__c = agreement.Apttus__Primary_Contact__c;
			String agreementRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Post Billpay Contract').getRecordTypeId();
			if(agreement.Apttus__Contract_End_Date__c != null) {
	//Defect 1569
				if(agreementRecordTypeId == agreement.recordTypeID)
				{
					renewedAgreement.Apttus__Contract_Start_Date__c = agreement.Apttus__Contract_End_Date__c;
					renewedAgreement.Apttus__Contract_End_Date__c = agreement.Apttus__Contract_End_Date__c.addYears(3)-1;
				}
				else
				{
					renewedAgreement.Apttus__Contract_Start_Date__c = agreement.Apttus__Contract_End_Date__c;
					renewedAgreement.Apttus__Contract_End_Date__c = agreement.Apttus__Contract_End_Date__c.addDays(365);
				}
			} else {
	//Defect 1569
				if(agreementRecordTypeId == agreement.recordTypeID)
				{
					renewedAgreement.Apttus__Contract_Start_Date__c = date.today();
					renewedAgreement.Apttus__Contract_End_Date__c = date.today().addYears(3)-1;
				}
				else
				{
					renewedAgreement.Apttus__Contract_Start_Date__c = date.today();
					renewedAgreement.Apttus__Contract_End_Date__c = date.today().addDays(365);
				}
			} 
			renewedAgreement.SAP_Contract_Number__c = APT_Constants.EMPTY_STRING;
			
		//APOST-1423
			renewedAgreement.APT_Salesforce_Case_Number__c = APT_Constants.EMPTY_STRING;
			renewedAgreement.Billing_Account__c = null;
			//renewedAgreement.Billing_Account_No__c = APT_Constants.EMPTY_STRING;
			renewedAgreement.APT_Contract_On_Hold__c = false;
			renewedAgreement.Apttus__Executed_Copy_Mailed_Out_Date__c = null;
			renewedAgreement.Apttus__Request_Date__c = null;
			renewedAgreement.Apttus__Other_Party_Sent_Date__c = null;
			renewedAgreement.APR_Stopped_in_SAP__c = false;
			renewedAgreement.APT_Provisioned_in_SAP__c = false;
			renewedAgreement.APT_Provisioned_in_SAP_Date__c = null;
			renewedAgreement.APT_Quotation_No__c = APT_Constants.EMPTY_STRING;
			renewedAgreement.Apttus__Activated_Date__c = null;
			renewedAgreement.Apttus__Activated_By__c = null;
			
			renewedAgreement.APT_Generated_Doc_Ids__c = null;
			renewedAgreement.APT_Is_Generate_Doc_Batch_Running__c = false;
			renewedAgreement.APT_Merge_Documents__c = false;
			renewedAgreement.APT_Remove_Standalone_Docs__c = false;
			renewedAgreement.APT_Submitted_Async_Merge_Call_Ids__c = null;
			renewedAgreement.APT_Template_Order_Sequence__c = null;
			renewedAgreement.APT_Ratecards_Created__c = false;
			renewedAgreement.APT_Mark_for_Review__c= false;
			
			//APOST-1423
			
			//APOST-1429
			renewedAgreement.APT_New_Rate_Card_Download__c = false;
			//APOST-1429

			//APOST-1888
			renewedAgreement.APT_Is_Create_Contract_Batch_Job_Running__c = false;
			//APOST-1888
			
			//1084
			renewedAgreement.APT_Mark_All_Agreement_Line_Items_as_Old__c = false;
			//1084

			renewedAgreement.APT_Pricing_Category__c = APT_Constants.PRICING_CATEGORY_STANDARD; //REQ2595048

			return renewedAgreement;
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			return null;
		}
	}

	/**
		This method will build relationship between original and renewed agreement
		@params -
		originalAgreementId - original agreement id
		renewedAgreementId - renewed agreement id
		*/
	public static Boolean afterRenew(Id originalAgreementId, Id renewedAgreementId ,Boolean copyLineItems) {

		Boolean bResult = false;
		try {
			system.debug('-->');
			bResult = Apttus.AgreementWebService.afterRenew(originalAgreementId, renewedAgreementId);
			if(copyLineItems){
				copyAgreementLineItems(originalAgreementId, renewedAgreementId);
			}
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			return null;
		}
		
		return bResult;
	}

	/**
	 * copies agreement line items
	 * */
	public static void copyAgreementLineItems(String originalAgreementId,String newAgreementID){
		
		try {
			List<Apttus__AgreementLineItem__c> agreementLineItemsToBeInserted = new List<Apttus__AgreementLineItem__c>();
			if(String.isNotBlank(originalAgreementId) && String.isNotBlank(newAgreementID)) {
				
				Set<Id> agreementIds = new Set<ID> {originalAgreementId};
				List<Apttus__AgreementLineItem__c> agreementLineItemsList = APT_AgreementTriggerHandler.getAgreementLineItemsCloned(agreementIds);
				
				if(agreementLineItemsList == null || agreementLineItemsList.size() == 0){ return;}
				
				for(Apttus__AgreementLineItem__c ali : agreementLineItemsList){
					
					Apttus__AgreementLineItem__c aliClone = ali.clone(false,true);
					aliClone.Apttus__AgreementId__c = newAgreementID;
					
					agreementLineItemsToBeInserted.add(aliClone);
				}
				
				if(agreementLineItemsToBeInserted.size() > 0 ) {
					
					insert agreementLineItemsToBeInserted;
					
					/*
					List<Apttus_CMConfig__AgreementUsagePriceTier__c> agreementUsagePriceTiers = new List<Apttus_CMConfig__AgreementUsagePriceTier__c>();
					
					for(Apttus__AgreementLineItem__c ali : agreementLineItemsToBeInserted){
						if(ali.Apttus_CMConfig__UsagePriceTiers__r != null && ali.Apttus_CMConfig__UsagePriceTiers__r.size() > 0 ){
							for(Apttus_CMConfig__AgreementUsagePriceTier__c usagePriceTier : ali.Apttus_CMConfig__UsagePriceTiers__r){
						
								Apttus_CMConfig__AgreementUsagePriceTier__c usagePriceTierClone = usagePriceTier.clone();
								usagePriceTierClone.Apttus_CMConfig__LineItemId__c = ali.id;
								
								agreementUsagePriceTiers.add(usagePriceTierClone);
							}
						}
					}
					if(agreementUsagePriceTiers.size() > 0 ){
						insert agreementUsagePriceTiers;
					}*/
				}
				ID jobID = System.enqueueJob(new APT_AgreementLineItemChildQueueable(new Set<ID> {newAgreementID}));
			}
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			
		} 
	}

	/**
		This method will create agreement line item, configuration and cart line items.
		*/
	public static String createAgreementChildRecords(Id configurationId, Id  agreementIdParam) {
		try {
			if(String.IsBlank(configurationId)) {
				return APT_Constants.ERROR_MISSING_CONFIGURATION;
			} else {
				APT_AgreementLineItemQueueable aliQueueable = new APT_AgreementLineItemQueueable(configurationId, agreementIdParam);
				ID jobID = System.enqueueJob(aliQueueable);
				
			}
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			return null;
			
		} 
		return APT_Constants.SUCCESS_LABEL;
	}

	/**
	 * creates usage price tiers 
	 */
		/*
	@future
	public static void createusagePriceTiers(Set<ID> agreementLineItemsIdSet){
		try {
			if(agreementLineItemsIdSet != null && agreementLineItemsIdSet.size() > 0 ){
				map<Id, Id> mapAgreementLineItemMap = new map<Id, Id>();
				set<Id> setLineItemId = new set<Id>();
				for(Apttus__AgreementLineItem__c ali : [select id,Apttus_CMConfig__DerivedFromId__c from Apttus__AgreementLineItem__c where id in: agreementLineItemsIdSet]) {
					mapAgreementLineItemMap.put(ali.Apttus_CMConfig__DerivedFromId__c, ali.Id);
					setLineItemId.add(ali.Apttus_CMConfig__DerivedFromId__c);
				}
				
				list<Apttus_Config2__UsagePriceTier__c> listUsagePriceTier = database.query(APT_Constants.SOQL_SELECT + getAllAgrFields(APT_Constants.USAGE_PRICETEIR_OBJECT) + APT_Constants.STRING_USAGEPRICE_TEIR);
				list<Apttus_CMConfig__AgreementUsagePriceTier__c> listClonedAgreementUsagePriceTier = new list<Apttus_CMConfig__AgreementUsagePriceTier__c>();
				Set<String> sourceFieldNames = new Set<String>(getFieldNames(Apttus_CMConfig__AgreementUsagePriceTier__c.getSObjectType()));
				if(listUsagePriceTier != null && listUsagePriceTier.size() > 0) {
					Apttus_CMConfig__AgreementUsagePriceTier__c clonedAgreementUsagePriceTier = new Apttus_CMConfig__AgreementUsagePriceTier__c();
					for(Apttus_Config2__UsagePriceTier__c upt : listUsagePriceTier) {
						clonedAgreementUsagePriceTier = new Apttus_CMConfig__AgreementUsagePriceTier__c();
						
						for (String fieldName : getFieldNames(Apttus_Config2__UsagePriceTier__c.getSObjectType())) {
							Object value = upt.get(fieldName);
							if(value != null) {
								// get the target field name
								String tgFieldName =  (fieldName.startsWith(APT_Constants.NAMESPACE_APTTUS_ONLY) ? toNoNamespaceName(fieldName) : fieldName);
								if(sourceFieldNames.contains(APT_Constants.NAMESPACE_APTTUS_CMCONFIG + tgFieldName) == true) {
									clonedAgreementUsagePriceTier.put(APT_Constants.NAMESPACE_APTTUS_CMCONFIG + tgFieldName, value);
								} else if(sourceFieldNames.contains(tgFieldName) == true) {
									clonedAgreementUsagePriceTier.put(tgFieldName, value);
								} else {}
							}
						}
						
						clonedAgreementUsagePriceTier.Apttus_CMConfig__LineItemId__c = mapAgreementLineItemMap.get(upt.Apttus_Config2__LineItemId__c);
						listClonedAgreementUsagePriceTier.add(clonedAgreementUsagePriceTier);
					}
				}
				
				if(listClonedAgreementUsagePriceTier.size() > 0) {
					insert listClonedAgreementUsagePriceTier;
				}
			}
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
		}
	}
	*/

	/**
	* function to get list of field names
	* */
	public static List<String> getFieldNames(Schema.SObjectType sobjectType) {
		// get custom field names from the object
		List<String> fieldNames = new List<String>();
		
		try {
			// get the field metadata
			Schema.DescribesObjectResult metadata = sobjectType.getDescribe();
			Schema.DescribeFieldResult fldMetadata;
			for (Schema.SObjectField field : metadata.fields.getMap().values()) {
				// use the fully qualified field name as the key
				fldMetadata = field.getDescribe();
	system.debug('checkpoint'+fldMetadata.isUpdateable());
				if (fldMetadata!= null && fldMetadata.isUpdateable()) {
					fieldNames.add(fldMetadata.getName());
				}

			}
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			return null;
		}
		return fieldNames;
	}

	/**
		This method will retrun all fields of provided object.
		@params -
		objectName - object api name
		*/
	public static String getAllAgrFields(String objectName){

		String query;
		try {
			Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
			Map<String, Schema.SObjectField> fieldMap = schemaMap.get(objectName).getDescribe().fields.getMap();
			String commaSepratedFields = APT_Constants.EMPTY_STRING;

			for(String fieldName : fieldMap.keyset()){
				if(String.isBlank(commaSepratedFields)){
					commaSepratedFields = fieldName;
				}else{
					commaSepratedFields = commaSepratedFields + APT_Constants.SEPERATOR_COMMA_SPACE + fieldName;
				}
			}
			query = commaSepratedFields;
			//query = 'select ' + commaSepratedFields + ' from ';
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			query = APT_Constants.EMPTY_STRING;
		}

		return query;
	} 
	/**
		Method for retrieve all fields API Name
	**/
	public static Set<String> getAllFieldsAPIName(String objectName){
		// get custom field names from the object
		Set<String> fieldNames = new Set<String>();
		try { 
			Schema.DescribeFieldResult fldMetadata;
			Schema.DescribesObjectResult metadata = Schema.getGlobalDescribe().get(objectName).getDescribe();
			for (Schema.SObjectField field : metadata.fields.getMap().values()) {
				// use the fully qualified field name as the key
					fldMetadata = field.getDescribe();
					if(fldMetadata != null) {
						fieldNames.add(fldMetadata.getName());
					}
			}
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			return null;
		}
		return fieldNames;
	}

	/**
	 * Strips the namespace from the name string.
	 * @param nameStr the name string to strip the namespace from
	 * @return the name string without the namespace prefix
	 */
	public static String toNoNamespaceName(String nameStr) {
		try {
			//String regex = '__(.)+[__cC]$';

			// get the namespace prefix
			String[] strs = nameStr.split(APT_Constants.SEPARATOR_DOUBLEUNDERSCORE);
			String nsPrefix = (strs.size() > 1 && !String.isEmpty(strs[1]) && !String.isEmpty(APT_Constants.END_CHARACTER_C) &&  !strs[1].equalsIgnoreCase(APT_Constants.END_CHARACTER_C) ? strs[0] : null);

			// remove package namespace
			return (!String.isEmpty(nsPrefix)
					? nameStr.replace(nsPrefix + APT_Constants.SEPARATOR_DOUBLEUNDERSCORE, APT_Constants.EMPTY_STRING)
					: nameStr);
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			return APT_Constants.EMPTY_STRING ;
		}
	}

	/**
		This method will amend Agreement.
		@params -
		recordTypeName - proposal record type name
		agreement - agreement record which is being amended
		*/
	public static Apttus__APTS_Agreement__c amendAgreement(String recordTypeName, Id opportunityId, Id proposalId, 
															Apttus__APTS_Agreement__c agreement, String actionName) {
		try{
			Apttus__APTS_Agreement__c amendedAgreement = Apttus.AgreementWebService.amendAgreement(agreement.Id);
			
			amendedAgreement.APT_Contract_Type__c = recordTypeName; 
			
			if(!String.isEmpty(opportunityId)) {
				amendedAgreement.Apttus__Related_Opportunity__c = opportunityId;
			} else {
				amendedAgreement.Apttus__Related_Opportunity__c = agreement.Apttus__Related_Opportunity__c;
			}   
			
			if(!String.isEmpty(proposalId)) {
				amendedAgreement.Apttus_QPComply__RelatedProposalId__c = proposalId;
			}  else {
				amendedAgreement.Apttus_QPComply__RelatedProposalId__c = agreement.Apttus_QPComply__RelatedProposalId__c;
			}   
			
			
			amendedAgreement.Apttus__Primary_Contact__c = agreement.Apttus__Primary_Contact__c;
			if(amendedAgreement.Apttus__Contract_End_Date__c != null) {
				//amendedAgreement.Apttus__Contract_Start_Date__c = agreement.Apttus__Contract_End_Date__c;
				//amendedAgreement.Apttus__Contract_End_Date__c = agreement.Apttus__Contract_End_Date__c.addDays(365);
				
				//APOST-1199
				amendedAgreement.Apttus__Contract_Start_Date__c = agreement.Apttus__Contract_Start_Date__c;
				amendedAgreement.Apttus__Contract_End_Date__c = agreement.Apttus__Contract_End_Date__c;
				//APOST-1199
			} else {
				amendedAgreement.Apttus__Contract_Start_Date__c = date.today();
				amendedAgreement.Apttus__Contract_End_Date__c = date.today().addDays(365);
			}
			amendedAgreement.SAP_Contract_Number__c = APT_Constants.EMPTY_STRING; 
			//APOST-1423
			amendedAgreement.APT_Salesforce_Case_Number__c = APT_Constants.EMPTY_STRING;
			amendedAgreement.Billing_Account__c = null;
			//amendedAgreement.Billing_Account_No__c = APT_Constants.EMPTY_STRING;
			amendedAgreement.APT_Contract_On_Hold__c = false;
			amendedAgreement.Apttus__Executed_Copy_Mailed_Out_Date__c = null;
			amendedAgreement.Apttus__Request_Date__c = null;
			amendedAgreement.Apttus__Other_Party_Sent_Date__c = null;
			amendedAgreement.APR_Stopped_in_SAP__c = false;
			amendedAgreement.APT_Provisioned_in_SAP__c = false;
			amendedAgreement.APT_Provisioned_in_SAP_Date__c = null;
			amendedAgreement.APT_Quotation_No__c = APT_Constants.EMPTY_STRING;
			amendedAgreement.Apttus__Activated_Date__c = null;
			amendedAgreement.Apttus__Activated_By__c = null;
			//APOST-1423
			amendedAgreement.APT_Generated_Doc_Ids__c = null;
			amendedAgreement.APT_Is_Generate_Doc_Batch_Running__c = false;
			amendedAgreement.APT_Merge_Documents__c = false;
			amendedAgreement.APT_Remove_Standalone_Docs__c = false;
			amendedAgreement.APT_Submitted_Async_Merge_Call_Ids__c = null;
			amendedAgreement.APT_Template_Order_Sequence__c = null;
			//APOST-1429
			amendedAgreement.APT_New_Rate_Card_Download__c = false;
			amendedAgreement.APT_Mark_for_Review__c= false;

			//APOST-1429
			
			//APOST-1888
			amendedAgreement.APT_Is_Create_Contract_Batch_Job_Running__c = false;
			//APOST-1888
			
			//1084
			amendedAgreement.APT_Mark_All_Agreement_Line_Items_as_Old__c = false;
			//1084
			
			//DoV
			amendedAgreement.APT_New_Pricing__c = false;
			//DoV
			if(amendedAgreement.Apttus__Amendment_Effective_Date__c == null || amendedAgreement.Apttus__Amendment_Effective_Date__c < system.today()){
				amendedAgreement.Apttus__Amendment_Effective_Date__c = system.today();
			}
			
			if(String.isNotBlank(actionName)) {
				if(actionName.equalsIgnoreCase(APT_Constants.CREATE_AMENDMENT_CONTRACT)){
					amendedAgreement.APT_Ratecards_Created__c = false;
				} else if(actionName.equalsIgnoreCase(APT_Constants.ACTION_NAME_AMEND)) {
					amendedAgreement.APT_Ratecards_Created__c = true;
				} else  {}
			}
			
			amendedAgreement.APT_Pricing_Category__c = APT_Constants.PRICING_CATEGORY_STANDARD; //REQ2595048

			return amendedAgreement;
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			return null;
		}
	}

	/**
		This method will build relationship between original and amended agreement
		@params -
		originalAgreementId - original agreement id
		renewedAgreementId - amended agreement id
		*/
	public static Boolean afterAmend(Id originalAgreementId, Id amendedAgreementId, Boolean copyLineItems) {
		Boolean bResult = false;
		try {
			bResult = Apttus.AgreementWebService.afterAmend(originalAgreementId, amendedAgreementId);
			if(copyLineItems){
				copyAgreementLineItems(originalAgreementId, amendedAgreementId);
			}
			
		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			return null;
		}
		
		return bResult;
	}  

	/*
		This method will clone attachment from original agreement to amended agreement for DoV
	*/
	public static void copyAttachments(Id originalAgreementId, Id amendedAgreementId) {
		//attachment
		list<Attachment> listAttachment = [SELECT Id, ParentId, Body, ContentType, Description, 
											IsPrivate, Name
											FROM Attachment
											WHERE ParentId = :originalAgreementId];
											
		if(listAttachment != null && listAttachment.size() > 0) {
			list<Attachment> listNewAttachment = new list<Attachment>();
			for(Attachment originalAttachment : listAttachment) {
				Attachment newAttachment = originalAttachment.clone(false);
				newAttachment.ParentId = amendedAgreementId;
				
				listNewAttachment.add(newAttachment);
			}
			
			if(listNewAttachment.size() > 0) {
				insert listNewAttachment;
			}
		}
		
		//1310
		APT_FeedItemUtility.copyFeedItems(originalAgreementId, amendedAgreementId);
		//1310
		
		/**
		//contentversion
		String contentVersionQuery = 'SELECT ' 
								+ APT_AmendRenewUtility.getAllAgrFields('ContentVersion') 
								+ ' FROM ContentVersion WHERE ParentId = :originalAgreementId';
		list<ContentVersion> listContentVersion = database.query(contentVersionQuery);
		if(listContentVersion != null && listContentVersion.size() > 0) {
			list<ContentVersion> listNewContentVersion = new list<ContentVersion>();
			ContentVersion newContentVersion;
			
			for(ContentVersion cv : listContentVersion) {
				newContentVersion = new ContentVersion();
				newContentVersion = cv.clone();
				
				listNewContentVersion.add(newContentVersion);
			}
			
			if(listNewContentVersion != null && listNewContentVersion.size() > 0) {
				insert listNewContentVersion;
			}
		} 
		**/ 
	}

	/*
		This method will clone SAP Contracts from original agreement to renewed agreement for renewal
	*/
	public static void copySAPContratcs(Id originalAgreementId, Id renewedAgreementId, decimal versionNumber) {
		
		system.debug('*** originalAgreementId ***'+originalAgreementId);
		system.debug('*** renewedAgreementId ***'+renewedAgreementId);
		system.debug('*** versionNumber ***'+versionNumber);
		
		String sapContractQuery = APT_Constants.SOQL_SELECT 
								+ APT_AmendRenewUtility.getAllAgrFields(APT_Constants.SAP_CONTRACT_OBJECT) 
								+ APT_Constants.FROM_WHERE_SAP_CONTRACT_STATUS;
		
		system.debug('*** sapContractQuery ***'+sapContractQuery);
		
		list<APT_SAP_Contracts__c> listSAPContracts = database.query(sapContractQuery);
		system.debug('*** listSAPContracts ***'+listSAPContracts);
		list<APT_SAP_Contracts__c> listClonedSAPContracts = new list<APT_SAP_Contracts__c>();
		list<APT_SAP_Contracts__c> listUpdateSAPContracts = new list<APT_SAP_Contracts__c>();
		APT_SAP_Contracts__c clonedSAPContract;
		Integer iIndex;
		if(listSAPContracts != null && listSAPContracts.size() > 0) {
			for(APT_SAP_Contracts__c sapContract : listSAPContracts){
				
				// Updated by Adrian Recio
				// Cloning adjusted to optimize assignment and make sure sap contract versioning works for temp field 
				// 2/8/2017
				
				//clone SAP Contract
				clonedSAPContract = new APT_SAP_Contracts__c();
				clonedSAPContract = sapContract.clone();
				clonedSAPContract.APT_Apttus_Contract__c = renewedAgreementId;
				clonedSAPContract.SAP_Contract_Status__c = APT_Constants.ACTIVE;
				
				if(String.isNotBlank(clonedSAPContract.APT_SAP_Contract_Number__c) ){
					// Flush versioned sap contract in the cloned sap contract
					if(clonedSAPContract.APT_SAP_Contract_Number__c.contains(APT_Constants.SEPERATOR_DOT)) {
						iIndex = clonedSAPContract.APT_SAP_Contract_Number__c.indexOf(APT_Constants.SEPERATOR_DOT);
						clonedSAPContract.APT_SAP_Contract_Number__c = clonedSAPContract.APT_SAP_Contract_Number__c.subString(0, iIndex);
						// Then version old sap contract if not
					}else{
						sapContract.APT_SAP_Contract_Number__c += APT_Constants.SEPERATOR_DOT + versionNumber;
						//Adding the status to Inactive
						sapContract.SAP_Contract_Status__c = 'Inactive'; 
					}
				}
				
				if(String.isNotBlank(clonedSAPContract.APT_SAP_Contract_Number_temp__c) ){
					// Flush versioned sap contract in the cloned sap contract
					if(clonedSAPContract.APT_SAP_Contract_Number_temp__c.contains(APT_Constants.SEPERATOR_DOT)) {
						iIndex = clonedSAPContract.APT_SAP_Contract_Number_temp__c.indexOf(APT_Constants.SEPERATOR_DOT);
						clonedSAPContract.APT_SAP_Contract_Number_temp__c = clonedSAPContract.APT_SAP_Contract_Number_temp__c.subString(0, iIndex);
						// Then version old sap contract if not
					}else{
					sapContract.APT_SAP_Contract_Number_temp__c += APT_Constants.SEPERATOR_DOT + versionNumber;
					}
				} 
				
				// Removed by Adrian Recio
				// SAP Contracts will not be deactivate until the renewal contract becomes In Effect
				// Inactivation moved to Apttus Contract trigger
				// 10/8/2017
				//sapContract.SAP_Contract_Status__c = APT_Constants.INACTIVE;
				
				listClonedSAPContracts.add(clonedSAPContract); // Add clone for insert
				listUpdateSAPContracts.add(sapContract); // Add clone for update
			}
			
			system.debug('*** listClonedSAPContracts ***'+listClonedSAPContracts.size());
			if(listClonedSAPContracts.size() > 0) {
				insert listClonedSAPContracts;
			}
			
			if(listUpdateSAPContracts.size() > 0) {
				update listUpdateSAPContracts;
			}
		}
	}

	/**
	 * @description	Validate the line item structure against the product option component which is the latest product schema configuration in Apttus
	 * @param Map<Id, Apttus_Config2__LineItem__c>
	 * @param Set<Id> productOptionToFind
	 * @return List<Apttus_Config2__LineItem__c>
	 */
	public static List<Apttus_Config2__LineItem__c> checkProductComponentOptions(Map<Id, Apttus_Config2__LineItem__c> mapProductOptionLI, Set<Id> productOptionToFind) {
		
		List<Apttus_Config2__LineItem__c> liToBeDeleteList = new List<Apttus_Config2__LineItem__c>();
		List<Apttus_Config2__ProductOptionComponent__c> productOptionComponentsList = APT_ProductOptionCompsSelector.newInstance().selectByParentProductId(
			productOptionToFind, 
			new Set<Object>{
				APT_ProductOptionCompsSelector.Options.WITH_COMPONENT_PRODUCT
			});
		if(productOptionComponentsList.size() > 0 ) {
			Set<string> productOptionComponentKeyMap = new Set<string>();
			//create a string using parent product id and Component Product Id, to filter on LI
			for(Apttus_Config2__ProductOptionComponent__c productOptionComponent :productOptionComponentsList){
				productOptionComponentKeyMap.add(productOptionComponent.Apttus_Config2__ParentProductId__c + '_' +productOptionComponent.Apttus_Config2__ComponentProductId__r.Name);
			}
			// set to store the product name for deletion
			Set<String> productNameForDeletionSet = new Set<String>();
			//check the List of LI of Option products 's key (generated) against product option component key map
			for(Apttus_Config2__LineItem__c li :mapProductOptionLI.values()){
				// Build a key string to match the above string for comparison
				string keyToCheck;
				if(li.Apttus_Config2__OptionId__c != null){
					keyToCheck = li.Apttus_Config2__ProductId__c + '_' + li.Apttus_Config2__OptionId__r.Name; 
				}
				// capture line item with Option products that matches the key's string
				if(!productOptionComponentKeyMap.contains(keyToCheck) && keyToCheck != null) {
					productNameForDeletionSet.add(li.Apttus_Config2__OptionId__r.Name);
				}
			}
			// capture all line items including 'Product/Service' and 'Options' types with same name
			for(Apttus_Config2__LineItem__c li :mapProductOptionLI.values()){
				if(productNameForDeletionSet.contains(li.Apttus_Config2__ChargeType__c)){
					liToBeDeleteList.add(li);
				}
			}
		}
		return liToBeDeleteList;
	}

	/**
	 * @description function to remove the DoV: and Renewal: strings from the opportunity name
	 * @param  oppName opportunity name
	 * @return String returns the string by removing DoV: and Renewal: strings from opportunity name
	 * Dov: Renewal: Dov: Test opportunity => Test opportunity
	 */
	@TestVisible
	private static String removeDovRenewalPartsFromOppName(String oppName) {
		if (String.isNotBlank(oppName)) {
			return oppname.replaceAll('(?i)(renewal: |dov: )', '');
		}
		return oppName;
	}

	/**
	 *This method will reset opportunity proposals Primary value
	 *@param Id opportunityId
	 */
    private static void resetOpportunityProposalPrimary(Id opportunityId) {
        //Querying the proposal record by using the opportunity id passed to the method newProposal() to check if there existing any proposal on the opportunity.
		List<Apttus_Proposal__Proposal__c> existingProposalList = APT_ProposalObjectsSelector.newInstance().selectByOpportunityId(new Set<Id>{opportunityId});
        List<Apttus_Proposal__Proposal__c> opportunityProposalsToUpdate = new List<Apttus_Proposal__Proposal__c>();
        if(!existingProposalList.isEmpty()){
            for(Apttus_Proposal__Proposal__c proposal : existingProposalList){
                if(proposal.Apttus_Proposal__Primary__c) {
                    proposal.Apttus_Proposal__Primary__c = APT_Constants.BOOL_FALSE;
                    opportunityProposalsToUpdate.add(proposal);
                }
            }
        }
        if(!opportunityProposalsToUpdate.isEmpty()) {
            ApplicationDatabase.getInstance().dmlupdate(opportunityProposalsToUpdate);
        }
	}
}