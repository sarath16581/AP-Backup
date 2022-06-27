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
    /*****************************
     * Description: Populate the classification field upon update
     * Author: JPalmero
     * History:
     * 7/31/2019            Created
     ****************************/
    public static void populateClassification(List<OpportunityLineItem> newOptyLineItemList){
        Integer barMonth;
        Integer barCYear;
        Integer barPYear;
        Integer startMonth;
        Decimal orgRev;
        Decimal prodRev;
        Decimal totalRevenue;
        Decimal totalOutsideRevenue;
        OpportunityLineItem oldRec = new OpportunityLineItem();
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> tradedAcctSet = new Set<Id>();
        Set<Id> tradedProductSet = new Set<Id>();
        Set<Id> optyIdSet = new Set<Id>();
        Map<Id, Id> optyOrgMap = new Map<Id, Id>();
        Map<Id, String> acctRevenueMap = new Map<Id, String>();
        Map<Id, String> optyStageMap = new Map<Id, String>();
        Map<Id, String> orgProductMap = new Map<Id, String>();
        Map<Id, Decimal> productTotalRevMap = new Map<Id, Decimal>();
        Map<String, Decimal> fyProductMap = new Map<String, Decimal>();
        Map<String, Decimal> barTotalRevMap = new Map<String, Decimal>();
        NominalTradeAmount__c ntAmount = NominalTradeAmount__c.getInstance();
        
        try{
            for(OpportunityLineItem optyLine : newOptyLineItemList){
                productIdSet.add(optyLine.Product2Id);//saves the product Id to the list
                optyIdSet.add(optyLine.OpportunityId);
            }
            Set<String> accountIdSet = new Set<String>();
            if(optyIdSet != NULL){
                for(Opportunity optyObj : [SELECT Id, AccountId, StageName 
                                           FROM Opportunity 
                                           WHERE Id IN: optyIdSet
                                           LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())]){
                    optyOrgMap.put(optyObj.Id, optyObj.AccountId);//saves the org in a map for later use
                    accountIdSet.add(optyObj.AccountId);//gets the opportunity's account id                    
                }
            }
            if(accountIdSet != NULL){
                List<OPCUtility.ParentAccountRevenue> revenue = OPCUtility.getParentAccountRevenueMaP(accountIdSet).values();
                revenue.sort();
                for (OPCUtility.ParentAccountRevenue bar : revenue) {
                    bar.group();             					
                    tradedProductSet.add(bar.Product);//products that have been traded with AuPost
                    tradedAcctSet.add(bar.Organisation);//accounts in this set have traded any product
                    //saves the monthly revenue of a product for the current and previous fiscal year
                    // January
                    fyProductMap.put(String.valueOf(bar.Product) + '1' + String.valueOf(bar.Financial_Year), bar.Jan_Revenue_Amount);
                    // February
					fyProductMap.put(String.valueOf(bar.Product) + '2' + String.valueOf(bar.Financial_Year), bar.Feb_Revenue_Amount);
                    // March
                    fyProductMap.put(String.valueOf(bar.Product) + '3' + String.valueOf(bar.Financial_Year), bar.Mar_Revenue_Amount);
                    // April
					fyProductMap.put(String.valueOf(bar.Product) + '4' + String.valueOf(bar.Financial_Year), bar.Apr_Revenue_Amount);
                    // May
					fyProductMap.put(String.valueOf(bar.Product) + '5' + String.valueOf(bar.Financial_Year), bar.May_Revenue_Amount);
                    // June
                    fyProductMap.put(String.valueOf(bar.Product) + '6' + String.valueOf(bar.Financial_Year), bar.Jun_Revenue_Amount);
                    // July
                    fyProductMap.put(String.valueOf(bar.Product) + '7' + String.valueOf(bar.Financial_Year), bar.Jul_Revenue_Amount);
                    // August
                   	fyProductMap.put(String.valueOf(bar.Product) + '8' + String.valueOf(bar.Financial_Year), bar.Aug_Revenue_Amount);
                    // September
                   	fyProductMap.put(String.valueOf(bar.Product) + '9' + String.valueOf(bar.Financial_Year), bar.Sep_Revenue_Amount);
                    // October
                    fyProductMap.put(String.valueOf(bar.Product) + '10' + String.valueOf(bar.Financial_Year), bar.Oct_Revenue_Amount);
                    // November
                    fyProductMap.put(String.valueOf(bar.Product) + '11' + String.valueOf(bar.Financial_Year), bar.Nov_Revenue_Amount);
                    // December
                    fyProductMap.put(String.valueOf(bar.Product) + '12' + String.valueOf(bar.Financial_Year), bar.Dec_Revenue_Amount);
                    
                    if(bar.Total_Revenue_Amount > ntAmount.Amount__c){//if Total Revenue exceeds the NTA, save the id
                        barTotalRevMap.put(bar.Organisation, bar.Total_Revenue_Amount);
                        productTotalRevMap.put(bar.Product, bar.Total_Revenue_Amount);
                        orgProductMap.put(bar.Organisation, bar.Product);
                    }

                }//end BaR for
            }
            for(OpportunityLineItem optyLine : newOptyLineItemList){
                startMonth = optyLine.Contract_Start_Date__c.MONTH();//get the start month for 12 months computation
                barCYear = optyLine.Contract_Start_Date__c.YEAR();//to check from which financial year it will be taken from
                
                //if there hasn't been any trade or the total revenue is <NTA
                if(!tradedAcctSet.contains(optyOrgMap.get(optyLine.OpportunityId)) || !barTotalRevMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){                
                    optyLine.Classification__c = Constants.CLSS_NEWBUSINESS;
                }
                
                //if the product has been traded before but is less than the NTA && has no other product that exceeded the NTA
                else if(tradedProductSet.contains(optyLine.Product2Id) && !productTotalRevMap.containsKey(optyLine.Product2Id) && !orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){
                    optyLine.Classification__c = Constants.CLSS_NEWBUSINESS;
                }
                
                //if the product has been traded before but is less than the NTA && has no other product that exceeded the NTA
                else if(tradedProductSet.contains(optyLine.Product2Id) && !productTotalRevMap.containsKey(optyLine.Product2Id) && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){
                    optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                }
                
                //if the product has never been traded and the org has traded other product with Total Revenue > NTA
                else if(!tradedProductSet.contains(optyLine.Product2Id) && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){
                    optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                }
                 
                else if(startMonth > 6){
                    //outside the 12 months of trade
                    for(Integer countRev = startMonth; countRev > 6 ; countRev--){
                        if(countRev == startMonth){//Start is AUG2019
                            //AUG2019 to JUL2019
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                totalOutsideRevenue = fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                            }
                            else{//if there are no values to be retrieved, sets it to 0
                                totalOutsideRevenue = 0;
                            }
                        }
                        else{
                        //System.assertEquals(totalOutsideRevenue, fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear)));
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                            }
                            else{//if there are no values to be retrieved, adds 0
                                totalOutsideRevenue += 0;
                            }
                        }
                    }
                    
                    //Example: Gets revenue for June back to January FY2018
                    for(Integer countRev = 6; countRev > 0; countRev--){//computes from January to June of the PFY
                        if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                            totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                        }
                        else{//if there are no values to be retrieved, adds 0
                            totalOutsideRevenue += 0;
                        }
                    }
                    
                    //Example: Gets revenue for AUG to December FY2018
                    for(Integer countRev = startMonth; countRev < 13; countRev++){//computes from January to June of the CFY
                        if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                            totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                        }
                        else{//if there are no values to be retrieved, adds 0
                            totalOutsideRevenue += 0;
                        }
                    }
                    
                    //within the 12 months of trade
                    for(Integer countRev = startMonth; countRev > 6 ; countRev--){
                        if(countRev == startMonth){//Start month to July for the Next FY
                            //Example: Start Date: 08/2019
                            //Gets the revenue for August back to July FY2020
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear+1))){
                                totalRevenue = fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear+1));
                            }
                            else{//if there are no values to be retrieved, sets it to 0
                                totalRevenue = 0;
                            }
                        }
                        else{
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear+1))){
                                totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear+1));
                            }
                            else{//if there are no values to be retrieved, adds 0
                                totalRevenue += 0;
                            }
                        }
                    }
                    
                    //Example: Gets revenue for June back to January FY2019
                    for(Integer countRev = 6; countRev > 0; countRev--){//computes from January to June of the CFY
                        if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                            totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                        }
                        else{//if there are no values to be retrieved, adds 0
                            totalRevenue += 0;
                        }
                    }
                    
                    //Example: Gets revenue for July to December FY2019
                    for(Integer countRev = startMonth; countRev < 13; countRev++){//computes from January to June of the CFY
                        if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                            totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                        }
                        else{//if there are no values to be retrieved, adds 0
                            totalRevenue += 0;
                        }
                    }
                    /*Example: Gets revenue for July to December FY2019
                    for(Integer countRev = startMonth; countRev < 13; countRev++){//computes from January to June of the CFY
                        if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                            totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                        }
                        else{//if there are no values to be retrieved, adds 0
                            totalRevenue += 0;
                        }
                    }*/
                    if(totalRevenue == 0 && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){//if the 12 months has no revenue and the org has other valid T&Rs
                        if(!productTotalRevMap.containsKey(optyLine.Product2Id)){//if the product has no valid T&R
                            optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                        }
                        else{//if the product has valid T&R from other FYs
                            optyLine.Classification__c = Constants.CLSS_WINBACK;
                        }
                    }
                    else if(ntAmount.Amount__c > totalRevenue){//if the total revenue is lesser than the NTA...
                        if(totalOutsideRevenue > ntAmount.Amount__c){//...but the total revenue outside the 12 months exceeds the NTA
                            optyLine.Classification__c = Constants.CLSS_WINBACK;
                        }
                        else if(totalOutsideRevenue < ntAmount.Amount__c && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){
                            //...but the total revenue outside is less than the NTA and the org has other valid T&Rs
                            optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                        }
                    }
                    else if(ntAmount.Amount__c < totalRevenue){//if the total revenue exceeds the NTA, it can either be Renewal or Growth depending on the Growth? field
                        if(Constants.NO_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){
                            optyLine.Classification__c = Constants.CLSS_RENEWAL;
                        }
                        else if(Constants.YES_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){
                            optyLine.Classification__c = Constants.CLSS_GROWTH;
                        }
                    }
                }
                
                else if(startMonth < 7){
                    for(Integer countRev = startMonth; countRev > 0 ; countRev--){//within 12 months of trade
                        if(countRev == startMonth){
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                totalOutsideRevenue = fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                            }
                            else{//if there are no values to be retrieved, set it to 0
                                totalOutsideRevenue = 0;
                            }
                        }
                        else{
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                            }
                            else{//if there are no values to be retrieved, add 0
                                totalOutsideRevenue += 0;
                            }
                        }
                    }
                    
                    //Example: Gets the revenue from July to December FY2019
                    for(Integer countRev = 7; countRev < 13; countRev++){
                        if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                            totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                        }
                        else{//if there are no values to be retrieved, add 0
                            totalOutsideRevenue += 0;
                        }
                    }
                    
                    //Example: Gets the revenue from April to June FY2018
                    for(Integer countRev = startMonth; countRev < 7; countRev++){
                        if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-2))){
                            totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-2));
                        }
                        else{//if there are no values to be retrieved, add 0
                            totalOutsideRevenue += 0;
                        }
                    }
                    
                    //Example Start Date: 04/2019
                    //Gets the revenue for Apr back to January FY2019
                    for(Integer countRev = startMonth; countRev > 0 ; countRev--){//within 12 months of trade
                        if(countRev == startMonth){
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                totalRevenue = fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                            }
                            else{//if there are no values to be retrieved, set it to 0
                                totalRevenue = 0;
                            }
                        }
                        else{
                            if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                            }
                            else{//if there are no values to be retrieved, add 0
                                totalRevenue += 0;
                            }
                        }
                    }
                    
                    //Example: Gets the revenue from July to December FY2019
                    for(Integer countRev = 7; countRev < 13; countRev++){
                        if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                            totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                        }
                        else{//if there are no values to be retrieved, add 0
                            totalRevenue += 0;
                        }
                    }
                    
                    //Example: Gets the revenue from April to June FY2018
                    for(Integer countRev = startMonth; countRev < 7; countRev++){
                        if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                            totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                        }
                        else{//if there are no values to be retrieved, add 0
                            totalRevenue += 0;
                        }
                    }
                    //Example: Gets revenue for July to December FY2019
                    for(Integer countRev = startMonth; countRev < 13; countRev++){//computes from January to June of the CFY
                        if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                            totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                        }
                        else{//if there are no values to be retrieved, adds 0
                            totalRevenue += 0;
                        }
                    }
                    if(totalRevenue == 0 && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){//if the 12 months has no revenue and the org has other valid T&Rs
                        if(!productTotalRevMap.containsKey(optyLine.Product2Id)){//if the product has no valid T&R
                            optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                        }
                        else{//if the product has valid T&R from other FYs
                            optyLine.Classification__c = Constants.CLSS_WINBACK;
                        }
                    }
                    else if(ntAmount.Amount__c > totalRevenue){//if the total revenue is lesser than the NTA...
                        if(totalOutsideRevenue > ntAmount.Amount__c){//...but the total revenue outside the 12 months exceeds the NTA
                            optyLine.Classification__c = Constants.CLSS_WINBACK;
                        }
                        else if(totalOutsideRevenue < ntAmount.Amount__c && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){
                            //...but the total revenue outside is less than the NTA and the org has other valid T&Rs
                            optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                        }
                    }
                    else if(ntAmount.Amount__c < totalRevenue){//if the total revenue exceeds the NTA, it can either be Renewal or Growth depending on the Growth? field
                        if(Constants.NO_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){
                            optyLine.Classification__c = Constants.CLSS_RENEWAL;
                        }
                        else if(Constants.YES_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){
                            optyLine.Classification__c = Constants.CLSS_GROWTH;
                        }
                    }
                    
                }
                if(salesUserProfiles.contains(currentProfileName) && !Constants.growthCLSS().contains(optyLine.Classification__c) && Constants.YES_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){
                    optyLine.Change_Classification__c.addError(Label.Not_Renewal);
                }
            }
            
        }catch(exception excp){
            system.debug('********* '+excp.getMessage());
            system.debug('********* '+excp.getStackTraceString());
            UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'populateClassification', triggerName, LoggingLevel.ERROR);
        }
    }
    
    /*****************************
     * Description: Update the classification field based if Opty is changed to Closed Won or upon change of Opty Line Item's Revenue Dates
     * Author: JPalmero
     * History:
     * 8/19/2019            Created
     ****************************/
    public static void updateClassification(List<OpportunityLineItem> newOptyLineItemList, Map<Id, OpportunityLineItem> oldRecMap){
        Integer barMonth;
        Integer barCYear;
        Integer barPYear;
        Integer startMonth;
        Decimal orgRev;
        Decimal prodRev;
        Decimal totalRevenue;
        Decimal totalOutsideRevenue;
        OpportunityLineItem oldRec = new OpportunityLineItem();
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> tradedAcctSet = new Set<Id>();
        Set<Id> tradedProductSet = new Set<Id>();
        Set<String> accountIdSet = new Set<String>();
        Set<Id> optyIdSet = new Set<Id>();
        List<OpportunityLineItem> newOptyProdList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> optyLIToUpdate = new List<OpportunityLineItem>();
        Map<Id, Id> optyOrgMap = new Map<Id, Id>();
        Map<Id, String> acctRevenueMap = new Map<Id, String>();
        Map<Id, String> optyStageMap = new Map<Id, String>();
        Map<Id, String> orgProductMap = new Map<Id, String>();
        Map<Id, Decimal> productTotalRevMap = new Map<Id, Decimal>();
        Map<String, Decimal> fyProductMap = new Map<String, Decimal>();
        Map<String, Decimal> barTotalRevMap = new Map<String, Decimal>();
        NominalTradeAmount__c ntAmount = NominalTradeAmount__c.getInstance();
        
        try{
            for(OpportunityLineItem optyLine : newOptyLineItemList){
                oldRec = oldRecMap != NULL && oldRecMap.containsKey(optyLine.Id) ? oldRecMap.get(optyLine.Id) : NULL;
                if((optyLine.Contract_Start_Date__c != oldRec.Contract_Start_Date__c) ||
                   (optyLine.Contract_End_Date__c != oldRec.Contract_End_Date__c) ||
                   ((salesAdminProfiles.contains(currentProfileName)) && (optyLine.Classification__c != oldRec.Classification__c) &&
                    !(Constants.CLSS_GROWTH.equalsIgnoreCase(oldRec.Classification__c) || Constants.CLSS_RENEWAL.equalsIgnoreCase(oldRec.Classification__c))))
                {//if revenue dates change and Classification shouldn't be Growth
                       productIdSet.add(optyLine.Product2Id);//saves the product Id to the list
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
                    optyOrgMap.put(optyObj.Id, optyObj.AccountId);//saves the Opty's Organisation
                    optyStageMap.put(optyObj.Id, optyObj.StageName);//saves the Opty's Stage
                    accountIdSet.add(optyObj.AccountId);//gets the opportunity's account id
                }
            }
            if(accountIdSet != NULL){//get all T&R records from the organisation
				for(OPCUtility.ParentAccountRevenue bar : OPCUtility.getParentAccountRevenueMap(accountIdSet).values())
                {  
                    bar.group();
                    tradedProductSet.add(bar.Product);//products that have been traded with AuPost
                    tradedAcctSet.add(bar.Organisation);//accounts in this set have traded any product
                     // January
                    fyProductMap.put(String.valueOf(bar.Product) + '1' + String.valueOf(bar.Financial_Year), bar.Jan_Revenue_Amount);
                    // February
					fyProductMap.put(String.valueOf(bar.Product) + '2' + String.valueOf(bar.Financial_Year), bar.Feb_Revenue_Amount);
                    // March
                    fyProductMap.put(String.valueOf(bar.Product) + '3' + String.valueOf(bar.Financial_Year), bar.Mar_Revenue_Amount);
                    // April
					fyProductMap.put(String.valueOf(bar.Product) + '4' + String.valueOf(bar.Financial_Year), bar.Apr_Revenue_Amount);
                    // May
					fyProductMap.put(String.valueOf(bar.Product) + '5' + String.valueOf(bar.Financial_Year), bar.May_Revenue_Amount);
                    // June
                    fyProductMap.put(String.valueOf(bar.Product) + '6' + String.valueOf(bar.Financial_Year), bar.Jun_Revenue_Amount);
                    // July
                    fyProductMap.put(String.valueOf(bar.Product) + '7' + String.valueOf(bar.Financial_Year), bar.Jul_Revenue_Amount);
                    // August
                   	fyProductMap.put(String.valueOf(bar.Product) + '8' + String.valueOf(bar.Financial_Year), bar.Aug_Revenue_Amount);
                    // September
                   	fyProductMap.put(String.valueOf(bar.Product) + '9' + String.valueOf(bar.Financial_Year), bar.Sep_Revenue_Amount);
                    // October
                    fyProductMap.put(String.valueOf(bar.Product) + '10' + String.valueOf(bar.Financial_Year), bar.Oct_Revenue_Amount);
                    // November
                    fyProductMap.put(String.valueOf(bar.Product) + '11' + String.valueOf(bar.Financial_Year), bar.Nov_Revenue_Amount);
                    // December
                    fyProductMap.put(String.valueOf(bar.Product) + '12' + String.valueOf(bar.Financial_Year), bar.Dec_Revenue_Amount);
                    
                    if(bar.Total_Revenue_Amount > ntAmount.Amount__c){//if Total Revenue exceeds the NTA, save the id
                        barTotalRevMap.put(bar.Organisation, bar.Total_Revenue_Amount);
                        productTotalRevMap.put(bar.Product, bar.Total_Revenue_Amount);
                        orgProductMap.put(bar.Organisation, bar.Product);
                    }
                }//end BaR for
            }
            for(OpportunityLineItem optyLine : newOptyProdList){
                if(Constants.NO_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){//if the Classification is not Growth, Growth? should be NO
                    oldRec = oldRecMap != NULL && oldRecMap.containsKey(optyLine.Id) ? oldRecMap.get(optyLine.Id) : NULL;
                    startMonth = optyLine.Contract_Start_Date__c.MONTH();//get the start month for 12 months computation
                    barCYear = optyLine.Contract_Start_Date__c.YEAR();//to check which Financial Year it will be taken from
                    if(!Constants.CLOSED_WON.equalsIgnoreCase(optyStageMap.get(optyLine.OpportunityId))){//skips the whole process if the Opty is Closed Won
                        //if there hasn't been any trade or the total revenue is <NTA
                        if(!tradedAcctSet.contains(optyOrgMap.get(optyLine.OpportunityId)) || !barTotalRevMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){                
                            optyLine.Classification__c = Constants.CLSS_NEWBUSINESS;
                        }
                        
                        //if the product has been traded before but is less than the NTA && has no other product that exceeded the NTA
                        else if(tradedProductSet.contains(optyLine.Product2Id) && !productTotalRevMap.containsKey(optyLine.Product2Id) && !orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){
                            optyLine.Classification__c = Constants.CLSS_NEWBUSINESS;
                        }
                        
                        //if the product has been traded before but is less than the NTA && has no other product that exceeded the NTA
                        else if(tradedProductSet.contains(optyLine.Product2Id) && !productTotalRevMap.containsKey(optyLine.Product2Id) && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){
                            optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                        }
                        
                        //if the product has never been traded and the org has traded other product with Total Revenue > NTA
                        else if(!tradedProductSet.contains(optyLine.Product2Id) && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){
                            optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                        }
                        
                        else if(startMonth > 6){
                            //after the 12 months of trade
                            for(Integer countRev = startMonth; countRev > 6 ; countRev--){
                                if(countRev == startMonth){//Start is AUG2019
                                    //AUG2019 to JUL2019
                                    if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                        totalOutsideRevenue = fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                                    }
                                    else{//if there are no values to be retrieved, sets it to 0
                                        totalOutsideRevenue = 0;
                                    }
                                }
                                else{
                                    if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                        totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                                    }
                                    else{//if there are no values to be retrieved, adds 0
                                        totalOutsideRevenue += 0;
                                    }
                                }
                            }
                            
                            //Example: Gets revenue for June back to January FY2018
                            for(Integer countRev = 6; countRev > 0; countRev--){//computes from January to June of the PFY
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                    totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                                }
                                else{//if there are no values to be retrieved, adds 0
                                    totalOutsideRevenue += 0;
                                }
                            }
                            
                            //Example: Gets revenue for AUG to December FY2018
                            for(Integer countRev = startMonth; countRev < 13; countRev++){//computes from January to June of the CFY
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                    totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                                }
                                else{//if there are no values to be retrieved, adds 0
                                    totalOutsideRevenue += 0;
                                }
                            }
                            //Example Start Date: October 2019
                            //Gets the revenue for October back to July FY2020
                            for(Integer countRev = startMonth; countRev > 6 ; countRev--){
                                if(countRev == startMonth){
                                    if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear+1))){
                                        totalRevenue = fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear+1));
                                    }
                                    else{//if there are no values to be retreived, set it to 0
                                        totalRevenue = 0;
                                    }
                                }
                                else{
                                    if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear+1))){
                                        totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear+1));
                                    }
                                    else{//if there are no values to be retreived, add 0
                                        totalRevenue += 0;
                                    }
                                }
                            }
                            
                            //Example: Gets the revenue for June back to January FY2019
                            for(Integer countRev = 6; countRev > 0; countRev--){//computes from January to June of the CFY
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                    totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                                }
                                else{//if there are no values to be retreived, add 0
                                    totalRevenue += 0;
                                }
                            }
                            
                            //example: Gets revenue from October to December FY2019
                            for(Integer countRev = startMonth; countRev < 13; countRev++){//computes from January to June of the CFY
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                    totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                                }
                                else{
                                    totalRevenue += 0;
                                }
                            }
                            
                            if(totalRevenue == 0 && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId)) && !productTotalRevMap.containsKey(optyLine.Product2Id)){
                                optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                            }
                            else if(totalRevenue == 0 && productTotalRevMap.containsKey(optyLine.Product2Id)){
                                optyLine.Classification__c = Constants.CLSS_WINBACK;
                            }
                            //if the Total Revenue is less than the NTA and the Total Revenue outside the 12 months is greater than the NTA
                            else if(ntAmount.Amount__c > totalRevenue && totalOutsideRevenue > ntAmount.Amount__c){
                                optyLine.Classification__c = Constants.CLSS_WINBACK;
                            }
                            else if(ntAmount.Amount__c > totalRevenue && ntAmount.Amount__c > totalOutsideRevenue && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){//total 12 months revenue && outside revenue is less than NTA
                                optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                            }
                            else if(ntAmount.Amount__c < totalRevenue){//if the total revenue exceeds the NTA, it can either be Renewal or Growth depending on the Growth? field
                                if(Constants.NO_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){
                                    optyLine.Classification__c = Constants.CLSS_RENEWAL;
                                }
                                else if(Constants.YES_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){
                                    optyLine.Classification__c = Constants.CLSS_GROWTH;
                                }
                            }
                        }
                        
                        else if(startMonth < 7){
                            for(Integer countRev = startMonth; countRev > 0 ; countRev--){//within 12 months of trade
                                if(countRev == startMonth){
                                    if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                        totalOutsideRevenue = fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                                    }
                                    else{//if there are no values to be retrieved, set it to 0
                                        totalOutsideRevenue = 0;
                                    }
                                }
                                else{
                                    if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                        totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                                    }
                                    else{//if there are no values to be retrieved, add 0
                                        totalOutsideRevenue += 0;
                                    }
                                }
                            }
                            
                            //Example: Gets the revenue from July to December FY2019
                            for(Integer countRev = 7; countRev < 13; countRev++){
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                    totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                                }
                                else{//if there are no values to be retrieved, add 0
                                    totalOutsideRevenue += 0;
                                }
                            }
                            
                            //Example: Gets the revenue from April to June FY2018
                            for(Integer countRev = startMonth; countRev < 7; countRev++){
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-2))){
                                    totalOutsideRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-2));
                                }
                                else{//if there are no values to be retrieved, add 0
                                    totalOutsideRevenue += 0;
                                }
                            }
        
                            //Example Start Date: Feb 2019
                            //Gets the revenue from Feb back to January FY2019
                            for(Integer countRev = startMonth; countRev > 0 ; countRev--){
                                if(countRev == startMonth){
                                    if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                        totalRevenue = fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                                    }
                                    else{//if there are no values to be retrieved, set it to 0
                                        totalRevenue = 0;
                                    }
                                }
                                else{
                                    if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                        totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                                    }
                                    else{//if there are no values to be retrieved, add 0
                                        totalRevenue += 0;
                                    }
                                }
                            }
                            
                            //Example: Gets the revenue from July to December FY2019
                            for(Integer countRev = 7; countRev < 13; countRev++){//computes from January to June of the CFY
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                    totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear));
                                }
                                else{//if there are no values to be retrieved, add 0
                                    totalRevenue += 0;
                                }
                            }
                            //Example: Gets the revenue from Feb to June FY2018
                            for(Integer countRev = startMonth; countRev < 7; countRev++){//computes from January to June of the CFY
                                if(fyProductMap.containsKey(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                    totalRevenue += fyProductMap.get(String.valueOf(optyLine.Product2Id) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                                }
                                else{//if there are no values to be retrieved, add 0
                                    totalRevenue += 0;
                                }
                            }

                            if(totalRevenue == 0 && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId)) && !productTotalRevMap.containsKey(optyLine.Product2Id)){
                                optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                            }
                            else if(totalRevenue == 0 && productTotalRevMap.containsKey(optyLine.Product2Id)){
                                optyLine.Classification__c = Constants.CLSS_WINBACK;
                            }
                            //if the Total Revenue is less than the NTA and the Total Revenue outside the 12 months is greater than the NTA
                            else if(ntAmount.Amount__c > totalRevenue && totalOutsideRevenue > ntAmount.Amount__c){
                                optyLine.Classification__c = Constants.CLSS_WINBACK;
                            }
                            else if(ntAmount.Amount__c > totalRevenue && ntAmount.Amount__c > totalOutsideRevenue && orgProductMap.containsKey(optyOrgMap.get(optyLine.OpportunityId))){//total 12 months revenue && outside revenue is less than NTA
                                optyLine.Classification__c = Constants.CLSS_CROSSSELL;
                            }

                            else if(ntAmount.Amount__c < totalRevenue){//if the total revenue exceeds the NTA, it can either be Renewal or Growth depending on the Growth? field
                                if(Constants.NO_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){
                                    optyLine.Classification__c = Constants.CLSS_RENEWAL;
                                }
                                else if(Constants.YES_STRING.equalsIgnoreCase(optyLine.Change_Classification__c)){
                                    optyLine.Classification__c = Constants.CLSS_GROWTH;
                                }
                            }
                        }
                    }
                }
            }
            
        }catch(exception excp){
            system.debug('********* '+excp.getMessage());
            system.debug('********* '+excp.getStackTraceString());
            UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'updateClassification', triggerName, LoggingLevel.ERROR);
        }
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
        }catch(exception excp){
       		system.debug('********* '+excp.getMessage());
            system.debug('******** '+excp.getStackTraceString());
            UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'changeClassification', triggerName, LoggingLevel.ERROR);
        }
    }
    

  
}