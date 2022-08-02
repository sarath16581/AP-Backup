/*------------------------------------------------------------
Author:   :      Jeoffrey Palmero
Date Created:    07/29/2019
Description:     Handles logic related to the Opportunity Line Item
History
<Date>           <Authors Name>     <Brief Description of Change>
07/29/2019        JPalmero           Created
28/06/2022		  KMcGuire			 Modified for including related account sales in OPC classification
------------------------------------------------------------*/
public class OpportunityLineItemService {
    public static final String CLASSNAME = 'OpportunityLineItemService';
    public static final String ORGID = UserInfo.getOrganizationId();
    public static final String triggerName = 'OpportunityLineItemTrigger';
    private static final Id userId = userinfo.getProfileId();//get the current user's Profile ID
    private static final String currentProfileName = [SELECT Name FROM Profile WHERE Id = :userId].Name;
    private static final Set<String> salesAdminProfiles = Constants.salesAdminProfiles();
    private static final Set<String> salesUserProfiles = Constants.salesUserProfiles();
    // INSERT OF OPPORTUNITY LINE ITEM
     /*****************************
     * Description: Populate the classification field upon insertion of new opportunity line item or upon change of opportunity to closed won.
     * Author: JPalmero
     * History:
     * 7/31/2019            Created
     * 22/07/2022	Ken McGuire	Modified
     ****************************/
    public static void populateClassification(List<OpportunityLineItem> newOptyLineItemList){
        Set<Id> productIdSet = new Set<Id>();
       	Set<Id> optyIdSet = new Set<Id>();
        Map<Id, Id> optyOrgMap = new Map<Id, Id>();
        for(OpportunityLineItem optyLine : newOptyLineItemList){
            productIdSet.add(optyLine.Product2Id);//saves the product Id to the list
            optyIdSet.add(optyLine.OpportunityId);
        }
        Set<String> accountIdSet = new Set<String>();
        if(optyIdSet != NULL) {
            for(Opportunity optyObj : [SELECT Id, AccountId, StageName 
                                       FROM Opportunity 
                                       WHERE Id IN: optyIdSet
                                       LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())]) {
				optyOrgMap.put(optyObj.Id, optyObj.AccountId);//saves the org in a map for later use
            	accountIdSet.add(optyObj.AccountId);//gets the opportunity's account id                    
         	}
        }
        updateClassification(newOptyLineItemList,accountIdSet,optyOrgMap);
    }
    
    // INSERT OF OPPORTUNITY LINE ITEM
    /*****************************
     * Description: Populate the classification field upon insertion of new opportunity line item or upon change of opportunity to closed won.
     * Author: JPalmero
     * History:
     * 7/31/2019            Created
     * 22/07/2022	Ken McGuire	Modified
     ****************************/
   public static List<OpportunityLineItem> updateClassification(List<OpportunityLineItem> lineItemsToUpdate,Set<String> accountIdSet,Map<Id, Id> optyOrgMap  ){
        Integer barCYear;
        Integer barPYear;
        Integer startMonth;
        Decimal orgRev;
        Decimal prodRev;
        Decimal totalRevenue;
        Decimal totalOutsideRevenue;
        OpportunityLineItem oldRec = new OpportunityLineItem();

		List<OpportunityLineItem> updatedLineItems = new List<OpportunityLineItem>();

        Map<Id, String> acctRevenueMap = new Map<Id, String>();
        Map<Id, String> optyStageMap = new Map<Id, String>();
        Map<String, Decimal> fyProductMap = new Map<String, Decimal>();
        NominalTradeAmount__c ntAmount = NominalTradeAmount__c.getInstance();
        
        TradingHistoryMaps tradingHistoryMaps = new TradingHistoryMaps();
        
        tradingHistoryMaps.optyOrgMap = optyOrgMap;
        
        try{
            OPCUtility.calculateParentAccountRevenueMaP(accountIdSet);
            List<OPCUtility.ParentAccountRevenue> revenue = OPCUtility.parentAccountRevenueMap.values();
            revenue.sort();
            populateGroupedTradingHistoryMaps(tradingHistoryMaps,revenue,(Double) ntAmount.Amount__c);
       
        	for(OpportunityLineItem optyLine : lineItemsToUpdate){
			
                string newClassification = getClassification(New TradingHistoryInfo(optyLine,tradingHistoryMaps,(Double)ntAmount.Amount__c)); 
                
                if (optyLine.Classification__c != newClassification) {
                    optyLine.Classification__c = newClassification;
                    if(salesUserProfiles.contains(currentProfileName) && !Constants.growthCLSS().contains(optyLine.Classification__c) && Constants.YES_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){
                        optyLine.Change_Classification__c.addError(Label.Not_Renewal);
                    }
                    updatedLineItems.add(optyLine);
                }
        	}
            
        }catch(exception excp){
            system.debug('********* '+excp.getMessage());
            system.debug('********* '+excp.getStackTraceString());
            UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'populateClassification', triggerName, LoggingLevel.ERROR);
        }
        return updatedLineItems;
    }
    
    // CHANGE TO OPPORTUNITY LINE ITEM
    /**********************************
     * Description: Update the classification field upon change of Opty Line Item's Revenue Dates
     * Author: JPalmero
     * History:
     * 8/19/2019            Created
     ****************************/
    public static void updateClassification(List<OpportunityLineItem> newOptyLineItemList, Map<Id, OpportunityLineItem> oldRecMap){
        Integer contractStartYear;
        Integer contractStartMonth;
        Decimal orgRev;
        Decimal prodRev;
        Decimal totalRevenue;
        Decimal totalOutsideRevenue;
        OpportunityLineItem oldRec = new OpportunityLineItem();
        List<OpportunityLineItem> newOptyProdList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> optyLIToUpdate = new List<OpportunityLineItem>();
        NominalTradeAmount__c ntAmount = NominalTradeAmount__c.getInstance();
		TradingHistoryMaps tradingHistoryMaps = new TradingHistoryMaps();
        Set<Id> optyIdSet = new Set<Id>();
        Set<String> accountIdSet = new Set<String>();
        Map<Id, String> optyStageMap = new Map<Id, String>();
        try{
            for(OpportunityLineItem optyLine : newOptyLineItemList){
                oldRec = oldRecMap != NULL && oldRecMap.containsKey(optyLine.Id) ? oldRecMap.get(optyLine.Id) : NULL;
                if((optyLine.Contract_Start_Date__c != oldRec.Contract_Start_Date__c) ||
                   (optyLine.Contract_End_Date__c != oldRec.Contract_End_Date__c) ||
                   ((salesAdminProfiles.contains(currentProfileName)) && (optyLine.Classification__c != oldRec.Classification__c) &&
                    !(Constants.CLSS_GROWTH.equalsIgnoreCase(oldRec.Classification__c) || Constants.CLSS_RENEWAL.equalsIgnoreCase(oldRec.Classification__c))))
                {//if revenue dates change and Classification shouldn't be Growth
                       optyIdSet.add(optyLine.OpportunityId);//saves the opportunity IDs of Line Items whose Dates changed (10/4/19: ...and Classification too)
                       newOptyProdList.add(optyLine);//saves the Line Items that fits the criteria to specify the values to be looped later
                }
                if(salesUserProfiles.contains(currentProfileName) && !Constants.growthCLSS().contains(optyLine.Classification__c) 
                   && Constants.YES_STRING.equalsIgnoreCase(optyLine.Change_Classification__c) && Constants.NO_STRING.equalsIgnoreCase(oldRec.Change_Classification__c)){
                    optyLine.Change_Classification__c.addError(Label.Not_Renewal);//Sales User cannot set YES if it is not Renewal
                }
                if(!Constants.CLSS_Growth.equalsIgnoreCase(optyLine.Classification__c) && Constants.CLSS_GROWTH.equalsIgnoreCase(oldRec.Classification__c)){
                    //From Growth to ANY, Growth? -> NO
                    optyLine.Change_Classification__c = Constants.NO_STRING;
                }
                if(Constants.CLSS_GROWTH.equalsIgnoreCase(optyLine.Classification__c) && !Constants.CLSS_GROWTH.equalsIgnoreCase(oldRec.Classification__c)){
                    //Any value to Growth, Growth? -> YES
                    optyLine.Change_Classification__c = Constants.YES_STRING;               
                }
            }
            
            if(optyIdSet != NULL){
                for(Opportunity optyObj : [SELECT Id, AccountId, StageName 
                                           FROM Opportunity 
                                           WHERE Id IN: optyIdSet
                                           LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())]){
                    tradingHistoryMaps.optyOrgMap.put(optyObj.Id, optyObj.AccountId);//saves the Opty's Organisation
                    optyStageMap.put(optyObj.Id, optyObj.StageName);//saves the Opty's Stage
                    accountIdSet.add(optyObj.AccountId);//gets the opportunity's account id
                }
            }
            if(accountIdSet != NULL){//get all T&R records from the organisation
            	OPCUtility.calculateParentAccountRevenueMaP(accountIdSet);
                 populateGroupedTradingHistoryMaps(tradingHistoryMaps,OPCUtility.parentAccountRevenueMap.values(),(Double) ntAmount.Amount__c);
            }
            for(OpportunityLineItem optyLine : newOptyProdList){
                if(Constants.NO_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){//if the Classification is not Growth, Growth? should be NO
                    optyLine.Classification__c = getClassification(New TradingHistoryInfo(optyLine,TradingHistoryMaps,(Double)ntAmount.Amount__c)); 
                }
            }
        }catch(exception excp){
            system.debug('********* '+excp.getMessage());
            system.debug('********* '+excp.getStackTraceString());
            UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'updateClassification', triggerName, LoggingLevel.ERROR);
        }
    }
    
    private static void populateGroupedTradingHistoryMaps(TradingHistoryMaps tradingHistoryMaps, List<OPCUtility.ParentAccountRevenue> revenue, double ntAmount) {
         	for (OPCUtility.ParentAccountRevenue bar : revenue ) {
                bar.group();             					
                tradingHistoryMaps.addTradedProduct(bar.Organisation,bar.Product);//products that an account has traded with AuPost
                tradingHistoryMaps.tradedAcctSet.add(bar.Organisation);//accounts in this set have traded any product
                
                if(bar.Total_Revenue_Amount > ntAmount) {//if Total Revenue exceeds the NTA, save the id
                    tradingHistoryMaps.significantTradeAccounts.add(bar.Organisation);
                    tradingHistoryMaps.addSignificantTradedProduct(bar.Organisation,bar.Product);
                }
            }//end BaR for
    }
    
    private static string getClassification(TradingHistoryInfo tradingHistoryInfo) {
       String classification = salesclassification(tradingHistoryInfo);
       if (classification == null) classification = getClassificationFromAccountTradingHistory(tradingHistoryInfo);
        return classification == null ? tradingHistoryInfo.optyLine.Classification__c : classification;
    }
    
    private static string getClassificationFromAccountTradingHistory(TradingHistoryInfo tradingHistoryInfo) {
        if (tradingHistoryInfo.optyLine.Contract_Start_Date__c == null) return tradingHistoryInfo.optyLine.Classification__c;
        Integer contractStartMonth = tradingHistoryInfo.optyLine.Contract_Start_Date__c.MONTH();//get the start month for 12 months computation
        Integer contractStartYear = tradingHistoryInfo.optyLine.Contract_Start_Date__c.YEAR();//to check which Financial Year it will be taken from
        Double totalRevenue = 0;
        Double totalOutsideRevenue = 0;
        
        if(contractStartMonth > 6) { 
            
            String previousYearRevenueKey = OPCUtility.constructRevenueKey(tradingHistoryInfo.parentAccountId,tradingHistoryInfo.optyLine.Product2Id,contractStartYear-1);
            String currentYearRevenueKey = OPCUtility.constructRevenueKey(tradingHistoryInfo.parentAccountId,tradingHistoryInfo.optyLine.Product2Id,contractStartYear);
            String subsequentYearRevenueKey = OPCUtility.constructRevenueKey(tradingHistoryInfo.parentAccountId,tradingHistoryInfo.optyLine.Product2Id,contractStartYear+1);
            
            // get totals from the previous year
            if(OPCUtility.parentAccountRevenueMap.containsKey(previousYearRevenueKey)) {
                // total outside revenue = total revenue for the year less the months betweeen July and the contract start date
                totalOutsideRevenue += OPCUtility.parentAccountRevenueMap.get(previousYearRevenueKey).getRevenue(1,6);
                totalOutsideRevenue += OPCUtility.parentAccountRevenueMap.get(previousYearRevenueKey).getRevenue(contractStartMonth,12);
            }
            // add totals from the current year
            if(OPCUtility.parentAccountRevenueMap.containsKey(currentYearRevenueKey)) {
                
                totalOutsideRevenue += OPCUtility.parentAccountRevenueMap.get(currentYearRevenueKey).getRevenue(7,contractStartMonth);
                totalRevenue +=  OPCUtility.parentAccountRevenueMap.get(currentYearRevenueKey).getRevenue(1,6);
                totalRevenue +=  OPCUtility.parentAccountRevenueMap.get(currentYearRevenueKey).getRevenue(contractStartMonth,12);
            }
            // add totals for the subsequent year 
            if(OPCUtility.parentAccountRevenueMap.containsKey(subsequentYearRevenueKey)) {
                totalRevenue += OPCUtility.parentAccountRevenueMap.get(subsequentYearRevenueKey).getRevenue(7,contractStartMonth);
            }
        }
        else {
            String twoYearsAgoRevenueKey = OPCUtility.constructRevenueKey(tradingHistoryInfo.parentAccountId,tradingHistoryInfo.optyLine.Product2Id,contractStartYear-2);
            String previousYearRevenueKey = OPCUtility.constructRevenueKey(tradingHistoryInfo.parentAccountId,tradingHistoryInfo.optyLine.Product2Id,contractStartYear-1);
            String currentYearRevenueKey = OPCUtility.constructRevenueKey(tradingHistoryInfo.parentAccountId,tradingHistoryInfo.optyLine.Product2Id,contractStartYear);
            
            // get totals from two years ago
            if(OPCUtility.parentAccountRevenueMap.containsKey(twoYearsAgoRevenueKey)) {
                // total outside revenue = total revenue for the year less the months betweeen July and the contract start date
                totalOutsideRevenue += OPCUtility.parentAccountRevenueMap.get(twoYearsAgoRevenueKey).getRevenue(contractStartMonth,6);
            }
            // add totals from last year
            if(OPCUtility.parentAccountRevenueMap.containsKey(previousYearRevenueKey)) {
                
                totalOutsideRevenue += OPCUtility.parentAccountRevenueMap.get(previousYearRevenueKey).getRevenue(1,contractStartMonth);
                totalOutsideRevenue +=  OPCUtility.parentAccountRevenueMap.get(previousYearRevenueKey).getRevenue(7,12);
                totalRevenue +=  OPCUtility.parentAccountRevenueMap.get(previousYearRevenueKey).getRevenue(contractStartMonth,6);
            }
            // add totals for this year
            if(OPCUtility.parentAccountRevenueMap.containsKey(currentYearRevenueKey)) {
                totalRevenue += OPCUtility.parentAccountRevenueMap.get(currentYearRevenueKey).getRevenue(1,contractStartMonth);
                totalRevenue += OPCUtility.parentAccountRevenueMap.get(currentYearRevenueKey).getRevenue(7,12);
            }
        } 
		String classification = salesClassification(tradingHistoryInfo,totalRevenue,totalOutsideRevenue);
        if (classification == null) {
           	String debugValues = tradingHistoryInfo.isTradingAccount +','+  
               					 tradingHistoryInfo.accountTradeExceedsNTA +','+ 
               					 tradingHistoryInfo.productPreviouslyTraded  +','+  
               					 tradingHistoryInfo.productTradeExceedsNTA  +','+  
               					 tradingHistoryInfo.anyTradedProdcutExceedsNTA +','+  
               					 totalRevenue +','+  
               					 totalOutsideRevenue;  
           	OPCException excp = new OPCException(debugValues); 
        	UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'getClassificationFromAccountTradingHistory', triggerName, LoggingLevel.ERROR);
        }
        return classification;

    }

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
        if(totalRevenue < tradingHistoryInfo.ntAmount && totalOutsideRevenue <  tradingHistoryInfo.ntAmount && tradingHistoryInfo.anyTradedProdcutExceedsNTA) {
            return Constants.CLSS_CROSSSELL;
        }
        //if the total revenue exceeds the NTA, it can either be Renewal or Growth depending on the Growth? field
        if(totalRevenue > tradingHistoryInfo.ntAmount  && Constants.NO_STRING.equalsIgnoreCase(tradingHistoryInfo.optyLine.Change_Classification__c)) { 
            return Constants.CLSS_RENEWAL;
        }
        if(totalRevenue > tradingHistoryInfo.ntAmount && Constants.YES_STRING.equalsIgnoreCase(tradingHistoryInfo.optyLine.Change_Classification__c)) {
            return Constants.CLSS_GROWTH;
        }

        return null;
    }
    
    /*****************************
     * Description: Prevents deletion of record if the Opty's Stage is Closed Won if the current user is a Coverage Sales user
     * Author: JPalmero
     * History:
     * 8/26/2019            Created
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
            system.debug('********* '+excp.getMessage());
            system.debug('********* '+excp.getStackTraceString());
            UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'beforeDeleteValidation', triggerName, LoggingLevel.ERROR);
        }
    }
    
    /*****************************
     * Description: Changes the classification from Renewal to Growth and vice versa if the user is a Coverage Sales User
     * Author: JPalmero
     * History:
     * 9/10/2019            Created
     ****************************/
    public static void changeClassification(List<OpportunityLineItem> newOptyLineItemList, Map<Id, OpportunityLineItem> oldRecMap){
        Set<Id> optyIdSet = new Set<Id>();
        Map<Id, String> optyStageMap = new Map<Id, String>();
        OpportunityLineItem oldRec = new OpportunityLineItem();
        try{
            //check if the user is a Coverage Sales user
            if(salesUserProfiles.contains(currentProfileName)){
                for(OpportunityLineItem optyLine : newOptyLineItemList){
                    oldRec = oldRecMap.containsKey(optyLine.Id) ? oldRecMap.get(optyLine.Id) : NULL;
                    if(Constants.CLSS_RENEWAL.equalsIgnoreCase(optyLine.Classification__c) &&
                       (Constants.NO_STRING.equalsIgnoreCase(oldRec.Change_Classification__c) && Constants.YES_STRING.equalsIgnoreCase(optyLine.Change_Classification__c))){
                           optyLine.Classification__c = Constants.CLSS_GROWTH;
                           //if the Classification is Renewal and the Growth? field is set from NO to YES, Classification will be changed to Growth
              
                       }
                    //if the Classification is Growth and the Growth? field is set from YES to NO, Classification will be changed to Renewal
                    else if(Constants.CLSS_GROWTH.equalsIgnoreCase(optyLine.Classification__c) && 
                       (Constants.YES_String.equalsIgnoreCase(oldRec.Change_Classification__c) && Constants.NO_STRING.equalsIgnoreCase(optyLine.Change_Classification__c))){
                           optyLine.Classification__c = Constants.CLSS_RENEWAL;
                       }
                }
            }
        } catch(exception excp){
       		system.debug('********* '+excp.getMessage());
            system.debug('******** '+excp.getStackTraceString());
            UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'changeClassification', triggerName, LoggingLevel.ERROR);
        }
    }
    
    public class TradingHistoryInfo {
        public OpportunityLineItem optyLine;
   		public Boolean isTradingAccount;
		public Boolean accountTradeExceedsNTA;
		public Boolean productPreviouslyTraded;
		public Boolean productTradeExceedsNTA;
		public Boolean anyTradedProdcutExceedsNTA;
        public Id parentAccountId;
        public double ntAmount;
        public TradingHistoryInfo(){}
        public TradingHistoryInfo( OpportunityLineItem optyLine,TradingHistoryMaps tradingHistoryMaps, double ntAmount) {
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
    
    public class TradingHistoryMaps {
    
        public Set<Id> tradedAcctSet = new Set<Id>();
        public Set<String> significantTradeAccounts = new Set<String>();
        public Map<Id,Set<Id>> tradedProductSet = new Map<Id,Set<Id>>();
        public Map<Id, Set<Id>> significantTradedProductSet = new Map<Id, Set<Id>>();
        public Map<Id, Id> optyOrgMap = new Map<Id, Id>();
        
        public void addTradedProduct(Id accountId, Id productId) {
            if (tradedProductSet.containsKey(accountId)) 
            	tradedProductSet.get(accountId).add(productId);
           	else    
                tradedProductSet.put(accountId,new Set<Id>{productId});
            
        }
        
        public void addSignificantTradedProduct(Id accountId, Id productId) {
            if (significantTradedProductSet.containsKey(accountId)) 
            	significantTradedProductSet.get(accountId).add(productId);
           	else    
                significantTradedProductSet.put(accountId,new Set<Id>{productId});
        }
        
        public boolean productPreviouslyTraded(Id accountId, Id productId) {
            if(!tradedProductSet.containsKey(accountId)) return false;
            return tradedProductSet.get(accountId).contains(productId);
        }
        
        public boolean productSignificantlyTraded(Id accountId, Id productId) {
            if(!anyProductSignificantlyTraded(accountId)) return false;
            return significantTradedProductSet.get(accountId).contains(productId);
        }
        
        public boolean anyProductSignificantlyTraded(Id accountId) {
            return significantTradedProductSet.containsKey(accountId);
        }
    }
    public class OPCException extends Exception {}
}