/*
 * 09.07 Eric.shen@auspost.com.au  Update  op2.StageName='Identify';
 * 17/7/2017 adrian.recio@auspost.com.au Update fix coverage from 3% to 80%. Added coverage for the class scheduler.
 * 02/06/2020 shashwat.a.nath@accenture.com : Updated the opportunity test data creation to be in sync with the validation Opportunity_Stage_Probability
 */

@isTest
private class OPCValidationService_Test{
    static testMethod void testOPCValidationService() {        
        
        // Generate products
        
        Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
        insert product;
        
        Id priceBookId=Test.getStandardPricebookId();
        PricebookEntry  priceBookEntry = APT_TestUtils.getPricebookEntry(priceBookId,product.Id);
        insert priceBookEntry;
        
        // Account
        List<Account> accList = new List<Account>();
        
        Account ac1=new Account();
        ac1.name='Test Account1';
        ac1.LEGACY_ID__c = '12345';         
        ac1.abn__c = '12345678901';         
        ac1.Organisation_Trading_Name__c = 'Trade';     
        ac1.billingstreet = 'street';         
        ac1.billingcity = 'city';           
        ac1.billingstate = 'state';           
        ac1.billingpostalcode = '3000';           
        ac1.billingcountry = 'AU';           
        ac1.shippingstreet = 'street';           
        ac1.shippingcity = 'city';           
        ac1.shippingstate = 'state';            
        ac1.shippingpostalcode = '3000';            
        ac1.shippingcountry = 'AU';  
        accList.add(ac1);
        
        Account ac2=new Account();
        ac2.name='Test Account2';
        ac2.LEGACY_ID__c = '12345';         
        ac2.abn__c = '12345678901';         
        ac2.Organisation_Trading_Name__c = 'Trade';     
        ac2.billingstreet = 'street';         
        ac2.billingcity = 'city';           
        ac2.billingstate = 'state';           
        ac2.billingpostalcode = '3000';           
        ac2.billingcountry = 'AU';           
        ac2.shippingstreet = 'street';           
        ac2.shippingcity = 'city';           
        ac2.shippingstate = 'state';            
        ac2.shippingpostalcode = '3000';            
        ac2.shippingcountry = 'AU'; 
        accList.add(ac2);
        
        insert accList;

        // Role
       
        
        List<Organisation_Role__c> orList = [SELECT Id, Role_Type__c FROM Organisation_Role__c                                
                                       WHERE (Organisation__c =: ac1.id OR Organisation__c =: ac2.id)                               
                                       AND Role_Type__c='Prospect'];   
        
        for(Organisation_Role__c orVar : orList){
            orVar.Role_Type__c='Customer';     
        }    
        
        update orList;
        
        // B&R
        List<Budget_and_Revenue__c>brList = new List<Budget_and_Revenue__c>();
        
        Budget_and_Revenue__c bar1=new Budget_and_Revenue__c();
        bar1.Organisation__c=ac1.Id;
        bar1.Product__c = product.Id; //'01t90000000to7UAAQ';
        bar1.Financial_Year__c = '2014';
        bar1.Jan_Revenue_Amount__c = 1;
        bar1.Feb_Revenue_Amount__c = 1;
        bar1.Mar_Revenue_Amount__c = 1;
        bar1.Apr_Revenue_Amount__c = 1;
        bar1.May_Revenue_Amount__c = 1;
        bar1.Jun_Revenue_Amount__c = 6643;
        bar1.Jul_Revenue_Amount__c = 1;
        bar1.Aug_Revenue_Amount__c = 1;
        bar1.Sep_Revenue_Amount__c = 432;
        bar1.Oct_Revenue_Amount__c = 1;
        bar1.Nov_Revenue_Amount__c = 1;
        bar1.Dec_Revenue_Amount__c = 431;
        brList.add(bar1);
        
        Budget_and_Revenue__c bar2=new Budget_and_Revenue__c();
        bar2.Organisation__c=ac2.Id;
        bar2.Product__c = product.Id; //'01t90000000to52AAA';
        bar2.Financial_Year__c = '2013';
        bar2.Jan_Revenue_Amount__c = 5;
        bar2.Feb_Revenue_Amount__c = 3;
        bar2.Mar_Revenue_Amount__c = 30;
        bar2.Apr_Revenue_Amount__c = 123;
        bar2.May_Revenue_Amount__c = 6;
        bar2.Jun_Revenue_Amount__c = 6643;
        bar2.Jul_Revenue_Amount__c = 33;
        bar2.Aug_Revenue_Amount__c = 1;
        bar2.Sep_Revenue_Amount__c = 1;
        bar2.Oct_Revenue_Amount__c = 1;
        bar2.Nov_Revenue_Amount__c = 1;
        bar2.Dec_Revenue_Amount__c = 1;
        brList.add(bar2);
        
        insert brList;
        
        // Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        
        Opportunity op1 = new Opportunity();
        op1.Name='Test Opportunity1';
        op1.AccountId=ac1.Id;
        op1.Offering_Type__c='Product';
        op1.StageName = 'Identify';
        op1.Closed_Reason__c='Price';
        op1.Probability=10; // shashwat.a.nath   - Changed to .05 from 100 to bypass validation Opportunity_Stage_Probability
        op1.CloseDate=Date.today();
        op1.Type='Existing Customer';
        oppList.add(op1);

        Opportunity op2 = new Opportunity();
        op2.Name='Test Opportunity2';
        op2.AccountId=ac2.Id;
        op2.Offering_Type__c='Product';
        op2.StageName='Identify';    // 09/07 - Changed to Identify from Closed Won
        op2.Closed_Reason__c='Price';
        op2.Probability=10;        // shashwat.a.nath   - Changed to .05 from 10 to bypass validation Opportunity_Stage_Probability
        op2.CloseDate=Date.today();
        op2.Type='New Customer';
        oppList.add(op2);
        
        insert oppList;
        
        // OP1 OPL
        List<OpportunityLineItem> opLIList = new List<OpportunityLineItem>();
            
        OpportunityLineItem li1 = new OpportunityLineItem();
        li1.OpportunityId=op1.Id;
        li1.OPCValidated__c=false;
        li1.PricebookEntryId= priceBookEntry.Id; //'01u90000001HfgpAAC';
        li1.Classification__c='Win Back';        
        li1.Contract_Start_Date__c=date.parse('09/09/2013');        
        li1.Contract_End_Date__c=date.parse('09/09/2014');        
        li1.Quantity=1;
        li1.UnitPrice=100;
        opLIList.add(li1);
        
        OpportunityLineItem li2 = new OpportunityLineItem();
        li2.OpportunityId=op1.Id;
        li2.OPCValidated__c=false;
        li2.PricebookEntryId= priceBookEntry.Id; //'01u90000001Hfh1AAC';
        li2.Classification__c='Growth';        
        li2.Contract_Start_Date__c=date.parse('07/07/2013');        
        li2.Contract_End_Date__c=date.parse('07/07/2014');        
        li2.Quantity=1;
        li2.UnitPrice=100;
        opLIList.add(li2);
        
        OpportunityLineItem li3 = new OpportunityLineItem();
        li3.OpportunityId=op1.Id;
        li3.OPCValidated__c=false;
        li3.PricebookEntryId= priceBookEntry.Id; //'01u90000001HfgpAAC';
        li3.Classification__c='Cross Sell';        
        li3.Contract_Start_Date__c=date.parse('04/04/2013');        
        li3.Contract_End_Date__c=date.parse('04/04/2014');        
        li3.Quantity=1;
        li3.UnitPrice=100;
        opLIList.add(li3);
               
        OpportunityLineItem li4 = new OpportunityLineItem();
        li4.OpportunityId=op1.Id;
        li4.OPCValidated__c=false;
        li4.PricebookEntryId= priceBookEntry.Id; //'01u90000001Hfh1AAC';
        li4.Classification__c='Renewal';        
        li4.Contract_Start_Date__c=date.parse('08/04/2013');        
        li4.Contract_End_Date__c=date.parse('08/04/2014');        
        li4.Quantity=1;
        li4.UnitPrice=100;
        opLIList.add(li4);

        // Opp2 OPL
        OpportunityLineItem li5 = new OpportunityLineItem();
        li5.OpportunityId=op2.Id;
        li5.OPCValidated__c=false;
        li5.PricebookEntryId= priceBookEntry.Id; //'01u90000001Hfh1AAC';
        li5.Classification__c='New Business';        
        li5.Contract_Start_Date__c=date.parse('09/03/2013');        
        li5.Contract_End_Date__c=date.parse('09/03/2014');        
        li5.Quantity=1;
        li5.UnitPrice=100;
        opLIList.add(li5);
        
        
        insert opLIList;
      
        OpportunityLineItem createVal = [Select Id,OPCValidated__c,PricebookEntryId,Classification__c,
                                                Contract_Start_Date__c, Contract_End_Date__c, Opportunity.AccountId,
                                                Opportunity.StageName, Opportunity.CloseDate
                                         from OpportunityLineItem where Id = :li1.Id];
        system.debug('OPCValidated__c:' + createVal.OPCValidated__c);
        system.debug('PricebookEntryId:' + createVal.PricebookEntryId);
        system.debug('Classification__c:' + createVal.Classification__c);
        system.debug('Contract_Start_Date__c:' + createVal.Contract_Start_Date__c);
        system.debug('Contract_End_Date__c:' + createVal.Contract_End_Date__c);
        system.debug('Opportunity.AccountId:' + createVal.Opportunity.AccountId);
        system.debug('Opportunity.StageName:' + createVal.Opportunity.StageName);
        system.debug('Opportunity.CloseDate:' + createVal.Opportunity.CloseDate);
        
        test.startTest();
        
            // Force a test of the error handling
            op2.Type='Existing Customer';
            update op2;
    
            BatchJobSettings__c b = new BatchJobSettings__c();
            b.OPC_Validation_Error_Email__c = 'test@test.com';
            insert b;
            OPCValidationService_Batchable batch2 = new OPCValidationService_Batchable (true);
            ID batchprocessid2 = Database.executeBatch(batch2, 200);
            
            //Test scheduler
            //Abort jobs to allow for test class to set the schedule
            
            try{
                list<CronTrigger> cron = new list<CronTrigger>([SELECT Id, State FROM CronTrigger where CronJobDetail.Name = 'OPCValidationService']);
                for(CronTrigger CT : cron){
                    system.abortjob(CT.Id);
                }
        
                OPCValidationService_Schedule.scheduleOPCValidation();
            }catch(exception e){
                system.debug('sched error:' + e);
            }
 
        test.stopTest();    
    }    
}