/**************************************************
Type:       Apex Batch Job Class for Budget and Revenue Object
Purpose:    Creates a summary of Billed Revenue and Budget data coming into Salesforce from a legacy system
Used By:    
History:
--------------------------------------------------
16.08.2012  M. Isidro (Cloud Sherpas)   Created
04.09.2012  M. Isidro (Cloud Sherpas)   Added test coverage
26.09.2012  M. Isidro (Cloud Sherpas)   Modified test coverage (Removed @isTest(seeAllData=true), added test data) 
**************************************************/
global with sharing class BudgetRevenueBatchable implements Database.Batchable<SObject> {

    global String query;
    global String strYear;
    global String strMonth;
    
    global Map<String, Decimal> mapRepSegmentTotal = new Map<String, Decimal>();
    global Map<String, Decimal> mapRepSegmentBudget = new Map<String, Decimal>();
    global Map<String, Budget_and_Revenue_by_Months__c> mapNewRepSegmentTotal = new Map<String, Budget_and_Revenue_by_Months__c>();
    global Map<String, Budget_and_Revenue_by_Months__c> mapNewRepSegmentBudget = new Map<String, Budget_and_Revenue_by_Months__c>();
    global Map<String, Budget_and_Revenue_by_Months__c> mapRequeryRepSegmentTotal = new Map<String, Budget_and_Revenue_by_Months__c>();
    global Map<String, Budget_and_Revenue_by_Months__c> mapRequeryRepSegmentBudget = new Map<String, Budget_and_Revenue_by_Months__c>();
    global List<Budget_and_Revenue_by_Months__c> addBARBMList = new List<Budget_and_Revenue_by_Months__c>();    
    
    global List<Budget_and_Revenue_by_Months__c> insertBARBYMList = new List<Budget_and_Revenue_by_Months__c>();
    global List<Budget_and_Revenue_by_Months__c> updateBARBYMList = new List<Budget_and_Revenue_by_Months__c>();        
    
    global BudgetRevenueBatchable() {
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        system.debug('### START:');
        
        
        // Get current FY and month
        Date dateToday = Date.today();  
        Integer iYear = dateToday.year();
        Integer iMonth = dateToday.month();
        strMonth = BudgetRevenueUtility.getMonth(iMonth);   
        if (iMonth >= 7) {
            iYear = iYear + 1;
        }
        strYear = String.valueof(iYear);
                
        system.debug('###strYear: ' + strYear);
        
        // Query records for current month and FY only
        //List<Budget_and_Revenue__c> currentBARList = 
        query =
          ' Select Organisation__c, Financial_Year__c, Organisation__r.OwnerId, Organisation__r.Sales_Segment__c,' 
        + ' Jan_Revenue_Amount__c, Feb_Revenue_Amount__c, Mar_Revenue_Amount__c,' 
        + ' Apr_Revenue_Amount__c, May_Revenue_Amount__c, Jun_Revenue_Amount__c,' 
        + ' Jul_Revenue_Amount__c, Aug_Revenue_Amount__c, Sep_Revenue_Amount__c,' 
        + ' Oct_Revenue_Amount__c, Nov_Revenue_Amount__c, Dec_Revenue_Amount__c,' 
        + ' Jan_Original_Budget__c, Feb_Original_Budget__c, Mar_Original_Budget__c,' 
        + ' Apr_Original_Budget__c, May_Original_Budget__c, Jun_Original_Budget__c,' 
        + ' Jul_Original_Budget__c, Aug_Original_Budget__c, Sep_Original_Budget__c,' 
        + ' Oct_Original_Budget__c, Nov_Original_Budget__c, Dec_Original_Budget__c,' 
        + ' Jan_Revised_Budget__c, Feb_Revised_Budget__c, Mar_Revised_Budget__c,' 
        + ' Apr_Revised_Budget__c, May_Revised_Budget__c, Jun_Revised_Budget__c,' 
        + ' Jul_Revised_Budget__c, Aug_Revised_Budget__c, Sep_Revised_Budget__c,' 
        + ' Oct_Revised_Budget__c, Nov_Revised_Budget__c, Dec_Revised_Budget__c,' 
        
        + ' MTDActual__c, MTD_Actual__c, MTD_Actual_Last_Year_R__c, MTD_Actual_Last_Year__c, MTD_Original_Budget_R__c, MTD_Original_Budget__c'
        
        + ' From Budget_and_Revenue__c'
        + ' Where Financial_Year__c = :strYear'
        + ' Order By Organisation__r.OwnerId, Organisation__r.Sales_Segment__c';        
        
        return Database.getQueryLocator(query); 
    }
    
    
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        
        system.debug('### EXECUTE:');
        // Get current FY and month
        Date dateToday = Date.today();  
        Integer iYear = dateToday.year();
        Integer iMonth = dateToday.month();
        strMonth = BudgetRevenueUtility.getMonth(iMonth);   
        if (iMonth >= 7) {
            iYear = iYear + 1;
        }
        strYear = String.valueof(iYear);
                
        system.debug('###strYear: ' + strYear);     
        
        List<String> barIdList = new List<String>();
        List<Budget_and_Revenue__c> barList = new List<Budget_and_Revenue__c>();
        List<Budget_and_Revenue_by_Months__c> addBARBMList = new List<Budget_and_Revenue_by_Months__c>();
        List<Budget_and_Revenue_by_Months__c> requeryBARByMonthsList = new List<Budget_and_Revenue_by_Months__c>();
        
        system.debug('### strYear + strMonth: ' + strYear);
        
        // Delete all Budget and Revenue By Month records (Current FY and Month)
        BudgetRevenueUtility.deleteBudgetandRevenueByMonth(strYear, strMonth);  


        // Requery Budget and Revenue because scope does not contain related object fields      
        if (!scope.isEmpty()) {
            
            system.debug('### SCOPE NOT EMPTY:');
            
            for (SObject bar : scope) {
                barIdList.add( String.valueOf(bar.get('Id')) ); 
            }
            
            barList =
            [Select Organisation__c, Financial_Year__c, Organisation__r.OwnerId, Organisation__r.Sales_Segment__c, 
            Jan_Revenue_Amount__c, Feb_Revenue_Amount__c, Mar_Revenue_Amount__c,
            Apr_Revenue_Amount__c, May_Revenue_Amount__c, Jun_Revenue_Amount__c, 
            Jul_Revenue_Amount__c, Aug_Revenue_Amount__c, Sep_Revenue_Amount__c, 
            Oct_Revenue_Amount__c, Nov_Revenue_Amount__c, Dec_Revenue_Amount__c, 
            Jan_Original_Budget__c, Feb_Original_Budget__c, Mar_Original_Budget__c, 
            Apr_Original_Budget__c, May_Original_Budget__c, Jun_Original_Budget__c, 
            Jul_Original_Budget__c, Aug_Original_Budget__c, Sep_Original_Budget__c, 
            Oct_Original_Budget__c, Nov_Original_Budget__c, Dec_Original_Budget__c, 
            Jan_Revised_Budget__c, Feb_Revised_Budget__c, Mar_Revised_Budget__c, 
            Apr_Revised_Budget__c, May_Revised_Budget__c, Jun_Revised_Budget__c, 
            Jul_Revised_Budget__c, Aug_Revised_Budget__c, Sep_Revised_Budget__c, 
            Oct_Revised_Budget__c, Nov_Revised_Budget__c, Dec_Revised_Budget__c,
            MTDActual__c, MTD_Actual__c, MTD_Actual_Last_Year_R__c, 
            MTD_Actual_Last_Year__c, MTD_Original_Budget_R__c, MTD_Original_Budget__c
            From Budget_and_Revenue__c
            Where Id in : barIdList];
            
            BudgetRevenueUtility.updateMTDFields(barList);
        }       
        
        // Map the Revenue and Budget per Account Owner:Sales Segment
        BudgetRevenueUtility.mapBudgetandRevenue(barList, iMonth, mapRepSegmentTotal, mapRepSegmentBudget);     
        
        system.debug('***mapRepSegmentTotal: ' + mapRepSegmentTotal);   
        system.debug('***mapRepSegmentBudget: ' + mapRepSegmentBudget); 
        
        // Create Revenue and Budget By Month records
        BudgetRevenueUtility.createRevenueandBudgetByMonth(mapRepSegmentTotal, mapRepSegmentBudget, addBARBMList, strYear, strMonth);
        system.debug('***mapRepSegmentTotal: ' + mapRepSegmentTotal);
        
        // Map New Revenue and Budget By Month records
        BudgetRevenueUtility.mapNewBARByMonth(addBARBMList, mapNewRepSegmentTotal, mapNewRepSegmentBudget);
        system.debug('***mapNewRepSegmentTotal: ' + mapNewRepSegmentTotal);
        system.debug('***mapNewRepSegmentBudget: ' + mapNewRepSegmentBudget);
        
        // Requery Existing Revenue and Budget By Month records
        requeryBARByMonthsList = BudgetRevenueUtility.requeryBudgetandRevenueByMonth(strYear, strMonth);
        system.debug('***requeryBARByMonthsList: ' + requeryBARByMonthsList);
        
        // Map Existing Revenue and Budget By Month records 
        BudgetRevenueUtility.mapExistingBARByMonth(requeryBARByMonthsList, mapRequeryRepSegmentTotal, mapRequeryRepSegmentBudget);
        system.debug('***requeryBARByMonthsList: ' + requeryBARByMonthsList);
        system.debug('***mapRequeryRepSegmentTotal: ' + mapRequeryRepSegmentTotal);
        system.debug('***mapRequeryRepSegmentBudget: ' + mapRequeryRepSegmentBudget);
        
        // Compare New to Existing Budget By Month records
        BudgetRevenueUtility.compareNewandExistingBARBYM(mapNewRepSegmentTotal, mapNewRepSegmentBudget, mapRequeryRepSegmentTotal, mapRequeryRepSegmentBudget, insertBARBYMList, updateBARBYMList);
    }   
    
    
    global void finish(Database.BatchableContext BC) {
        system.debug('*** FINISH:');    
    }   
    
    
    //@isTest(seeAllData=true)
    private static testMethod void testBudgetRevenueBatchable() {
        RecordType orgrectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        system.debug('*** orgrectype: ' + orgrectype);
        
        Profile p = [SELECT Id FROM Profile where name = 'Customer Team' limit 1];
        User u = new User(Alias = 'x', Email='x@x.com', ProfileId = p.Id,
                        EmailEncodingKey='UTF-8', FirstName='Holding', LastName='User', LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US', isActive = true,
                        TimeZoneSidKey='America/Los_Angeles', UserName='x356@x.com');
        insert u;
        
        system.runas(u) {
            //create account
            Account bacct = new Account(
                name='test org', recordtypeid=orgrectype.Id, type='Small Business',  
                phone='11111111', email__c='test@test.com', abn__c='12345678901', Website='www.google.com',
                Organisation_Trading_Name__c='Trade',
                BillingCity='City',
                BillingCountry='Country',
                BillingState='State',
                BillingPostalCode='12345',
                ShippingCity='City',
                ShippingCountry='Country',
                ShippingState='State',
                ShippingStreet='Street',
                ShippingPostalCode='12345');    
            //name='test org', recordtypeid=orgrectype.Id, type='Small Business', industry='Communications', Industry_Sub_Sector__c='Media',  phone='11111111', email__c='test@test.com', abn__c='12345678901', Website='www.google.com');
            insert bacct; 
            
            Organisation_Role__c orgRole = [SELECT Id, Role_Type__c 
                                            FROM Organisation_Role__c 
                                            WHERE Organisation__c =: bacct.Id
                                            AND Role_Type__c='Prospect' 
                                            limit 1];
            orgRole.Role_Type__c='Customer';        
            update OrgRole;     
            List<SObject> list_scope = new List<SObject>();
            List<Budget_and_Revenue__c> barList = new List<Budget_and_Revenue__c>();
            Integer nCount = 12;
            for( Integer i=0; i<nCount; i++){
                Budget_and_Revenue__c bar = new Budget_and_Revenue__c(
                    Organisation__c=bacct.id, 
                    Financial_Year__c= String.valueOf(2010 + Math.mod(i, 4)), 
                    Jan_Revenue_Amount__c=100, 
                    Feb_Revenue_Amount__c=200,
                    Mar_Revenue_Amount__c=300,
                    Apr_Revenue_Amount__c=400,
                    May_Revenue_Amount__c=500,
                    Jun_Revenue_Amount__c=600,
                    Jul_Revenue_Amount__c=700,
                    Aug_Revenue_Amount__c=800,
                    Sep_Revenue_Amount__c=900,
                    Oct_Revenue_Amount__c=1000,
                    Nov_Revenue_Amount__c=1100,
                    Dec_Revenue_Amount__c=1200,
                    Jan_Original_Budget__c=1000,
                    Feb_Original_Budget__c=2000,
                    Mar_Original_Budget__c=3000,
                    Apr_Original_Budget__c=4000,
                    May_Original_Budget__c=5000,
                    Jun_Original_Budget__c=6000,
                    Jul_Original_Budget__c=7000,
                    Aug_Original_Budget__c=8000,
                    Sep_Original_Budget__c=9000,
                    Oct_Original_Budget__c=10000,
                    Nov_Original_Budget__c=11000,
                    Dec_Original_Budget__c=12000
                    );
                    
                barList.add(bar);  
                list_scope.add(bar);                                 
            }
            insert barList;             
            
            system.debug('*** barList: ' + barList);
            
            test.startTest();
            Database.BatchableContext BC;
            BudgetRevenueBatchable brb = new BudgetRevenueBatchable();
            Database.executeBatch(brb, 1000);
            
            brb.execute(BC, list_scope);
            test.stopTest();
        }
        
            
    }  

}