/**************************************************
Provides test coverage to OPCBatchableSchedulable class
History:
--------------------------------------------------

31/08/2023 KMcGuire created
**************************************************/
@isTest
private class GenerateOPCBatchable_Test {

     @testSetup
    static void setup() {
     Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
        
     Account acc = new Account(Name = 'Test Account',ShippingCity='city', ShippingState = 'State', ShippingPostalCode='PostCode');
        insert acc;
        
        Contact keyCon =new Contact(FirstName = 'First Name',
                LastName = 'Last Name',
                Email = 'ZZtest@test.com',
                DoNotCall = true,
                AccountId = acc.id);
        insert keyCon;
        
        Organisation_Role__c orgRole = [SELECT Id, Role_Type__c FROM Organisation_Role__c WHERE Organisation__c = :acc.Id limit 1];
        orgRole.Role_Type__c = 'Customer';
        update orgRole;

        Opportunity opp = new Opportunity(Name='TestOpportunity', AccountId=acc.Id, CloseDate=Date.today(), StageName='Propose', Amount = 50000, Description = 'blah blah', KeyContact__c = keyCon.id);
        insert opp;
        
        Competitor__c comp = new Competitor__c(
            Competitor_Type__c = 'Competitor',
            Competitor_Name__c = 'AaE',
            Competitive_Status__c = 'Behind Competition',
            Competitive_Advantage__c = 'Competitive Advantage',
            OpportunityId__c = opp.Id);
        
        insert comp;
        
        Task testTask = new Task(ActivityDate = date.today().addDays(-5), WhatId = opp.Id, WhoId = keyCon.Id, Subject = 'test', Status='Completed');
        insert testTask;
        
        Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
        insert product;
        
        Apttus_Config2__PriceList__c priceList =APT_TestUtils.createPriceList();
        insert priceList;
        
        Id priceBookId=Test.getStandardPricebookId();
        PricebookEntry priceBookEntry = APT_TestUtils.getPricebookEntry(priceBookId,product.Id);
        insert priceBookEntry;
        
        OpportunityLineItem oppLineItem = new OpportunityLineItem(Quantity=2,OpportunityId=opp.Id,TotalPrice =45678,PricebookEntryId=priceBookEntry.Id,Contract_Start_Date__c=System.Today(),Contract_End_Date__c=System.Today()+1 );
        oppLineItem.Classification__c = 'New Business';
        insert oppLineItem;      
        
        opp.Monthly_Executive_Summary__c = 'blah blah';
        opp.StageName = 'Closed Won';
        opp.Type = 'New Customer';
        //opp.Pricebook2Id = pricebookId;
        opp.Offline_Contract_Received__c  = true;
        opp.Pre_Entry__c = true;
        opp.Hidden_Restrict_Path_Closure__c = true;
        update(opp);
        
        Date currentDate = Date.today();
        Integer currentYear = currentDate.year();
        // create OPC
        Opp_Product_Classification__c opc = new Opp_Product_Classification__c(
                Account__c = acc.Id, 
                Product__c = product.Id, 
                Classification__c = 'Growth', 
                Financial_Year__c = String.valueOf(currentYear),
                Jan_Schedule_Amount__c = 1, 
                Feb_Schedule_Amount__c = 2, 
                Mar_Schedule_Amount__c = 3, 
                Apr_Schedule_Amount__c = 4,
                May_Schedule_Amount__c = 5, 
                Jun_Schedule_Amount__c = 6, 
                Jul_Schedule_Amount__c = 7, 
                Aug_Schedule_Amount__c = 8,
                Sep_Schedule_Amount__c = 9, 
                Oct_Schedule_Amount__c = 10, 
                Nov_Schedule_Amount__c = 11, 
                Dec_Schedule_Amount__c = 12,
                Hidden_Under_Review__c = false
            );
            insert opc; 

            Revenue_Schedule__c rs = new Revenue_Schedule__c();
            rs.Opportunity__c = opp.Id;
            rs.Product__c = product.Id;
            rs.Opportunity_Product_Classification__c = opc.id;
            rs.Classification_c__c = 'Growth';
            rs.CalendarYear__c =String.valueOf(currentYear);
            rs.Financial_Year__c =String.valueOf(currentYear);
            rs.Contract_Start_Date__c = currentDate.addDays(-90);
            rs.Contract_End_Date__c = currentDate.addDays(90);
            rs.Jan_Claimed_Revenue__c=5000;
            rs.Feb_Claimed_Revenue__c=5000;
            rs.Mar_Claimed_Revenue__c=5000;
            rs.Apr_Claimed_Revenue__c=5000;
            rs.May_Claimed_Revenue__c=5000;
            rs.Jun_Claimed_Revenue__c=5000;
            rs.Jul_Claimed_Revenue__c=5000;
            rs.Aug_Claimed_Revenue__c=5000;
            rs.Sep_Claimed_Revenue__c=5000;
            rs.Oct_Claimed_Revenue__c=5000;
            rs.Nov_Claimed_Revenue__c=5000;
            rs.Dec_Claimed_Revenue__c= 5000;
            rs.Jan_NRT_Adjustment__c= 2000;
            rs.Feb_NRT_Adjustment__c= 2000;
            rs.Mar_NRT_Adjustment__c= 2000;
            rs.Apr_NRT_Adjustment__c= 2000;
            rs.May_NRT_Adjustment__c= 2000;
            rs.Jun_NRT_Adjustment__c= 2000;
            rs.Jul_NRT_Adjustment__c= 2000;
            rs.Aug_NRT_Adjustment__c= 2000;
            rs.Sep_NRT_Adjustment__c= 2000;
            rs.Oct_NRT_Adjustment__c= 2000;
            rs.Nov_NRT_Adjustment__c= 2000;
            rs.Dec_NRT_Adjustment__c = 2000;
            rs.Exception_Override__c = true;
            insert rs;
    }
    
    @isTest
    static void testExecuteRevenueSchedule() {
        // Setup: Create required test data

       List<Revenue_Schedule__c> revenueSchedules = [Select Id,Opportunity__c,Product__c,Opportunity_Product_Classification__c,Opportunity__r.AccountId,Classification_c__c FROM Revenue_Schedule__c];
        
        
        Test.startTest();
        
        // Instantiate the class containing the executeRevenueSchedule method and then call it.
        GenerateOPCBatchable generateOPC = new GenerateOPCBatchable();
        ID batchProcessId = Database.executeBatch(generateOPC);
        //generateOPC.executeRevenueSchedule(revenueSchedules);
        
        Test.stopTest();
        

        List<Opp_Product_Classification__c> createdOPCs = [SELECT Id FROM Opp_Product_Classification__c];
        System.assert(createdOPCs.size() > 0, 'Opp_Product_Classification__c records should be created.');

    }
}