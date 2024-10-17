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
7/10/2024 Ken McGuire Removed obsolete line item opc classification methods.
------------------------------------------------------------*/
public inherited sharing class OpportunityLineItemService {
	public static final String CLASSNAME = 'OpportunityLineItemService';
	public static final String ORGID = UserInfo.getOrganizationId();
	public static final String triggerName = 'OpportunityLineItemTrigger';
	private static final Id userId = userinfo.getProfileId();//get the current user's Profile ID
	private static final String currentProfileName = [SELECT Name FROM Profile WHERE Id = :userId].Name;
	private static final Set<String> salesAdminProfiles = Constants.salesAdminProfiles();
	private static final Set<String> salesUserProfiles = Constants.salesUserProfiles();
    
	public static List<OpportunityLineItem> getPreClassifiedLineItems(List<OpportunityLineItem> items) {
	
		if (items == null || items.isEmpty() || items[0].Opportunity.AccountId == null) {
			return items;
		 
		}
		// return the opportunity line items with freshly cacluated OPC values
		return items;
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