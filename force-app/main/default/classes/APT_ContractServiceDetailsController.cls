/**
 * @description: A class which handles Contract creation and Service Details modification
 *						when Create Contract button is clicked on Proposal
 * @author: Yatika Bansal
**/
public without sharing class APT_ContractServiceDetailsController {

	/**
	* @description: This method creates a Agreement/Contract record from respected Proposal
	* @author Bharat Patel
	* @param Apttus_Proposal__Proposal__c proposal
	* @return Agreement/Contract Id
	**/
	public static string createContract(Apttus_Proposal__Proposal__c proposal){
		Apttus__APTS_Agreement__c aggreement = new Apttus__APTS_Agreement__c();
		aggreement.Apttus_QPComply__RelatedProposalId__c = proposal.Id;
		aggreement.Apttus__Related_Opportunity__c = proposal.Apttus_Proposal__Opportunity__c;
		aggreement.Apttus__Account__c = proposal.Apttus_Proposal__Account__c ;
		aggreement.APT_Date_of_Generation_Rate_Card__c = proposal.APT_Date_of_Generation_Rate_Card__c;
		aggreement.Apttus_CMConfig__ConfigurationFinalizedDate__c = proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c;
		aggreement.Apttus_CMConfig__PriceListId__c = proposal.Apttus_QPConfig__PriceListId__c;
		aggreement.Apttus__Status__c = APT_Constants.AGREEMENT_STATUS_REQUEST ;
		aggreement.APT_Sales_Team__c = proposal.Apttus_Proposal__Account__r.Sales_Segment__c ;
		aggreement.OwnerId = proposal.OwnerId;
		aggreement.Apttus__Primary_Contact__c = proposal.APT_Opportunity_Key_contact__c;
		aggreement.recordTypeId = System.Label.APT_MSARecordTypeID;

		ApplicationDatabase.getInstance().dmlInsert(new List<Apttus__APTS_Agreement__c>{aggreement});
		return aggreement.Id;
	}

	/**
	* @description: This method creates a contract record
	* @author Yatika Bansal
	* @param String proposalId
	* @return Contract Id
	**/
	@AuraEnabled
	public static String createContractRecord(String proposalId){
		try{
			Map<Id, Apttus_Proposal__Proposal__c> proposalById = APT_ProposalObjectsSelector.newInstance(1)
				.selectByConfigId(new Set<Id>{proposalId},
								  new Set<Object> {APT_ProposalObjectsSelector.Options.WITH_ACCOUNT});
			Apttus_Proposal__Proposal__c proposal = proposalById.values()[0];

			//Checking if credit assessment is required or not
			if(proposal.Apttus_Proposal__Account__r.Role_Type_Roll_Up__c == 'Prospect') {
				List<APT_Credit_Assessment__c> creditAssess = APT_CreditAssessmentSelector.newInstance(1)
					.selectByProposalAndAssessStatus(new Set<Id>{proposalId},
														 new Set<String> {APT_Constants.CREDIT_ASSESSMENT_STATUS_APPROVED, APT_Constants.CREDIT_ASSESSMENT_STATUS_AUTO_APPROVED});

				if(creditAssess.size() > 0){
					return createContract(proposal);
				}else{
					return APT_Constants.STRING_RESPONSE_INCOMPLETE + '_' + proposal.Apttus_Proposal__Opportunity__c;
				}
			}
			else {

				return createContract(proposal);
			}
		}
		Catch(Exception ex){
			return APT_Constants.ERROR_PREFIX + ex.getMessage() ;
		}
	}

	/**
	* @description: This method returns service details of an agreement.
	* @author Yatika Bansal
	* @param String contractId
	* @return service record Id //(cacheable = true)
	**/
	@AuraEnabled
	public static List<Id> getServiceDetail(String contractId){
		List<Apttus__AgreementLineItem__c> alis = APT_AgreementLineItemsSelector.newInstance()
			.selectByContractIdLineTypeAndChargeType(new Set<Id>{contractId},
													 new Set<String>{APT_Constants.PARAM_PRODUCT_Type, APT_Constants.PARAM_PRODUCT_Type_Misc} ,
													 new Set<String>{APT_Constants.CHARGE_TYPE_STANDARD_PRICE} ,
													 new Set<Object> {APT_AgreementLineItemsSelector.Options.WITH_PRODUCT});

		Map<String, Id> mapAliByProdLine = new Map<String, Id>();
		for(Apttus__AgreementLineItem__c ali : alis){
			if(!mapAliByProdLine.containsKey(ali.Apttus__ProductId__r.APT_Product_Lines__c)){
				mapAliByProdLine.put(ali.Apttus__ProductId__r.APT_Product_Lines__c, ali.id);
			}
		}
		return mapAliByProdLine.values();
	}

	  /**
	* @description: This method returns current collection address.
	* @author Yatika Bansal
	* @param String contractId
	* @return address
	**/
	@AuraEnabled(cacheable = true)
	public static String getCurrentAddress(String contractId){
		List<APT_Operational_Schedule__c> os= APT_OperationalScheduleSelector.newInstance(1)
				.selectByContractId(new Set<Id>{contractId});

		if(os.size() > 0){
			return os[0].APT_Parcel_Collection_Points__c;
	   }else{
		   return APT_Constants.ERROR_PREFIX;
	   }
	}

	  /**
	* @description: This method updates collection address.
	* @author Yatika Bansal
	* @param String contractId
	* @param String address
	* @return Success/Error
	**/
	@AuraEnabled
	public static String updateCollectionAddress(String contractId, String address){
		try{
			List<APT_Operational_Schedule__c> os = APT_OperationalScheduleSelector.newInstance(1)
				.selectByContractId(new Set<Id>{contractId});

			os[0].APT_Parcel_Collection_Points__c = address;
			update os[0];

			return APT_Constants.SUCCESS_LABEL_SMALL;
		}
		Catch(Exception ex){
			return APT_Constants.ERROR_PREFIX + ex.getMessage() ;
		}
	}
}