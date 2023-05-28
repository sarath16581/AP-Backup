/**
	@description:  This controller class is used for linking PSR and apply appropriate business rule if PSR requires standard delegated pricing or custom pricing.
	Delegated pricing is using existing pricing in apttus while custom pricing require making an API call to retrieve rate from COMPASS pricing tool.
	@author Seth Heang & Nasir Jawed
	@date 2022-04-01
	@changelog:
	2022-04-01 - Seth Heang - Created
	2022-05-05 - Nasir Jawed - Modified for CI-134 for Delegate Pricing
	2022-08-23 - Bharat Patel - Modified  applyConstraintRules(), updatePriceForCart() methods and remove debug log from code
	2023-01-24 - Sarath Burra - Added the Evaluated Spend Logic  as per the user story https://australiapost.jira.com/browse/CI-772
	27/01/2023 - Sarath Burra - Removing the LodgmentZone Validation for APPC in the onApply Method as the Lodgement Zones will be defaulted going forward as per story https://australiapost.jira.com/browse/CI-828
	* 							Lines Removed 141-147
	01/05/2023 - Sarath Burra - CI 834- Populate the Min Transit cover amount for Custom and Delegated Pricing Scenarios
	**/
	public with sharing class APT_CompassPricingController {
		public String lineItemId {get; set;}
		public String configId {get; set;}
		public String opportunityId {get; set;}

		public String parentPageURL{get;set;}

		public APT_CompassPricingController(){
			// get parameters from VF Page
			lineItemId = apexpages.currentPage().getParameters().get('selectedRecordID');
			configId = apexpages.currentPage().getParameters().get('configId');
			opportunityId = apexpages.currentPage().getParameters().get('opportunityId');

			String hostURL = String.valueof(URL.getSalesforceBaseUrl().toExternalForm());
			hostURL += '/apex/Apttus_Config2__Cart?configRequestId=' + configId + '&id=' + configId + '#/cart';

			parentPageURL = hostURL;
		}

		public String compassPricingAttributes {
			get {
				// build attributes map pf VF paramters to pass into LWC
				Map<String, Object> componentAttributes = new Map<String, Object> {
					'lineitemId' => lineItemId,
					'configId' => configId,
					'opportunityId' => opportunityId
				};
				return JSON.serialize(componentAttributes);
			}
			private set;
		}

		/**
		 * This method retrieve APPC PSR provided all valid criteria is met and return the list of PSR back to the LWC.
		 * It is linked to Wire Method in LWC to populate the PSR table in LWC on page load
		 * @param String oppId
		 * @return List<Deal_Support_Request__c>
		 */
		@AuraEnabled(cacheable=true)
		public static List<SObject> getPSRList(String oppID, String selectedLineItemId){

			List<Deal_Support_Request__c> completedPSRList = new List<Deal_Support_Request__c>();
			List<Deal_Support_Request__c> psrList = new List<Deal_Support_Request__c>();
			AuraHandledException exceptionHandler;
			try{
				// retrieve PSR APPC record type Id
				Id psrAPPCRecTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Deal_Support_Request__c', new Set<String>{APT_Constants.PSR_APPC_RECORD_TYPE_APINAME}).values()[0].Id;
				/**
				 * Query PSR based on following criteria:
				 * -Quote's Opportunity should be equal to the Deal Support Request's Opportunity
				 * -PSR stage and status is Completed and Completed respectively.
				 * -Record type of DSR should be "Pricing Support Request - Australia Post Parcel Contract" and PSR.Product = "Australia Post Parcel Contract"
				 */
				Map<String, Object> searchParams = new Map<String, Object>();
				searchParams.put('opportunityIds', new Set<Id>{oppID});
				searchParams.put('recTypeIds', new Set<Id>{psrAPPCRecTypeId});
				searchParams.put('productNames', new Set<String>{APT_Constants.PSR_APPC_PRODUCT_NAME});
				psrList = DealSupportRequestsSelector.newInstance().search(searchParams, new Set<Object>{DealSupportRequestsSelector.Options.WITH_ORGANISATION}, true);

				// fetch product attribute value and its neccessary fields' values for validation purposes
				Apttus_Config2__ProductAttributeValue__c pavRec = APT_ProductAttributeValuesSelector.newInstance(1).selectByLineItemId(new Set<Id>{selectedLineItemId})[0];
				Set<String> allowedTierWithoutPSR = new Set<String>{'T04','T05','T06','T07','T08'};
				// validate if there is no PSR raised and customer tier is not between Tier 4 to Tier 8
				if(!allowedTierWithoutPSR.contains(pavRec.APT_Customer_Tier__c) && (psrList == null || psrList.size() == 0)){
					exceptionHandler = new AuraHandledException(System.Label.APT_NoAPPCPSR);
					exceptionHandler.setMessage(System.Label.APT_NoAPPCPSR);
					throw exceptionHandler;
				}
				List<SObject> psrSObject = new List<SObject>();
				psrSObject.addAll(psrList);
				return psrSObject;
			} catch (Exception e) {
				throw new AuraHandledException(e.getMessage());
			}
		}

		/**
		 * This method return the ID of the temporary configuration object used by Apttus shopping cart to temporarily store product information in one session.
		 * It is linked to Wire Method in LWC to fetch the temporary configuration object ID on page load
		 * @param String configId
		 * @return Apttus_Config2__TempObject__c.Id
		 */
		@AuraEnabled(cacheable=true)
		public static Id fetchConfigRequestId(String configId){
			try {
				// fetch the temporary configuration object ID based on Apttus config Id
				Id configRequestRecId = APT_ConfigTempObjectsSelector.newInstance(1).selectByConfigId(new Set<Id>{configId})[0].Id;
				return configRequestRecId;
			} catch (Exception e) {
				throw new AuraHandledException(e.getMessage());
			}
		}

		/**
		 * This method is used to link the PSR to the current proposal.
		 * It validates APPC product's config details and PSR details to determine if standard delegated pricing is satisfactory or a custom rate from COMPASS is required.
		 *  -Delegated Pricing: recalculate the apttus cart with existing apttus rate
		 *  -Customised Pricing: make an external callout to COMPASS to get custom rate
		 * @param SObject objDSR
		 * @param String configId
		 * @param String selectedLineItemId
		 * @return String for Success Message
		 */
		@AuraEnabled
		public static String onApply(SObject objDSR, string configId, string selectedLineItemId){
			ID conID=(String) configId;
			Apttus_Config2__ProductAttributeValue__c pavRec;
			AuraHandledException exceptionHandler;
			Deal_Support_Request__c selectedPSR = (Deal_Support_Request__c) objDSR;

			try{
				// fetch product attribute value and its neccessary fields' values for validation purposes
				pavRec = APT_ProductAttributeValuesSelector.newInstance(1).selectByLineItemId(new Set<Id>{selectedLineItemId})[0];

				// check if validity end date has passed in PSR and display error message
				if(selectedPSR.Quote_Validity_End_Date__c < Date.today()){
					exceptionHandler = new AuraHandledException(System.Label.APT_ExpiredQuoteValidityEndDate);
					exceptionHandler.setMessage(System.Label.APT_ExpiredQuoteValidityEndDate);
					throw exceptionHandler;
				}

				// Standard delegated pricing is required
				if(selectedPSR.Approved_Event__c == APT_Constants.PSR_APPC_STANDARD_DELEGATED_PRICING) {
					updateProdConfigAndPricingForCart(conID,selectedPSR,null,null,null,null, false,null,null);
				}
				// Custom rate is required, make COMPASS callout
				else if(selectedPSR.Approved_Event__c == APT_Constants.PSR_APPC_CUSTOM_PRICING) {
					return setCustTierDefault(conID, selectedPSR);
				}

				return System.Label.APT_LinkPSRSuccess;
			}
			catch(Exception e){
				throw new AuraHandledException(e.getMessage());
			}
		}

		@AuraEnabled
		public static Boolean rePriceCartForCustomPricing(string configId) {
			if(configId != null ) {
				ID conID=(String) configId;
				return updatePriceForCart(conID,true);
			}
			return false;
		}

		//calling the method to update the records for custom pricing
		@AuraEnabled
		public static String updateCartForCustomPricing(SObject objDSR, string configId, string selectedLineItemId, string cartTier) {

			ID conID=(String) configId;
			Apttus_Config2__ProductAttributeValue__c pavRec;
			AuraHandledException exceptionHandler;
			Deal_Support_Request__c selectedPSR = (Deal_Support_Request__c) objDSR;

			if(selectedPSR.Approved_Event__c == APT_Constants.PSR_APPC_CUSTOM_PRICING) {
				updateRecordForCustomPricing(conID,selectedPSR);
			}
			return System.Label.APT_LinkPSRSuccess;
		}


		//Making a callout to compass API and handling the response using the wrapper class and collecting the Key
		// to search the key in LineItem and Usage price tier
		public static void updateRecordForCustomPricing(ID quoteConfigurationId,Deal_Support_Request__c selectedPSR) {

			AuraHandledException exceptionHandler;
			List<CompassWrapper.serviceSpeeds> rateCardService = new List<CompassWrapper.serviceSpeeds>();
			List<CompassWrapper.features> rateCardFeatures = new List<CompassWrapper.features>();
			List<CompassWrapper.returns> rateCardReturns = new List<CompassWrapper.returns>();
			List<CompassWrapper.surcharges> rateCardsurcharges = new List<CompassWrapper.surcharges>();
			List<String> key1List = new List<String>();
			Map<String,CompassWrapper.serviceSpeeds> keyServiceMap = new Map<String,CompassWrapper.serviceSpeeds>();
			Map<String,CompassWrapper.frsWrapper> keyFRSMap = new Map<String,CompassWrapper.frsWrapper>();
			CompassWrapper.CompassPriceWrapper  compassPriceResponse = new CompassWrapper.CompassPriceWrapper();
			CompassWrapper.ratecardItem rateCardResponse = new CompassWrapper.ratecardItem();
			compassPriceResponse.ratecardItem = new List<CompassWrapper.ratecardItem>();
			List<CompassWrapper.ratecardItem> rateCardResponseList = new List<CompassWrapper.ratecardItem>();
			map<String,string> customRefMap = new map<String,string>()  ;
			CompassWrapper.features tcCoverFeature= new CompassWrapper.features();
			HttpResponse responseCustomPricing ;

			try{

				HttpRequestWrapper reqWrap= new HttpRequestWrapper(selectedPSR.Compass_Quote_Reference__c,selectedPSR.Organisation__r.LEGACY_ID__c,APT_Constants.RATING_MODEL_PD);

				responseCustomPricing = APT_HttpCallouts.makeCompassAPIRequest(reqWrap);

				if(responseCustomPricing.getStatusCode() == 200){
					compassPriceResponse  = (CompassWrapper.CompassPriceWrapper)JSON.deserialize(responseCustomPricing.getBody(), CompassWrapper.CompassPriceWrapper.class);
					system.debug('compassPriceResponse:'+ compassPriceResponse);

					rateCardResponseList = compassPriceResponse.ratecardItem;

					if(rateCardResponseList != null && rateCardResponseList.size() > 0 ){
						for(CompassWrapper.ratecardItem rcr: rateCardResponseList ){
							//making key for service speed products
							if(rcr.serviceSpeeds!=null){
								rateCardService.addall(rcr.serviceSpeeds);

								string key1= rcr.customerTier+'~'+rcr.ratingcardCategory+'~'+rcr.lodgementZone;
								if(key1 != ''){
									customRefMap.put(key1,rcr.customRef);
									key1List.add(key1);
								}

								for(CompassWrapper.serviceSpeeds ss: rateCardService){
									string keyService = ss.pricePoint+'_'+ss.priceFactor;
									if(keyService != ''){
										keyServiceMap.put(keyService,ss);
									}
								}

							}
							//making key for FRS products
							if(rcr.features!=null){
								rateCardFeatures.addAll(rcr.features);

								for(CompassWrapper.features fea: rateCardFeatures){
									CompassWrapper.frsWrapper totalFields= new CompassWrapper.frsWrapper(fea.pricePoint,fea.priceFactor,fea.price);
									string keyFeat = fea.pricePoint+'_'+fea.priceFactor;
									if(keyFeat != ''){
										customRefMap.put(keyFeat,rcr.customRef);
										keyFRSMap.put(keyFeat,totalFields);
									}
									//CI-834 Add changes to Populate the Min Transit cover amount for Custom and Delegated Pricing Scenarios, Pass the parameter to update the PAV
									if(fea.name.containsIgnoreCase('Transit Cover')) {
										tcCoverFeature=fea;
									}
								}
							}
							if(rcr.returns!=null){
								rateCardReturns.addAll(rcr.returns);
								for(CompassWrapper.returns ret: rateCardReturns){
									CompassWrapper.frsWrapper totalFields= new CompassWrapper.frsWrapper(ret.pricePoint,ret.priceFactor,ret.price);
									string keyRet = ret.pricePoint+'_'+ret.priceFactor;
									if(keyRet != ''){
										customRefMap.put(keyRet,rcr.customRef);
										keyFRSMap.put(keyRet,totalFields);
									}
								}
							}
							if(rcr.surcharges!=null){
								rateCardsurcharges.addAll(rcr.surcharges);
								for(CompassWrapper.surcharges sCharge: rateCardsurcharges){
									CompassWrapper.frsWrapper totalFields= new CompassWrapper.frsWrapper(sCharge.pricePoint,sCharge.priceFactor,sCharge.price);
									string keySur = sCharge.pricePoint+'_'+sCharge.priceFactor;
									if(keySur != ''){
										customRefMap.put(keySur,rcr.customRef);
										keyFRSMap.put(keySur,totalFields);
									}
								}
							}
						}
					}
				}

				// Handling the error when legitimate data are not send in the Compass callout
				if(responseCustomPricing.getStatusCode() == 400 ){

					Map<String, Object> responseError = (Map<String, Object>) JSON.deserializeUntyped(responseCustomPricing.getBody());
					list<object> errorlisttemp = (list<object>)responseError.get('errors');

					Map<String, Object> responseErrorCode = (Map<String, Object>) errorlisttemp[0];

					if(responseErrorCode.get('code') == 'DATA_NOT_FOUND'){
						exceptionHandler = new AuraHandledException(System.Label.INVALID_QUOTE);
						exceptionHandler.setMessage(System.Label.DATA_NOT_FOUND);
						throw exceptionHandler;
					}
					else if(responseErrorCode.get('code') == 'INVALID_QUOTE'){
						exceptionHandler = new AuraHandledException(System.Label.INVALID_CUSTOMER_ID);
						exceptionHandler.setMessage(System.Label.INVALID_QUOTE);
						throw exceptionHandler;
					}
					else if(responseErrorCode.get('code') == 'EXPIRED_QUOTE'){
						exceptionHandler = new AuraHandledException(System.Label.INVALID_CUSTOMER_ID);
						exceptionHandler.setMessage(System.Label.EXPIRED_QUOTE);
						throw exceptionHandler;
					}
					else if(responseErrorCode.get('code') == 'INVALID_CUSTOMER_ID'){
						exceptionHandler = new AuraHandledException(System.Label.INVALID_CUSTOMER_ID);
						exceptionHandler.setMessage(System.Label.INVALID_CUSTOMER_ID);
						throw exceptionHandler;
					}

					else if(responseErrorCode.get('code') == 'INVALID_RATING_MODEL'){
						exceptionHandler = new AuraHandledException(System.Label.INVALID_CUSTOMER_ID);
						exceptionHandler.setMessage(System.Label.INVALID_RATING_MODEL);
						throw exceptionHandler;
					}

				}

				else if(responseCustomPricing.getStatusCode() == 404){
					exceptionHandler = new AuraHandledException(System.Label.DATA_NOT_FOUND);
					exceptionHandler.setMessage(System.Label.DATA_NOT_FOUND);
					throw exceptionHandler;

				}
				else if(responseCustomPricing.getStatusCode() == 500){
					exceptionHandler = new AuraHandledException(System.Label.SYSTEM_ERROR);
					exceptionHandler.setMessage(System.Label.SYSTEM_ERROR);
					throw exceptionHandler;
				}


				if(rateCardResponseList != null && rateCardResponseList.size() > 0 && responseCustomPricing.getStatusCode() == 200){
					updateProdConfigAndPricingForCart(quoteConfigurationId,selectedPSR,compassPriceResponse,key1List,keyServiceMap,keyFRSMap, true,customRefMap,tcCoverFeature);
				}

			}catch(Exception e){
				throw new AuraHandledException(e.getMessage());
			}
		}

		/**
		 * This method updates the shopping cart configuration record and recalculate the Apttus product pricing in the shopping cart.
		 * @param String quoteConfigurationId, DSR object
		 * @return void
		 */

		public static void updateProdConfigAndPricingForCart(ID quoteConfigurationId,Deal_Support_Request__c selectedPSR , CompassWrapper.CompassPriceWrapper compassPriceResponse ,
												List<String> key1List,Map<String,CompassWrapper.serviceSpeeds> keyServiceMap,Map<String,CompassWrapper.frsWrapper> keyFRSMap, Boolean isCustomPrice, map<string,string> customRefMap,CompassWrapper.features tcCoverFeature) {
			try{
				String pavTierCheck ;
				List<Apttus_Config2__LineItem__c> lineItemListUPT;
				List<ID> pavList= new List<ID>();
				List<Apttus_Config2__ProductAttributeValue__c> pavListQuery;
				List<Apttus_Proposal__Proposal__c > proposalListUpdate= new List<Apttus_Proposal__Proposal__c >();
				List<Apttus_Proposal__Proposal__c> currentProposal;
				List<Apttus_Config2__ProductConfiguration__c> productConfig;
				List<ID> lineItemCustom = new List<ID>();
				List<Apttus_Config2__LineItem__c> lineItemToUpdate = new List<Apttus_Config2__LineItem__c>();
				List<Apttus_Config2__UsagePriceTier__c> uptList= new List<Apttus_Config2__UsagePriceTier__c>();
				Map<String,APT_UPT_Dimension4Value__c> allCodes = APT_UPT_Dimension4Value__c.getAll();
				string KR;
				string BR;
				boolean constraintRuleResult=false;
				boolean isPricePending = false;
				boolean tcUpdateRequired=false;
				//Checking in the custom setting weather the price to be picked from basic rate or KG rate.
				if(compassPriceResponse != null){
					for(APT_UPT_Dimension4Value__c code: allCodes.values()){
						if(code.name == APT_Constants.APT_KG_Rate){
							KR = code.BR_KR__c;
						}
						if(code.name == APT_Constants.APT_Basic_Rate){
							BR = code.BR_KR__c;
						}
					}
				}
            	for(Apttus_Config2__LineItem__c li:LineItemsSelector.newInstance().selectByProdConfId(new set<ID>{(ID)quoteConfigurationId})){
                //if(li.Apttus_Config2__LineType__c == 'Product/Service')  // BRP : 20221007
                    pavList.add(li.Apttus_Config2__AttributeValueId__c);
            	}

				//Fetch all the Product Attribute value records and update all the records with Tier and Price structure
				if(pavList != null && pavList.size() > 0 ){
					pavListQuery = APT_ProductAttributeValuesSelector.newInstance().selectByPavID(pavList);
					if(pavListQuery.size() > 0){
						pavTierCheck = pavListQuery[0].APT_Customer_Tier__c;
					}
					UpdateProductAttributeValues(pavListQuery,selectedPSR,compassPriceResponse, quoteConfigurationId,tcCoverFeature);
				}
				/*CI-834 Changes to accomodate Custom pricing for Transit Cover and consolidate LienItem Updates for Custom/Delegated Pricing scenarios
				Provided below is the flow for Custom/Delegated Pricing
				Custom Pricing: 1.  Update PAV
								2.  Update LineItem.Apttus_Config2__PricingStatus__c to 'Pending' (This Will make sure the LineItem Record is picked up for Repricing)
								3.  Update LineItems
								4.  Update Price for the cart with LineItem.Apttus_Config2__IsCustomPricing__c = false(This will ensure that Pricing is calculated based on PAV update).
									This Step helps would help in identifiying correct PLI, Compass_LineItem_Identifier__c for Transit Cover
								5.	Change Apttus_Config2__IsCustomPricing__c value to true and update the pricing based on Custom Pricing received from I2
									Apttus_Config2__IsCustomPricing__c=true ensure that the record is not repriced further

				Delegated Pricing	1. Update PAV
									2. Update LineItem.Apttus_Config2__PricingStatus__c to 'Pending' (This Will make sure the LineItem Record is picked up for Repricing)
									3. applyConstraintRules
									4. Update Price for the cart with LineItem.Apttus_Config2__IsCustomPricing__c = false(This will ensure that Pricing is calculated based on PAV update)
				*/

				If(!isPricePending){
					List<Apttus_Config2__LineItem__c> lineItemUpdtList = new List<Apttus_Config2__LineItem__c>();
					for(Apttus_Config2__LineItem__c li :LineItemsSelector.newInstance().selectByProdConfId(new Set<Id>{quoteConfigurationId})){
						li.Apttus_Config2__PricingStatus__c = 'Pending';
						lineItemUpdtList.add(li);
					}

					if(lineItemUpdtList.size() > 0){
						ApplicationDatabase.getInstance().dmlUpdate(lineItemUpdtList);
					}

					updatePriceForCart(quoteConfigurationId,true);

					if(isCustomPrice){
						list<Apttus_Config2__LineItem__c>lineItemList = new list<Apttus_Config2__LineItem__c>();
						for(Apttus_Config2__LineItem__c li :LineItemsSelector.newInstance().selectByProdConfId(new Set<Id>{quoteConfigurationId})){
							li.Apttus_Config2__IsCustomPricing__c = true;
							if(compassPriceResponse != null && !keyFRSMap.isEmpty()){
								if(li.Apttus_Config2__LineType__c == APT_Constants.LABEL_LINE_TYPE_OPTION && keyFRSMap.containsKey(li.Compass_LineItem_Identifier__c)){
									Decimal priceValue = keyFRSMap.get(li.Compass_LineItem_Identifier__c).price;
									li.Apttus_Config2__BasePrice__c = priceValue;
									li.Apttus_Config2__NetPrice__c = priceValue;
									li.Apttus_Config2__AdjustedPrice__c = priceValue;
									li.Apttus_Config2__BaseExtendedPrice__c = priceValue;
									li.Apttus_Config2__DeltaPrice__c = priceValue;
									li.Apttus_Config2__ExtendedPrice__c = priceValue;
									li.Apttus_Config2__NetUnitPrice__c = priceValue;
								}
							}
							if(key1List != null && key1List.size() > 0 && compassPriceResponse != null){
								if(li.Apttus_Config2__LineType__c == APT_Constants.LABEL_LINE_TYPE_OPTION && key1List.contains(li.Compass_LineItem_Identifier__c)){

									lineItemCustom.add(li.id);
								}
							}
							lineItemList.add(li);
						}
						if(lineItemList.size() > 0){
							ApplicationDatabase.getInstance().dmlUpdate(lineItemList);
						}
					}
					else{
						applyConstraintRules(quoteConfigurationId,false);
					}
					if(!lineItemCustom.isEmpty()){

						Map<Id, Apttus_Config2__UsagePriceTier__c> uptMap = APT_UsagePriceTierSelector.newInstance().selectByLineItemId(lineItemCustom);
						Map<id,List<Apttus_Config2__UsagePriceTier__c>> liIDUptRecMap = new Map<id,List<Apttus_Config2__UsagePriceTier__c>>();
						for(Apttus_Config2__UsagePriceTier__c upt: uptMap.values()){
							if(keyServiceMap.containsKey(upt.Apttus_Config2__Dimension4Value__c) && upt.Apttus_Config2__Dimension4Value__c != '' ){

								if(upt.Apttus_Config2__Dimension4Value__c != '' && upt.Apttus_Config2__Dimension4Value__c.contains('KR')){
									upt.Apttus_Config2__AdjustmentAmount__c = keyServiceMap.get(upt.Apttus_Config2__Dimension4Value__c).kgRate;

								}
								if(upt.Apttus_Config2__Dimension4Value__c != '' && upt.Apttus_Config2__Dimension4Value__c.contains('BR')){
									upt.Apttus_Config2__AdjustmentAmount__c = keyServiceMap.get(upt.Apttus_Config2__Dimension4Value__c).basicRate;
								}
								uptList.add(upt);
							}
						}

						if(uptList.size() > 0){
							ApplicationDatabase.getInstance().dmlUpdate(uptList);
						}
					}

					if(quoteConfigurationId!=null){
						productConfig=ProductConfigurationSelector.newInstance().selectByConfigId(new set<ID>{(ID)quoteConfigurationId});
					}
					//getting the current proposal record
					if(productConfig != null){
						id proposalID = productConfig[0].Apttus_QPConfig__Proposald__c;
						currentProposal=APT_ProposalObjectsSelector.newInstance().selectByConfigIds(new set<ID>{(ID)proposalID});
					}
					//updating the proposal record for the field expiry date from the salected DSR
					if(currentProposal!=null){
						currentProposal[0].Apttus_Proposal__Proposal_Expiration_Date__c=selectedPSR.Quote_Validity_End_Date__c;
						proposalListUpdate.add(currentProposal[0]);
						ApplicationDatabase.getInstance().dmlUpdate(proposalListUpdate);
					}
				}
			}catch(Exception e){
				throw new AuraHandledException(e.getMessage());
			}
		}

			/* This method process cleanup invalid
			*  Param : product Configuration ID
			*/
		public static void cleanUpInvalidLineItems(Id quoteConfigurationId, Boolean onlyPriceStructeChange) {

			List<Apttus_Config2__LineItem__c> afterCRLiList = LineItemsSelector.newInstance().selectByProdConfId(new set<ID>{(ID)quoteConfigurationId});
			List <Apttus_Config2__AppliedRuleInfo__c> ruleInfos = APT_AppliedRuleInfoSelector.newInstance().selectByConfigId(new set<ID>{(ID)quoteConfigurationId});

			List<Apttus_Config2__LineItem__c> toDeleteLine = new List<Apttus_Config2__LineItem__c>();
			Set<String> allInvalidCR = new Set<String>();
			for (Apttus_Config2__AppliedRuleInfo__c rInfo : ruleInfos) {
				if(rInfo.Apttus_Config2__Invalid__c == true){
					String inValidCR = rInfo.Apttus_Config2__PrimaryLineNumber__c + ','+ rInfo.Apttus_Config2__ConstraintRuleId__c;
					allInvalidCR.add(inValidCR);
				}
			}
			for (Apttus_Config2__LineItem__c li : afterCRLiList) {
				if(li.Apttus_Config2__AddedByRuleInfo__c != null){
					String[] ruleInfos1 = (li.Apttus_Config2__AddedByRuleInfo__c).split(',');
					if(allInvalidCR.contains(ruleInfos1[0]+ ',' +ruleInfos1[1])) {
						toDeleteLine.add(li);
					}
				}
			}

			ApplicationDatabase.getInstance().dmlDelete(toDeleteLine);
		}

		/* This method sets the default Tier and the method is getting called from the LW components.
			* Param : Configguration ID and DSR record
		*/
		@AuraEnabled
		public static String setCustTierDefault(ID configId, Deal_Support_Request__c dsrRecord) {
			try {
				Boolean onlyPriceStructeChange = false;
				string resultValue = APT_Constants.APPC_CUSTOMER_TIER_DEFAULT;
				List<Apttus_Config2__ProductAttributeValue__c> pavListUpdate= new List<Apttus_Config2__ProductAttributeValue__c>();
				List<Id> configIDs = new List<Id>();
				configIDs.add(configId);

				Map<Id, Apttus_Config2__ProductAttributeValue__c> idPavMap = APT_ProductAttributeValuesSelector.newInstance().selectByconfigIDAndLineType(configIDs);
				Boolean isSetCartTier = false;
				for(Apttus_Config2__ProductAttributeValue__c pav: idPavMap.Values()){

					if(isSetCartTier == false) {
						isSetCartTier = true;
						resultValue =  resultValue+':' + pav.APT_Customer_Tier__c;

						if(pav.APT_Customer_Tier__c == dsrRecord.Approved_Tier__c && pav.APTS_Price_Structure__c !=  dsrRecord.Approved_Pricing_Structure__c) {
							onlyPriceStructeChange = true;
						}
					}

					pav.APT_Customer_Tier__c =  dsrRecord.Approved_Tier__c;
					//apply price structure only for speed products
					if( pav.APTS_Price_Structure__c != APT_Constants.ANYWHERE_PRICE_STRUCTURE)
					{
						pav.APTS_Price_Structure__c =  dsrRecord.Approved_Pricing_Structure__c;
					}
					pav.APT_RK_Code_AppliedYN__c=APT_Constants.OPTION_YES;
					pavListUpdate.add(pav);
				}

				if(pavListUpdate.size() > 0 ) {
					ApplicationDatabase.getInstance().dmlUpdate(pavListUpdate);
				}

				if(onlyPriceStructeChange == false) {
					List<Integer> primaryLines = new List<Integer>();

					//BRP: 20221116 - added below condition check only
					if(!Test.isRunningTest()){
					Apttus_CPQApi.CPQWebService.associateConstraintRules(configId, null);
					Apttus_CPQApi.CPQWebService.applyConstraintRules(configId, false);
					Apttus_CPQApi.CPQ.ConstraintResultDO constraintResult = Apttus_CPQApi.CPQWebService.getConstraintRuleResult(configId);

					if(constraintResult.NeedMoreProcessing)
					{
						Apttus_CPQApi.CPQWebService.applyConstraintRules(configId, false);
						Apttus_CPQApi.CPQ.ConstraintResultDO constraintResult2 = Apttus_CPQApi.CPQWebService.getConstraintRuleResult(configId);
						if(constraintResult2.NeedMoreProcessing)
						{
							Apttus_CPQApi.CPQWebService.applyConstraintRules(configId, false);
							cleanUpInvalidLineItems(configId, onlyPriceStructeChange);
						}
						else {
							cleanUpInvalidLineItems(configId, onlyPriceStructeChange);
						}
					}
					else {
						cleanUpInvalidLineItems(configId, onlyPriceStructeChange);
					}
					}
					//BRP: 20221116 - added below condition check only stop

				}
				else if(onlyPriceStructeChange) {

						List<Apttus_Config2__LineItem__c> liListUpdate= new List<Apttus_Config2__LineItem__c>();
						List<Apttus_Config2__LineItem__c> liList  = LineItemsSelector.newInstance().selectByProdConfId(new set<ID>{(ID)configId});
						for( Apttus_Config2__LineItem__c li : liList)
						{
							li.Apttus_Config2__PricingStatus__c = 'Pending';
							liListUpdate.add(li);
						}
						if(liListUpdate.size() > 0){
							ApplicationDatabase.getInstance().dmlUpdate(liListUpdate);
						}
				}
				return resultValue;
			}
			Catch(Exception ex) {
				system.debug('setCustTierDefault associateConstraintRules ex : ' + ex);
				return 'ERROR';
			}
		}
		/*
			* Resetting the customer Tier value from the LWC components
			* param : configuration ID and Customer Tier
			*/
		@AuraEnabled
		public static String reSetCustTier(String configId, String customerTier) {
			try {
				ID conID=(String) configId;
				List<Id> configIDs = new List<Id>();
				configIDs.add(conID);

				Map<Id, Apttus_Config2__ProductAttributeValue__c> idPavMap = APT_ProductAttributeValuesSelector.newInstance().selectByconfigIDAndLineType(configIDs);

				List<Apttus_Config2__ProductAttributeValue__c> pavListUpdate= new List<Apttus_Config2__ProductAttributeValue__c>();

				for(Apttus_Config2__ProductAttributeValue__c pav: idPavMap.Values()){
					pav.APT_Customer_Tier__c = customerTier;
					pav.APT_RK_Code_AppliedYN__c=APT_Constants.OPTION_YES;
					pavListUpdate.add(pav);
				}

				if(pavListUpdate.size() > 0 ) {
					ApplicationDatabase.getInstance().dmlUpdate(pavListUpdate);
				}

				Boolean constraintRuleResult = applyConstraintRules(configId, false);

				return 'CUST_TIER_RESET';
			}
			Catch(Exception ex) {
				system.debug('reSetCustTier associateConstraintRules ex : ' + ex);
				return 'ERROR';
			}
		}

		/* This method updated the Product Attribute value records with the DSR records when it is delegate pricing and with custom
			* response when it is custom pricing
			* Param : List of Product Attribute value, DSR record and Compass Response
			*/
		public static void UpdateProductAttributeValues(List<Apttus_Config2__ProductAttributeValue__c> productAttributeValuesListToUpdate,Deal_Support_Request__c selectedPSR, CompassWrapper.CompassPriceWrapper compassPriceResponse, Id quoteConfigurationId,CompassWrapper.features tcCoverFeature){
			List<Apttus_Config2__ProductAttributeValue__c> pavListUpdate= new List<Apttus_Config2__ProductAttributeValue__c>();
			Boolean liUpdateRequired = false;

			// updating all the product Attribute values for the proposal
			for(Apttus_Config2__ProductAttributeValue__c pav: productAttributeValuesListToUpdate){
				if(pav.APT_Customer_Tier__c == selectedPSR.Approved_Tier__c && liUpdateRequired == false)
				{
					liUpdateRequired = true;
				}
				pav.APT_Customer_Tier__c = selectedPSR.Approved_Tier__c;
				pav.Applied_PSR__c =  selectedPSR.id;
				if( pav.APTS_Price_Structure__c != APT_Constants.ANYWHERE_PRICE_STRUCTURE) {
					pav.APTS_Price_Structure__c = compassPriceResponse == null? selectedPSR.Approved_Pricing_Structure__c: compassPriceResponse.priceStructure;
				}
				pav.APT_RK_Code_AppliedYN__c=APT_Constants.OPTION_YES;
				if(selectedPSR.Approved_Event__c == APT_Constants.PSR_APPC_CUSTOM_PRICING) {
				//CI-772 Populate Product Attribute Value evaluated spend for delegated pricing and custom pricing scenario
				//Custom Pricing--Value comes from Compass I2 interface
					pav.APT_Min_Spend_Per_Annum__c = compassPriceResponse == null? selectedPSR.APT_Evaluated_Spend_per_annum__c:compassPriceResponse.evaluatedSpend;//New Logic to populate pav evaluated spend for custom pricing scenario
					pav.SAP_Weight_Rounding__c = compassPriceResponse == null? null : compassPriceResponse.weightRounding;
					pav.SAP_Cubic_Conversion_Factor__c = compassPriceResponse ==null? null: compassPriceResponse.cubicConvfac;
					pav.APT_Cubic_Status__c = compassPriceResponse ==null? null : compassPriceResponse.cubingFlag;
					//CI-834 Make the following change to populate the Minimun Transit cover Amount in the cart from I2 for custom pricing scenario
					if(tcCoverFeature!=null){
						Decimal amount=Decimal.valueOf(tcCoverFeature.totDeclaredCover);
						pav.APT_Min_Transit_Cover_Amount_Per_Article__c=amount;
						if(tcCoverFeature.pricePoint==APT_Constants.TC_PRICEPOINT_ALWAYS_ON) pav.APT_Transit_Cover_Type__c=APT_Constants.TC_COVER_TYPE_ALWAYS_ON;
						else pav.APT_Transit_Cover_Type__c=APT_Constants.TC_COVER_TYPE_ADHOC;
					}
				}
				//CI-772 Populate Product Attribute Value evaluated spend for delegated pricing and custom pricing scenario
				//Delegated Pricing--Value comes from PSR Evaluated Spend
				else if(selectedPSR.Approved_Event__c == APT_Constants.PSR_APPC_STANDARD_DELEGATED_PRICING){
					pav.APT_Min_Spend_Per_Annum__c = selectedPSR.APT_Evaluated_Spend_per_annum__c;
					//CI-834 Make the following change to populate the Minimun Transit cover Amount in the cart from PSR for Delegated pricing scenario
					pav.APT_Min_Transit_Cover_Amount_Per_Article__c=selectedPSR.Min_Transit_Cover_Amount_Per_Article__c;
					pav.APT_Transit_Cover_Type__c=selectedPSR.Transit_Cover_Type__c;
				}

				pavListUpdate.add(pav);
			}

			if(pavListUpdate.size() > 0){
				ApplicationDatabase.getInstance().dmlUpdate(pavListUpdate);
			}
		}
		/* This method does the repricing of the Cart
			* param : product Configuration ID
			*/
		public static boolean updatePriceForCart(ID quoteConfigurationId, Boolean isMoreProcessing) {
			Apttus_Config2__ProductConfiguration__c  updateConfig = new Apttus_Config2__ProductConfiguration__c();
			updateConfig.Id = quoteConfigurationId;
			Boolean IsPricePendingCheck=false;
			//updateConfig.Apttus_Config2__Status__c = 'Saved'; //to save the respected cart from backend
			updateConfig.Apttus_Config2__IsPricePending__c = true;
			ApplicationDatabase.getInstance().dmlUpdate(new List<Apttus_Config2__ProductConfiguration__c>{updateConfig});

			// Apttus webservice method to reprice the cart
			if(!Test.isRunningTest()){
				Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
				objUpdatePriceRequestDO.CartId = quoteConfigurationId;
				Apttus_CpqApi.CPQ.UpdatePriceResponseDO result = Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
				IsPricePendingCheck= result.IsPricePending;
				if(IsPricePendingCheck){
					result=Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
					IsPricePendingCheck= result.IsPricePending;
				}
			}
			return IsPricePendingCheck;
		}

		/**
		 * Back button navigates back to cart summary page of the shopping cart
		 * Reason for this solution is due to Salesforce technical Limitation:
		 *  1.PageReference and lighting/navigation service library are not supported in Lightning out framework
		 *  2.Javascript native navigation functions(e.g. history.back() and Location.href()) does not work correctly in Apttus shopping cart's lightning experience
		 * Solution: VF page action:function to call apex method directly to return PageReference object and perform navigation
		 * @return PageReference
		 */
		public static PageReference goBack(){
			// navigate to the url paramter, passed in from the VF page
			string backURL = Apexpages.currentPage().getParameters().get('url');
			return new PageReference(backURL);
		}

		/**
		 * This method calls the constraint rule when the repricing is done after the delegate or custom pricing is completed
		 * param : product Configuration ID
		 * param : isMoreProcessing, flag to extend apply constraint rule's more processing
		 */
		public static boolean applyConstraintRules(ID quoteConfigurationId, Boolean isMoreProcessing) {
			List<Integer> primaryLines = new List<Integer>();
			Boolean returnReuslt = false;
			if(!Test.isRunningTest()){
				Apttus_CPQApi.CPQWebService.associateConstraintRules(quoteConfigurationId, primaryLines);
				Apttus_CPQApi.CPQWebService.applyConstraintRules(quoteConfigurationId, false);
				Apttus_CPQApi.CPQ.ConstraintResultDO constraintResult = Apttus_CPQApi.CPQWebService.getConstraintRuleResult(quoteConfigurationId);

				if(constraintResult.NeedMoreProcessing || isMoreProcessing)
				{
					Apttus_CPQApi.CPQWebService.applyConstraintRules(quoteConfigurationId, false);
					constraintResult = Apttus_CPQApi.CPQWebService.getConstraintRuleResult(quoteConfigurationId);
				}
				returnReuslt = constraintResult.HasPendingError;
			}
			return returnReuslt;
		}
			/**
		 * Compass API request wrapper class
		 */
		public class HttpRequestWrapper{
			Public string quoteId{ get; set; }
			Public string customerId{ get; set; }
			Public string ratingModel{ get; set; }

			public HttpRequestWrapper(string quoteIdInput,string customerIdInput,string ratingModelInput){
				quoteId = quoteIdInput;
				customerId = customerIdInput;
				ratingModel = ratingModelInput;
			}
		}
	}