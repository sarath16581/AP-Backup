//Created by: Viswanatha Goki
//Created date: April 17th 2013
//Description: This batch class Updates Custmer Accounts with Aggregated Quarterly targets and forecasts for the current financial year
//Additional Comments: This btach class should be scheduled to run whenever, Target and revenue data is loaded into salesforce


global with sharing class CustomerQuarterlyForecasts implements Database.Batchable<SObject>, Database.Stateful {
    
    //Default Constructor
    global CustomerQuarterlyForecasts() {
    }
    
    //Start method of Apex of Batch class. Returns the account ids of customers to execute method
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('*** Start:');       
        String strCustomer='Customer';        
        String query='Select Id from Account where Role_Type_Roll_Up__c=:strCustomer';
        //String query='Select Id from Account';

        return Database.getQueryLocator(query);
    }
  
    //Retrieves the related Target and revenue records and updates Accounts with aggregated quarterly targets and forecast for current financial year  
    global void execute(Database.BatchableContext BC, List<SObject> scope) {
    
        system.debug('*** Execute:');     
                
        //Stores accounts ids which are in the scope of the execute method
        List<Id> accountIdList = new List<String>();
        
        //Stores List of accounts which needs to be updated in the execute method
        Map<String, Account> mapaccountList = new Map<String, Account>(); 
                
        // Get current FY and month
        Date dateToday = Date.today();  
        Integer iYear = dateToday.year();
        Integer iMonth = dateToday.month();
        //String strMonth = getMonth(iMonth);   
        if (iMonth >= 7) {
            iYear = iYear + 1;
        }
        String strYear = String.valueof(iYear); 
        


        
        if (!scope.isEmpty()) {
            
          //Get list of Accounts Ids from scope
          for (SObject acc : scope) {
            accountIdlIst.add(String.valueOf(acc.get('Id')));
          }
          
          //Retrive aggregation of Quarterly targets and forecasts, from target and revenue, for the list of accounts in the scope of execute method
          String query='Select Organisation__c,SUM(Q1_Revised_Budget__c) Q1RSUM,SUM(Q1_Original_Budget__c) Q1OSUM,SUM(Q2_Revised_Budget__c) Q2RSUM,SUM(Q2_Original_Budget__c) Q2OSUM,SUM(Q3_Revised_Budget__c) Q3RSUM,SUM(Q3_Original_Budget__c) Q3OSUM,SUM(Q4_Revised_Budget__c) Q4RSUM,SUM(Q4_Original_Budget__c) Q4OSUM From Budget_and_Revenue__c Where Financial_Year__c = :strYear and Organisation__c=:accountIdList group by Organisation__c';
          List<sObject> tarList=Database.query(query);
          
          //Update accounts with aggregated quarterly targets and forecasts
          for(sObject tar : tarList) {
                Account a=new Account();
                a.id=String.valueOf(tar.get('Organisation__c'));
                a.Q1_Forecast__c=0;
                a.Q2_Forecast__c=0;
                a.Q3_Forecast__c=0;
                a.Q4_Forecast__c=0;
                a.Original_Q1_Target__c=0;
                a.Original_Q2_Target__c=0;
                a.Original_Q3_Target__c=0;
                a.Original_Q4_Target__c=0;
                
                if(tar.get('Q1RSUM')!=null && tar.get('Q1RSUM')!='')
                a.Q1_Forecast__c = Decimal.valueOf(String.valueOf(tar.get('Q1RSUM')));
                if(tar.get('Q2RSUM')!=null && tar.get('Q2RSUM')!='')
                a.Q2_Forecast__c = Decimal.valueOf(String.valueOf(tar.get('Q2RSUM')));
                if(tar.get('Q3RSUM')!=null && tar.get('Q3RSUM')!='')
                a.Q3_Forecast__c = Decimal.valueOf(String.valueOf(tar.get('Q3RSUM')));
                if(tar.get('Q4RSUM')!=null && tar.get('Q4RSUM')!='')
                a.Q4_Forecast__c = Decimal.valueOf(String.valueOf(tar.get('Q4RSUM')));
                if(tar.get('Q1OSUM')!=null && tar.get('Q1OSUM')!='')
                a.Original_Q1_Target__c = Decimal.valueOf(String.valueOf(tar.get('Q1OSUM')));
                if(tar.get('Q2OSUM')!=null && tar.get('Q2OSUM')!='')
                a.Original_Q2_Target__c = Decimal.valueOf(String.valueOf(tar.get('Q2OSUM')));
                if(tar.get('Q3OSUM')!=null && tar.get('Q3OSUM')!='')
                a.Original_Q3_Target__c = Decimal.valueOf(String.valueOf(tar.get('Q3OSUM')));                
                if(tar.get('Q4OSUM')!=null && tar.get('Q4OSUM')!='')
                a.Original_Q4_Target__c = Decimal.valueOf(String.valueOf(tar.get('Q4OSUM')));
                
                mapaccountList.put(String.valueOf(tar.get('Organisation__c')),a);
          }
          update mapaccountList.values();
        }


    }

    //Btach class finish methos
    global void finish(Database.BatchableContext BC) {
        system.debug('*** FINISH:');    
    }
    
  

    //@isTest(seeAllData=true)
    private static testMethod void testBudgetRevenueBatchable() {
       
        //create account
        Account bacct = new Account(
            name='test org',
            BillingCity='City',
            BillingCountry='Country',
            BillingState='State',
            BillingPostalCode='12345',
            ShippingCity='City',
            ShippingCountry='Country',
            ShippingState='State',
            ShippingStreet='Street',
            ShippingPostalCode='12345',
    Q1_Forecast__c=0);    
        //name='test org', recordtypeid=orgrectype.Id, type='Small Business', industry='Communications', Industry_Sub_Sector__c='Media',  phone='11111111', email__c='test@test.com', abn__c='12345678901', Website='www.google.com');
        insert bacct; 
        
        
        List<Budget_and_Revenue__c> tarList = new List<Budget_and_Revenue__c>();
        Integer nCount = 12;
        for( Integer i=0; i<nCount; i++){
            Budget_and_Revenue__c bar = new Budget_and_Revenue__c(
                Organisation__c=bacct.id, 
                Financial_Year__c= String.valueOf(2010 + Math.mod(i, 4)), 
                Q1_Revised_Budget__c=100,
                Q2_Revised_Budget__c=100,
                Q3_Revised_Budget__c=100,
                Q4_Revised_Budget__c=100,
                Q1_Original_Budget__c=100,
                Q2_Original_Budget__c=100,
                Q3_Original_Budget__c=100,
                Q4_Original_Budget__c=100);
                
            tarList.add(bar);                                   
        }
        insert tarList;   
          
          string bacctId=string.valueOf(bacct.id);        
          String query='Select Id,Organisation__c,Role_Type__c From Organisation_Role__c Where Organisation__c=:bacctId';
          List<sObject> roleList=Database.query(query);
          for(sObject r: roleList){
              Organisation_Role__c customerRoleRecord=new Organisation_Role__c();
              customerRoleRecord.Role_Type__c='Customer';
              customerRoleRecord.id=String.valueOf(r.get('Id'));
              update customerRoleRecord;

          }
        
  
        
        
        test.startTest();
        CustomerQuarterlyForecasts brb = new CustomerQuarterlyForecasts();
        Database.executeBatch(brb, 1000);
        test.stopTest();
    } 
}