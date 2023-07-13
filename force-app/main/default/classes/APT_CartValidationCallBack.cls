/*************************************************************************************************************
* Class to Validate the APTPS_Constraint_Rules controller where all the Constraint Rules related to the Quote
* are validated and 
* @author Raviteja Epuri
* @CreatedDate 21/01/2016

* Last Modified By -  Mausam Padhiyar
* Description - APOST - 646
* Last Modified Date -  22nd Feb, 2016

* Last Modified By - Mausam Padhiyar
* Last Modified Date - 22nd Sept, 2016 | 1387 : Validation for approvals for ren

* Last Modified By - Mausam Padhiyar
* Last Modified Date - 3rd Nov, 2016 | Validate Approvals

* Last Modified By - Mausam Padhiyar
* Last Modified Date - 12th Dec, 2016 | 1869 | Match Usage Price Tier with Price Matrix Entry records.

* Last Modified By - Mausam Padhiyar
* Last Modified Date - 12th Jan, 2017 | 1825 - Use Offline Rates

* Last Modified By - Mahesh Patel
* Last Modified Date - 21st Oct, 2020 | validateAttributesOfLineItems for startrack

* Last Modified By - Darshan Chauhan
* Last Modified Date - 18th June, 2021 | validating for revenue by billing account

* Last Modified By - Madhuri Awasthi
* Last Modified Date - 27th Sep, 2021 | REQ2594537 (Allow StarTrack Standard Delegation Approval Process for Intermediaries for Price Adjustment)
Ken McGuire 2023.04.19 Proposal field migration to opportunity
***************************************************************************************************************/
global with sharing class APT_CartValidationCallBack implements Apttus_Config2.CustomClass.IValidationCallback2 {

	private static final String CALLER_PAGE_CARTDETAILVIEW = 'CartDetailView';

	/**
		* Callback to validate the line items in the cart
		* @param cart the cart object to validate
		* @return the validation result
	 */
	global Apttus_Config2.CustomClass.ValidationResult validateCart(Apttus_Config2.ProductConfiguration cart) {
		//system.debug('*** validation call back > start ***');
		Apttus_Config2.CustomClass.ValidationResult result = new Apttus_Config2.CustomClass.ValidationResult(true);
		try {
			Map<string,Network__c> mapntwkPostCodes =new map<string,Network__c>();
			list <Apttus_Config2.LineItem> allLines = cart.getLineItems();
			list<Apttus_Config2__LineItem__c> allLineItems = getLineItems(allLines);
			//set<string> setProducts = new set<string>();

			set<Id> setLPidVal= new set<Id>();

			Map<String, String> mapValues = Apttus_Config2.RuntimeContext.getParameters();
			//System.debug('*** mapValues ***'+mapValues);
			//String itenNums = mapValues.get('contextLineNumbers');
			String PageAction = mapValues.get('pageAction');
			System.debug('*** PageAction ***'+PageAction);
			//System.debug('*** itenNums ***'+itenNums);

			//system.debug('*** page ***'+ApexPages.currentPage());

			//validation call back should run only for Finalize button
			//tested for both - Angular and Classic
			//APOST-1078
			if(!String.isEmpty(PageAction) && PageAction != 'Finalize' && PageAction != 'SubmitForApproval') {
				//system.debug('*** PageAction > inside ***'+PageAction);
				result.isSuccess =  true;
				return result;
			}


			/**
				Do not execute validaitons except from 'Shopping Cart Page'
				Idea is to avoid validation when we click on 'Go To Pricing' button
			 */

			/*
			String flowName = ApexPages.currentPage().getParameters().get('flow');
			system.debug('*** flowName ****'+flowName);
			if(flowName != 'ngFlow'){
				String callerPageParam = ApexPages.currentPage().getParameters().get('callerPage');
				if(callerPageParam != null && callerPageParam != CALLER_PAGE_CARTDETAILVIEW) {
					result.isSuccess =  true;
					return result;
				}
			}
			*/


			//won't work with ng-cpq - commented temporarily
			/*
			String callerPageParam = ApexPages.currentPage().getParameters().get('callerPage');
			if(callerPageParam != null && callerPageParam != CALLER_PAGE_CARTDETAILVIEW) {
				result.isSuccess =  true;
				return result;
			}
			*/


			Id configurationId;
			if(allLineItems != null) {
				configurationId = allLineItems[0].Apttus_Config2__ConfigurationId__c;
			}

			Apttus_Config2__ProductConfiguration__c prodConfig;
			String selectedLPQuote;
			//ST-4725 added field Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c
			if(!String.isEmpty(configurationId)){
				prodConfig = [SELECT id, Apttus_QPConfig__Proposald__c, Apttus_QPConfig__Proposald__r.APT_Selected_LP__c,
						Apttus_Config2__Status__c, Apttus_QPConfig__Proposald__r.recordType.Name,
						APT_Validate_Approvals__c, APT_Config_Change__c,
						Apttus_QPConfig__Proposald__r.APT_Use_Offline_Rates__c, Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c
				FROM Apttus_Config2__ProductConfiguration__c
				WHERE Id = :configurationId limit 1];
			}

			Apttus__APTS_Admin__c admin = [SELECT Id, name, Apttus__Value__c FROM Apttus__APTS_Admin__c WHERE Name = :APT_Constants.ADMIN_LARGE_CART_THRESHOLD];
			decimal largeCartThresholdLimit = 0;
			if(admin != null && String.isNotBlank(admin.Apttus__Value__c)) {
				largeCartThresholdLimit = decimal.valueOf(admin.Apttus__Value__c);
			}

			decimal lineItemCount = 0;
			if(allLineItems != null && allLineItems.size() > 0) {
				lineItemCount = allLineItems.size();
			}



			//avoid SOQL in validation call back
			//LIst<Apttus_Config2__LineItem__c> lstLI =[select id,Apttus_Config2__ConfigurationId__c,Apttus_Config2__ProductId__r.APT_Sync_with_Opportunity__c,Apttus_Config2__LineType__c,Apttus_Config2__IsPrimaryLine__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c=:configurationId AND Apttus_Config2__ProductId__r.APT_Sync_with_Opportunity__c=True AND Apttus_Config2__LineType__c!='Option' AND Apttus_Config2__IsPrimaryLine__c=True];
			List<Apttus_Config2__LineItem__c> lstLI = new List<Apttus_Config2__LineItem__c>();

			// Query opportunity product line items
			list<APT_Opportunity_Product_Line_Item__c> lstOPLI=[SELECT id,APT_Revenue_Start_Date__c,APT_Revenue_End_Date__c,
					APT_Unit_Sales_Price__c,APT_Quantity__c
			FROM APT_Opportunity_Product_Line_Item__c
			WHERE APT_Quote_Proposal__c=:prodConfig.Apttus_QPConfig__Proposald__c]; //CR-148/13 Added fields: APT_Unit_Sales_Price__c, APT_Quantity__c

			//Mausam Padhiyar : APOST-646 : 22nd Feb, 2016 : Start

			String selectedCategory;
			decimal iTotalMinQuantity = 0;
			//Mausam Padhiyar : APOST-646 : 22nd Feb, 2016 : End


			set<Id> setLineItems = new set<Id>();
			Map<string,set<string>> mapProductFields = new  Map<string,set<string>>();
			Map<string,List<Apttus_Config2__LineItem__c>> mapCodeLineItem = new  Map<string,list<Apttus_Config2__LineItem__c>>();
			Map<string,List<Apttus_Config2__ProductAttributeValue__c>> mapCodePAV = new  Map<string,list<Apttus_Config2__ProductAttributeValue__c>>();
			Map<string,string> mapProductCode = new  Map<string,string>();
			Map<string,set<string>> mapeParcelfeildValue = new  Map<string,set<string>>();
			//defect 1426
			Map<ID,string> mapAgrIDToReason = new Map<ID,string>();
			set<Id> setContractID = new set<Id>();

			Integer digitalInternationalBundlesCount = 0;
			Integer nonDigitalInternationalBundlesCount = 0;
			Integer InternationalPCMSBundlesCount = 0;
			Integer InternationalPCMSBundlesincAirmailLettersCount = 0;
			Integer InternationalAirmaillettersCount = 0;
			Integer InternationalRKcodemandatory = 0;
			Integer InternationalLegacyDigitalDelete = 0;



			List<String> approvalRequiredLineItems = new List<String>();

			for(APT_R2TValidationFields__c cs: APT_R2TValidationFields__c.getall().Values()){
				if(!String.isEmpty(cs.APT_Unique_Fields__c)){
					for(string s: cs.APT_Unique_Fields__c.split(APT_Constants.SEPERATOR_COMMA)){
						if(mapProductFields.containsKey(cs.APT_Product_Code__c)) {
							mapProductFields.get(cs.APT_Product_Code__c).add(s);
						}else {
							mapProductFields.put(cs.APT_Product_Code__c, new set<string> { s });
						}
					}
				}
			}

			//1869
			set<Id> setPriceListItemId = new set<Id>();
			set<Id> setLineItemId = new set<Id>();
			map<Id, Apttus_Config2__LineItem__c> mapLineItem = new map<Id, Apttus_Config2__LineItem__c>();
			set<String> setValidKey = new set<String>();
			//1869


			//Defect 1426
			for(Apttus_Config2__LineItem__c lineItem : allLineItems)
			{


				if(null != lineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_Contract_Id__c)
				{
					setContractID.add(lineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_Contract_Id__c);
				}

				//1869
				if(lineItem.Apttus_Config2__PriceListItemId__c != null) {
					setPriceListItemId.add(lineItem.Apttus_Config2__PriceListItemId__c);
					setValidKey.add(lineItem.id + APT_Constants.SEPERATOR_SIMILARITY + lineItem.Apttus_Config2__PriceListItemId__c);
				}

				setLineItemId.add(lineItem.Id);
				mapLineItem.put(lineItem.Id, lineItem);
				//1869
			}

			//1869
			//usage price tier records
			map<String, Integer> mapUsagePriceTierCount = new map<String, Integer>();
			Integer iUsagePriceTierCount = 1;
			set<Id> setValidLineItemIds = new set<Id>();
			for(Apttus_Config2__UsagePriceTier__c upt : [SELECT Id,Apttus_Config2__LineItemId__c, Apttus_Config2__LineItemId__r.Apttus_Config2__PriceListItemId__c,
					Apttus_Config2__LineItemId__r.Apttus_Config2__PrimaryLineNumber__c
			FROM Apttus_Config2__UsagePriceTier__c
			WHERE Apttus_Config2__LineItemId__c IN :setLineItemId]) {

				setValidLineItemIds.add(upt.Apttus_Config2__LineItemId__c);
				iUsagePriceTierCount = mapUsagePriceTierCount.get(upt.Apttus_Config2__LineItemId__c + APT_Constants.SEPERATOR_SIMILARITY + upt.Apttus_Config2__LineItemId__r.Apttus_Config2__PriceListItemId__c);
				if(iUsagePriceTierCount != null){
					iUsagePriceTierCount++;
				} else {
					iUsagePriceTierCount = 1;
				}
				mapUsagePriceTierCount.put(upt.Apttus_Config2__LineItemId__c + APT_Constants.SEPERATOR_SIMILARITY + upt.Apttus_Config2__LineItemId__r.Apttus_Config2__PriceListItemId__c, iUsagePriceTierCount);
			}

			//price matrix
			map<String, Integer> mapPriceMatrixEntryCount = new map<String, Integer>();
			set<Id> setValidPriceListItemIds = new set<Id>();
			for(Apttus_Config2__PriceMatrix__c pm : [SELECT Id, Apttus_Config2__NumberOfEntries__c, Apttus_Config2__PriceListItemId__c
			FROM Apttus_Config2__PriceMatrix__c
			WHERE Apttus_Config2__PriceListItemId__c IN :setPriceListItemId]) {

				if(pm.Apttus_Config2__NumberOfEntries__c != null) {
					setValidPriceListItemIds.add(pm.Apttus_Config2__PriceListItemId__c);
					mapPriceMatrixEntryCount.put(pm.Apttus_Config2__PriceListItemId__c, Integer.valueOf(pm.Apttus_Config2__NumberOfEntries__c));
				}

			}

			integer iPriceMatrixEntryCount = 0;
			for(Id liId : setValidLineItemIds) {
				iUsagePriceTierCount = 0;
				for(Id pliId : setValidPriceListItemIds) {
					iPriceMatrixEntryCount = 0;
					system.debug('*** liId ***'+liId + '*** pliId ***'+ pliId);

					if(mapUsagePriceTierCount.get(liId + APT_Constants.SEPERATOR_SIMILARITY + pliid) != null && mapPriceMatrixEntryCount.get(pliId) != null) {
						iUsagePriceTierCount = mapUsagePriceTierCount.get(liId + APT_Constants.SEPERATOR_SIMILARITY + pliid);
						iPriceMatrixEntryCount = mapPriceMatrixEntryCount.get(pliId);
						system.debug('*** iPriceMatrixEntryCount ***'+iPriceMatrixEntryCount);
						system.debug('*** iUsagePriceTierCount ***'+iUsagePriceTierCount);
						// Condition : (mapLineItem.get(liId).APT_Rate_Card_Key__c==null || mapLineItem.get(liId).APT_Rate_Card_Key__c=='') Added by Apttus Support || Case :00209154  || Date : 27022017
						if(iUsagePriceTierCount != iPriceMatrixEntryCount && (mapLineItem.get(liId).APT_Rate_Card_Key__c==null || mapLineItem.get(liId).APT_Rate_Card_Key__c=='')) {
							result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, Label.APT_Cart_Usage_Price_Tier_Mismatch_Error + APT_Constants.SEPERATOR_SPACE + mapLineItem.get(liId).Apttus_Config2__LineNumber__c));
							result.isSuccess =  false;
						}
					}
				}
			}


			/**CR-148/13 Start
			 * Added by Daric Dava
			 */
			// Retrieve related proposal based on proposal configuraton record

			// ST-4725 added field Apttus_Proposal__Opportunity__r.IsStartrackProposal__c, APT_Tier_Adjustment_Type__c
			List<Apttus_Proposal__Proposal__c> lstProposal =
			[Select id,RecordType.name, APT_Revenue_Type__c, APT_Contract_Id__c,
					Apttus_Proposal__Opportunity__r.IsStartrackProposal__c,
					APT_Tier_Adjustment_Type__c From Apttus_Proposal__Proposal__c
			where id = :prodConfig.Apttus_QPConfig__Proposald__c ];
			Decimal totPrice = 0;
			Decimal opptySubTotalAmount = 0;
			String quoteRecordType;
			String revenueType;

			Set<Id> opptyIds = new Set<Id>();
			List<Apttus__APTS_Agreement__c> originalContract;
			id accountId;
			Decimal opptyTotalAmount = 0;
			Decimal opptyTotaRevenueDecrease = 0;

			//get record type and revenue type
			if(lstProposal.size()>0){
				quoteRecordType = lstProposal[0].RecordType.name;
				revenueType = lstProposal[0].APT_Revenue_Type__c;

				// Pull original contract from current amendement proposal
				originalContract = [select Id, Apttus__Agreement_Number__c From Apttus__APTS_Agreement__c where Id =: lstProposal[0].APT_Contract_Id__c Limit 1];

				// If quote is amendment record type perform increase and decrease validation
				if(quoteRecordType==APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE &&
						originalContract.size()==1){

					// Pull main organisation/account from current amendement proposal
					accountId = [Select Id, Apttus_Proposal__Account__c from Apttus_Proposal__Proposal__c where Id =: prodConfig.Apttus_QPConfig__Proposald__c limit 1].Apttus_Proposal__Account__c;

					// Calculate total price of all opportunity product line items
					if(lstOPLI.size()>0){
						//get total price
						for(APT_Opportunity_Product_Line_Item__c opli:lstOPLI){
							opli.APT_TotalPrice__c= opli.APT_Unit_Sales_Price__c * opli.APT_Quantity__c;
							totPrice = totPrice + opli.APT_TotalPrice__c;
						}
					}
					// Fetch all Contract where Contract Step = "Amendement" AND Contract Step Status = "Superseded"
					// This contracts represent the original closed won contracts
					for(Apttus__APTS_Agreement__c contract : [SELECT Id, Apttus__Related_Opportunity__c
					FROM Apttus__APTS_Agreement__c
					WHERE
							Apttus__Account__c =: accountId AND
							Apttus__Agreement_Number__c =: originalContract[0].Apttus__Agreement_Number__c AND
							(
									(Apttus__Status__c =: APT_AmendRenewController.SUPERSEDED_STATUS AND
									Apttus__Status_Category__c =: APT_AmendRenewController.AMENDED_STATUS_CATEGORY) OR
									Id =: lstProposal[0].APT_Contract_Id__c
							)]){

						opptyIds.add(contract.Apttus__Related_Opportunity__c);

					}

					// Calculate total opportunity revenue from previous contracts
					if(opptyIds.size() > 0){
						for(Opportunity oppty: [Select Id, Amount, APT_Revenue_Decrease__c From Opportunity where Id in:  opptyIds ]){
							// Total increase revenue amount
							if(oppty.Amount > 0 && oppty.Amount != null){
								opptyTotalAmount = opptyTotalAmount + oppty.Amount;
							}
							// Total decrease revenue amount
							if(oppty.APT_Revenue_Decrease__c > 0 && oppty.APT_Revenue_Decrease__c != null && oppty.APT_Revenue_Decrease__c > opptyTotaRevenueDecrease ){
								opptyTotaRevenueDecrease = oppty.APT_Revenue_Decrease__c;
							}
						}
					}

					// Actual current opportunity amount is total opportunity amount less decrease revenue amount
					opptySubTotalAmount = opptyTotalAmount - opptyTotaRevenueDecrease;

					system.debug('Total Opp Amount:' + opptySubTotalAmount);
					system.debug('Total Opp Amount:' + totPrice);
				}
				//CR-148/13 End


				//Begin Added by Naresh for Winback  STP-6324

				if(String.isNotBlank(lstProposal[0].Apttus_Proposal__Opportunity__r.IsStartrackProposal__c) && (lstProposal[0].Apttus_Proposal__Opportunity__r.IsStartrackProposal__c).equalsIgnoreCase('Yes') ){
					set<Id> productId = new set<Id>();
					if(String.isNotBlank(lstProposal[0].APT_Tier_Adjustment_Type__c) ){
						List<Id> cardtProdId = new List<Id>();
						List<AggregateResult> revenueBillingAccList = new List<AggregateResult>();
						if(prodConfig.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c != null){
							//Adding Customer__r.Sales_Segment__c to check the sales team
							revenueBillingAccList = [select Customer__r.Sales_Segment__c,MAX(APT_Last_Rev_Realized__c) LastRev,Product__c product from Revenue_by_Billing_Account__c
							WHERE Customer__c =: prodConfig.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Account__c GROUP BY Customer__r.Sales_Segment__c,Product__c];

							if(!revenueBillingAccList.isEmpty() && revenueBillingAccList.size() > 0){
								//logic for checkign cart products
								List<Apttus_Config2__LineItem__c> allLineItemswb = [SELECT Id, Apttus_Config2__ProductId__c, APT_StarTrack_Proposal__c, APT_Approval_Required_ST__c,
										Apttus_CQApprov__Approval_Status__c, Apttus_Config2__LineType__c
								FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c =: configurationId];

								for(Apttus_Config2__LineItem__c lineItem : allLineItemswb){
									productId.add(lineItem.Apttus_Config2__ProductId__c);
								}
								for(AggregateResult rba : revenueBillingAccList ){
									if(productId.contains(String.valueOf(rba.get('product')))){
										if(rba.get('Sales_Segment__c') == 'Intermediaries' || rba.get('Sales_Segment__c') == 'Intermediaries - Not Active'){
											result.isSuccess =  true;
										}
										else {
											Date revRealizedDate = (Date)rba.get('LastRev');
											system.debug('days between ** '+revRealizedDate.daysBetween(system.today()));
											if(revRealizedDate.daysBetween(system.today()) < 365){
												result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'This opportunity is not for New Business/Cross Sell/Winback, to request standard pricing delegation, contact pricing support team via Deal Support Request (DSR)'));
												result.isSuccess =  false;
											}
										}
									}
								}
							}
						}
					}
				}

				//End Added by Naresh for Winback  STP-6324


			}// End If


			// Create map of amendement/revew agreement and reason
			for(Apttus__APTS_Agreement__c agrObj : [select ID,APT_SelectedContractAmendRenewCategory__c from Apttus__APTS_Agreement__c where ID IN:setContractID])
			{
				mapAgrIDToReason.put(agrObj.ID, agrObj.APT_SelectedContractAmendRenewCategory__c);
			}

			//System.debug('allLineItems:'+allLineItems);
			APT_R2T_System_Properties__c sysPropObj = APT_R2T_System_Properties__c.getInstance();
			set<string> uniqueProducts =new set<string>();
			for(Apttus_Config2__LineItem__c lineItem : allLineItems) {
				//   system.debug('lineItem.APT_Product_Code__c--------->'+lineItem.APT_Product_Code__c);
				system.debug('*** is opc deleted? ***'+lineItem.APT_Is_OPC_deleted__c);
				if(lineItem.APT_Is_OPC_deleted__c == false && (!uniqueProducts.contains(lineItem.APT_Product_Name__c) && lineItem.APT_Product_Name__c!=null) && ((lineItem.Apttus_Config2__LineType__c ==APT_Constants.LABEL_LINE_TYPE_OPTION &&  lineItem.Apttus_Config2__OptionId__r.APT_Sync_with_Opportunity__c) || (lineItem.Apttus_Config2__LineType__c !=APT_Constants.LABEL_LINE_TYPE_OPTION &&  lineItem.Apttus_Config2__ProductId__r.APT_Sync_with_Opportunity__c))){
					uniqueProducts.add(lineItem.APT_Product_Name__c);
				}
				//this section to iterate on All Line Items
				system.debug('***************' + lineItem.Apttus_Config2__OptionId__r.APT_Sync_with_Opportunity__c);
				system.debug('***************' + lineItem.Apttus_Config2__ProductId__r.APT_Sync_with_Opportunity__c);
				if(lineItem.Apttus_Config2__ProductId__r.APT_Sync_with_Opportunity__c || lineItem.Apttus_Config2__OptionId__r.APT_Sync_with_Opportunity__c ) {
					lstLI.add(lineItem);

				}

				//This section to iterate only on Primary Line Items
				if(lineItem.Apttus_Config2__IsPrimaryLine__c
						&& APT_Constants.LINE_TYPE_PRODUCT_SERVICE.equalsIgnoreCase(lineItem.Apttus_Config2__LineType__c)){
					//setProducts.add(lineItem.Apttus_Config2__ProductId__r.Name);

					/*
					System.debug('lineItem.APT_Competitors__c-->' + lineItem.APT_Competitors__c);
					 System.debug('lineItem.APT_Pricing_Reason__c-->' + lineItem.APT_Pricing_Reason__c);
					 System.debug('lineItem.APT_Pricing_Reason__c-->' +(APT_Constants.LABEL_APPROVAL_REQUIRED).equalsIgnoreCase(lineItem.Apttus_CQApprov__Approval_Status__c));
					 System.debug('lineItem.APT_Pricing_Reason__c-->' + (!String.isEmpty(lineItem.APT_Pricing_Reason__c)
							   || !String.isEmpty(lineItem.APT_Competitors__c)));
					 System.debug('lineItem.APT_Pricing_Reason__c-->' + ((APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE).equalsIgnoreCase(lineItem.Apttus_Config2__ProductId__r.ProductCode)
							   || (APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD).equalsIgnoreCase(lineItem.Apttus_Config2__ProductId__r.ProductCode)
							   || (APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS).equalsIgnoreCase(lineItem.Apttus_Config2__ProductId__r.ProductCode)));
					 System.debug('lineItem.Apttus_CQApprov__Approval_Status__c-->' + lineItem.Apttus_CQApprov__Approval_Status__c);
					 */

					//Pricing reason and competitors are required for Approval request only for Eparcel and International products only.


					if((APT_Constants.LABEL_APPROVAL_REQUIRED).equalsIgnoreCase(lineItem.Apttus_CQApprov__Approval_Status__c)
							&& (String.isEmpty(lineItem.APT_Pricing_Reason__c)
							|| String.isEmpty(lineItem.APT_Competitors__c))
							&& (sysPropObj.APT_Cart_Validation_products__c.containsIgnoreCase(';'+lineItem.Apttus_Config2__ProductId__r.ProductCode+';'))
							&& (lineItem.APT_Approval_Required__c || lineItem.APT_Approval_Required2__c || lineItem.APT_Ar4__c)) {

						//approvalRequiredLineItems.add(lineItem.Apttus_Config2__ProductId__r.Name);
						//1387
						//1825 - Use Offline Rates
						if((prodConfig != null && String.isNOTBlank(PageAction) && String.isNotBlank(prodConfig.Apttus_QPConfig__Proposald__r.recordType.Name) && !prodConfig.Apttus_QPConfig__Proposald__r.recordType.Name.equalsIgnoreCase(APT_Constants.RECORD_TYPE_RENEWAL_QUOTE) && String.isBlank(lineItem.APT_Rate_Card_Key__c)) || (prodConfig != null && String.isNotBlank(prodConfig.Apttus_QPConfig__Proposald__r.recordType.Name) && (prodConfig.Apttus_QPConfig__Proposald__r.recordType.Name.equalsIgnoreCase(APT_Constants.RECORD_TYPE_RENEWAL_QUOTE) && lineItem.Apttus_Config2__AttributeValueId__r.Revenue_Committment__c == 'Above 50,000'))) {
							approvalRequiredLineItems.add(lineItem.Apttus_Config2__ProductId__r.ProductCode);
						}
						//1387

					}
					//System.debug('approvalRequiredLineItems-->' + approvalRequiredLineItems);
				}

				if(lineItem.Apttus_Config2__IsPrimaryLine__c && mapProductFields.containsKey(lineItem.Apttus_Config2__ProductId__r.ProductCode)){
					setLineItems.add(lineItem.Id);
					mapProductCode.put(lineItem.Apttus_Config2__ProductId__r.ProductCode,lineItem.Apttus_Config2__ProductId__r.Name);
					if(mapCodeLineItem.containsKey(lineItem.Apttus_Config2__ProductId__r.ProductCode)) {
						mapCodeLineItem.get(lineItem.Apttus_Config2__ProductId__r.ProductCode).add(lineItem);
					}else {
						mapCodeLineItem.put(lineItem.Apttus_Config2__ProductId__r.ProductCode, new List<Apttus_Config2__LineItem__c> { lineItem });
					}
				}



				//HJ : APOST-667 : 23 May, 2016
				if((!String.isEmpty(lineItem.Apttus_Config2__ProductId__r.ProductCode) && !String.isEmpty(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE) && lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE) ) && lineItem.Apttus_Config2__IsPrimaryLine__c && String.isEmpty(lineItem.Apttus_Config2__OptionId__c)) {

					if(lineItem.Apttus_Config2__AttributeValueId__r.APT_eParcel_Lodgment__c){
						digitalInternationalBundlesCount++;
					} else if(lineItem.Apttus_Config2__AttributeValueId__r.APT_International_Letters__c){
						nonDigitalInternationalBundlesCount++;
					} else{
						result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select Digital or non Digital attribute for International Bundle.'));
						result.isSuccess =  false;
					}

				}


				//New International Bundles implimentation(Start)
				if((!String.isEmpty(lineItem.Apttus_Config2__ProductId__r.ProductCode) && !String.isEmpty(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE) && lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE) ) && lineItem.Apttus_Config2__IsPrimaryLine__c && String.isEmpty(lineItem.Apttus_Config2__OptionId__c)) {

					InternationalPCMSBundlesCount++;


				}else if((!String.isEmpty(lineItem.Apttus_Config2__ProductId__r.ProductCode) && !String.isEmpty(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL) && lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL) ) && lineItem.Apttus_Config2__IsPrimaryLine__c && String.isEmpty(lineItem.Apttus_Config2__OptionId__c)) {

					InternationalPCMSBundlesincAirmailLettersCount++;


				}else if((!String.isEmpty(lineItem.Apttus_Config2__ProductId__r.ProductCode) && !String.isEmpty(APT_Constants.PRODUCT_CODE_INTERNATIONAL_AIRMAIL_LETTERS) && lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_AIRMAIL_LETTERS) ) && lineItem.Apttus_Config2__IsPrimaryLine__c && String.isEmpty(lineItem.Apttus_Config2__OptionId__c)) {

					InternationalAirmaillettersCount++;

				}

				system.debug('---->lineItem.Apttus_Config2__ConfigurationId__r.APT_Created_On__c' +lineItem.Apttus_Config2__ConfigurationId__r.APT_Created_On__c);
				system.debug('---->lineItem.APT_Is_Band_Changed__c' +lineItem.APT_Is_Band_Changed__c);
				//system.debug('---->lineItem.APT_For_Price_Change__c' +lineItem.APT_For_Price_Change__c);
				/*if(!String.isEmpty(lineItem.Apttus_Config2__ProductId__r.ProductCode)
				   &&
				   (lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE)
					  ||
				 lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL)
					  ||
				  lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE))
				   &&
				 ((lineItem.Apttus_Config2__ConfigurationId__r.APT_Created_On__c.equalsIgnoreCase(APT_Constants.RECORD_TYPE_RENEWAL_QUOTE)
				   &&
				   !(lineItem.APT_New_Renew__c))
				  ||
				  (lineItem.Apttus_Config2__ConfigurationId__r.APT_Created_On__c.equalsIgnoreCase(APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE)
				   &&
				 lineItem.APT_Is_Band_Changed__c)) &&
				   String.isBlank(lineItem.APT_Rate_Card_Key__c)
				 && lineItem.Apttus_Config2__IsPrimaryLine__c
				   && String.isEmpty(lineItem.Apttus_Config2__OptionId__c)){

				  InternationalRKcodemandatory++;

				  }*/

				if(!String.isEmpty(lineItem.Apttus_Config2__ProductId__r.ProductCode) && lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE) &&
						lineItem.Apttus_Config2__AttributeValueId__r.APT_eParcel_Lodgment__c && lineItem.Apttus_Config2__ConfigurationId__r.APT_Is_Cloned__c &&
						lineItem.Apttus_Config2__IsPrimaryLine__c && String.isEmpty(lineItem.Apttus_Config2__OptionId__c)){

					InternationalLegacyDigitalDelete++;

				}

				// Condition update by Adrian Recio
				// 30/7/2018
				// Get map condition move to second level to make sure a value exist before performing value check
				//Defect 1426
				if(null != lineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_Contract_Id__c &&
						lineItem.Apttus_Config2__IsPrimaryLine__c &&
						(lineItem.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD ||
								lineItem.Apttus_Config2__ProductId__r.ProductCode == APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS) &&
						lineItem.APT_Added_LP__c == false && lineItem.Apttus_Config2__LineType__c == APT_Constants.LINE_TYPE_PRODUCT_SERVICE) {
					string mapReasonVal = mapAgrIDToReason.get(lineItem.Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_Contract_Id__c);
					if(mapReasonVal!= null && mapReasonVal!='') {
						if (mapReasonVal.equalsIgnoreCase(APT_Constants.AGREEMENT_AMEND_RENEW_CATEGORY_ZONE_CHANGE)) {
							result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please add Lodgement Point for '+lineItem.Apttus_Config2__ProductId__r.Name+' product to finalize'));
							result.isSuccess =  false;
						}
					}
				}


				//Mausam Padhiyar : APOST-646 : 22nd Feb, 2016 : Start
				if(((!String.isEmpty(lineItem.Apttus_Config2__ProductId__r.ProductCode) && !String.isEmpty(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) && lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD))
						|| (!String.isEmpty(lineItem.Apttus_Config2__ProductId__r.ProductCode) && !String.isEmpty(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS) && lineItem.Apttus_Config2__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)))
						&& lineItem.Apttus_Config2__IsPrimaryLine__c && String.isEmpty(lineItem.Apttus_Config2__OptionId__c)) {
					if(!String.isEmpty(lineItem.Apttus_Config2__AttributeValueId__r.Category__c)) {
						selectedCategory = lineItem.Apttus_Config2__AttributeValueId__r.Category__c;
					}

					if(lineItem.Apttus_Config2__AttributeValueId__r.APT_Minimum_Quantity__c != null) {
						iTotalMinQuantity += lineItem.Apttus_Config2__AttributeValueId__r.APT_Minimum_Quantity__c;
					}
				}
				//Mausam Padhiyar : APOST-646 : 22nd Feb, 2016 : End
			}

			if(digitalInternationalBundlesCount > 1 || nonDigitalInternationalBundlesCount > 1){
				result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, '1 Shopping cart can not have more than 1 digital or non digital International bundle'));
				result.isSuccess =  false;
			}

			//New International Bundles implimentation(Start)


			if((digitalInternationalBundlesCount >= 1) && (InternationalPCMSBundlesCount >= 1)){
				result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.APT_IntDigital13));
				result.isSuccess =  false;

			}

			if((digitalInternationalBundlesCount >= 1) && (InternationalPCMSBundlesincAirmailLettersCount >= 1)){
				result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.APT_IntDigital14));
				result.isSuccess =  false;

			}
			if((nonDigitalInternationalBundlesCount >= 1) && (InternationalPCMSBundlesincAirmailLettersCount >= 1)){
				result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.APT_IntNonDigital24));
				result.isSuccess =  false;

			}
			if((nonDigitalInternationalBundlesCount >= 1) && (InternationalAirmaillettersCount >= 1)){
				result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.APT_IntNonDigital25));
				result.isSuccess =  false;

			}

			if(InternationalPCMSBundlesCount > 1){
				result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.APT_NewIntPCMS33));
				result.isSuccess =  false;

			}
			if((InternationalPCMSBundlesCount >= 1) && (InternationalPCMSBundlesincAirmailLettersCount >= 1)){
				result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.APT_NewIntPCMS34));
				result.isSuccess =  false;

			}

			if(InternationalPCMSBundlesincAirmailLettersCount > 1){
				result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.APT_NewIntPCMSIncAL44));
				result.isSuccess =  false;

			}
			if((InternationalPCMSBundlesincAirmailLettersCount >= 1) && (InternationalAirmaillettersCount >= 1)){
				result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.APT_NewIntPCMSIncAL45));
				result.isSuccess =  false;

			}

			if(InternationalAirmaillettersCount > 1){
				result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.APT_NewIntAL55));
				result.isSuccess =  false;

			}

			system.debug('--->InternationalRKcodemandatory' +InternationalRKcodemandatory);
			system.debug('--->InternationalLegacyDigitalDelete' +InternationalLegacyDigitalDelete);
			/*if(InternationalRKcodemandatory >= 1){
				 result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.APT_RK_Code_Mandatory));
				 result.isSuccess =  false;

			}*/


			if(InternationalLegacyDigitalDelete >= 1){
				result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.APT_Int_LDigital_Delete));
				result.isSuccess =  false;

			}

			//New International Bundles implimentation(End)

			/*
			if(nonDigitalInternationalBundlesCount > 1){
				result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Maximum number of Non Digital product for International Bundle is one.'));
				result.isSuccess =  false;
			}*/

			if(approvalRequiredLineItems != null && approvalRequiredLineItems.size()>0){
				result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select pricing reason and competitors to submit for approvals.'));
				result.isSuccess =  false;
				//return result;
			}

			/* Shashwat.Nath@Auspost.com has commented the below validation as going forward users are no longer required
			   to do OPC from the  Apttus Cart .

			/*if(lstOPLI.size()>0){
				for(APT_Opportunity_Product_Line_Item__c opLI:lstOPLI){
					if(opLI.APT_Revenue_Start_Date__c == null || opLI.APT_Revenue_End_Date__c == null){
						result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please add Opportunity Product Classifiction to finalize'));
						result.isSuccess =  false;
						//return result;
					}
				}
			}

			if(lstLI!=null && lstLI.size()>0){
				if((lstOPLI.size()==0 && lstLI.size()>0)||(uniqueProducts.size()>0 && uniqueProducts.size()!=lstOPLI.size())){
					result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please add Opportunity Product Classifiction to finalize'));
					result.isSuccess =  false;
					//return result;
				}
			}*/

			/* Shashwat.nath@Auspost.com Code Comments End */

			selectedLPQuote =prodConfig.Apttus_QPConfig__Proposald__r.APT_Selected_LP__c;

			if(String.isNotBlank(selectedLPQuote)){
				String[] selectedLpListVal=  selectedLPQuote.split(APT_Constants.SEPERATOR_COMMA) ;
				Integer sizeOfLPSelected =selectedLpListVal.size();
				String [] lastLPVal = selectedLpListVal[sizeOfLPSelected-1].split(APT_Constants.SEPERATOR_SIMILARITY);
				selectedLpListVal [sizeOfLPSelected-1]=lastLPVal[0];
				for(Integer i=0;i<sizeOfLPSelected;i++){
					setLPidVal.add(selectedLpListVal[i]);
				}
			}

			if(!String.isEmpty(selectedCategory)) {
				if(!String.isEmpty(APT_Constants.CATEGORY_CAT1) && selectedCategory.equalsIgnoreCase(APT_Constants.CATEGORY_CAT1) && iTotalMinQuantity < 1000) {
					result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Min Quantity must be at least 1000 for Category CAT1.'));
					result.isSuccess =  false;
				} else if(!String.isEmpty(APT_Constants.CATEGORY_CAT2) && selectedCategory.equalsIgnoreCase(APT_Constants.CATEGORY_CAT2) && iTotalMinQuantity < 2000) {
					result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Min Quantity must be at least 2000 for Category CAT2.'));
					result.isSuccess =  false;
				} else if(!String.isEmpty(APT_Constants.CATEGORY_CAT3) && selectedCategory.equalsIgnoreCase(APT_Constants.CATEGORY_CAT3) && iTotalMinQuantity < 5000) {
					result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Min Quantity must be at least 5000 for Category CAT3.'));
					result.isSuccess =  false;
				} else if(!String.isEmpty(APT_Constants.CATEGORY_CAT4) && selectedCategory.equalsIgnoreCase(APT_Constants.CATEGORY_CAT4) && iTotalMinQuantity < 10000) {
					result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Min Quantity must be at least 10000 for Category CAT4.'));
					result.isSuccess =  false;
				} else if(!String.isEmpty(APT_Constants.CATEGORY_CAT5) && selectedCategory.equalsIgnoreCase(APT_Constants.CATEGORY_CAT5) && iTotalMinQuantity < 20000) {
					result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Min Quantity must be at least 20000 for Category CAT5.'));
					result.isSuccess =  false;
				} else if(!String.isEmpty(APT_Constants.CATEGORY_CAT6) && selectedCategory.equalsIgnoreCase(APT_Constants.CATEGORY_CAT6) && iTotalMinQuantity < 50000) {
					result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, 'Min Quantity must be at least 50000 for Category CAT6.'));
					result.isSuccess =  false;
				}
			}
			//Mausam Padhiyar : APOST-646 : 22nd Feb, 2016 : End
			string pAVQuery = 'select id';
			for(string productCode :mapCodeLineItem.keySet()){
				if(mapProductFields.containskey(productCode)){
					for(string fieldName: mapProductFields.get(productCode)){
						if(!pAVQuery.contains(fieldName)){
							pAVQuery =pAVQuery +','+fieldName;
						}
					}
				}
			}
			pAVQuery =pAVQuery+ ',Apttus_Config2__LineItemId__r.Apttus_Config2__ProductId__r.ProductCode from Apttus_Config2__ProductAttributeValue__c where Apttus_Config2__LineItemId__c IN :setLineItems';

			for(Apttus_Config2__ProductAttributeValue__c pav: Database.query(String.escapeSingleQuotes(pAVQuery))){
				if(mapCodePAV.containsKey(pav.Apttus_Config2__LineItemId__r.Apttus_Config2__ProductId__r.ProductCode)) {
					mapCodePAV.get(pav.Apttus_Config2__LineItemId__r.Apttus_Config2__ProductId__r.ProductCode).add(pav);
				}else {
					mapCodePAV.put(pav.Apttus_Config2__LineItemId__r.Apttus_Config2__ProductId__r.ProductCode, new List<Apttus_Config2__ProductAttributeValue__c> { pav });
				}
			}


			for(string productCode : mapCodePAV.keySet()){
				if(mapCodePAV.get(productCode).size()>1){
					Map<string,set<string>> mapFieldValue = new  Map<string,set<string>>();
					for(Apttus_Config2__ProductAttributeValue__c pav:mapCodePAV.get(productCode)){
						for(string fieldName : mapProductFields.get(productCode)){
							if(mapFieldValue.containsKey(fieldName)) {
								mapFieldValue.get(fieldName).add(string.valueOf(pav.get(fieldName)));
							}else {
								mapFieldValue.put(fieldName, new set<string> { string.valueOf(pav.get(fieldName)) });
							}
						}
					}
					/*
						 Commented By Sagar Jogi Start - 19th July 2016
					for(string field:mapFieldValue.keyset()){
					   if(mapFieldValue.get(field).size()>1){
						 string fieldLabel= Schema.getGlobalDescribe().get('Apttus_Config2__ProductAttributeValue__c').getDescribe().fields.getMap().get(field).getDescribe().getLabel();
						   result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, fieldLabel+' must be same for all '+mapProductCode.get(productCode)+' products configured.'));
						   result.isSuccess =  false;
						   return result;
					   }
					}
					  Commented By Sagar Jogi End - 19th July 2016
					*/
				}
			}

			for(string productCode : mapCodePAV.keySet()){
				if(mapCodePAV.containsKey(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) && mapCodePAV.containsKey(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)
						&& ((!String.isEmpty(productCode) && !String.isEmpty(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD) && productCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD))
						|| (!String.isEmpty(productCode) && !String.isEmpty(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS) && productCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)))){
					for(Apttus_Config2__ProductAttributeValue__c pav:mapCodePAV.get(productCode)){
						for(string fieldName : mapProductFields.get(productCode)){
							if(mapeParcelfeildValue.containsKey(fieldName)) {
								mapeParcelfeildValue.get(fieldName).add(string.valueOf(pav.get(fieldName)));
							}else {
								mapeParcelfeildValue.put(fieldName, new set<string> { string.valueOf(pav.get(fieldName)) });
							}
						}
					}
					/*
						Commented By Sagar Jogi Start - 19th July 2016
					 for(string field:mapeParcelfeildValue.keyset()){
					  if(mapeParcelfeildValue.get(field).size()>1){
						string fieldLabel= Schema.getGlobalDescribe().get('Apttus_Config2__ProductAttributeValue__c').getDescribe().fields.getMap().get(field).getDescribe().getLabel();
						  result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, fieldLabel+' must be same across all eParcel and eParcel Express products configured.'));
						  result.isSuccess =  false;
						  return result;
					  }
				   }
					   Commented By Sagar Jogi End - 19th July 2016
				   */
				}
			}

			//STP-2955 Modify Existing Batch to Create PLI, PM and PME for Express Road - STE Product
			//Calling validate Attriute (with list of LineItems as paramater) related method to check attributes are selected with atleast 1 value
			string attrErrorMessage = validateAttributesOfLineItems(prodConfig, allLineItems);
			if(attrErrorMessage != null && !string.isEmpty(attrErrorMessage))
			{
				result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, attrErrorMessage));
				result.isSuccess = false;
			}

		} catch(Exception ex) {
			result.Messages.add(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			//System.debug('Ex.getmessage(): ' + ex.getmessage());
			result.isSuccess =  false;
		}
		return result;
	}

	//Method used to concat multiple products into a single string
	private string concatMessage(List<string> errorProductList)
	{
		String products = '';

		//looping through all products (which have any error) and converting it into single string which need to show it into error message
		for(string msgString : errorProductList)
		{
			if(products == '')
			{
				products = msgString;
			}
			else
			{
				products = products + ', ' + msgString;
			}
		}

		return products;
	}

	//Getting ProductName and its Sequence to show it into the error message
	private string getProductNameForMessage(Apttus_Config2__LineItem__c lineItem)
	{
		string productSequence = String.valueOf(lineItem.Apttus_Config2__LineSequence__c);
		system.debug('productSequence: ' + productSequence);
		//Check for Option Line Item
		if(lineItem.Apttus_Config2__OptionId__c != null && lineItem.Apttus_Config2__OptionId__r.Name != null)
		{
			productSequence = productSequence + '. ' + lineItem.Apttus_Config2__OptionId__r.Name;
		}
		//Check for Standalone/ Bundle Line Item
		else
		{
			productSequence = productSequence + '. ' + lineItem.Apttus_Config2__ProductId__r.Name;
		}
		system.debug('productSequence: ' + productSequence);

		return productSequence;
	}

	/**
		This method is used to validate the PostcodeSuburb attributes of LineItem are populated or not, if not populated then show error message.
		@params -
		cart - product configuration
		params - action params
	*/
	private string validateAttributesOfLineItems(Apttus_Config2__ProductConfiguration__c configSO, List<Apttus_Config2__LineItem__c> lineItems)
	{
		List<String> requiredProductMapForPostCodeAndSuburb = new List<String>();
		string errorMessage;

		if(!lineItems.isEmpty())
		{
			for(Apttus_Config2__LineItem__c lineItem : lineItems)
			{
				//Check in Attribute Value that if PostCode&Suburb for ST Products is selected or not
				if(lineItem.Apttus_Config2__OptionId__c == null &&
						lineItem.Apttus_Config2__ProductId__r.APT_Product_type__c == APT_Constants.PRODUCTTYPE_STARTRACK && String.isBlank(lineItem.Apttus_Config2__AttributeValueId__r.APT_Post_Code_Suburb__c))
				{
					requiredProductMapForPostCodeAndSuburb.add(getProductNameForMessage(lineItem));
				}
			}
		}
		if(!requiredProductMapForPostCodeAndSuburb.isEmpty())
		{
			String productsForPostcodeAndSuburb = concatMessage(requiredProductMapForPostCodeAndSuburb);

			//Show Error Message if PostCodeAndSuburb attribute is not populated/selected
			if(!String.isBlank(productsForPostcodeAndSuburb))
			{
				errorMessage = APT_Constants.POSTCODEANDSUBURB_ATTRIBUTE_ERROR + productsForPostcodeAndSuburb;
			}
		}

		return errorMessage;
	}

	/** Gets the list of product line items associated with the Battery line
	  @param cart the cart object
	 @return the list of line item objects
	**/
	private static List<Apttus_Config2__LineItem__c> getLineItems(List<Apttus_Config2.LineItem> allLines) {
		list<Apttus_Config2__LineItem__c> lineItems = new list<Apttus_Config2__LineItem__c>();
		// iterate thru the cart and get the line items matching the battery code1
		for (Apttus_Config2.LineItem lineItemMO : allLines) {
			lineItems.add(lineItemMO.getLineItemSO());
		}

		return lineItems;
	}

	/**
		Must implement methods of Apttus_Config2.CustomClass.IValidationCallback2
	**/
	global Apttus_Config2.CustomClass.ValidationResult validateAssetItems(Apttus_Config2.ProductConfiguration cart,List<Apttus_Config2__TempRenew__c> lstTemp) {
		Apttus_Config2.CustomClass.ValidationResult result;
		return result;
	}
	/**
		Method to validate ramp line items
	**/
	global Apttus_Config2.CustomClass.ValidationResult validateRampLineItems(Apttus_Config2.ProductConfiguration cart,List<Apttus_Config2.LineItem> lstLI) {
		Apttus_Config2.CustomClass.ValidationResult result;
		return result;
	}
}