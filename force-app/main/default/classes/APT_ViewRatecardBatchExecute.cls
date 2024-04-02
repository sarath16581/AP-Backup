/**************************************************
Description: This apex class is called while generating the proposal document from the proposal record
History:
2016-03-16 Himanshu Jain Created
2016-07-27 Mausam Padhiyar Modified APOST-2023, populate Zones on proposal for template, moved code from trigger to create proposal
2016-08-04 Mausam Padhiyar Modified APOST-2035, charge code calculation
2016-11-08 Mausam Padhiyar Modified 1714 | Charge Code Calculation Fix for WINE Z30
2016-12-12 Mausam Padhiyar Modified 1869 | validate charge code
2017-02-14 Mausam Padhiyar Modified 1834 | set flag - Identical Lines
2019-05-31 anshul.goyal@auspost.com.au Modified | 31052019 | pass exempted product type to the batch class from the proposal record
2020-10-20 Mahesh Patel Modified STP-2763 STPAC - Generate ST proposal document - Added this condition for not doing any of these calculations for StarTrack
2021-06-02 Naveen Rajanna - STP-5598/REQ2519238 Check if Pricing fields changed on proposal then display error if matches certain condition
2021-11-10 Sautul Mehta - CI-95 Changes for APPC product
2023-07-15 Nasir Jawed - commented ApexPages.AddMessage and added log Exception
**************************************************/
public with sharing class APT_ViewRatecardBatchExecute {

	public String proposalId;
	public Boolean hideMessage {get;set;}
	public Boolean isCallFromRateCalc {get;set;}
	//public Boolean isPriorityProd;
	public string prodType='';
	/**
		Constructor
	**/
	public APT_ViewRatecardBatchExecute(){
		proposalId = Apexpages.currentPage().getParameters().get(APT_Constants.STIRNG_ID_FIRST_CAPITAL);

	}

	 /**
		Constructor
	**/
	public APT_ViewRatecardBatchExecute(String proposal){
		proposalId = proposal;
	}

	/**
		Constructor
	**/
	public APT_ViewRatecardBatchExecute(String proposal, Boolean isCallFromRC){
		proposalId = proposal;
		isCallFromRateCalc = isCallFromRC;
	}

	/**
		Initial execution
	**/
	/*
	ApexCSRF: Avoid making DML operations in Apex class constructor or initializers(can not be addressed because it is in existing code.)
	*/
	public PageReference init(){
		try {
			PageReference redirectPage = null;

			Apttus_Config2__ProductConfiguration__c config = [select id, Apttus_Config2__Status__c from
																Apttus_Config2__ProductConfiguration__c
																where Apttus_QPConfig__Proposald__c =: proposalId
																Order by Apttus_Config2__VersionNumber__c Desc Limit 1];


				//charge code calculation
				set<String> setNetworkType = new set<String>{APT_Constants.NETWORK_TYPE_STANDARD, APT_Constants.NETWORK_TYPE_EXPRESS};
				set<String> setWeightMeasure = new set<String>{APT_Constants.WEIGHT_MEASURE_CUBIC, APT_Constants.WEIGHT_MEASURE_DEADWEIGHT};
				set<String> setPriceStructure = new set<String>();

				//31052019-query the exempted prod type from the proposal record
				//STP-5598/REQ2519238
				List<Apttus_Proposal__Proposal__c> activeProposals = [SELECT Id, Exempted_Product_Type__c, APT_pricing_fields_changed__c, Apttus_Proposal__Approval_Stage__c, APT_Proposal_Generated_Date__c, Apttus_QPConfig__ConfigurationFinalizedDate__c FROM Apttus_Proposal__Proposal__c where id=:proposalId];
				if(activeProposals.size() > 0){
					Apttus_Proposal__Proposal__c prop = activeProposals[0];
					prodType = prop.Exempted_Product_Type__c;

					//STP-5598/REQ2519238
					if(prop.APT_pricing_fields_changed__c &&
						prop.Apttus_Proposal__Approval_Stage__c.equalsIgnoreCase(APT_Constants.APPROVAL_STAGE_GENERATED) &&
						prop.APT_Proposal_Generated_Date__c > prop.Apttus_QPConfig__ConfigurationFinalizedDate__c
					) {
						hideMessage = true;
						ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.APT_Pricing_Fields_Changed_Error));
						return null;
					}

				} else {
					hideMessage = true;
					ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.APT_Missing_Proposal_Error));
					return null;
				}

				list<Apttus_Proposal__Proposal_Line_Item__c> listProposalLineItem = [SELECT Id, APT_Price_Structure__c, Apttus_QPConfig__OptionId__c,
																	Apttus_QPConfig__OptionId__r.APT_Domestic_Pricing__c,
																	APT_Charge_Code_Formula__c, Apttus_QPConfig__AttributeValueId__c,
																	Apttus_QPConfig__AttributeValueId__r.APTS_Price_Structure__c,
																	Apttus_Proposal__Product__c, Apttus_Proposal__Product__r.ProductCode,
																	Apttus_Proposal__Product__r.APT_Product_type__c,
																	Apttus_QPConfig__AttributeValueId__r.APT_Cubic_Factor__c,
																	Apttus_QPConfig__AttributeValueId__r.APT_Consignment_Pricing__c,
																	Apttus_QPConfig__AttributeValueId__r.APT_Signature_On_Delivery__c,
																	Apttus_QPConfig__IsPrimaryLine__c, Apttus_QPConfig__IsOptionRollupLine__c,
																	Apttus_QPConfig__ParentBundleNumber__c, Apttus_QPConfig__LineNumber__c,
																	APT_New__c, APT_Product_and_Price_Structure__c, APT_Zone__c,
																	Apttus_QPConfig__DerivedFromId__c,
																	Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__c,
																	Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c,
																	Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Cubic_Factor__c,
																	Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Consignment_Pricing__c,
																	Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Signature_On_Delivery__c,
																	Apttus_QPConfig__ChargeType__c, APT_Identical_Line__c
																	FROM Apttus_Proposal__Proposal_Line_Item__c
																	WHERE Apttus_Proposal__Proposal__c = :proposalId FOR UPDATE
																	/*AND Apttus_QPConfig__OptionId__r.APT_Domestic_Pricing__c = true*/];


				//APOST-2023
				String productNames;
				String strZones;
				//APOST-2023

				if(listProposalLineItem != null && listProposalLineItem.size() > 0) {

					//1834
					Id productId;
					set<string> setUniqueLines = new set<string>();
					List<Apttus_Proposal__Proposal_Line_Item__c> lstIdenticalLines = new List<Apttus_Proposal__Proposal_Line_Item__c>();
					//1834

					map<Decimal, Boolean> mapIsNewPricing = new map<Decimal, Boolean>();
					for(Apttus_Proposal__Proposal_Line_Item__c pli : listProposalLineItem)
					{
						//STP-2763 STPAC - Generate ST proposal document - Added this condition for not doing any of these calculations for StarTrack
						if(pli.Apttus_Proposal__Product__r.APT_Product_type__c != APT_Constants.PRODUCTTYPE_STARTRACK
						&& pli.Apttus_Proposal__Product__r.APT_Product_type__c != APT_Constants.PRODUCT_TYPE_PARCEL_CONTRACT)
						{
							if(pli.Apttus_QPConfig__OptionId__r.APT_Domestic_Pricing__c) {
								setPriceStructure.add(pli.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c);//charge code calculation
							}

							//1084
							if(pli.Apttus_QPConfig__IsPrimaryLine__c && !pli.Apttus_QPConfig__IsOptionRollupLine__c && pli.Apttus_QPConfig__ParentBundleNumber__c == null) {
								mapIsNewPricing.put(pli.Apttus_QPConfig__LineNumber__c, pli.APT_New__c);
							}
							//1084

							//1834
							if(pLI.Apttus_QPConfig__OptionId__c != null){
								productId = pLI.Apttus_QPConfig__OptionId__c;
							} else {
								productId = pLI.Apttus_Proposal__Product__c;
							}

							if(setUniqueLines.contains(productId + pli.Apttus_QPConfig__ChargeType__c)){
								pli.APT_Identical_Line__c = true;
								lstIdenticalLines.add(pLI);
							} else {
								setUniqueLines.add(productId+pli.Apttus_QPConfig__ChargeType__c);
							}
							//1834
						}
					}

					map<String, APT_Charge_Code__c> mapChargeCode = new map<String, APT_Charge_Code__c>();
					for(APT_Charge_Code__c chargeCode : [SELECT APT_Charge_Code_C1__c, APT_Charge_Code_C2__c, APT_Charge_Code_C3__c, APT_Charge_Code_C4__c,
													APT_Price_Structure__c, APT_Network_Type__c, APT_Weight_Measure__c, APT_Consignment_Pricing__c, APT_Signature__c
													FROM APT_Charge_Code__c
													WHERE APT_Price_Structure__c IN :setPriceStructure
													AND APT_Network_Type__c IN :setNetworkType
													AND APT_Weight_Measure__c IN :setWeightMeasure]) {

						mapChargeCode.put(chargeCode.APT_Price_Structure__c + APT_Constants.SEPERATOR_SIMILARITY + chargeCode.APT_Network_Type__c + APT_Constants.SEPERATOR_SIMILARITY +
											chargeCode.APT_Weight_Measure__c + APT_Constants.SEPERATOR_SIMILARITY + chargeCode.APT_Consignment_Pricing__c + APT_Constants.SEPERATOR_SIMILARITY +
											chargeCode.APT_Signature__c, chargeCode);
					}

					String networkType;
					String weightMeasure;
					Boolean bConsignmentPricing;
					Boolean bSignature;
					list<Apttus_Proposal__Proposal_Line_Item__c> listPLI = new list<Apttus_Proposal__Proposal_Line_Item__c>();
					set<Id> setUniquePLI = new set<Id>();

					//APOST-2023
					set<string> setProducts = new set<string>();
					set<string> setZones =new set<string>();
					//APOST-2023

					for(Apttus_Proposal__Proposal_Line_Item__c pli : listProposalLineItem)
					{
						//STP-2763 STPAC - Generate ST proposal document - Added this condition for not doing any of these calculations for StarTrack
						if(pli.Apttus_Proposal__Product__r.APT_Product_type__c != APT_Constants.PRODUCTTYPE_STARTRACK
						&& pli.Apttus_Proposal__Product__r.APT_Product_type__c != APT_Constants.PRODUCT_TYPE_PARCEL_CONTRACT)
						{
							//charge code calculation
							if(pli.Apttus_QPConfig__OptionId__r.APT_Domestic_Pricing__c) {
								networkType = null;
								weightMeasure = null;
								bSignature = null;
								bConsignmentPricing = null;

								if(!String.isEmpty(pli.Apttus_Proposal__Product__r.ProductCode)){
									if(pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD)) {
										networkType = APT_Constants.NETWORK_TYPE_STANDARD;
									} else if(pli.Apttus_Proposal__Product__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)) {
										networkType = APT_Constants.NETWORK_TYPE_EXPRESS;
									}
								}
								system.debug('*** networkType ***'+networkType);
								//if(pli.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Cubic_Factor__c != null && pli.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Cubic_Factor__c > 1) {
								if(pli.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Cubic_Factor__c != null
									|| (String.isNotBlank(pli.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c) && pli.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c.equalsIgnoreCase(APT_Constants.PRICE_STRUCTURE_WINE_Z30))) {
									weightMeasure = APT_Constants.WEIGHT_MEASURE_DEADWEIGHT;
								} else{
									weightMeasure = APT_Constants.WEIGHT_MEASURE_CUBIC;
								}
								system.debug('*** weightMeasure ***'+weightMeasure);
								if(!String.isEmpty(pli.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Consignment_Pricing__c)) {
									if(pli.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Consignment_Pricing__c.equalsIgnoreCase(APT_Constants.OPTION_YES)) {
										bConsignmentPricing = true;
									} else {
										bConsignmentPricing = false;
									}
								}
								system.debug('*** bConsignmentPricing ***'+bConsignmentPricing);
								if(!String.isEmpty(pli.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Signature_On_Delivery__c)) {
									if(pli.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Signature_On_Delivery__c.equalsIgnoreCase(APT_Constants.OPTION_YES)) {
										bSignature = true;
									} else {
										bSignature = false;
									}
								}
								system.debug('*** bSignature ***'+bSignature);
								APT_Charge_Code__c chargeCode = mapChargeCode.get(pli.Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c + APT_Constants.SEPERATOR_SIMILARITY + networkType + APT_Constants.SEPERATOR_SIMILARITY +
																					weightMeasure + APT_Constants.SEPERATOR_SIMILARITY + bConsignmentPricing + APT_Constants.SEPERATOR_SIMILARITY +
																					bSignature);

								if(chargeCode != null) {
									system.debug('*** chargeCode ***'+chargeCode);
									pli.APT_Charge_Code_Formula__c = chargeCode.APT_Charge_Code_C1__c + chargeCode.APT_Charge_Code_C2__c + chargeCode.APT_Charge_Code_C3__c + chargeCode.APT_Charge_Code_C4__c;
									if(!setUniquePLI.contains(pli.Id)) {
										listPLI.add(pli);
										setUniquePLI.add(pli.Id);
									}
								} else {
									//1869
									ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.APT_Missing_Charge_Code_Error + APT_Constants.SEPERATOR_SPACE + pli.Apttus_QPConfig__LineNumber__c));
									return null;
									//1869
								}
							}
							//charge code calculation

							//1084
							if(mapIsNewPricing.get(pli.Apttus_QPConfig__LineNumber__c) != null) {
							pli.APT_New__c = mapIsNewPricing.get(pli.Apttus_QPConfig__LineNumber__c);
							if(!setUniquePLI.contains(pli.Id)) {
								listPLI.add(pli);
								setUniquePLI.add(pli.Id);
							}
							}
							//1084

							//APOST-2023
							if(String.isNotBlank(pli.APT_Product_and_Price_Structure__c) && !setProducts.contains(pli.APT_Product_and_Price_Structure__c)){
							setProducts.add(pli.APT_Product_and_Price_Structure__c);

							IF(String.isBlank(productNames)){
							productNames = pli.APT_Product_and_Price_Structure__c;
							} else {
								productNames = productNames + APT_Constants.SEPERATOR_COMMA + pli.APT_Product_and_Price_Structure__c;
							}
							}

							iF(String.isNotBlank(pli.APT_Zone__c) && !setZones.contains(pli.APT_Price_Structure__c +  APT_Constants.SEPERATOR_SPACE + (pli.APT_New__c ? 'true' : 'false'))) {
							//setZones.add(pli.APT_Zone__c);
							setZones.add(pli.APT_Price_Structure__c +  APT_Constants.SEPERATOR_SPACE + (pli.APT_New__c ? 'true' : 'false'));
							if(String.IsEmpty(strZones)) {
								//strZones = pli.APT_Zone__c;
								strZones = pli.APT_Price_Structure__c + APT_Constants.SEPERATOR_SPACE + (pli.APT_New__c ? 'true' : 'false');
							} else {
								//strZones = strZones + APT_Constants.SEPERATOR_COMMA + pli.APT_Zone__c;
								strZones = strZones + APT_Constants.SEPERATOR_COMMA + pli.APT_Price_Structure__c + APT_Constants.SEPERATOR_SPACE + (pli.APT_New__c ? 'true' : 'false');
							}
							}
							//APOST-2023
						}
					}

					if(listPLI != null && listPLI.size() > 0) {
						update listPLI;
					}

					//1834
					if(lstIdenticalLines.size() > 0){
					update lstIdenticalLines;
					}
					//1834
			}
			//charge code calculation

			//if(config.Apttus_Config2__Status__c == 'Finalized'){
			String sessionId = UserInfo.getSessionId();
			//String serverUrl = URL.getSalesforceBaseUrl().toExternalForm() + APT_Constants.URL_SERVICES_SOAP + UserInfo.getOrganizationId();
			String serverUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/38.0/' + UserInfo.getOrganizationId();

			//31052019- added one more attribute product type
			APT_ViewratecardBatch viewBatch = new APT_ViewratecardBatch(config.ID, proposalId, sessionId, serverUrl, URL.getSalesforceBaseUrl().toExternalForm(),isCallFromRateCalc, prodType);
			Database.executeBatch(viewBatch,1);
			/*
			ApexXSSFromURLParam: Apex classes should escape/sanitize Strings obtained from URL parameters(can not be addressed because it is in existing code.)
			*/
			//set flag
			Apttus_Proposal__Proposal__c proposal = [SELECT Id FROM Apttus_Proposal__Proposal__c WHERE Id = : proposalId FOR UPDATE];
			proposal.APT_Document_Generation_in_Progress__c = true;

			//APOST-2023
			proposal.APT_Product_names__c = productNames;
			proposal.APT_Zone__c = strZones;

			if(proposal.APT_Product_names__c != null && (proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_NonContractedUMS) || proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_NonContractedPrintPost)
													|| proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_CLEAN_MAIL) || proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_SAMPLE_POST)
													|| proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_PRESORT_LETTERS) || proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_IMPACT_MAIL)
													|| proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_ACQUISITION_MAIL) || proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_CHARITY_MAIL)
													|| proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_REGISTERED_POST) || proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_PO_BOXES)
													|| proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_COUNCILLOR_MAIL) || proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_PROMO_POST)
													|| proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_IMPRINT_METERED_POST) || proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_REPLY_PAID)
													|| proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_LOCAL_COUNTRY_LETTER) || proposal.APT_Product_names__c.contains(APT_Constants.PRODUCT_NAME_COMPETITION_MAIL))){

				proposal.APT_Non_Contracted_Mail_Products__c = true;
			} else {
				proposal.APT_Non_Contracted_Mail_Products__c = false;
			}
			//APOST-2023

			//STP-5598/REQ2519238
			proposal.APT_pricing_fields_changed__c = false;

			update proposal;

			redirectPage = redirectToProposal();
			/*} else{
				hideMessage = true;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Cart is not Finalized. Finalize the cart and try again.'));

			}
			*/
			return redirectPage;
		} catch(Exception ex) {
			String stackTrace = ex.getStackTraceString().substringBefore('\n');
			String className = stackTrace.substringAfter('.').substringBefore('.');
			String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Sales', className, methodName, 'NONE', LoggingLevel.ERROR);
			return null;
		}

	}

	/**
		This method will redirect you to proposal page
	**/
	/*
	ApexOpenRedirect: Apex classes should safely redirect to a known location(can not be addressed because it is in existing code.)
	*/
	public PageReference redirectToProposal(){
		try {
			return new PageReference(APT_Constants.SEPERATOR_BACKWARD_SLASH + proposalId);
		}
		catch(Exception ex) {
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			return null;
		}
	}
}