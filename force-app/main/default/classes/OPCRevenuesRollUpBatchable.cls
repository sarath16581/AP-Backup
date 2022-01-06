/**************************************************
Type:       	Apex Batchable Job Class for Revenues Rollup of Opportunity Product Classification (OPC)
@Description:	Roll up the Total Schedule Revenue to Date and the Total Actual Revenue to Date from Opportunity Product Classification (OPC)
				and update the associated Opportunity, so that the Account Manager or Sales Manager can see daily snapshots of the Sales performance
History:
--------------------------------------------------
29.10.2020  seth.heang@auspost.com.au   Created
**************************************************/
global without sharing class OPCRevenuesRollUpBatchable implements Database.Batchable<sObject> {
    global Set<String> setErrorMessage {get;set;}  
    public final String lastModifiedDateCondition;
    public final String queryString;

    /**
      * @description       Constructor method, retrieve WHERE Clause from custom setting and build Query string
      * @param             None
      * @return            N/a
      */ 
    global OPCRevenuesRollUpBatchable(){
        setErrorMessage = new set<String>();
        // Retrieve the WHERE Condition from the Custom Setting(BatchJobSettings)
        lastModifiedDateCondition = BatchJobSettings__c.getInstance().OPC_Last_Modified_Date_Condition__c;
        System.debug('***lastModifiedDateCondition=> ' + lastModifiedDateCondition);
        queryString = 'SELECT id, Jan_Schedule_Amount__c, Feb_Schedule_Amount__c,' 
                            +  ' Mar_Schedule_Amount__c, Apr_Schedule_Amount__c,'
                            +  ' May_Schedule_Amount__c, Jun_Schedule_Amount__c, '
                            +  ' Jul_Schedule_Amount__c, Aug_Schedule_Amount__c,'
                            +  ' Sep_Schedule_Amount__c, Oct_Schedule_Amount__c,'
                            +  ' Nov_Schedule_Amount__c, Dec_Schedule_Amount__c,'
                            +  ' Total_Actual_Revenue__c, Total_Schedule_Amount__c,'
                            +  ' Opportunity__c, Financial_Year__c'
                            +  ' FROM Opp_Product_Classification__c'
                            +  ' WHERE ' + lastModifiedDateCondition;
        
    }

    /**
      * @description       Start method, queries the latest modified OPCs for Batch execution
      * @param             Database.BatchableContext
      * @return            List<Opp_Product_Classification__c>
      */ 
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        // Execute Query
        system.debug('***queryString=>' + queryString);
        return Database.getQueryLocator(queryString);
    }
    
    /**
        * @description      The execute method, roll up the Total Schedule Revenue to Date and the Total Actual Revenue to Date from Opportunity Product Classification (OPC)
				            and update the associated Opportunity
        * @param             Database.BatchableContext, List<Opp_Product_Classification__c>
        * @return            Void
        * @throws            Method might throw exception which is handled by Try-Catch block
      */ 
    global void execute(Database.BatchableContext BC, list<Opp_Product_Classification__c> scope){
        system.debug('***EXECUTE***');
        Integer currentMonth = system.today().month();
        Boolean currentFiscalYearFlag = false;
        Integer currentFiscalYear;
        Map<Id, List<Opp_Product_Classification__c>> currentFiscalYearOPCMap = new Map<Id, List<Opp_Product_Classification__c>>();
        Map<Opp_Product_Classification__c, Map<Integer, Decimal>> currentFYMonthlyRevenueOPCMap = new Map<Opp_Product_Classification__c, Map<Integer, Decimal>>();
        Map<Opp_Product_Classification__c, decimal> scheduleRevenue_CurrentFiscalYearMap = new Map<Opp_Product_Classification__c, decimal>();
        Map<Id, decimal> totalActualRevenueOPCMap = new Map<Id, decimal>();
        Map<Id, decimal> pastScheduleRevenueOPCMap = new Map<Id, decimal>();
        List<Opportunity> updateOpportunityList = new List<Opportunity>();

        try{
            // Get the current financial year and update current financial year flag
            currentFiscalYear = getCurrentFinancialYear();

            // Retrieve Opportunity associated with the updated OPC and add to Set
            Set<Id> oppSet = new Set<Id>();
            for(Opp_Product_Classification__c opc : scope){
                oppSet.add(opc.opportunity__c);
            }
           
            // Query all OPCs under the Opportunities related to the updated OPC
            for(Opp_Product_Classification__c opc : OpportunityProductClassificationSelector.newInstance().selectByOpportunity(oppSet).values()){                                             
                Integer financialYear = Integer.valueof(opc.Financial_Year__c);
                
                // initialise the maps
                if(!totalActualRevenueOPCMap.containsKey(opc.Opportunity__c)){
                    totalActualRevenueOPCMap.put(opc.Opportunity__c,0);
                }
                if(!pastScheduleRevenueOPCMap.containsKey(opc.Opportunity__c)){
                    pastScheduleRevenueOPCMap.put(opc.Opportunity__c,0);
                }
                
                // OPC is current financial year
                if(financialYear == currentFiscalYear){
                    // has OPC with current financial year
                    currentFiscalYearFlag = true;
                    List<Opp_Product_Classification__c> opcList= new List<Opp_Product_Classification__c>();
                    if(!currentFiscalYearOPCMap.containsKey(opc.Opportunity__c)){
                        opcList.add(opc);
                    }else{
                        opcList = currentFiscalYearOPCMap.get(opc.Opportunity__c);
                        opcList.add(opc);
                    }
                    // populate the current financial year OPCs into a map, with opportunity key
                    currentFiscalYearOPCMap.put(opc.Opportunity__c, opcList);
                    // sum up the total actual revenues of current financial years and map to opportunity
                    totalActualRevenueOPCMap.put(opc.Opportunity__c, totalActualRevenueOPCMap.get(opc.Opportunity__c) + opc.Total_Actual_Revenue__c);
                }
                // OPC is past financial year
                else if(financialYear < currentFiscalYear){
                    // populate the past financial year OPCs into a map, with opportunity key
                    pastScheduleRevenueOPCMap.put(opc.Opportunity__c, pastScheduleRevenueOPCMap.get(opc.Opportunity__c) + opc.Total_Schedule_Amount__c);
                    // sum up the total actual revenues of past financial years and map to opportunity
                    totalActualRevenueOPCMap.put(opc.Opportunity__c, totalActualRevenueOPCMap.get(opc.Opportunity__c) + opc.Total_Actual_Revenue__c);
                }           
                
            }

            // loop current fiscal year OPC and initialise the map for each monthly schedule revenue and add to map
            if(currentFiscalYearFlag){
                // populate the monthly schedule revenues of the current financial year, and map to respective OPC
                for(Id oppID : currentFiscalYearOPCMap.keyset()){
                    List<Opp_Product_Classification__c> opcList = currentFiscalYearOPCMap.get(oppId);
                    for(Opp_Product_Classification__c opc : opcList){
                        Map<Integer, Decimal> currentFYOPCMap = new Map<Integer, Decimal>();
                        currentFYOPCMap.put(1,convertNullToZero(opc.Jan_Schedule_Amount__c));
                        currentFYOPCMap.put(2,convertNullToZero(opc.Feb_Schedule_Amount__c));
                        currentFYOPCMap.put(3,convertNullToZero(opc.Mar_Schedule_Amount__c));
                        currentFYOPCMap.put(4,convertNullToZero(opc.Apr_Schedule_Amount__c));
                        currentFYOPCMap.put(5,convertNullToZero(opc.May_Schedule_Amount__c));
                        currentFYOPCMap.put(6,convertNullToZero(opc.Jun_Schedule_Amount__c));
                        currentFYOPCMap.put(7,convertNullToZero(opc.Jul_Schedule_Amount__c));
                        currentFYOPCMap.put(8,convertNullToZero(opc.Aug_Schedule_Amount__c));
                        currentFYOPCMap.put(9,convertNullToZero(opc.Sep_Schedule_Amount__c));
                        currentFYOPCMap.put(10,convertNullToZero(opc.Oct_Schedule_Amount__c));
                        currentFYOPCMap.put(11,convertNullToZero(opc.Nov_Schedule_Amount__c));
                        currentFYOPCMap.put(12,convertNullToZero(opc.Dec_Schedule_Amount__c));
                        currentFYMonthlyRevenueOPCMap.put(opc, currentFYOPCMap);
                    }
                }
                // Logic to sum up elapsed monthly revenues inclusive of current month's of current financial year
                for(Opp_Product_Classification__c opc : currentFYMonthlyRevenueOPCMap.keyset()){
                    Map<Integer, Decimal> currentMap = currentFYMonthlyRevenueOPCMap.get(opc);
                    decimal scheduleRevenue_CurrentFiscalYear = 0;
                    // second half of financial year
                    if(currentMonth < 7){
                        // count backward from current month to January, max range is June and min range is January
                        for(Integer i = currentMonth; i >= 1; i--){
                            scheduleRevenue_CurrentFiscalYear += currentMap.get(i);
                        }
                        // count backward from December to July, to sum up all monthly revenues for first half of financial year
                        for(Integer i = 12; i >= 7; i--){
                            scheduleRevenue_CurrentFiscalYear += currentMap.get(i);
                        }
                    }else{
                        // count backward from current month to July, max range is December and min range is July
                        for(Integer i = currentMonth; i >= 7; i--){
                            scheduleRevenue_CurrentFiscalYear += currentMap.get(i);
                        }
                    }
                    // save elapsed monthly revenues of current financial year and map to respective OPC
                    scheduleRevenue_CurrentFiscalYearMap.put(opc, scheduleRevenue_CurrentFiscalYear);    
                }
            }
            
            /**
             * Loop action to sum up the past and current financial year OPC records under each opportunity
             * Then, roll up the calculated revenues and update Total_Schedule_Revenue_to_Date__c and Opportunity_Traded_Revenue__c field on Opportunity
             */  
            for(Opportunity opp : OpportunitiesSelector.newInstance().selectById(oppSet).values()){
                decimal scheduleRevenue_PastFiscalYear = 0;
                decimal scheduleRevenue_CurrentFiscalYear = 0;
                decimal totalScheduleRevenueToDate = 0;
                decimal totalActualRevenueToDate = 0;
                
                // Retrieve all the current financial year OPC associated with same opportunity and sum them all up 
                if(currentFiscalYearOPCMap.containsKey(opp.id)){
                    for(Opp_Product_Classification__c opc : currentFiscalYearOPCMap.get(opp.id)){
                        if(opc.opportunity__c.equals(opp.id)){
                            scheduleRevenue_CurrentFiscalYear += scheduleRevenue_CurrentFiscalYearMap.get(opc);
                        }
                	}
                }

                // Retrieve past financial year schedule revenues, from Total_Schedule_Amount__c value on OPC 
                if(pastScheduleRevenueOPCMap.containsKey(opp.id)){
                    scheduleRevenue_PastFiscalYear = pastScheduleRevenueOPCMap.get(opp.id);
                }

                // Retrieve the total roll up actual revenues, from the beginning of revenue start month to the current month's revenues
                if(totalActualRevenueOPCMap.containsKey(opp.id)){
                    totalActualRevenueToDate = totalActualRevenueOPCMap.get(opp.id);
                }
                
                /**
                 * Sum of past financial year schedule revenues and the current financial year's elapsed months' revenues 
                 * This results in total schedule revenue to date
                 */ 
                totalScheduleRevenueToDate = scheduleRevenue_PastFiscalYear + scheduleRevenue_CurrentFiscalYear;
                opp.Total_Schedule_Revenue_to_Date__c = totalScheduleRevenueToDate;
                opp.Opportunity_Traded_Revenue__c = totalActualRevenueToDate;
                updateOpportunityList.add(opp);
            }

            if(!updateOpportunityList.isEmpty()){
                // Perform Update DML on the updated field on the opportunity
                ApplicationDatabase.getInstance().dmlUpdate(updateOpportunityList);        
            }
        }catch(Exception exp){
            setErrorMessage.add(exp.getMessage());    
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), null, 'OPCRevenuesRollUpBatchable', 'execute()', null, LoggingLevel.ERROR);
        }
        
    }

    /*
     *  @description    Check if the param value is null, then convert it to 0
     *                  This is done, to resolve the null error during field assignment
     *  @param          Decimal
     *  @return         Decimal
     */
    public decimal convertNullToZero(decimal num) {
        if (num == null) {
            num = 0;
        }
        return num;
    }

    /*
     *  @description    Retrieve the current financial year value
     *                  The current time is determined using System.today(), in order to derive the current financial year
     *  @param          Void - No param required,
     *  @return         Integer - Current Financial Year 
     */
    public static Integer getCurrentFinancialYear(){
        Integer currentFinancialYear;
        dateTime startCurrentFiscalYear;
        dateTime endCurrentFiscalYear;
        
        // between July and December, first half of financial year
        if(system.today().month() >= 7 && system.today().month() <= 12){
            startCurrentFiscalYear = datetime.newInstance(system.today().year(),7,1); // 1st July
            endCurrentFiscalYear = datetime.newInstance(system.today().year()+1,6,30); // 30th June
        }else{
            // between January and June, second half of financial year
            startCurrentFiscalYear = datetime.newInstance(system.today().year()-1,7,1); // 1st July
            endCurrentFiscalYear = datetime.newInstance(system.today().year(),6,30); // 30th June
        }
        // get current financial year 
        if(system.today() >= startCurrentFiscalYear && system.today() <= endCurrentFiscalYear){
            currentFinancialYear = endCurrentFiscalYear.year();
        }
        return currentFinancialYear;
    }


    /**
      * @description       finish method, capture and log any errors found in the Batch Job Run
      * @param             Database.BatchableContext
      * @return            void
      */   
    global void finish(Database.BatchableContext BC) {
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus 
                        FROM AsyncApexJob 
                        WHERE Id = :BC.getJobId()];
                        
        Integer iErrorCount = setErrorMessage.size();
        
        if(a.NumberOfErrors > 0) {
            setErrorMessage.add(a.ExtendedStatus);
        }
        
        if(iErrorCount > 0) {
            String errorMessage;
            for(String errorMessage1 : setErrorMessage) {
                if(String.isNotBlank(errorMessage)) {
                    errorMessage += APT_Constants.SEPARATOR_NEXT_LINE + errorMessage1;
                } else {
                    errorMessage = errorMessage1;
                }
            }
            System.debug(System.LoggingLevel.DEBUG, 'The OPC Revenues Roll Up Batch job has processed ' + a.TotalJobItems + ' batches with '+ iErrorCount + ' failures.');
        }else{
            System.debug(System.LoggingLevel.DEBUG, 'The OPC Revenues Roll Up Batch job has processed ' + a.TotalJobItems + ' batches successfully');
        }      
    }
}