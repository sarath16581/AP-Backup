/*********************************
* Description: Handles all logic about the Apttus Opportunity Line Item object
* Author: Jeoffrey Palmero
* History:
* 08/6/2019        Created
* 08.10.2024 Ken McGurie removed legacy opc calculations
********************************/
public class APTOptyLineItemService {
    public static final String CLASSNAME = 'APTOptyLineItemService';
    public static final String ORGID = UserInfo.getOrganizationId();
    public static final String triggerName = 'APTOptyLineItemTrigger';
    private static final Id userId = userinfo.getProfileId();//get the current user's Profile ID
    private static final String currentProfileName = [SELECT Name FROM Profile WHERE Id = :userId].Name;
    private static final Set<String> salesAdminProfiles = Constants.salesAdminProfiles();
    private static final Set<String> salesUserProfiles = Constants.salesUserProfiles();
    /*********************************
    * Description: Populates the Classification field in the APT Opty Line Item Object
    * Author: Jeoffrey Palmero
    * History:
    * 08/6/2019        Created
    ********************************/
    public static void populateClassification(List<APT_Opportunity_Product_Line_Item__c> newAPTOptyLineItem){
        Integer barMonth;
        Integer barCYear;
        Integer barPYear;
        Integer startMonth;
        Decimal prodRev;
        Decimal totalRevenue;
        Decimal totalOutsideRevenue;
        String orgString;
        Set<Id> tradedAcctSet = new Set<Id>();
        Set<Id> tradedProductSet = new Set<Id>();
        Set<Id> proposalIdSet = new Set<Id>();
        Set<Id> proposalSyncSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        List<APT_Opportunity_Product_Line_Item__c> filteredAPTOLIList = new List<APT_Opportunity_Product_Line_Item__c>();
        List<APT_Opportunity_Product_Line_Item__c> APTOLIToUpdate = new List<APT_Opportunity_Product_Line_Item__c>();
        Map<Id, Id> proposalAcctMap = new Map<Id, Id>();
        Map<Id, String> acctRevenueMap = new Map<Id, String>();
        Map<Id, String> optyStageMap = new Map<Id, String>();
        Map<Id, String> orgProductMap = new Map<Id, String>();
        Map<Id, Decimal> productTotalRevMap = new Map<Id, Decimal>();
        Map<String, Decimal> fyProductMap = new Map<String, Decimal>();
        Map<String, Decimal> barTotalRevMap = new Map<String, Decimal>();
        NominalTradeAmount__c ntAmount = NominalTradeAmount__c.getInstance();
        APT_Opportunity_Product_Line_Item__c oldRec = new APT_Opportunity_Product_Line_Item__c();
        //
        Set<String> upsertSet = new Set<String>();
        List<APT_Opportunity_Product_Line_Item__c> toInsertList = new List<APT_Opportunity_Product_Line_Item__c>();
        //
        try{
            for(APT_Opportunity_Product_Line_Item__c optyLineObj : newAPTOptyLineItem){
                if(optyLineObj.APT_Product__c != NULL){
                    proposalIdSet.add(optyLineObj.APT_Quote_Proposal__c);//saves the Proposal ID for the query
                }
            }
            if(proposalIdSet != NULL){//query all proposals to save the proposal and account Id
                for(Apttus_Proposal__Proposal__c proposal : [SELECT Id, Apttus_Proposal__Account__c, Apttus_Proposal__Opportunity__c, Apttus_Proposal__Opportunity__r.StageName 
                                                             FROM Apttus_Proposal__Proposal__c
                                                             WHERE Id IN : proposalIdSet
                                                             LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())])
                {
                    proposalAcctMap.put(proposal.Id, proposal.Apttus_Proposal__Account__c);//saves the organisation of the proposal
                    optyStageMap.put(proposal.Id, proposal.Apttus_Proposal__Opportunity__r.StageName);//saves the opty's stage name
                    accountIdSet.add(proposal.Apttus_Proposal__Account__c);//saves the organisation ids
                }
            }
            if(accountIdSet != NULL){//query all T&R Records under the Organisation
                for (Budget_and_Revenue__c bar : [SELECT Organisation__c, Product__c, Financial_Year__c, 
                                                  Jan_Revenue_Amount__c, Feb_Revenue_Amount__c, Mar_Revenue_Amount__c,
                                                  Apr_Revenue_Amount__c, May_Revenue_Amount__c, Jun_Revenue_Amount__c,
                                                  Jul_Revenue_Amount__c, Aug_Revenue_Amount__c, Sep_Revenue_Amount__c,
                                                  Oct_Revenue_Amount__c, Nov_Revenue_Amount__c, Dec_Revenue_Amount__c,
                                                  Total_Revenue_Amount__c
                                                  FROM Budget_and_Revenue__c
                                                  WHERE Organisation__c IN : accountIdSet
                                                  AND Financial_Year__c != NULL
                                                  LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())])
                {
                    tradedProductSet.add(bar.Product__c);//products that have a been traded with AuPost before
                    tradedAcctSet.add(bar.Organisation__c);//accounts in this set have traded any product
                   
                    // January
                    if(bar.Jan_Revenue_Amount__c > 0){//saves the monthly revenue of a product for the current and previous fiscal year
                        fyProductMap.put(String.valueOf(bar.Product__c) + '1' + String.valueOf(bar.Financial_Year__c), bar.Jan_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '1' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // February
                    if(bar.Feb_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '2' + String.valueOf(bar.Financial_Year__c), bar.Feb_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '2' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // March
                    if(bar.Mar_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '3' + String.valueOf(bar.Financial_Year__c), bar.Mar_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '3' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // April
                    if(bar.Apr_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '4' + String.valueOf(bar.Financial_Year__c), bar.Apr_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '4' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // May
                    if(bar.May_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '5' + String.valueOf(bar.Financial_Year__c), bar.May_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '5' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // June
                    if(bar.Jun_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '6' + String.valueOf(bar.Financial_Year__c), bar.Jun_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '6' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // July
                    if(bar.Jul_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '7' + String.valueOf(bar.Financial_Year__c), bar.Jul_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '7' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // August
                    if(bar.Aug_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '8' + String.valueOf(bar.Financial_Year__c), bar.Aug_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '8' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // September
                    if(bar.Sep_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '9' + String.valueOf(bar.Financial_Year__c), bar.Sep_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '9' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // October
                    if(bar.Oct_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '10' + String.valueOf(bar.Financial_Year__c), bar.Oct_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '10' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // November
                    if(bar.Nov_Revenue_Amount__c > 0){
                        fyProductMap.put(String.valueOf(bar.Product__c) + '11' + String.valueOf(bar.Financial_Year__c), bar.Nov_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '11' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    // December
                    if(bar.Dec_Revenue_Amount__c > 0){ 
                        fyProductMap.put(String.valueOf(bar.Product__c) + '12' + String.valueOf(bar.Financial_Year__c), bar.Dec_Revenue_Amount__c);
                    }
                    else{
                        fyProductMap.put(String.valueOf(bar.Product__c) + '12' + String.valueOf(bar.Financial_Year__c), 0);
                    }
                    
                    if(bar.Total_Revenue_Amount__c > ntAmount.Amount__c){//if the revenue exceeds the Nominal Trade Amount, save it into the map
                        barTotalRevMap.put(bar.Organisation__c, bar.Total_Revenue_Amount__c);
                        productTotalRevMap.put(bar.Product__c, bar.Total_Revenue_Amount__c);
                        orgProductMap.put(bar.Organisation__c, bar.Product__c);
                    }
                }//end BaR for loop
            }
            for(APT_Opportunity_Product_Line_Item__c newAPTObj : newAPTOptyLineItem){
                if(Constants.NO_STRING.equalsIgnoreCase(newAPTObj.APT_Change_Classification__c)){
                    if(!Constants.CLOSED_WON.equalsIgnoreCase(optyStageMap.get(newAPTObj.APT_Quote_Proposal__c))){
                        startMonth = newAPTObj.APT_Revenue_Start_Date__c.MONTH();
                        barCYear = newAPTObj.APT_Revenue_Start_Date__c.YEAR();
                        orgString = proposalAcctMap.get(newAPTObj.APT_Quote_Proposal__c);//if there hasn't been any trade or the total revenue is <100
                        
                        //if there hasn't been any trade or the total revenue is <NTA
                        if(!tradedAcctSet.contains(orgString) || !barTotalRevMap.containsKey(orgString)){                
                            newAPTObj.APT_Classification__c = Constants.CLSS_NEWBUSINESS;
                        }
                        
                        //if the product has been traded before but is less than the NTA && has no other product that exceeded the NTA
                        else if(tradedProductSet.contains(newAPTObj.APT_Product__c) && !productTotalRevMap.containsKey(newAPTObj.APT_Product__c) && !orgProductMap.containsKey(orgString)){
                            newAPTObj.APT_Classification__c = Constants.CLSS_NEWBUSINESS;
                        }
                        
                        //if the product has been traded before but is less than the NTA && has no other product that exceeded the NTA
                        else if(tradedProductSet.contains(newAPTObj.APT_Product__c) && !productTotalRevMap.containsKey(newAPTObj.APT_Product__c) && orgProductMap.containsKey(orgString)){
                            newAPTObj.APT_Classification__c = Constants.CLSS_CROSSSELL;
                        }
                        
                        //if the product has never been traded and the org has traded other product with Total Revenue > NTA
                        else if(!tradedProductSet.contains(newAPTObj.APT_Product__c) && orgProductMap.containsKey(orgString)){
                            newAPTObj.APT_Classification__c = Constants.CLSS_CROSSSELL;
                        }
                        
                        else if(startMonth > 6){
                            //after the 12 months of trade
                            for(Integer countRev = startMonth; countRev > 6 ; countRev--){
                                if(countRev == startMonth){//Start month to July for the Next FY
                                    //Example: Start Date: 08/2019
                                    //Gets the revenue for August back to July FY2020
                                    if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                        totalOutsideRevenue = fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear));
                                    }
                                    else{//if there are no values to be retrieved, sets it to 0
                                        totalOutsideRevenue = 0;
                                    }
                                }
                                else{
                                    if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                        totalOutsideRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear));
                                    }
                                    else{//if there are no values to be retrieved, adds 0
                                        totalOutsideRevenue += 0;
                                    }
                                }
                            }
                            
                            //Example: Gets revenue for June back to January FY2019
                            for(Integer countRev = 6; countRev > 0; countRev--){//computes from January to June of the CFY
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                    totalOutsideRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                                }
                                else{//if there are no values to be retrieved, adds 0
                                    totalOutsideRevenue += 0;
                                }
                            }
                            
                            //Example: Gets revenue for July to December FY2019
                            for(Integer countRev = startMonth; countRev < 13; countRev++){//computes from January to June of the CFY
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                    totalOutsideRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1));
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
                                    if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear+1))){
                                        totalRevenue = fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear+1));
                                    }
                                    else{//if there are no values to be retrieved, sets it to 0
                                        totalRevenue = 0;
                                    }
                                }
                                else{
                                    if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear+1))){
                                        totalRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear+1));
                                    }
                                    else{//if there are no values to be retrieved, adds 0
                                        totalRevenue += 0;
                                    }
                                }
                            }
                            
                            //Example: Gets revenue for June back to January FY2019
                            for(Integer countRev = 6; countRev > 0; countRev--){//computes from January to June of the CFY
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                    totalRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear));
                                }
                                else{//if there are no values to be retrieved, adds 0
                                    totalRevenue += 0;
                                }
                            }
                            
                            //Example: Gets revenue for July to December FY2019
                            for(Integer countRev = startMonth; countRev < 13; countRev++){//computes from January to June of the CFY
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                    totalRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear));
                                }
                                else{//if there are no values to be retrieved, adds 0
                                    totalRevenue += 0;
                                }
                            }
                            if(totalRevenue == 0 && orgProductMap.containsKey(orgString) && !productTotalRevMap.containsKey(newAPTObj.APT_Product__c)){
                                newAPTObj.APT_Classification__c = Constants.CLSS_CROSSSELL;
                            }
                            else if(totalRevenue == 0 && productTotalRevMap.containsKey(newAPTObj.APT_Product__c)){
                                newAPTObj.APT_Classification__c = Constants.CLSS_WINBACK;
                            }
                            //if the Total Revenue is less than the NTA and the Total Revenue outside the 12 months is greater than the NTA
                            else if(ntAmount.Amount__c > totalRevenue && totalOutsideRevenue > ntAmount.Amount__c){
                                newAPTObj.APT_Classification__c = Constants.CLSS_WINBACK;
                            }
                            else if(ntAmount.Amount__c > totalRevenue && ntAmount.Amount__c > totalOutsideRevenue && orgProductMap.containsKey(orgString)){//total 12 months revenue && outside revenue is less than NTA
                                newAPTObj.APT_Classification__c = Constants.CLSS_CROSSSELL;
                            }
                            else if(ntAmount.Amount__c < totalRevenue){//if the total revenue exceeds the NTA, it can either be Renewal or Growth depending on the Growth? field
                                if(Constants.NO_STRING.equalsIgnoreCase(newAPTObj.APT_Change_Classification__c)){
                                    newAPTObj.APT_Classification__c = Constants.CLSS_RENEWAL;
                                }
                                else if(Constants.YES_STRING.equalsIgnoreCase(newAPTObj.APT_Change_Classification__c)){
                                    newAPTObj.APT_Classification__c = Constants.CLSS_GROWTH;
                                }
                            }
                        }
                        
                        else if(startMonth < 7){
                            //after 12 months
                            for(Integer countRev = startMonth; countRev > 0 ; countRev--){
                                if(countRev == startMonth){
                                    if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                        totalOutsideRevenue = fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                                    }
                                    else{//if there are no values to be retrieved, set it to 0
                                        totalOutsideRevenue = 0;
                                    }
                                }
                                else{
                                    if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                        totalOutsideRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                                    }
                                    else{//if there are no values to be retrieved, add 0
                                        totalOutsideRevenue += 0;
                                    }
                                }
                            }
                            
                            //Example: Gets the revenue from July to December FY2019
                            for(Integer countRev = 7; countRev < 13; countRev++){
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                    totalOutsideRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                                }
                                else{//if there are no values to be retrieved, add 0
                                    totalOutsideRevenue += 0;
                                }
                            }
                            
                            //Example: Gets the revenue from April to June FY2018
                            for(Integer countRev = startMonth; countRev < 7; countRev++){
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-2))){
                                    totalOutsideRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-2));
                                }
                                else{//if there are no values to be retrieved, add 0
                                    totalOutsideRevenue += 0;
                                }
                            }
                            
                            //Example Start Date: 04/2019
                            //Gets the revenue for Apr back to January FY2019
                            for(Integer countRev = startMonth; countRev > 0 ; countRev--){//within 12 months of trade
                                if(countRev == startMonth){
                                    if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                        totalRevenue = fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear));
                                    }
                                    else{//if there are no values to be retrieved, set it to 0
                                        totalRevenue = 0;
                                    }
                                }
                                else{
                                    if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                        totalRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear));
                                    }
                                    else{//if there are no values to be retrieved, add 0
                                        totalRevenue += 0;
                                    }
                                }
                            }
                            
                            //Example: Gets the revenue from July to December FY2019
                            for(Integer countRev = 7; countRev < 13; countRev++){
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear))){
                                    totalRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear));
                                }
                                else{//if there are no values to be retrieved, add 0
                                    totalRevenue += 0;
                                }
                            }
                            
                            //Example: Gets the revenue from April to June FY2018
                            for(Integer countRev = startMonth; countRev < 7; countRev++){
                                if(fyProductMap.containsKey(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1))){
                                    totalRevenue += fyProductMap.get(String.valueOf(newAPTObj.APT_Product__c) + String.valueOf(countRev) + String.valueOf(barCYear-1));
                                }
                                else{//if there are no values to be retrieved, add 0
                                    totalRevenue += 0;
                                }
                            }
                            
                            if(totalRevenue == 0 && orgProductMap.containsKey(orgString) && !productTotalRevMap.containsKey(newAPTObj.APT_Product__c)){
                                newAPTObj.APT_Classification__c = Constants.CLSS_CROSSSELL;
                            }
                            else if(totalRevenue == 0 && productTotalRevMap.containsKey(newAPTObj.APT_Product__c)){
                                newAPTObj.APT_Classification__c = Constants.CLSS_WINBACK;
                            }
                            //if the Total Revenue is less than the NTA and the Total Revenue outside the 12 months is greater than the NTA
                            else if(ntAmount.Amount__c > totalRevenue && totalOutsideRevenue > ntAmount.Amount__c){
                                newAPTObj.APT_Classification__c = Constants.CLSS_WINBACK;
                            }
                            else if(ntAmount.Amount__c > totalRevenue && ntAmount.Amount__c > totalOutsideRevenue && orgProductMap.containsKey(orgString)){//total 12 months revenue && outside revenue is less than NTA
                                newAPTObj.APT_Classification__c = Constants.CLSS_CROSSSELL;
                            }
                            else if(ntAmount.Amount__c < totalRevenue){//if the total revenue exceeds the NTA, it can either be Renewal or Growth depending on the Growth? field
                                if(Constants.NO_STRING.equalsIgnoreCase(newAPTObj.APT_Change_Classification__c)){
                                    newAPTObj.APT_Classification__c = Constants.CLSS_RENEWAL;
                                }
                                else if(Constants.YES_STRING.equalsIgnoreCase(newAPTObj.APT_Change_Classification__c)){
                                    newAPTObj.APT_Classification__c = Constants.CLSS_GROWTH;
                                }
                            }
                            
                        }
                        
                        if(!Constants.growthCLSS().contains(newAPTObj.APT_Classification__c) && Constants.YES_STRING.equalsIgnoreCase(newAPTObj.APT_Change_Classification__c)){
                            newAPTObj.APT_Change_Classification__c.addError(Label.Not_Renewal);
                        }
                    }
                }else{
                    newAPTObj.APT_Classification__c = Constants.CLSS_GROWTH;
                }
            }
            
        }catch(exception excp){
            UTIL_LoggingService.logHandledException(excp, ORGID, 'Sales', CLASSNAME, 'populateClassification', triggerName, LoggingLevel.ERROR);
        }
    }
    
    /*****************************
     * Description: Changes the classification from Renewal to Growth and vice versa if the user is a Coverage Sales User
     * Author: JPalmero
     * History:
     * 9/10/2019            Created
     ****************************/
    public static void overrideClassification(List<APT_Opportunity_Product_Line_Item__c> APTOppPLIList, Map<Id, APT_Opportunity_Product_Line_Item__c> oldRecMap) {
        APT_Opportunity_Product_Line_Item__c oldAPT = new APT_Opportunity_Product_Line_Item__c();
        Set<Id> proposalIdSet = new Set<Id>();
        Set<String> salesUserProfiles = Constants.salesUserProfiles();
        try{
            for(APT_Opportunity_Product_Line_Item__c opli : APTOppPLIList) {
                proposalIdSet.add(opli.APT_Quote_Proposal__c);
                if(salesUserProfiles.contains(currentProfileName)){
                    if(oldRecMap != NULL){//for update
                        oldAPT = oldRecMap != NULL && oldRecMap.containsKey(opli.Id) ? oldRecMap.get(opli.Id) : NULL;
                        if((Constants.YES_STRING.equalsIgnoreCase(opli.APT_Change_Classification__c) && Constants.NO_STRING.equalsIgnoreCase(oldAPT.APT_Change_Classification__c))
                           && opli.APT_Classification__c.equalsIgnoreCase(Constants.CLSS_RENEWAL)){
                               opli.APT_Classification__c = Constants.CLSS_GROWTH; //if the Classification is Renewal and the Growth? field is set to YES
                           }else if((Constants.NO_STRING.equalsIgnoreCase(opli.APT_Change_Classification__c) && Constants.YES_STRING.equalsIgnoreCase(oldAPT.APT_Change_Classification__c))
                                    && opli.APT_Classification__c.equalsIgnoreCase(Constants.CLSS_GROWTH)){//if the Classification is Growth and the Growth? field is set to NO
                                        opli.APT_Classification__c = Constants.CLSS_RENEWAL;
                                    }
                    }
                    else{//for insert
                        if(Constants.YES_STRING.equalsIgnoreCase(opli.APT_Change_Classification__c) && opli.APT_Classification__c.equalsIgnoreCase(Constants.CLSS_RENEWAL)) {
                            opli.APT_Classification__c = Constants.CLSS_GROWTH; //if the Classification is Renewal and the Growth? field is set to YES
                        }else if (Constants.NO_STRING.equalsIgnoreCase(opli.APT_Change_Classification__c) && opli.APT_Classification__c.equalsIgnoreCase(Constants.CLSS_GROWTH)) {
                            opli.APT_Classification__c = Constants.CLSS_RENEWAL; //if the Classification is Renewal and the Growth? field is set to YES
                        }
                    }
                }
            }
        }catch (exception ex) {
            UTIL_LoggingService.logHandledException(ex, ORGID, 'Sales', CLASSNAME, 'overrideClassification', triggerName, LoggingLevel.ERROR);
        }
    }
    
    /*****************************
     * Description: Closed Won control for Products; includes BeforeInsert, BeforeDelete, BeforeUpdate contexts
     * Author: Prince Encina
     * History:
     * 9/26/2019            Created
     ****************************/
    public static void productControlWhenClosedWon(List<APT_Opportunity_Product_Line_Item__c> APTOppPLIList, Map<Id, APT_Opportunity_Product_Line_Item__c> oldRecMap) {
        Set<Id> proposalIdSet = new Set<Id>();
        Map<Id, String> oppStageMap = new Map<Id, String>();
        Map<Id, String> proposalRevenueTypeMap = new Map<Id, String>();
        Map<Id, String> proposalRecordTypeMap = new Map<Id, String>();
        /* TRIGGER CONTEXT AS SET PARAMETERS IN APTOptyLineItemHandler()
         * beforeInsert (Trigger.New, null)
         * beforeUpdate (Trigger.New, Trigger.OldMap)
         * beforeDelete (Trigger.Old, null)
         */
        try {
            // Everything applies only to Sales Users
            if (salesUserProfiles.contains(currentProfileName)) {
                // Get all Proposal IDs
                for (APT_Opportunity_Product_Line_Item__c oppPLIObj : APTOppPLIList) {
                    if(oppPLIObj.APT_Product__c != null) {
                        proposalIdSet.add(oppPLIObj.APT_Quote_Proposal__c);
                    }
                }
                
                // Query for Proposal records to get Opportunity's Stage
                if (proposalIdSet != null) {
                    for(Apttus_Proposal__Proposal__c proposal : [SELECT Id, Apttus_Proposal__Opportunity__c, Apttus_Proposal__Opportunity__r.StageName, APT_Revenue_Type__c, RecordType.Name
                                                                 FROM Apttus_Proposal__Proposal__c
                                                                 WHERE Id IN : proposalIdSet
                                                                 LIMIT:(LIMITS.getLimitQueryRows()-LIMITS.getQueryRows())]) {
                        oppStageMap.put(proposal.Id, proposal.Apttus_Proposal__Opportunity__r.StageName);       // put Opportunity's Stage in the Map
                        proposalRevenueTypeMap.put(proposal.Id, proposal.APT_Revenue_Type__c);
                        proposalRecordTypeMap.put(proposal.Id, proposal.RecordType.Name);
                    }
                }
                
                // Loop through the Trigger.New/Trigger.Old context for Opportunity Product Line Items
                if (!oppStageMap.isEmpty()) {
                    for (APT_Opportunity_Product_Line_Item__c opli : APTOppPLIList) {
                        // 10/9/19: Defect for locking down fields on Revenue Date change
                        String isGrowth = 'No';
                        String isGrowthNow = 'No';
                        
                        // 10/10/19: If Proposal's Revenue Type is 'Decrease Revenue' and Record Type is 'Amendment Quote', do not lock down Product
                        if (!( (Constants.REVENUE_TYPE_DECREASE_REVENUE.equalsIgnoreCase(proposalRevenueTypeMap.get(opli.APT_Quote_Proposal__c))) &&
                               (Constants.RECORDTYPE_NAME_AMENDMENT_QUOTE.equalsIgnoreCase(proposalRecordTypeMap.get(opli.APT_Quote_Proposal__c))) )) {
                            if (oldRecMap == null) {
                                if (opli.Id != null) {
                                    // beforeDelete; Trigger.Old has record ID
                                    // RULE: Sales Users cannot delete Products when Opportunity is Closed Won
                                    if (Constants.CLOSED_WON.equalsIgnoreCase(oppStageMap.get(opli.APT_Quote_Proposal__c))) {
                                        opli.addError('This Opportunity is Closed Won, you do not have access to delete Products');
                                    }
                                } else {
                                    // beforeInsert; Trigger.New has no record ID
                                    // RULE: Sales Users cannot add Products when Opportunity is Closed Won
                                    if (Constants.CLOSED_WON.equalsIgnoreCase(oppStageMap.get(opli.APT_Quote_Proposal__c))) {
                                        opli.addError('This Opportunity is Closed Won, you do not have access to add Products');
                                    }
                                }
                            } else {
                                APT_Opportunity_Product_Line_Item__c oldAPT = new APT_Opportunity_Product_Line_Item__c();
                                oldAPT = oldRecMap.containsKey(opli.Id) ? oldRecMap.get(opli.Id) : null;                        // oldRecMap and oldAPT is null/empty for Insert and Delete
                                
                                // beforeUpdate; Trigger.oldMap has been provided
                                // RULE: Sales Users cannot modify fields except Revenue Dates when Opportunity is Closed Won
                                if (oldAPT != null && Constants.CLOSED_WON.equalsIgnoreCase(oppStageMap.get(opli.APT_Quote_Proposal__c))) {
                                    // 10/9/19: pre-set the value of Growth? for some null instances of Trigger.old version
                                    if (Constants.CLSS_GROWTH.equalsIgnoreCase(oldAPT.APT_Classification__c)) {
                                        isGrowth = 'Yes';
                                    }
                                    if (Constants.CLSS_GROWTH.equalsIgnoreCase(opli.APT_Classification__c)) {
                                        isGrowthNow = 'Yes';
                                    }
                                    
    
                                    if ((oldAPT.APT_Quantity__c != opli.APT_Quantity__c) ||
                                        (oldAPT.APT_Unit_Sales_Price__c != opli.APT_Unit_Sales_Price__c) ||
                                        (oldAPT.APT_Contract_Product__c != opli.APT_Contract_Product__c) ||
                                        (isGrowth != isGrowthNow)) {
                                             
                                        // call error on the record (top of page in VR) if any of the accessible fields changed their value
                                        opli.addError('You cannot change details of products (with the exception of revenue dates) when the opportunity has been Closed Won');
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception ex) {
            UTIL_LoggingService.logHandledException(ex, ORGID, 'Sales', CLASSNAME, 'productControlWhenClosedWon', triggerName, LoggingLevel.ERROR);
        }
    }
    
}