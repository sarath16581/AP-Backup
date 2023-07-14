/**
Description: This apex class if handler class for apex trigger - APT_ProposalTrigger.
Created By: Himanshu Jain
Created Date: 07th Jan, 2016

Last Modified By: Mausam  Padhiyar
Last Modified Date: 3rd Nov, 2016 | Validate Approvals

Last Modified By: Mausam  Padhiyar
Last Modified Date: 17th Jan, 2017 | 1825

Last Modified By: Lyndon Lavapie
Last Modified Date: 30th July, 2018 | Added changes for CR 146/13

Last Modified By: Ranjeewa Silva
Last Modified Date: 24th Aug, 2020 | Optimised syncWithOpportunity method to attempt the SOQL query only if there are Apttus product configurations matching the criteria.
Last Modified By : Mansi Shah
Last Modified Date : 15th June, 2021 | added a method onAfterUpdate for ST Pricing delegation Approvals
Ken McGuire 2023.04.19 Proposal field migration to opportunity
*/
public without sharing class APT_ConfigurationTriggerHandler {

	/**
	 * before update trigger event
	 */
	public static String beforeUpdateEvent(list<Apttus_Config2__ProductConfiguration__c> listConfiguration) {
		try {
			//validate approvals
			for(Apttus_Config2__ProductConfiguration__c config : listConfiguration) {
				if(config.APT_Config_Change__c && config.APT_Validate_Approvals__c) {
					config.APT_Config_Change__c = false;
				} else if((!config.APT_Config_Change__c && !config.APT_Validate_Approvals__c) || (!config.APT_Config_Change__c && config.APT_Validate_Approvals__c)) {
					config.APT_Config_Change__c = true;
					config.APT_Validate_Approvals__c = false;
				}
			}
			//validate approvals

			return APT_Constants.SUCCESS_LABEL;
		} catch(system.exception ex) {
			return ex.getMessage();
		}
	}

	/**
		   This method will set field on agreement based on custom pricing
		   @param
		   listConfiguration - List of Product configuration
	*/
	public static String afterInsertEvent(list<Apttus_Config2__ProductConfiguration__c> listConfiguration) {
		//APOST-1347
		try {
			set<Id> setAgreementId = new set<Id>();
			set<Id> setProposalId = new set<Id>();  //1825
			for(Apttus_Config2__ProductConfiguration__c configuration : listConfiguration) {
				if(String.isNotBlank(configuration.Apttus_CMConfig__AgreementId__c) && configuration.APT_Customised_Pricing__c) {
					setAgreementId.add(configuration.Apttus_CMConfig__AgreementId__c);
				}

				setProposalId.add(configuration.Apttus_QPConfig__Proposald__c); //1825
			}

			list<Apttus__APTS_Agreement__c> listAgreement = new list<Apttus__APTS_Agreement__c>();
			for(Apttus__APTS_Agreement__c agreement : [SELECT Id, Name, APT_Pricing_Category__c
			FROM Apttus__APTS_Agreement__c
			WHERE Id IN :setAgreementId]) {
				agreement.APT_Pricing_Category__c = APT_Constants.AGREEMENT_CATEGORY_CUSTOMISED;
				listAgreement.add(agreement);
			}

			update listAgreement;

			//1825
			if(setProposalId.size() > 0) {
				list<Apttus_Proposal__Proposal__c> listProposal = new list<Apttus_Proposal__Proposal__c>();
				for(Apttus_Proposal__Proposal__c proposal : [SELECT Id, APT_Use_Offline_Rates__c
				FROM Apttus_Proposal__Proposal__c
				WHERE Id IN :setProposalId]) {
					if(proposal.APT_Use_Offline_Rates__c) {
						proposal.APT_Use_Offline_Rates__c = false;
						listProposal.add(proposal);
					}
				}

				if(listProposal.size() > 0) {
					update listProposal;
				}
			}
			//1825

			return APT_Constants.SUCCESS_LABEL;
		} catch(system.exception ex) {
			return ex.getMessage();
		}
	}

	/**
	* @description : This method will be called from APT_ConfigurationTrigger. It will identify the approved Configuration and will enque job for furhter processing.
	* @author Mansi Shah | 06-09-2021
	* @param configList
	* @param oldConfigMap
	**/
	public static void onAfterUpdate(List<Apttus_Config2__ProductConfiguration__c> configList, Map<ID, Apttus_Config2__ProductConfiguration__c> oldConfigMap){
		Set<Id> setOfApprovedConfigurationIds = new Set<Id>();
		for(Apttus_Config2__ProductConfiguration__c oProductConfig : configList)
		{
			if(oProductConfig.Apttus_CQApprov__Approval_Status__c != null &&
					oProductConfig.Apttus_CQApprov__Approval_Status__c.equalsIgnoreCase(APT_Constants.APPROVAL_STATUS_PROCESSING_APPROVAL) &&
					oldConfigMap.containsKey(oProductConfig.Id) &&
					oProductConfig.Apttus_CQApprov__Approval_Status__c != oldConfigMap.get(oProductConfig.Id).Apttus_CQApprov__Approval_Status__c &&
					oldConfigMap.get(oProductConfig.Id).Apttus_CQApprov__Approval_Status__c != null &&
					oldConfigMap.get(oProductConfig.Id).Apttus_CQApprov__Approval_Status__c.equalsIgnoreCase(APT_Constants.PROPOSAL_APPROVAL_STATUS_PENDING_APPROVAL))
			{
				setOfApprovedConfigurationIds.add(oProductConfig.Id);
			}
		}

		if(setOfApprovedConfigurationIds != null && setOfApprovedConfigurationIds.size() > 0){
			ID jobID = System.enqueueJob(new APT_ProcessApprovedConfigurationBatch(setOfApprovedConfigurationIds));
		}
	}

	/**
		This method will manage price book entry records for products. If price book entry does not exist then will be created.
		@params -
		setProductId - set of product ids
	 */
	public static map<Id, PriceBookEntry> managePriceBookEntry(set<Id> setProductId) {
		map<Id, PriceBookEntry> mapPriceBookEntry = new map<Id, PriceBookEntry>();
		try {
			PriceBook2 standardPriceBook;
			If(!Test.isRunningTest()){
				standardPriceBook = [SELECT Id, Name, IsActive, IsStandard FROM PriceBook2 WHERE IsStandard = true AND isActive = true limit 1];
			}else{
				standardPriceBook= new PriceBook2(ID=Test.getStandardPricebookId());
			}

			for(PriceBookEntry pbe : [SELECT Id, Product2Id FROM PriceBookEntry WHERE Product2Id IN :setProductId]){
				mapPriceBookEntry.put(pbe.Product2Id, pbe);
			}

			list<PriceBookEntry> listPriceBookEntry = new list<PriceBookEntry>();
			PriceBookEntry pbe;
			for(Id productId : setProductId) {
				if((mapPriceBookEntry.get(productId) != null) == false) {
					pbe = new PriceBookEntry();
					pbe.Pricebook2Id = standardPriceBook.Id;
					pbe.Product2Id = productId;
					pbe.UnitPrice = 1000;
					pbe.IsActive = true;

					listPriceBookEntry.add(pbe);
				}
			}

			insert listPriceBookEntry;

			mapPriceBookEntry.clear();
			for(PriceBookEntry pbet : [SELECT Id, Product2Id , UnitPrice FROM PriceBookEntry WHERE Product2Id IN :setProductId]){
				mapPriceBookEntry.put(pbet.Product2Id, pbet);
			}

		}catch(Exception e){
			system.debug('Expception -'+e);
			return null;
		}
		return mapPriceBookEntry;
	}


	public static void onDeleteConfigurationRecord(List<Apttus_Config2__ProductConfiguration__c> configList){
		set<Id> proposalId = new Set<Id>();
		for(Apttus_Config2__ProductConfiguration__c configRec : configList){
			if(String.isNotBlank(configRec.Apttus_QPConfig__Proposald__c)){
				proposalId.add(configRec.Apttus_QPConfig__Proposald__c);
			}
		}
		System.debug('proposalId>>>'+proposalId);
		List<Apttus_Proposal__Proposal__c> proposalList = new List<Apttus_Proposal__Proposal__c>();
		proposalList = [Select Id, Apttus_Proposal__Opportunity__r.IsStartrackProposal__c, APT_Tier_Adjustment_Type__c, APT_Pricing_Request_Type__c,
				APT_Tier_Adjustment_Justification__c, APT_Intermediary__c, APT_Customer_Background__c, APT_Conversation__c,
				APT_Name_of_Intermediary_s_Client__c from Apttus_Proposal__Proposal__c where Id IN: proposalId];
		System.debug('proposalList>>>'+proposalList);
		if(!proposalList.isEmpty()){
			for( Apttus_Proposal__Proposal__c proposalObj : proposalList){
				if(proposalObj.Apttus_Proposal__Opportunity__r.IsStartrackProposal__c.equalsIgnoreCase('Yes')){
					proposalObj.APT_Tier_Adjustment_Type__c = '';
					proposalObj.APT_Pricing_Request_Type__c = '';
					proposalObj.APT_Tier_Adjustment_Justification__c = '';
					proposalObj.APT_Intermediary__c = '';
					proposalObj.APT_Customer_Background__c = '';
					proposalObj.APT_Conversation__c = '';
					proposalObj.APT_Name_of_Intermediary_s_Client__c = null;
					proposalObj.APT_competitor__c = '';
					// update proposalObj;
				}
			}
			update proposalList;
		}
	}
}