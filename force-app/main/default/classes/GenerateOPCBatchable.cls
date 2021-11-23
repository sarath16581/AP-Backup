/**************************************************
Type:       Apex Batchable Job Class for Generation of Opportunity Product Classification (OPC)
Purpose:    Generates the Opportunity Product Classification (OPC) record from their source revenue schedule(s) and 
            finds any matching actual revenue against it from the current financial year and last financial year
Used By:    
History:
--------------------------------------------------
10.08.2012  M. Isidro (Cloud Sherpas)   Created
15.08.2012  M. Isidro (Cloud Sherpas)   Consolidation of logic flow and OPCUtility Class
28.08.2012  M. isidro (Cloud Sherpas)   Fixed null error exception on Revenue Schedule
30.08.2012  M. Isidro (Cloud Sherpas)   Added Revenue Schedule that are reclassified but previously flagged as under review
04.09.2012  M. Isidro (Cloud Sherpas)   Added test coverage
11.09.2012  M. Isidro (Cloud Sherpas)   Fixed heap size too large error
04.10.2012  M. Isidro (Cloud Sherpas)   Added code to exclude Revenue Schedule where Opportunity Stage is not equal to Closed Won 
11.10.2012  M. Isidro (Cloud Sherpas)   Added filter to exclude OPC records under review by Sales Manager
15.10.2012  R. Enojas (Salesforce)      Added code to clear OPCs whose Revenue Schedules have been deleted due to 'Product Error' (CR 27)
19.12.2012	R. Enojas (Salesforce)		Changed date criteria on batch scope to start from July 1st of the CFY
**************************************************/

global class GenerateOPCBatchable implements Database.Batchable<SObject> {
    
    public Boolean testRun = false;

    global String query;
    
/*  
    global Map<String, Opp_Product_Classification__c> idOPCMap = new Map<String, Opp_Product_Classification__c>();
    global Map<String, Budget_and_Revenue__c> idBARMap = new Map<String, Budget_and_Revenue__c>();
    global Map<String, Revenue_Schedule__c> idRSMap = new Map<String, Revenue_Schedule__c>();
    global Map<String, Id> uniqueIdopcIdMap = new Map<String, Id>();
    global Map<String, String> renewalUpsellMap = new Map<String, String>();
    global Map<String, Revenue_Schedule__c> opcIdRSMap = new Map<String, Revenue_Schedule__c>();
    global List<Opp_Product_Classification__c> opcList = new List<Opp_Product_Classification__c>();
    global List<Case> caseList = new List<Case>();  
    
    global Map<String, Opp_Product_Classification__c> idOPCExistingMap = new Map<String, Opp_Product_Classification__c>();
    global List<Opp_Product_Classification__c> insertOPCList = new List<Opp_Product_Classification__c>();
    global List<Opp_Product_Classification__c> updateOPCList = new List<Opp_Product_Classification__c>();    
    global List<Opp_Product_Classification__c> requeryOPCList = new List<Opp_Product_Classification__c>();
    
    global String rtId = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType='Case' AND Name='OPC Exception' Limit 1].Id;  
*/    
    
    global GenerateOPCBatchable() {
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {

        system.debug('### START:');
        system.debug('***getHeapSize: ' + Limits.getHeapSize());
        
        Date dateToday = Date.today();
        Integer currYear = dateToday.year();
        Integer currMonth = dateToday.month();
        Integer finalYear;
        
        //Logic to derive the start of the FY based on today's date
        system.debug('Current Year: ' + currYear);
        system.debug('Current Month: ' + currMonth);
        
        if (currMonth >= 7 && currMonth <= 12)
        	finalYear = currYear;
        else if (currMonth >= 1 && currMonth <= 6)
        	finalYear = currYear-1;  
		
		system.debug('Final Year: ' + finalYear);
		
		Date finalDate = date.newInstance(finalYear, 7, 1);
		
		system.debug('Final Date: ' + finalDate);
		
		
        query = 'Select Id '
        + ' From Revenue_Schedule__c'
        + ' Where'
        + ' ( Opportunity__r.AccountId <> null' 

        + ' And Opportunity__r.StageName = \'Closed Won\' '

        + ' And Product__c <> null'
        + ' And Classification_c__c <> null'
        + ' And CalendarYear__c <> null'
        + ' And Financial_Year__c <> null'
        + ' And Opportunity__c <> null )'
//        + ' And ( (Opportunity_Product_Classification__r.Hidden_Under_Review__c = false) Or (Opportunity_Product_Classification__r.Hidden_Renewal_Missing_Growth__c = true) )'
        + ' And ( ' 
        + ' (((Opportunity_Product_Classification__r.Hidden_Under_Review__c = false) Or' 
        + ' (Opportunity_Product_Classification__r.Hidden_Renewal_Missing_Growth__c = true) Or' 
        + ' (Opportunity_Product_Classification__r.Hidden_Under_Review__c = true AND (Reclassified__c = true)))'
        + ' AND (Opportunity_Product_Classification__r.Under_Review_by_Sales_Manager__c = false))'
        + ' )'
        + ' And ' 
        + ' ( (Contract_End_Date__c >= :finalDate) Or (Exception_Override__c = true) )'
        + ' Order By Opportunity__r.AccountId, Product__c, Classification_c__c, Financial_Year__c';            
        
        //append 200 query limit for testing
        if(testRun)
            query = query + ' limit 200';
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        system.debug('### EXECUTE:');
        system.debug('***getLimitHeapSize: ' + Limits.getLimitHeapSize());
        system.debug('***getHeapSize: ' + Limits.getHeapSize());        

        Map<String, Opp_Product_Classification__c> idOPCMap = new Map<String, Opp_Product_Classification__c>();
        Map<String, Budget_and_Revenue__c> idBARMap = new Map<String, Budget_and_Revenue__c>();
        Map<String, Revenue_Schedule__c> idRSMap = new Map<String, Revenue_Schedule__c>();
        Map<String, Id> uniqueIdopcIdMap = new Map<String, Id>();
        Map<String, String> renewalUpsellMap = new Map<String, String>();
        Map<String, Revenue_Schedule__c> opcIdRSMap = new Map<String, Revenue_Schedule__c>();
        List<Opp_Product_Classification__c> opcList = new List<Opp_Product_Classification__c>();
        List<Case> caseList = new List<Case>(); 
        
        Map<String, Opp_Product_Classification__c> idOPCExistingMap = new Map<String, Opp_Product_Classification__c>();
        List<Opp_Product_Classification__c> insertOPCList = new List<Opp_Product_Classification__c>();
        List<Opp_Product_Classification__c> updateOPCList = new List<Opp_Product_Classification__c>();    
        List<Opp_Product_Classification__c> requeryOPCList = new List<Opp_Product_Classification__c>();
        
        List<String> rsIdList = new List<String>();
        List<Revenue_Schedule__c> rsList = new List<Revenue_Schedule__c>();
        List<String> acctIdList = new List<String>();
        List<String> prodIdList = new List<String>();
        
        List<String> opcIdList = new List<String>();        
        
        String rtId = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType='Case' AND Name='OPC Exception' Limit 1].Id;  
/*      
        Map<String, Opp_Product_Classification__c> idOPCMap = new Map<String, Opp_Product_Classification__c>();
        Map<String, Budget_and_Revenue__c> idBARMap = new Map<String, Budget_and_Revenue__c>();
        Map<String, Revenue_Schedule__c> idRSMap = new Map<String, Revenue_Schedule__c>();
        Map<String, Id> uniqueIdopcIdMap = new Map<String, Id>();
        Map<String, String> renewalUpsellMap = new Map<String, String>();
        Map<String, Revenue_Schedule__c> opcIdRSMap = new Map<String, Revenue_Schedule__c>();
        List<Opp_Product_Classification__c> opcList = new List<Opp_Product_Classification__c>();
        List<Case> caseList = new List<Case>(); 
*/

        // Get OPC Id to be deleted from Revenue Schedule records   
        system.debug('### scope: ' + scope);
        
        if (!scope.isEmpty()) {
            for (SObject rs : scope) {
                rsIdList.add( String.valueOf(rs.get('Id')) );   
            }
            
            system.debug('### rsIdList: ' + rsIdList);
            
            rsList =
            [Select Id, Opportunity__r.AccountId, Product__c, Classification_c__c, CalendarYear__c, 
            Opportunity__c, Financial_Year__c, Opportunity_Product_Classification__c,
            Product__r.Name, Opportunity__r.Customer_Name__c, Contract_Start_Date__c, Contract_End_Date__c,
            Multi_Year__c, Exception_Override__c, Hidden_1st_of_Multi_Year__c,
            Jan_Claimed_Revenue__c, Feb_Claimed_Revenue__c, Mar_Claimed_Revenue__c,  
            Apr_Claimed_Revenue__c, May_Claimed_Revenue__c, Jun_Claimed_Revenue__c,
            Jul_Claimed_Revenue__c, Aug_Claimed_Revenue__c, Sep_Claimed_Revenue__c,
            Oct_Claimed_Revenue__c, Nov_Claimed_Revenue__c, Dec_Claimed_Revenue__c,
            
            Jan_NRT_Adjustment__c, Feb_NRT_Adjustment__c, Mar_NRT_Adjustment__c,  
            Apr_NRT_Adjustment__c, May_NRT_Adjustment__c, Jun_NRT_Adjustment__c,
            Jul_NRT_Adjustment__c, Aug_NRT_Adjustment__c, Sep_NRT_Adjustment__c,
            Oct_NRT_Adjustment__c, Nov_NRT_Adjustment__c, Dec_NRT_Adjustment__c
            
            From Revenue_Schedule__c
            Where Id in : rsIdList
            Order By Opportunity__r.AccountId, Product__c, Classification_c__c, Financial_Year__c];
        }       
        
        system.debug('### rsList: ' + rsList);
        system.debug('***getHeapSize: After rsList: ' + Limits.getHeapSize());
        
        for (Revenue_Schedule__c rs : rsList) {
            String opcId = rs.Opportunity_Product_Classification__c;
            system.debug('***opcId: ' + opcId);
            if (opcId != '' && opcId != null) {
                opcIdList.add( opcId );
            }
            
            String accountId = rs.Opportunity__r.AccountId;
            system.debug('***accountId: ' + accountId);
            if (accountId != '' && accountId != null) {
                acctIdList.add( accountId );
            }   
            
            String prodId = rs.Product__c;
            system.debug('***prodId: ' + prodId);
            if (prodId != '' && prodId != null) {
                prodIdList.add( prodId );
            }                       
        } 
        
        // Delete all OPC records related to the Revenue Schedule records in scope
        if (!opcIdList.isEmpty()) {
            system.debug('*** opcIdList Not Empty: ' + opcIdList);
            OPCUtility.deleteOPCList(opcIdList);
        }
        system.debug('***getHeapSize: After deleteOPCList: ' + Limits.getHeapSize());
        
        // For CR 27, delete all OPC records related to Revenue Schedule records that have been deleted due to 'Product Error'
        // Only delete OPCs in the context of the Organisations within scope and those that do not have any Revenue Schedules 
        List<Id> addlOPCList = new List<Id>(); 
        
        for (Opp_Product_Classification__c addlOPC : [SELECT Id, Account__c, Under_Review_by_Sales_Manager__c 
        												FROM Opp_Product_Classification__c 
        												WHERE Account__c in :acctIdList
        												AND Id NOT IN (SELECT Opportunity_Product_Classification__c FROM Revenue_Schedule__c)])
            if (addlOPC.Under_Review_by_Sales_Manager__c <> true)
                addlOPCList.add(addlOPC.Id);
        
        if (!addlOPCList.isEmpty()) {
            system.debug('*** addlOPCList Not Empty: ' + addlOPCList);
            OPCUtility.deleteOPCList(addlOPCList);
        }
        system.debug('***getHeapSize: After deleteOPCList for addlOPCList: ' + Limits.getHeapSize()); 
        
        
        OPCUtility.createMapGrowthClassification(rsList, renewalUpsellMap);
        system.debug('***getHeapSize: After createMapGrowthClassification: ' + Limits.getHeapSize());       
        
        // Create OPC from Revenue Schedule/s
        OPCUtility.createOPCMap(rsList, idOPCMap, idRSMap, renewalUpsellMap);
        system.debug('***getHeapSize: After createOPCMap: ' + Limits.getHeapSize());        
        // After this method is executed, input parameters should be updated
        
        // Check if OPC records already exist
        // New OPCs will be inserted and existing OPCs will be aggregated
        OPCUtility.checkIfOPCExist(idOPCMap, idOPCExistingMap, insertOPCList, updateOPCList);
        system.debug('***getHeapSize: After checkIfOPCExist: ' + Limits.getHeapSize()); 
        
        // After this method is executed, input parameters should be updated 
        
        // Relate the related Revenue Schedule to the new OPC records
        OPCUtility.relateRevenueScheduleToOPC(insertOPCList, rsList, uniqueIdopcIdMap, opcIdRSMap);
        system.debug('***getHeapSize: After relateRevenueScheduleToOPC:' + Limits.getHeapSize());   
        
        // Create Budget and Revenue Map
        OPCUtility.createBARMap(idBARMap, acctIdList, prodIdList);
        system.debug('***getHeapSize: After createBARMap: ' + Limits.getHeapSize());    

        // Check for exceptions
        if (!insertOPCList.isEmpty()) {
            requeryOPCList = OPCUtility.requeryOPCList(insertOPCList, requeryOPCList);
            system.debug('***requeryOPCList: ' + requeryOPCList);
            system.debug('***getHeapSize: After requeryOPCList: ' + Limits.getHeapSize());  
            
            OPCUtility.checkForException(requeryOPCList, idBARMap, opcIdRSMap, caseList, rtId, rsList);
            system.debug('***getHeapSize: After checkForException: ' + Limits.getHeapSize());       
            
            
            system.debug('@@@ Size of idOPCMap: ' + idOPCMap.size());   
            system.debug('@@@ Size of idBARMap: ' + idBARMap.size());
            system.debug('@@@ Size of idRSMap: ' + idRSMap.size());
            system.debug('@@@ Size of uniqueIdopcIdMap: ' + uniqueIdopcIdMap.size());
            system.debug('@@@ Size of renewalUpsellMap: ' + renewalUpsellMap.size());
            system.debug('@@@ Size of opcIdRSMap: ' + opcIdRSMap.size());
            system.debug('@@@ Size of opcList: ' + opcList.size());
            system.debug('@@@ Size of caseList: ' + caseList.size());
            system.debug('@@@ Size of idOPCExistingMap: ' + idOPCExistingMap.size());
            system.debug('@@@ Size of insertOPCList: ' + insertOPCList.size());
            system.debug('@@@ Size of updateOPCList: ' + updateOPCList.size());
            system.debug('@@@ Size of requeryOPCList: ' + requeryOPCList.size());
            system.debug('@@@ Size of rsIdList: ' + rsIdList.size());
            system.debug('@@@ Size of rsList: ' + rsList.size());
            system.debug('@@@ Size of acctIdList: ' + acctIdList.size());
            system.debug('@@@ Size of prodIdList: ' + prodIdList.size());
            system.debug('@@@ Size of opcIdList: ' + opcIdList.size());
            
        
            idOPCMap.clear();
            idBARMap.clear();
            idRSMap.clear();
            uniqueIdopcIdMap.clear();   
            renewalUpsellMap.clear();   
            opcIdRSMap.clear(); 
            opcList.clear();
            caseList.clear();
            idOPCExistingMap.clear();
            insertOPCList.clear();
            updateOPCList.clear();
            requeryOPCList.clear();
            rsIdList.clear();
            rsList.clear();
            acctIdList.clear();
            prodIdList.clear();
            opcIdList.clear();
            
            system.debug('***getHeapSize: After checkForException: REDUCED: ' + Limits.getHeapSize());  

            idOPCMap = null;
            idBARMap = null;
            idRSMap = null;
            uniqueIdopcIdMap = null;    
            renewalUpsellMap = null;    
            opcIdRSMap = null;  
            opcList = null;
            caseList = null;
            idOPCExistingMap = null;
            insertOPCList = null;
            updateOPCList = null;
            requeryOPCList = null;
            rsIdList = null;
            rsList = null;
            acctIdList = null;
            prodIdList = null;
            opcIdList = null;
            addlOPCList = null;

            system.debug('***getHeapSize: After NULLING: REDUCED: ' + Limits.getHeapSize());    
        }
    
        
/*      
        caseList.clear();
        if (!updateOPCList.isEmpty()) {
            requeryOPCList = OPCUtility.requeryOPCList(updateOPCList, requeryOPCList);
            system.debug('***requeryOPCList: ' + requeryOPCList);
            OPCUtility.checkForException(requeryOPCList, idBARMap, opcIdRSMap, caseList, rtId, rsList);         
        }
*/                      
    }

    
    global void finish(Database.BatchableContext BC) {
        system.debug('*** FINISH:');    
    }   
    
/*
    @isTest(seeAllData=true)
    private static void testGenerateOPCBatchable() {
        test.startTest();
        GenerateOPCBatchable gob = new GenerateOPCBatchable();
        Database.executeBatch(gob, 1000);
        test.stopTest();
    }   
*/
}