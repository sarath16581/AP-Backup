/*------------------------------------------------------------
@Test OpportunityLineItemServiceTest
Author: : Jeoffrey Palmero
Date Created: 07/29/2019
Description: Handles logic related to the Opportunity Line Item
History
<Date> <Authors Name> <Brief Description of Change>
07/29/2019 JPalmero Created
28/06/2022 KMcGuire Modified for including related account sales in OPC classification
26/08/2022 KMcGuire Do not change classification on line item update when opportunity is closed won
29/2/2023 Ken McGurie allow for OPC override and forward planning
03/03/2022 KMcGuire Created opc precalculation method
14/03/2023 Nasir Jawed Added function logic populateRevenueDate() to populate the Revenue start/End Date when an OLI in inserted
17/4/2023 Ken McGurire Modified for related products
14/8/2023 Ken McGuire modified for consuming class use of selector class
------------------------------------------------------------*/
public inherited sharing class OpportunityLineItemService {
	public static final String CLASSNAME = 'OpportunityLineItemService';
	public static final String ORGID = UserInfo.getOrganizationId();
	public static final String triggerName = 'OpportunityLineItemTrigger';
	private static final Id userId = userinfo.getProfileId();//get the current user's Profile ID
	private static final String currentProfileName = [SELECT Name FROM Profile WHERE Id = :userId].Name;
	private static final Set<String> salesAdminProfiles = Constants.salesAdminProfiles();
	private static final Set<String> salesUserProfiles = Constants.salesUserProfiles();

	// OPC CALCULATION ENTRY POINT FOR INSERT OF AN OPPORTUNITY LINE ITEM
	 /*****************************
	 * Description: Populate line item classification BEFORE INSERTION of new opportunity line items having a contract start date.
	 * - Called by opportunityLineItemTriggerHander.beforeInsert method.
	 * Param newOptyLineItemList - the newly inserted opportunity line items. Must have a contract start date.
	 * Author: JPalmero
	 * History:
	 * 7/31/2019 Created
	 * 22/07/2022 Ken McGuire Modified
	 ****************************/
	public static void populateClassification(List<OpportunityLineItem> newOptyLineItemList){

		// The opportunities associated with the line items.
		Set<Id> optyIdSet = new Set<Id>();
		// maps Opportunities to their associated Account
		Map<Id, Id> optyOrgMap = new Map<Id, Id>();

		// Since the line items are being inserted (new), do NOT exclude records flagged from renewal to growth
		// as we need to first calculate whether the line item OPC is in fact renewal.
		List<OpportunityLineItem> opportunityLineItemsToRecalculate = excludeOverride(newOptyLineItemList,false);

		// populate associated products and opportunities
		for(OpportunityLineItem optyLine : opportunityLineItemsToRecalculate){
			optyIdSet.add(optyLine.OpportunityId);
		}

		// Map opportunities to their accounts
		if(optyIdSet != NULL) {
			for(Opportunity optyObj : [SELECT Id, AccountId, StageName
									 FROM Opportunity
									 WHERE Id IN: optyIdSet
									 LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())]) {
				optyOrgMap.put(optyObj.Id, optyObj.AccountId);//saves the org in a map for later use
			}
		}
		// populate classification for the line items.
		List<OpportunityLineItem> populatedLineItems = calculateClassification(opportunityLineItemsToRecalculate,optyOrgMap);
		// Enforce OPC classification override from renewal to growth
		overrideRenewalToGrowth(populatedLineItems);
	}

	// OPC CALCULATION ENTRY POINT FOR UPDATE OPPORTUNITY LINE ITEM
	/**********************************
	 * Description: recalculate the OPC upon change of Opty Line Item's Revenue Dates
	 * - called by opportunityLineItemTriggerHandler.beforeUpdateActions
	 * Author: Ken McGuire
	 * History:
	 * 26/08/2022 Created
	 ****************************/
	public static void recalculateClassification(List<OpportunityLineItem> newOptyLineItemList, Map<Id, OpportunityLineItem> oldRecMap){
		// filtered list of candidates for OPC recalculation
		// specifically, these candidates do not have overridden OPC values however they may be associated with opportunities
		// that have been closed-won
		List<OpportunityLineItem> recalculationCandidates = filterForRecalculationCandidates(newOptyLineItemList,oldRecMap);

		if (recalculationCandidates.Size()==0) {
			return;
		}

		// maps Opportunities to their associated Account
		Map<Id, Id> optyOrgMap = new Map<Id, Id>();

		try{

			// obtain opportunityIds from the product line items
			Set<Id> optyIdSet = new Set<Id>();
			for (OpportunityLineItem currentItem : recalculationCandidates) {
				optyIdSet.add(currentItem.opportunityId);
			}

			// obtain associated opportunities for the product line items, ignoring closed opportunities
			list<Opportunity> assocatedOpenOpportunities = loadOpenOpportunities(optyIdSet);
			if(assocatedOpenOpportunities.size()==0) {
				return;
			}

			// populate opportunity account map
			 for(Opportunity currentOpportunity : assocatedOpenOpportunities) {
				optyOrgMap.put(currentOpportunity.Id, currentOpportunity.AccountId);
			}

			// only recalculate line items that have associated opportunities in the opportunity account map.
			// Specifically, this excludes opportunities that have been closed won
			List<OpportunityLineItem> opportunityLineItemsToRecalculate = filterForRecalculation(recalculationCandidates,optyIdSet);

			// recalculate classification for the relevant line items.
			List<OpportunityLineItem> updatedLineItems = calculateClassification(opportunityLineItemsToRecalculate,optyOrgMap);

			// Enforce OPC classification override from renewal to growth
			overrideRenewalToGrowth(opportunityLineItemsToRecalculate,oldRecMap);

		}catch(exception excp){
			UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'recalculateClassification', triggerName, LoggingLevel.ERROR);
		}
	}
	
	 // OPC CALCULATION ENTRY POINT FOR UPDATE OF AN OPPORTUNITY
	 /*********************************
	 * Description: Updates all the opportunity line items OPC for opportunities that have been closed-won
	 * Author: Prince Encina
	 * History:
	 * 08/20/19 Created
	 * 22/07/2022 Ken McGuire Modified
	 ********************************/
	public static void updateClassification(List<Opportunity> newOptyList, Map<Id, Opportunity> oldRecMap){
		// Maps Opportunities and their associated accounts.
		// Filtered for those opportunities that have been changed to closed won.
		Map<Id, Id> newlyClosedOpportunityAccountMap = new Map<Id, Id>();
		// the opportunity line items associated with the newly closed won opportunities that require new OPC calculations
		List<OpportunityLineItem> optyLineItemList = new List<OpportunityLineItem>();

		// populate the list of opportuninites that have been changed to closed-won.
		try{
			for(Opportunity currentOpportunity : newOptyList){
				Opportunity oldOptyRec = oldRecMap.get(currentOpportunity.Id);
				if(Constants.CLOSED_WON.equalsIgnoreCase(currentOpportunity.StageName) && !Constants.CLOSED_WON.equalsIgnoreCase(oldOptyRec.StageName)){
					newlyClosedOpportunityAccountMap.put(currentOpportunity.Id, currentOpportunity.AccountId);
				}
			}

			if (newlyClosedOpportunityAccountMap.size()==0) {
				return;
			}

			// track opportunities with products
			Set<Id> opportunitiesWithProducts = new Set<id>();

			// obtain opportunity line items associated with opportunities that have been closed-won.
			// filter out those line items whose OPC value has been overridden.The remainder are candidates for OPC recalculation.
			for (OpportunityLineItem currentItem : [SELECT Id, Product2Id, Contract_Start_Date__c, OpportunityId, Classification__c, Opportunity.AccountId,
								 Contract_End_Date__c, APT_Is_Apttus_Opportunity_Line_item__c, Change_Classification__c,OPCOverride__c
								 FROM OpportunityLineItem
								 WHERE OpportunityId IN : newlyClosedOpportunityAccountMap.keySet()
								 AND Change_Classification__c = 'No'
								 AND OPCOverride__c = 'No'
								 LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())]) {
				optyLineItemList.add(currentItem);
				opportunitiesWithProducts.add(currentItem.OpportunityId);
			}

			// If there are no opportunity line item OPC calculation candidates, return.
			if (optyLineItemList.size()==0) {
				return;
			}

			// remove any closed-won opportunities that do not have line item candidates for OPC caclulation updates.
			// this will avoid unnecessary calls for associated account sales history.
			Set<Id> opportunitiesWithoutProducts = new Set<id>();

			for (Id currentOpportunityId : newlyClosedOpportunityAccountMap.keyset()) {
				if (!opportunitiesWithProducts.contains(currentOpportunityId)) {
					opportunitiesWithoutProducts.add(currentOpportunityId);
				}
			}

			if (opportunitiesWithoutProducts.size()>0) {
				newlyClosedOpportunityAccountMap.keyset().removeAll(opportunitiesWithoutProducts);
			}

			// Update classification for the line items.
			List<OpportunityLineItem> updatedLineItems = calculateClassification(optyLineItemList,newlyClosedOpportunityAccountMap);
			if(updatedLineItems.size()>0){
				Database.update(updatedLineItems, TRUE);
			}

		}catch(exception excp){
			UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'updateClassification', triggerName, LoggingLevel.ERROR);
		}
	}

	/*********************************
	 * Description: Retireves opportunity line items for a a single opportunity
	 * after re-calculating OPC values
	 * Author: Ken McGuire
	 * History:
	 * 03/03/2022 Created
	 * 14/8/2023 modified for consuming class use of selector class
	 ********************************/
	public static List<OpportunityLineItem> getPreClassifiedLineItems(List<OpportunityLineItem> items) {
	
		if (items == null || items.isEmpty() || items[0].Opportunity.AccountId == null) {
			return items;
		 
		}
		// recalculate OPC for the opporutnity line items
		Map<Id,Id> optyOrgMap = new Map<Id,Id>();
		optyOrgMap.put(items[0].Opportunity.id,items[0].Opportunity.AccountId);
		calculateClassification(excludeOverride(items,true),optyOrgMap);

		// return the opportunity line items with freshly cacluated OPC values
		return items;
	}

	// PERFORMS OPC CALCULATIONS
	/*****************************
	 * Description: Calculate the classification field based on current sales history
	 * @parameter recordsToCalculate - a list of line items that have not been overridden.
	 * @parameter accountIdSet - the ids of all accounts associated with the line item opportunities.
	 * @parameter optyOrgMap - a map linking an opportunity Id with its associated account Id.
	 * 22/07/2022 Ken McGuire Modified
	 ****************************/
 	private static List<OpportunityLineItem> calculateClassification(List<OpportunityLineItem> recordsToCalculate,Map<Id, Id> optyOrgMap ){

	// Track the opportunity line items that have a new or different classification.
	 List<OpportunityLineItem> calculatedLineItems = new List<OpportunityLineItem>();
	 if (recordsToCalculate.size()==0) {
		 return calculatedLineItems;
	 }

	 Set<String> productIdSet = new Set<String>();
	 for (OpportunityLineItem currentItem : recordsToCalculate) {
		 productIdSet.add(currentItem.Product2Id);
	 }

	 // Nominal trading amount for determining any significant sales history
	 NominalTradeAmount__c ntAmount = NominalTradeAmount__c.getInstance();

	 // a data object (class) that manages trading history for products purchased by accounts
	// It provides parameters that are used for OPC classification.
	 TradingHistoryMaps tradingHistoryMaps = new TradingHistoryMaps();

	 // populate the trading history maps with the map of opportunities to their accounts as passed in to this method
	 tradingHistoryMaps.optyOrgMap = optyOrgMap;
		try{

			// obtain account revenue figures
			OPCUtility.calculateParentAccountRevenueMap(new Set<String>((List<String>)optyOrgMap.values()),productIdSet);
			List<OPCUtility.ParentAccountRevenue> revenue = OPCUtility.parentAccountRevenueMap.values();
			revenue.sort();

			// populate the trading history map figures using account revenue figures
			populateGroupedTradingHistoryMaps(tradingHistoryMaps,revenue,(Double) ntAmount.Amount__c);

			// classify the opportunity line items
			List<String> errors = new List<String>();
			for(OpportunityLineItem optyLine : recordsToCalculate){

				// obtain the current opportunity line item classification based on current trading history
				string newClassification = getClassification(New TradingHistoryInfo(optyLine,tradingHistoryMaps,(Double)ntAmount.Amount__c));

				//OPC classificaiton should never be null
				if (newClassification == null) {

					errors.add('Null Classification Id: ' + optyLine.id + ' ChangeClassification: ' + optyLine.Change_Classification__c + ' prior Classification: ' + optyLine.Classification__c);
				}
				system.debug('****** SETTING CLASSIFICATION INSIDE OPPORTUNITYLINEITEMSERVICE');
				// If the new classification is different than the existing one, update it and add it to the list of updated items.
				if (optyLine.Classification__c != newClassification) {
					optyLine.Classification__c = newClassification;
					calculatedLineItems.add(optyLine);
				}
			}

			// Log any instances where the classification was null
			if (errors.size()>0) {
				ApplicationLogger.getInstance().logGenericMessage(errors, 'Sales', CLASSNAME, 'calculateClassification', triggerName, ApplicationLogger.LoggingLevel.ERROR);
			}

		}catch(exception excp){
			UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'calculateClassification', triggerName, LoggingLevel.ERROR);
		}
	 // return the list of opportunity line items which have changed classification.
		return calculatedLineItems;
	}

	/**********************************
	 * Description: populate tradingHistoryMaps object with sales history maps used for OPC calculations.
	 * @parameter tradingHistoryMaps - custom data structure (class) to provide account sales revenue data and calculations
	 * @parameter revenueHistory - relevant sales revenue history for opportunity accounts, including immediate AccountRelationship child accounts.
	 * @parameter ntAmount - nominal trading amount used to determine if sales history is 'significant'
	 * @returns by reference population of the tradingHistoryMaps object passed in
	 * Author: Ken McGuire
	 * History:
	 * 26/08/2022 Created
	 ****************************/
	private static void populateGroupedTradingHistoryMaps(TradingHistoryMaps tradingHistoryMaps, List<OPCUtility.ParentAccountRevenue> revenueHistory, double ntAmount) {

		// iterate through each product revenue entry. There is one entry per financial year of traded history
		for (OPCUtility.ParentAccountRevenue currentProductRevenue : revenueHistory ) {

			// include sales figures from related accounts.
			currentProductRevenue.group();

			//products that an account has traded with AuPost
			tradingHistoryMaps.addTradedProduct(currentProductRevenue.Organisation,currentProductRevenue.Product);
			//accounts in this set have traded any product
			tradingHistoryMaps.tradedAcctSet.add(currentProductRevenue.Organisation);

			//if the Total annual Revenue of the current product revenue exceeds the NTA, update maps
			if(currentProductRevenue.Total_Revenue_Amount > ntAmount) {
				// The account is considered a signficant trading account
				tradingHistoryMaps.significantTradeAccounts.add(currentProductRevenue.Organisation);
				// The product is considered a significant traded product for the account.
				tradingHistoryMaps.addSignificantTradedProduct(currentProductRevenue.Organisation,currentProductRevenue.Product);
			}
		}
	}

	/**********************************
	 * Description: Calculates a classificaiton for an opportunity line item based on its account trading history.
	 * @parameter TradingHistoryInfo - contains a reference to an opportunity line item and its associated trading history parameters.
	 * @returns a string representing the calculated classification for the opportunity line item.
	 * Author: Ken McGuire
	 * History:
	 * 26/08/2022 Created
	 ****************************/
	private static string getClassification(TradingHistoryInfo tradingHistoryInfo) {

		// try getting the classification of the product based on product sales history
		String classification = salesclassification(tradingHistoryInfo);

		// try getting the classification of the product based on account sales history
		if (classification == null) {
			classification = getClassificationFromAccountTradingHistory(tradingHistoryInfo);
		}

		return classification;
	}

	/**********************************
	 * Description: Calculates a classificaiton for an opportunity line item based on its account trading history.
	 * @parameter TradingHistoryInfo - contains a reference to an opportunity line item and its associated trading history parameters.
	 * @returns a string representing the calculated classification for the opportunity line item.
	 * Author: Ken McGuire
	 * History:
	 * 26/08/2022 Created
	 ****************************/
	private static string getClassificationFromAccountTradingHistory(TradingHistoryInfo tradingHistoryInfo) {
		// The opportunity line item should have a contract start date
		if (tradingHistoryInfo.optyLine.Contract_Start_Date__c == null) {
			return tradingHistoryInfo.optyLine.Classification__c;
		}

		// Determine the month and year to base the start of the OPC calculation on.
		date todaysDate = date.today();
		Integer daysInFuture = todaysDate.daysBetween(tradingHistoryInfo.optyLine.Contract_Start_Date__c);
		boolean isForwardPlanning = daysInFuture > 365;
		Integer startMonth = tradingHistoryInfo.optyLine.Contract_Start_Date__c.MONTH();//get the start month for 12 months computation

		// in the case of forward planning, use the closest year
		// in the case it is not forward planning, use the start date year.
		Integer startYear = isForwardPlanning ?
			todaysDate.month() < startMonth ?
				todaysDate.year()
				: todaysDate.year()+1
			: tradingHistoryInfo.optyLine.Contract_Start_Date__c.YEAR();

		// The revenue for the 12 months prior to the startMonth and startYear
		Double totalRevenue = 0;
		// The revenue for all previous financial years and future years
		Double totalOutsideRevenue = 0;

		// Base calculations on which finanical year the calculation starts in.
		if(StartMonth > 6) {
			// current calendar year equals current financial year
			String previousFinancialYearRevenueKey = OPCUtility.constructRevenueKey(tradingHistoryInfo.parentAccountId,tradingHistoryInfo.optyLine.Product2Id, startYear-1);
			String currentFinancialYearRevenueKey = OPCUtility.constructRevenueKey(tradingHistoryInfo.parentAccountId,tradingHistoryInfo.optyLine.Product2Id, startYear);
			String subsequentFinancialYearRevenueKey = OPCUtility.constructRevenueKey(tradingHistoryInfo.parentAccountId,tradingHistoryInfo.optyLine.Product2Id, startYear+1);

			// get totals from the previous year
			if(OPCUtility.parentAccountRevenueMap.containsKey(previousFinancialYearRevenueKey)) {
				// total outside revenue = total revenue for the year less the months betweeen July and the contract start date
				totalOutsideRevenue += OPCUtility.parentAccountRevenueMap.get(previousFinancialYearRevenueKey).getRevenue(1,6);
				totalOutsideRevenue += OPCUtility.parentAccountRevenueMap.get(previousFinancialYearRevenueKey).getRevenue( startMonth,12);
			}
			// add totals from the current year
			if(OPCUtility.parentAccountRevenueMap.containsKey(currentFinancialYearRevenueKey)) {

				totalOutsideRevenue += OPCUtility.parentAccountRevenueMap.get(currentFinancialYearRevenueKey).getRevenue(7, startMonth);
				totalRevenue += OPCUtility.parentAccountRevenueMap.get(currentFinancialYearRevenueKey).getRevenue(1,6);
				totalRevenue += OPCUtility.parentAccountRevenueMap.get(currentFinancialYearRevenueKey).getRevenue( startMonth,12);
			}
			// add totals for the subsequent year
			if(OPCUtility.parentAccountRevenueMap.containsKey(subsequentFinancialYearRevenueKey)) {
				totalRevenue += OPCUtility.parentAccountRevenueMap.get(subsequentFinancialYearRevenueKey).getRevenue(7, startMonth);
			}
		}
		else {
			// current calendar year falls insdie last financial year
			String twoFinancialYearsAgoRevenueKey = OPCUtility.constructRevenueKey(tradingHistoryInfo.parentAccountId,tradingHistoryInfo.optyLine.Product2Id, startYear-2);
			String previousFinancialYearRevenueKey = OPCUtility.constructRevenueKey(tradingHistoryInfo.parentAccountId,tradingHistoryInfo.optyLine.Product2Id, startYear-1);
			String currentFinancialYearRevenueKey = OPCUtility.constructRevenueKey(tradingHistoryInfo.parentAccountId,tradingHistoryInfo.optyLine.Product2Id, startYear);

			// get totals from two years ago
			if(OPCUtility.parentAccountRevenueMap.containsKey(twoFinancialYearsAgoRevenueKey)) {
				// total outside revenue = total revenue for the year less the months betweeen July and the contract start date
				totalOutsideRevenue += OPCUtility.parentAccountRevenueMap.get(twoFinancialYearsAgoRevenueKey).getRevenue( startMonth,6);
			}
			// add totals from last year
			if(OPCUtility.parentAccountRevenueMap.containsKey(previousFinancialYearRevenueKey)) {

				totalOutsideRevenue += OPCUtility.parentAccountRevenueMap.get(previousFinancialYearRevenueKey).getRevenue(1, startMonth);
				totalOutsideRevenue += OPCUtility.parentAccountRevenueMap.get(previousFinancialYearRevenueKey).getRevenue(7,12);
				totalRevenue += OPCUtility.parentAccountRevenueMap.get(previousFinancialYearRevenueKey).getRevenue( startMonth,6);
			}
			// add totals for this year
			if(OPCUtility.parentAccountRevenueMap.containsKey(currentFinancialYearRevenueKey)) {
				totalRevenue += OPCUtility.parentAccountRevenueMap.get(currentFinancialYearRevenueKey).getRevenue(1, startMonth);
				totalRevenue += OPCUtility.parentAccountRevenueMap.get(currentFinancialYearRevenueKey).getRevenue(7,12);
			}
		}

		String classification = salesClassification(tradingHistoryInfo,totalRevenue,totalOutsideRevenue);

		// The sales calssificaiton should never be null
		if (classification == null) {

			// record the values used to arrive at a classification
			String debugValues = tradingHistoryInfo.isTradingAccount +','+
								 tradingHistoryInfo.accountTradeExceedsNTA +','+
								 tradingHistoryInfo.productPreviouslyTraded +','+
								 tradingHistoryInfo.productTradeExceedsNTA +','+
								 tradingHistoryInfo.anyTradedProdcutExceedsNTA +','+
								 totalRevenue +','+
								 totalOutsideRevenue;
			// Log the problem
			OPCException excp = new OPCException(debugValues);
			UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'getClassificationFromAccountTradingHistory', triggerName, LoggingLevel.ERROR);
		}

		return classification;

	}

	/**********************************
	 * Description: Calculates a classificaiton for an opportunity line item based on its product trading history.
	 * @parameter TradingHistoryInfo - contains a reference to an opportunity line item and its associated trading history parameters.
	 * @returns a string representing the calculated classification for the opportunity line item.
	 * Author: Ken McGuire
	 * History:
	 * 26/08/2022 Created
	 ****************************/
	@testVisible
	private static string salesclassification(TradingHistoryInfo tradingHistoryInfo) {

		//if there hasn't been any trade or the total revenue is <NTA
		if(!tradingHistoryInfo.isTradingAccount || !tradingHistoryInfo.accountTradeExceedsNTA) {
			return Constants.CLSS_NEWBUSINESS;
		}

		//if the product has been traded before but is less than the NTA && has no other product that exceeded the NTA
		if(tradingHistoryInfo.productPreviouslyTraded && !tradingHistoryInfo.productTradeExceedsNTA && !tradingHistoryInfo.anyTradedProdcutExceedsNTA) {
			return Constants.CLSS_NEWBUSINESS;
		}

		//if the product has never been traded and the org has traded other product with Total Revenue > NTA
		if(!tradingHistoryInfo.productPreviouslyTraded && tradingHistoryInfo.anyTradedProdcutExceedsNTA) {
			return Constants.CLSS_CROSSSELL;
		}

		return null;
	}
	 /**********************************
	 * Description: Calculates a classificaiton for an opportunity line item based on revenue inside and outside the current FY.
	 * @parameter TradingHistoryInfo - contains a reference to an opportunity line item and its associated trading history parameters.
	 * @parameter totalRevenue - the total revenue in the current FY.
	 * @parameter totalOutsideRevenue - the total revenue outside the current FY.
	 * @returns a string representing the calculated classification for the opportunity line item.
	 * Author: Ken McGuire
	 * History:
	 * 26/08/2022 Created
	 ****************************/
	@testVisible
	private static String salesclassification(TradingHistoryInfo tradingHistoryInfo, Double totalRevenue, Double totalOutsideRevenue) {

		if(totalRevenue == 0 && tradingHistoryInfo.anyTradedProdcutExceedsNTA && !tradingHistoryInfo.productTradeExceedsNTA) {
			return Constants.CLSS_CROSSSELL;
		}

		if(totalRevenue == 0 && tradingHistoryInfo.productTradeExceedsNTA) {
			return Constants.CLSS_WINBACK;
		}

		//if the Total Revenue is less than the NTA and the Total Revenue outside the 12 months is greater than the NTA
		if(tradingHistoryInfo.ntAmount > totalRevenue && totalOutsideRevenue > tradingHistoryInfo.ntAmount){
			return Constants.CLSS_WINBACK;
		}

		//total 12 months revenue && outside revenue is less than NTA
		if(totalRevenue < tradingHistoryInfo.ntAmount && totalOutsideRevenue < tradingHistoryInfo.ntAmount && tradingHistoryInfo.anyTradedProdcutExceedsNTA) {
			return Constants.CLSS_CROSSSELL;
		}

		//if the total revenue exceeds the NTA, it is Renewal
		if(totalRevenue > tradingHistoryInfo.ntAmount) {
			return Constants.CLSS_RENEWAL;
		}

		return null;
	}

	/*****************************
	 * Description: Prevents deletion of record if the Opty's Stage is Closed Won if the current user is a Coverage Sales user
	 * Author: JPalmero
	 * History:
	 * 8/26/2019 Created
	 ****************************/
	public static void beforeDeleteValidation(List<OpportunityLineItem> newOptyLineItemList){
		Set<Id> optyIdSet = new Set<Id>();
		Map<Id, String> optyStageMap = new Map<Id, String>();
		try{
			if(salesUserProfiles.contains(currentProfileName)){//checks if the current user is a Coverage Sales user
				for(OpportunityLineItem optyObj : newOptyLineItemList){
					optyIdSet.add(optyObj.OpportunityId);
				}

				for(Opportunity opty : [SELECT Id, StageName
										FROM Opportunity
										WHERE Id IN : optyIdSet
										LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())]){
					optyStageMap.put(opty.Id, opty.StageName);//queries and gets the opty and its corresponding stage
				}

				for(OpportunityLineItem optyBuff : newOptyLineItemList){
					if(Constants.CLOSED_WON.equalsIgnoreCase(optyStageMap.get(optyBuff.OpportunityId))){
						optyBuff.addError(Label.Delete_Opty_Line);//if the Opty is Closed Won and the user is attemping to delete the record, an error is displayed
					}
				}
			}
		}catch(exception excp){
			UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'beforeDeleteValidation', triggerName, LoggingLevel.ERROR);
		}
	}

	/*****************************
	 * Description: filters a list of changed opportunity line items,
	 * returning those items that may require OPC recalculation.
	 * @parameter items : a list of opportunity Line Items to filter
	 * @parameter priorValues: a map of prior values for the opportunity Line Items to filter.
	 * @returns a filtered list of opportunityLineItem containing only those items that may require recalculation.
	 * Author: Ken McGuire
	 * History:
	 * 06/02/2022 Created
	 ****************************/
	private static List<OpportunityLineItem> filterForRecalculationCandidates(List<OpportunityLineItem> items, Map<Id,OpportunityLineItem> priorValues) {

		// the list of items that will require OPC recalculation
		List<OpportunityLineItem> filteredItems = new List<OpportunityLineItem>();

		// exlude items that have been overridden
		for (OpportunityLineItem currentItem : excludeOverride(items,true)) {
			OpportunityLineItem priorValue = priorValues.get(currentItem.id);
			// include only items requiring recalcuation
			if (requiresRecalculation(currentItem,priorValue)) {
				filteredItems.add(currentItem);
			}
		}

		return filteredItems;
	}

	/*****************************
	 * Description: filters a list of opportunity line item recalculation canddidates,
	 * returning those items that actually require OPC recalculation.
	 * @parameter items : a list of opportunity Line Items to filter
	 * @parameter associatedOpportunities : a set of associated opportunityIds
	 * @returns a filtered list of opportunityLineItem containing only those items requiring recalculation.
	 * Author: Ken McGuire
	 * History:
	 * 06/02/2022 Created
	 ****************************/
	private static List<OpportunityLineItem> filterForRecalculation(List<OpportunityLineItem> items, Set<Id> associatedOpportunities) {

		// the list of items that will require OPC recalculation
		List<OpportunityLineItem> filteredItems = new List<OpportunityLineItem>();

		// exlude items that have been overridden
		for (OpportunityLineItem currentItem : items) {
			// include only items having an associated opportunity
			if (associatedOpportunities.contains(currentItem.OpportunityId)) {
				filteredItems.add(currentItem);
			}
		}

		return filteredItems;
	}

	 /*****************************
	 * Description: filters a list of opportunity line items, returning only those items that have not had their OPC overridden.
	 * @parameter opportunityLineItems : a list of opportunityLineItems to filter
	 * @parameter excludeGrowthOverride : specifies if growth override should also be excluded.
	 * @returns a filtered list of opportunityLineItem containing only those items that have not been overridden.
	 * Author: Ken McGuire
	 * History:
	 * 06/02/2022 Created
	 ****************************/
	private static List<OpportunityLineItem> excludeOverride(List<OpportunityLineItem> opportunityLineItems, boolean excludeGrowthOverride) {

		// the list of items that have not had their OPC overriden
		List<OpportunityLineItem> filteredItems = new List<OpportunityLineItem>();

		// Build List
		for (OpportunityLineItem currentItem : opportunityLineItems) {
			if ( (!excludeGrowthOverride || !isGrowthOverride(currentItem)) && !isOverride(currentItem)) {
				filteredItems.add(currentItem);
			}
		}

		return filteredItems;
	}

	 /*****************************
	 * Description: filters a list of opportunity line items (for newlly inserted records)
	 * returning only those items that have requested OPC override from Renewal to Growth.
	 * @parameter opportunityLineItems : a list of opportunityLineItems to filter
	 * @returns a filtered list of opportunityLineItem containing only those items that have not been overridden.
	 * Author: Ken McGuire
	 * History:
	 * 06/02/2022 Created
	 ****************************/
	private static List<OpportunityLineItem> getNewOverrideRenewalToGrowth(List<OpportunityLineItem> opportunityLineItems) {

		// the list of items that have changed from renewal to growth override
		List<OpportunityLineItem> filteredItems = new List<OpportunityLineItem>();
		// Build List
		for (OpportunityLineItem currentItem : opportunityLineItems) {
			boolean changeRequested = Constants.YES_STRING.equalsIgnoreCase(currentItem.Change_Classification__c);
			if (changeRequested) {
				filteredItems.add(currentItem);
			}
		}

		return filteredItems;
	}


	 /*****************************
	 * Description: Enforces OPC classification override from renewal to growth (for newly inserted records)
	 * @parameter opportunityLineItems : a list of opportunityLineItem candidates to override
	 * Author: Ken McGuire
	 * History:
	 * 06/02/2022 Created
	 ****************************/
	private static void overrideRenewalToGrowth(List<OpportunityLineItem> opportunityLineItems) {

		// If there are no items nothing to do.
		if (opportunityLineItems.isEmpty()) {
			return;
		}

		// iterate through all the line items that have the growth override
		for (OpportunityLineItem currentItem : getNewOverrideRenewalToGrowth(opportunityLineItems)) {
			// if the item is renewal and it shoud be growth, change it.
			// If the item is not renewal and also not growth, you can't override it.
			system.debug('***** CALCULATING CLASSIFICATION INSIDE OPPORTUNITY LINE ITEM SERVICE');
            if (currentItem.Classification__c == Constants.CLSS_RENEWAL) {
				currentItem.Classification__c = Constants.CLSS_GROWTH;
			} else if (currentItem.Classification__c != Constants.CLSS_GROWTH) {
				currentItem.Change_Classification__c.addError(Label.Not_Renewal);
			}
		}
	}

	/*****************************
	 * Description: Enforces OPC classification override from renewal to growth (for updated records)
	 * @parameter opportunityLineItems : a list of opportunityLineItem candidates to override
	 * @parameter priorValues : trigger old map values (for update) or null (for insert)
	 * Author: Ken McGuire
	 * History:
	 * 06/02/2022 Created
	 ****************************/
	private static void overrideRenewalToGrowth(List<OpportunityLineItem> opportunityLineItems, Map<id,OpportunityLineItem> priorValues) {

		// If there are no opportunity line items, nothing to do
		if (opportunityLineItems.isEmpty()) {
			return;
		}

		// retrieve items that have changed the growth override flag
		for (OpportunityLineItem currentItem : getNewOverrideRenewalToGrowth(opportunityLineItems,priorValues)) {
			// if the item is renewal and it shoud be growth, change it.
			// If the item is not renewal and also not growth, you can't override it.
			system.debug('CALCULATING CLASSIFICATION INSIDE OPPORTUNITY LINE ITEM SERVICE');
			if (currentItem.Classification__c == Constants.CLSS_RENEWAL) {
				currentItem.Classification__c = Constants.CLSS_GROWTH;
			} else if (currentItem.Classification__c != Constants.CLSS_GROWTH) {
				currentItem.Change_Classification__c.addError(Label.Not_Renewal);
			}
		}
	}


	 /*****************************
	 * Description: filters a list of opportunity line items (for updated records),
	 * returning only those items that have requested OPC override from Renewal to Growth.
	 * @parameter opportunityLineItems : a list of opportunityLineItems to filter
	 * @parameter priorValues : the prior values for the list of opportunity line items.
	 * @returns a filtered list of opportunityLineItem containing only those items that have not been overridden.
	 * Author: Ken McGuire
	 * History:
	 * 06/02/2022 Created
	 ****************************/
	private static List<OpportunityLineItem> getNewOverrideRenewalToGrowth(List<OpportunityLineItem> opportunityLineItems, Map<Id,OpportunityLineItem> priorValues) {

		// a list of items that have requested renewal to growth override
		List<OpportunityLineItem> filteredItems = new List<OpportunityLineItem>();

		// build list
		for (OpportunityLineItem currentItem : opportunityLineItems) {
			// change requested must have changed from no to yes.
			boolean changeRequested = Constants.YES_STRING.equalsIgnoreCase(currentItem.Change_Classification__c) && Constants.NO_STRING.equalsIgnoreCase(priorValues.get(currentItem.id).Change_Classification__c);
			if (changeRequested) {
				filteredItems.add(currentItem);
			}
		}

		return filteredItems;
	}

	/*****************************
	 * Description: determines if an opportunity line items OPC value has been overridden.
	 * @parameter item : the opportunity line item to evaluate
	 * @returns true if the OPC value has been overridden.
	 * Author: Ken McGuire
	 * History:
	 * 06/02/2022 Created
	 ****************************/
	private static boolean isOverride(OpportunityLineItem item) {

		return Constants.YES_STRING.equalsIgnoreCase(item.OPCOverride__c) && String.isNotBlank(item.Classification__c);

	}

	 /*****************************
	 * Description: determines if an opportunity line items OPC value has been overridden from renewal to growth.
	 * @parameter item : the opportunity line item to evaluate
	 * @returns true if the OPC value has been overridden from renewal to growth.
	 * Author: Ken McGuire
	 * History:
	 * 06/02/2022 Created
	 ****************************/
	private static boolean isGrowthOverride(OpportunityLineItem item) {

		return Constants.YES_STRING.equalsIgnoreCase(item.Change_Classification__c) && item.Classification__c == Constants.CLSS_GROWTH;

	}
	/*****************************
	 * Description: determines if an opportunity line items has changed such that
	 * the OPC value requires recalcuation.
	 * @parameter item : the opportunity line item to evaluate
	 * @parameter priorValue : the prior value of the item
	 * @returns true if the OPC value requires recalculation.
	 * Author: Ken McGuire
	 * History:
	 * 06/02/2022 Created
	 ****************************/
	private static boolean requiresRecalculation(OpportunityLineItem item, OpportunityLineItem priorValue) {

		boolean datesHaveChanged = item.Contract_Start_Date__c != priorValue.Contract_Start_Date__c
									|| item.Contract_End_Date__c != priorValue.Contract_End_Date__c;

		boolean growthOverrideChanged = item.Change_Classification__c != priorValue.Change_Classification__c;

		return datesHaveChanged || growthOverrideChanged;
	}

	private static List<Opportunity> loadOpenOpportunities(Set<Id> opportunityIds) {
		// future refactoring notes - use a selector here
		return [SELECT Id, AccountId, StageName
				FROM Opportunity
				WHERE Id IN :opportunityIds
				and StageName != :Constants.CLOSED_WON
				LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())];

	}

 /*****************************
	* Description: insert Revenue Start/End Date when OLI in inserted
	* @parameter item : the opportunity line item to evaluate
	* @returns viod.
	* Author: Nasir Jawed
	* History:
	* 14/03/2023 Created
	****************************/
	public static void populateRevenueDate(List<OpportunityLineItem> newOppLineItemList) {

		set<Id> oppIds= new set<Id>();
		map<id,Date> oppIdcloseDateMap= new map<id,date>();

		//filtering the opportunity line item only for Conga related line item and Prepairing a set for all the opportunity Id
		for(OpportunityLineItem oli : newOppLineItemList){
			if(oli.Contract_Number__c != null && oli.Contract_Number__c != ''){
				oppIds.add(oli.OpportunityId);
			}
		}

		//Querying the opportunity record to get close date and Owner and populating the map
		List<Opportunity> oppList = OpportunitySelector.newInstance(0,new Set<SObjectField>{Opportunity.CloseDate,Opportunity.Id,Opportunity.OwnerId}).selectById(oppIds).values();

		for(Opportunity o: oppList){
			if(o.closeDate !=null){
				oppIdcloseDateMap.put(o.id,o.closeDate);
			}
		}

		//populating the value for start date and end date for above prepared data
		for(OpportunityLineItem oli:newOppLineItemList){
			if(oppIdcloseDateMap.get(oli.opportunityId) != null){
				oli.Contract_Start_Date__c =oppIdcloseDateMap.get(oli.opportunityId).addDays(APT_Constants.START_DATE_BUFFER_DAYS);
				oli.Contract_End_Date__c = oli.Contract_Start_Date__c.addDays(APT_Constants.END_DATE_BUFFER_DAYS) ;
			}
		}

	}

	/*****************************
	 * Description: a data structure that contains sales history and parameters used in OPC calculations for
	 * an opportunity line item.
	 * Author: Ken McGuire
	 * History:
	 * 26/08/2022 Created
	 ****************************/
	public class TradingHistoryInfo {
		public OpportunityLineItem optyLine;
		public Boolean isTradingAccount;
		public Boolean accountTradeExceedsNTA;
		public Boolean productPreviouslyTraded;
		public Boolean productTradeExceedsNTA;
		public Boolean anyTradedProdcutExceedsNTA;
		public Id parentAccountId;
		public double ntAmount;
		// constructor
		public TradingHistoryInfo(OpportunityLineItem optyLine,TradingHistoryMaps tradingHistoryMaps, double ntAmount) {
			this.optyLine = optyLine;
			parentAccountId = tradingHistoryMaps.optyOrgMap.get(optyLine.OpportunityId);
			isTradingAccount = tradingHistoryMaps.tradedAcctSet.contains(parentAccountId) ;
			accountTradeExceedsNTA = tradingHistoryMaps.significantTradeAccounts.contains(parentAccountId);
			productPreviouslyTraded = tradingHistoryMaps.productPreviouslyTraded(parentAccountId,optyLine.Product2Id);
			productTradeExceedsNTA = tradingHistoryMaps.productSignificantlyTraded(parentAccountId,optyLine.Product2Id);
			anyTradedProdcutExceedsNTA = tradingHistoryMaps.anyProductSignificantlyTraded(parentAccountId);
			this.ntAmount = ntAmount;
		}
	}
	/*****************************
	* Description: a data structure that contains sales revenue history maps (collection) for Accounts, Opportunities and Line Items.
	* an opportunity line item.
	* Author: Ken McGuire
	* History:
	* 26/08/2022 Created
	****************************/
	public class TradingHistoryMaps {

		public Set<Id> tradedAcctSet = new Set<Id>();
		public Set<String> significantTradeAccounts = new Set<String>();
		public Map<Id,Set<Id>> tradedProductSet = new Map<Id,Set<Id>>();
		public Map<Id, Set<Id>> significantTradedProductSet = new Map<Id, Set<Id>>();
		public Map<Id, Id> optyOrgMap = new Map<Id, Id>();

		public void addTradedProduct(Id accountId, Id productId) {
			if (tradedProductSet.containsKey(accountId)) {
				tradedProductSet.get(accountId).add(productId);
			} else {
				tradedProductSet.put(accountId,new Set<Id>{productId});
			}
		}

		public void addSignificantTradedProduct(Id accountId, Id productId) {
			if (significantTradedProductSet.containsKey(accountId)) {
				significantTradedProductSet.get(accountId).add(productId);
			} else {
				significantTradedProductSet.put(accountId,new Set<Id>{productId});
			}
		}

		public boolean productPreviouslyTraded(Id accountId, Id productId) {
			if(!tradedProductSet.containsKey(accountId)) {
				return false;
			}
			return tradedProductSet.get(accountId).contains(productId);
		}

		public boolean productSignificantlyTraded(Id accountId, Id productId) {
			if(!anyProductSignificantlyTraded(accountId)) {
				return false;
			}
			return significantTradedProductSet.get(accountId).contains(productId);
		}

		public boolean anyProductSignificantlyTraded(Id accountId) {
			return significantTradedProductSet.containsKey(accountId);
		}
	}
	// custom exception handling
	public class OPCException extends Exception {}
}