/**************************************************
Description: This apex class if handler class for apex trigger - APT_AgreementLineItemTrigger.
History:
2016-01-12 aviteja Epuri Created
2016-03-04 Mausam Padhiyar Modified  , defect-1512
2019-05-31 anshul.goyal@auspost.com.au Modified | 31052019 | mark Exempted_Product_Type__c and Is_T_C_Enabled__c flag on the proposal record for Priority Prod, Workforce and StarTrack proposals
2019-09-05 Neha Nimran|WVF 118|Create Proposal button visible/invisible depending on pricing mode Online/Offline for Exempted Product 
2019-10-08 Neha Nimran|WV-107|Logic to update proposal ACIC request required field based on custom setting
**************************************************/
public with sharing class APT_ProposalLineItemTriggerHandler {

/** Copy product image from product to proposal Line Item       
	@Params -
	listProposalLineItem: List of Proposal line item     
*/
public static String beforeInsertEvent(list<Apttus_Proposal__Proposal_Line_Item__c> listProposalLineItem) {
	try {                  
		Set<Id> productOptionIds = new Set<Id>();
		for(Apttus_Proposal__Proposal_Line_Item__c proLineItem : listProposalLineItem){
			if(proLineItem.Apttus_Proposal__Product__c != null)
				productOptionIds.add(proLineItem.Apttus_Proposal__Product__c);
				// Add the below line to populate the Product Name Text field with the product name
				prolineItem.Product_Name_Text__c = prolineItem.APT_Product_Name__c;

			if(proLineItem.Apttus_QPConfig__OptionId__c != null)
				productOptionIds.add(proLineItem.Apttus_QPConfig__OptionId__c);
		}

		Map<Id,Product2> products = new Map<Id,Product2>([Select APT_Product_Image__c from Product2 where Id In :productOptionIds]);

		for(Apttus_Proposal__Proposal_Line_Item__c proLineItem : listProposalLineItem){
			if(proLineItem.Apttus_Proposal__Product__c != null && proLineItem.Apttus_QPConfig__LineType__c !=APT_Constants.LABEL_LINE_TYPE_OPTION){
				proLineItem.APT_Product_Image__c = products.get(proLineItem.Apttus_Proposal__Product__c).APT_Product_Image__c ;
			}else if(proLineItem.Apttus_QPConfig__OptionId__c != null && proLineItem.Apttus_QPConfig__LineType__c ==APT_Constants.LABEL_LINE_TYPE_OPTION){
				proLineItem.APT_Product_Image__c = products.get(proLineItem.Apttus_QPConfig__OptionId__c).APT_Product_Image__c ;
			} else {}
		}

		return APT_Constants.SUCCESS_LABEL;
	} catch(Exception ex) {
		return ex.getMessage()+ex.getStackTraceString();
	}
}

/**
	Copy Line Item Rate Card records using Quote Rate Card record. APOST-801.
	@Params -
	listProposalLineItem: List of Proposal line item     
	*/
public static String afterInsertEvent(list<Apttus_Proposal__Proposal_Line_Item__c> listProposalLineItem, Boolean isUpdate) {
	try {

		set<Id> setLineItemId = new set<Id>();
		map<String, String> mapLineItemId = new map<String, String>();
		Set <Id> proposalIdsForTCFlagUpdate = new  Set <Id>();
		Map<Id,String> proposalIdToType = new Map<Id,String>();
		Map<String,Boolean> prodTypeToT_CFlagMap = new Map<String,Boolean>();
		Set <String> exemptedProdTypeSet = new  Set <String>();
		final String OFFLINE= 'Offline';
		final String ONLINE= 'Online';
		Map<String,String> productPricing = new Map<String, String>();
					
		//update proposals ACIC request required field to enable contract
		set<Id> proposalIdsToUpdateACICRequestRequired = new set<Id>();
		//get list of product types which requires ACIC request to be approved to create contract
		System.debug('######acic prod types'+APT_R2T_System_Properties__c.getInstance().APT_ACIC_Request_Product_types__c);
		set<string> ACICRequestRequiredProductTypes = new set<string>();
		if(APT_R2T_System_Properties__c.getInstance().APT_ACIC_Request_Product_types__c != null){
			ACICRequestRequiredProductTypes.addAll(APT_R2T_System_Properties__c.getInstance().APT_ACIC_Request_Product_types__c.split(','));
		}

		set<Id> proposalIdstoUpdateACICRequestRequiredField = new set<Id>();
		
		//31052019-query the exempted custom metadata to fetch the exempted prods(priority prod,workforce ver and StarTrack prod)
		for(R2T_Exempted_Proposal_Settings__mdt rec:  [SELECT MasterLabel, QualifiedApiName,Is_T_C_Enabled__c,Pricing__c FROM R2T_Exempted_Proposal_Settings__mdt]){
			exemptedProdTypeSet.add(rec.MasterLabel.toLowerCase());
			//WFV-118 Collect Pricing information for exempted Product
			productPricing.put(rec.MasterLabel, rec.Pricing__c);
			
			if(rec.Is_T_C_Enabled__c==false)
				prodTypeToT_CFlagMap.put(rec.MasterLabel.toLowerCase(), rec.Is_T_C_Enabled__c);
		}

		//31052019-collect the line items and identify the line items which have the product with the exempted product types(priority prod,workforce ver and startrack prod)
		//collect the line items having product for which specific Terms&Condition document need to be generated
		for(Apttus_Proposal__Proposal_Line_Item__c pli :
		[SELECT Id,Apttus_Proposal__Proposal__c,Apttus_QPConfig__DerivedFromId__c,
				Apttus_Proposal__Product__c ,APT_Process_Line_Item_RateCard_on_Update__c,Apttus_Proposal__Product__r.APT_Product_type__c
		FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Id IN:listProposalLineItem]) {
			//collect proposal ids when product's product type is listed in set which requires ACIC request to be approved to create contract
			if(ACICRequestRequiredProductTypes.contains(pli.Apttus_Proposal__Product__r.APT_Product_type__c)){
				proposalIdstoUpdateACICRequestRequiredField.add(pli.Apttus_Proposal__Proposal__c);
			}
			//collect the proposal lineItems having the product types mentioned in the custom metadata "R2T_Exempted_Proposal_Settings__mdt"
			//System.debug('###pli.Apttus_Proposal__Product__r.APT_Product_type__c####'+pli.Apttus_Proposal__Product__r.APT_Product_type__c);
			if(!isUpdate && (!exemptedProdTypeSet.isEmpty() && pli.Apttus_Proposal__Product__c != null && pli.Apttus_Proposal__Product__r.APT_Product_type__c != null && exemptedProdTypeSet.contains(pli.Apttus_Proposal__Product__r.APT_Product_type__c.toLowerCase()))){
				proposalIdToType.put(pli.Apttus_Proposal__Proposal__c,pli.Apttus_Proposal__Product__r.APT_Product_type__c);
			}
			//collect the proposal lineItems having the product types mentioned in the custom metadata "R2T_Exempted_Proposal_Settings__mdt" and for which T&c flag is true
			//T&C flag is true for the product types for which the different T&C document need to be generated
			if(!isUpdate && (!prodTypeToT_CFlagMap.isEmpty() && pli.Apttus_Proposal__Product__c != null && pli.Apttus_Proposal__Product__r.APT_Product_type__c != null && prodTypeToT_CFlagMap.containskey(pli.Apttus_Proposal__Product__r.APT_Product_type__c.toLowerCase()))){
				proposalIdsForTCFlagUpdate.add(pli.Apttus_Proposal__Proposal__c);
			}
			if(isUpdate && !pli.APT_Process_Line_Item_RateCard_on_Update__c) {
				continue;
			}
			setLineItemId.add(pli.Apttus_QPConfig__DerivedFromId__c);
			mapLineItemId.put(pli.Apttus_QPConfig__DerivedFromId__c, pli.Id);
		}

		if(setLineItemId.size() > 0) {
			list<APT_Quote_Rate_Card__c> listQuoteRateCard = database.query(APT_Constants.SOQL_SELECT + APT_AmendRenewUtility.getAllAgrFields(APT_Constants.SOQL_QUOTE_RATE_CARD_OBJECT)  + APT_Constants.SOQL_QUOTE_RATE_CARD_QUERY);
			list<APT_Line_Item_Rate_Card__c> listLineItemRateCard = new list<APT_Line_Item_Rate_Card__c>();
			set<String> setIgnoreFields = new set<String>{APT_Constants.SOQL_LINE_ITEM_OBJECT};
			if(listQuoteRateCard != null && listQuoteRateCard.size() > 0) {
				APT_Line_Item_Rate_Card__c clonedLineItemRateCard;
				for(APT_Quote_Rate_Card__c qrc : listQuoteRateCard) {
					clonedLineItemRateCard = new APT_Line_Item_Rate_Card__c();
					for (String fieldName : APT_AmendRenewUtility.getFieldNames(APT_Quote_Rate_Card__c.getSObjectType())) {
						Object value = qrc.get(fieldName);
						if(value != null) {
							// get the target field name
							if(setIgnoreFields.contains(fieldName) == false) {
								clonedLineItemRateCard.put(fieldName, value);
							}
						}
					}
					clonedLineItemRateCard.APT_Proposal_Line_Item__c = mapLineItemId.get(qrc.APT_Line_Item__c);
					clonedLineItemRateCard.APT_Proposal__c = qrc.APT_Line_Item__r.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c;
					listLineItemRateCard.add(clonedLineItemRateCard);
				}
				system.debug(listLineItemRateCard + '--->');

				if(listLineItemRateCard.size() > 0) {
					insert listLineItemRateCard;
				}
			}
		}


		//31052019-loop over the proposals related to the line items with the prod type as (priority prod,workforce ver and startrack prod)
		//mark the proposal with Flag for exempted prod types and for the specific T&c document template
		List <Apttus_Proposal__Proposal__c> proposalsForUpdate = new List <Apttus_Proposal__Proposal__c>();
	
		for(Apttus_Proposal__Proposal__c prop: [SELECT ID,Is_Exempted_Prod__c,Exempted_Product_Type__c,Is_T_C_Enabled__c,APT_ACIC_Request_required_for_Contract__c 
												FROM Apttus_Proposal__Proposal__c
												WHERE ID IN:proposalIdToType.keySet() OR ID IN :proposalIdstoUpdateACICRequestRequiredField]){

				//proposal update for exempted prod types and t&c template
				if(proposalIdToType.keySet().contains(prop.Id)){
					//mark proposal record with the exempted flag to indicate the prosal have the lineitems defined in the custom metadata "R2T_Exempted_Proposal_Settings__mdt"
					prop.Is_Exempted_Prod__c = true;

					//marking the exempted product type value on the proposal record
					//the picklist product type will have the values as defined in the custom metadata "R2T_Exempted_Proposal_Settings__mdt"
					if(!proposalIdToType.isEmpty()){
						prop.Exempted_Product_Type__c   = proposalIdToType.get(prop.Id);
					}

					if(proposalIdsForTCFlagUpdate.contains(prop.Id)){
						prop.Is_T_C_Enabled__c = false;
					}
				}
				//proposal update for ACIC request approved to create contract
				if(proposalIdstoUpdateACICRequestRequiredField.contains(prop.Id)){
					prop.APT_ACIC_Request_required_for_Contract__c = true;
				}
				proposalsForUpdate.add(prop);
				
				//WFV-118 To make Create proposal Button visible depending on the Pricing mode Online/Offline for exempted products
		
				System.debug('productPricing---->'+productPricing);
				System.debug('prop.Exempted_Product_Type__c---->'+prop.Exempted_Product_Type__c);
				system.debug('BEFORE prop.Is_Exempted_Prod__c--->'+prop.Is_Exempted_Prod__c);

				/**Check if the selected product is Exempted and its pricing mode is online or offline
				Exempted Product(WFV) with Pricing Online , Create Proposal button will be visible
				Exempted Product(StarTrack/Priority) with Pricing Offline , Create Proposal button will be not visible**/                                                    
				if(productPricing.containsKey(prop.Exempted_Product_Type__c) && 
							productPricing.get(prop.Exempted_Product_Type__c).equalsIgnoreCase(ONLINE)){
				System.debug('prop.Exempted_Product_Type__c Inside---->'+prop.Exempted_Product_Type__c);
				prop.Is_Exempted_Prod__c = false; 
				system.debug('IF prop.Is_Exempted_Prod__c--->'+prop.Is_Exempted_Prod__c);
				}else{
				prop.Is_Exempted_Prod__c = true; 
				system.debug('ELSE prop.Is_Exempted_Prod__c--->'+prop.Is_Exempted_Prod__c);
				}
				system.debug('AFTER prop.Is_Exempted_Prod__c--->'+prop.Is_Exempted_Prod__c);
													
		}
		if(!proposalsForUpdate.isEmpty()){
			update proposalsForUpdate;
		}

		return APT_Constants.SUCCESS_LABEL;
	} catch(Exception ex) {
		return ex.getMessage()+ex.getStackTraceString();
	}
}
}