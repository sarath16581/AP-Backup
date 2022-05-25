/****************************************
 * Description: Test Class for the OpportunityLineItemService class
 * Author: JPalmero
 * History
 *     09/03/2019                               Created
 *     09/13/2019                               Added test methods for populateClassification()
 *     05/03/2020   seth.p.heang@accenture.com  Updated Test methods with dynamic dateTime test data to fix test failure due to static dateTime
 *     01/06/2020   shashwat.a.nath@accenture.com Updated Methods to assign PS to running user to bypass Opportunity Creation Restriction in Classic
 ***************************************/
@isTest
public class OpportunityLineItemServiceTest {
    
    @testSetup
    static void setup() {
        Id pricebookId = Test.getStandardPricebookId();
        Set<Id> accIdSet = new Set<Id>();
        List<Account> accVarList = new List<Account>();
        List<Opportunity> optyList = new List<Opportunity>();
        List<Product2> productList = new List<Product2>();
        List<PricebookEntry> pbEntryList = new List<PricebookEntry>();
        List<Budget_and_Revenue__c> barList = new List<Budget_and_Revenue__c>();
        List<Organisation_Role__c> orgRoleList = new List<Organisation_Role__c>();
        List<Organisation_Role__c> newOrgRoleList = new List<Organisation_Role__c>();
        Integer currentYear = Date.today().year();
        // Create a Sales Administrator Profile for running tests
        Profile covSales = [SELECT Id FROM Profile WHERE Name = 'Coverage Sales'];

        User user1 = new User(
                Alias = 'CovSal', Email = 'test@auspost.com.au',
                EmailEncodingKey = 'UTF-8', LastName = 'xTesting', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = covSales.Id, isActive = true,
                TimeZoneSidKey = 'America/Los_Angeles', UserName = 'auTestX@auspost.com.au.def',
                EmployeeNumber = '10000'
        );
        
        INSERT user1;
        
        // Set the nominal trade amount to be used in classification
        NominalTradeAmount__c ntAmount = NominalTradeAmount__c.getInstance();
        ntAmount.Amount__c = 100;
        upsert ntAmount;
        
        // Trigger Isolation Setttings
        SystemSettings__c sysCS = SystemSettings__c.getInstance();
        sysCS.Disable_Triggers__c = FALSE;
        upsert sysCS;
        
        // Create test Accounts
        Account accountWithRevenue1 = APT_TestUtil2.createOrganisation();
        accountWithRevenue1.Name = 'WithRevenue';
        accIdSet.add(accountWithRevenue1.Id);
        accVarList.add(accountWithRevenue1);
        
        Account accountWithRevenue2 = APT_TestUtil2.createOrganisation();
        accountWithRevenue2.Name = 'AnotherWithRevenue';
        accIdSet.add(accountWithRevenue2.Id);
        accVarList.add(accountWithRevenue2);
        
        Account accountWithoutRevenue = APT_TestUtil2.createOrganisation();
        accountWithoutRevenue.Name = 'WithoutRevenue';
        accIdSet.add(accountWithoutRevenue.Id);
        accVarList.add(accountWithoutRevenue);
        

        
        Account refactoredAccount = APT_TestUtil2.createOrganisation();
        refactoredAccount.Name = 'RefactoredAcct';
        accIdSet.add(refactoredAccount.Id);
        accVarList.add(refactoredAccount);
        
        insert accVarList;
        
        //Create Roles
        orgRoleList = [SELECT Id, Role_Type__c FROM Organisation_Role__c WHERE Organisation__c IN : accIdSet OR Role_Type__c =: 'Prospect'];
        for(Organisation_Role__c orgRole : orgRoleList){
            orgRole.Role_Type__c = 'Customer';
            newOrgRoleList.add(orgRole);
        }
        
        UPDATE newOrgRoleList;
        
        // Create an open test Opportunity for the first account with revenue 
        Opportunity oppVar1 = APT_TestUtil2.createOpportunity(accountWithRevenue1);
        oppVar1.Pre_Entry__c = TRUE;
        oppVar1.StageName = 'Identify';
        optyList.add(oppVar1);
        
        // Create two test opportunities, one open and one with a close reason for the second account with revenue
        Opportunity oppVar2a = APT_TestUtil2.createOpportunity(accountWithRevenue2);
        oppVar2a.Pre_Entry__c = TRUE;
        oppVar2a.StageName = 'Identify';
        optyList.add(oppVar2a);
        
        Opportunity oppVar2b = APT_TestUtil2.createOpportunity(accountWithRevenue2);
        oppVar2b.Pre_Entry__c = TRUE;
        oppVar2b.Closed_Reason__c = 'Functionality';
        oppVar2b.StageName = 'Identify';
        optyList.add(oppVar2b);
        
        // Create a test opportunity for the refactored account with a closed reason
        Opportunity oppVar3 = APT_TestUtil2.createOpportunity(refactoredAccount);
        oppVar3.Pre_Entry__c = TRUE;
        oppVar3.Closed_Reason__c = 'Functionality';
        oppVar3.StageName = 'Identify';
        optyList.add(oppVar3);
        
        insert optyList;
        
        //create product bundles
        Product2 bundle1 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('International Bundle', TRUE);
        productList.add(bundle1);
        
        Product2 bundle2 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('Road Express - STE', TRUE);
        productList.add(bundle2);
        
        Product2 bundle3 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('eParcel Express', TRUE);
        productList.add(bundle3);
        
        Product2 bundle4 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('Boxes and Bags Others', TRUE);
        productList.add(bundle4);
        
        insert productList;
        
        //Create pricebook entries for teh product bundles
        PricebookEntry pbEntry = new PricebookEntry();
        
        for(Product2 testProd : productList){
            pbEntry = new PricebookEntry();
            pbEntry.Pricebook2Id = pricebookId;
            pbEntry.Product2Id = testProd.Id;
            pbEntry.UnitPrice = 100.00;
            pbEntry.IsActive = true;
            pbEntryList.add(pbEntry);
        }
        
        insert pbEntryList;
        
        //Create Budget_and_Revenue__c for the first account with revenue
        Budget_and_Revenue__c barObj = new Budget_and_Revenue__c();
        barObj.Name = 'Revenue 1a Current Year'; // test name
        barObj.Organisation__c = accountWithRevenue1.Id;
        barObj.Product__c = bundle3.Id;
        barObj.Jan_Revenue_Amount__c = 50;
        barObj.Feb_Revenue_Amount__c = 50;
        barObj.Mar_Revenue_Amount__c = 50;
        barObj.Apr_Revenue_Amount__c = 50;
        barObj.May_Revenue_Amount__c = 50;
        barObj.Jun_Revenue_Amount__c = 50;
        barObj.Jul_Revenue_Amount__c = 50;
        barObj.Aug_Revenue_Amount__c = 5;
        barObj.Sep_Revenue_Amount__c = 5;
        barObj.Oct_Revenue_Amount__c = 5;
        barObj.Nov_Revenue_Amount__c = 5;
        barObj.Dec_Revenue_Amount__c = 5;
        barObj.Total_Revenue_Amount__c = 600;
        barObj.Financial_Year__c = String.valueOf(currentYear);
        
        barList.add(barObj);
        
        
        Budget_and_Revenue__c barObjPFY = new Budget_and_Revenue__c();
        barObjPFY.Name = 'Revenue 1a Last Year';
        barObjPFY.Organisation__c = accountWithRevenue1.Id;
        barObjPFY.Product__c = bundle3.Id;
        barObjPFY.Total_Revenue_Amount__c = 0;
        barObjPFY.Financial_Year__c = String.valueOf(currentYear-1);
        
        barList.add(barObjPFY);
        
                
        Budget_and_Revenue__c barObj6 = new Budget_and_Revenue__c();
        barObj6.Name = 'Revenue 1b Current Year';
        barObj6.Organisation__c = accountWithRevenue1.Id;
        barObj6.Product__c = bundle4.Id;
        barObj6.Jan_Revenue_Amount__c = 0;
        barObj6.Feb_Revenue_Amount__c = 0;
        barObj6.Mar_Revenue_Amount__c = 0;
        barObj6.Apr_Revenue_Amount__c = 0;
        barObj6.May_Revenue_Amount__c = 0;
        barObj6.Jun_Revenue_Amount__c = 0;
        barObj6.Jul_Revenue_Amount__c = 0;
        barObj6.Aug_Revenue_Amount__c = 0;
        barObj6.Sep_Revenue_Amount__c = 0;
        barObj6.Oct_Revenue_Amount__c = 0;
        barObj6.Nov_Revenue_Amount__c = 0;
        barObj6.Dec_Revenue_Amount__c = 0;
        barObj6.Total_Revenue_Amount__c = 0;
        barObj6.Financial_Year__c = String.valueOf(2020);
        
        barList.add(barObj6);
        
        Budget_and_Revenue__c barObj7 = new Budget_and_Revenue__c();
        barObj7.Name = 'Revenue 1b Last Year';
        barObj7.Organisation__c = accountWithRevenue1.Id;
        barObj7.Product__c = bundle4.Id;
        barObj7.Jan_Revenue_Amount__c = 0;
        barObj7.Feb_Revenue_Amount__c = 0;
        barObj7.Mar_Revenue_Amount__c = 0;
        barObj7.Apr_Revenue_Amount__c = 0;
        barObj7.May_Revenue_Amount__c = 0;
        barObj7.Jun_Revenue_Amount__c = 0;
        barObj7.Jul_Revenue_Amount__c = 0;
        barObj7.Aug_Revenue_Amount__c = 0;
        barObj7.Sep_Revenue_Amount__c = 0;
        barObj7.Oct_Revenue_Amount__c = 150;
        barObj7.Nov_Revenue_Amount__c = 0;
        barObj7.Dec_Revenue_Amount__c = 0;
        barObj7.Total_Revenue_Amount__c = 150;
        barObj7.Financial_Year__c = String.valueOf(2018);
        
        barList.add(barObj7);
        
         //Create Budget_and_Revenue__c for the second account with revenue
        Budget_and_Revenue__c barObj2 = new Budget_and_Revenue__c();
        barObj2.Name = 'Revenue 2a Currrent Year';
        barObj2.Organisation__c = accountWithRevenue2.Id;
        barObj2.Product__c = bundle3.Id;
        barObj2.Jan_Revenue_Amount__c = 100;
        barObj2.Feb_Revenue_Amount__c = 100;
        barObj2.Mar_Revenue_Amount__c = 100;
        barObj2.Apr_Revenue_Amount__c = 100;
        barObj2.May_Revenue_Amount__c = 100;
        barObj2.Jun_Revenue_Amount__c = 100;
        barObj2.Jul_Revenue_Amount__c = 100;
        barObj2.Aug_Revenue_Amount__c = 100;
        barObj2.Sep_Revenue_Amount__c = 100;
        barObj2.Oct_Revenue_Amount__c = 100;
        barObj2.Nov_Revenue_Amount__c = 100;
        barObj2.Dec_Revenue_Amount__c = 100;
        barObj2.Total_Revenue_Amount__c = 1200;
        barObj2.Financial_Year__c = String.valueOf(currentYear-1);
        
        barList.add(barObj2);
        
        Budget_and_Revenue__c barObj3 = new Budget_and_Revenue__c();
        barObj3.Name = 'Revenue 2a Last year';
        barObj3.Organisation__c = accountWithRevenue2.Id;
        barObj3.Product__c = bundle3.Id;
        barObj3.Jan_Revenue_Amount__c = 100;
        barObj3.Feb_Revenue_Amount__c = 100;
        barObj3.Mar_Revenue_Amount__c = 100;
        barObj3.Apr_Revenue_Amount__c = 100;
        barObj3.May_Revenue_Amount__c = 100;
        barObj3.Jun_Revenue_Amount__c = 100;
        barObj3.Jul_Revenue_Amount__c = 100;
        barObj3.Aug_Revenue_Amount__c = 100;
        barObj3.Sep_Revenue_Amount__c = 100;
        barObj3.Oct_Revenue_Amount__c = 100;
        barObj3.Nov_Revenue_Amount__c = 100;
        barObj3.Dec_Revenue_Amount__c = 100;
        barObj3.Total_Revenue_Amount__c = 1200;
        barObj3.Financial_Year__c = String.valueOf(currentYear-2);
        
        barList.add(barObj3);
        
        
        Budget_and_Revenue__c barObj4 = new Budget_and_Revenue__c();
        barObj4.Name = 'Revenue 2b First Year';
        barObj4.Organisation__c = accountWithRevenue2.Id;
        barObj4.Product__c = bundle3.Id;
        barObj4.Jan_Revenue_Amount__c = 0;
        barObj4.Feb_Revenue_Amount__c = 0;
        barObj4.Mar_Revenue_Amount__c = 0;
        barObj4.Apr_Revenue_Amount__c = 0;
        barObj4.May_Revenue_Amount__c = 0;
        barObj4.Jun_Revenue_Amount__c = 0;
        barObj4.Jul_Revenue_Amount__c = 0;
        barObj4.Aug_Revenue_Amount__c = 0;
        barObj4.Sep_Revenue_Amount__c = 0;
        barObj4.Oct_Revenue_Amount__c = 0;
        barObj4.Nov_Revenue_Amount__c = 0;
        barObj4.Dec_Revenue_Amount__c = 0;
        barObj4.Total_Revenue_Amount__c = 1200;
        barObj4.Financial_Year__c = String.valueOf(currentYear+1);
        
        barList.add(barObj4);
        
        Budget_and_Revenue__c barObj5 = new Budget_and_Revenue__c();
        barObj5.Name = 'Revenue 2b Last Year';
        barObj5.Organisation__c = accountWithRevenue2.Id;
        barObj5.Product__c = bundle4.Id;
        barObj5.Jan_Revenue_Amount__c = 0;
        barObj5.Feb_Revenue_Amount__c = 0;
        barObj5.Mar_Revenue_Amount__c = 0;
        barObj5.Apr_Revenue_Amount__c = 0;
        barObj5.May_Revenue_Amount__c = 0;
        barObj5.Jun_Revenue_Amount__c = 0;
        barObj5.Jul_Revenue_Amount__c = 0;
        barObj5.Aug_Revenue_Amount__c = 0;
        barObj5.Sep_Revenue_Amount__c = 0;
        barObj5.Oct_Revenue_Amount__c = 0;
        barObj5.Nov_Revenue_Amount__c = 0;
        barObj5.Dec_Revenue_Amount__c = 0;
        barObj5.Total_Revenue_Amount__c = 50;
        barObj5.Financial_Year__c = String.valueOf(2020);
        
        barList.add(barObj5);

        
        insert barList;
        
    }
    /*********************************
     * Description: Tests the populateClassification() method for Cross Sell
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationCS() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'International Bundle' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();

        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.today();
        oliVar.Contract_End_Date__c = Date.today()+10;
        optyLIList.add(oliVar);
        
        test.startTest();
        OpportunityLineItemService.populateClassification(optyLIList);
        test.stopTest();
        
        System.assertEquals('Cross Sell', oliVar.Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Win Back
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationWB() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Boxes and Bags Others' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();

        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.today();
        oliVar.Contract_End_Date__c = Date.today()+10;
        optyLIList.add(oliVar);
        
        test.startTest();
        OpportunityLineItemService.populateClassification(optyLIList);
        test.stopTest();
        
        System.assertEquals('Win Back', oliVar.Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Win Back
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationWB2() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Boxes and Bags Others' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();

        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(2019, 03, 01);
        oliVar.Contract_End_Date__c = Date.today()+10;
        optyLIList.add(oliVar);
        
        test.startTest();
        OpportunityLineItemService.populateClassification(optyLIList);
        test.stopTest();
        
        System.assertEquals('Win Back', oliVar.Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for New Business
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationNB() {
        Account testOrg = [SELECT Id, Name FROM Account WHERE Name = 'WithoutRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Road Express - STE' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.today();
        oliVar.Contract_End_Date__c = Date.today()+10;
        optyLIList.add(oliVar);
        
        test.startTest();
        OpportunityLineItemService.populateClassification(optyLIList);
        test.stopTest();
        
        System.assertEquals('New Business', oliVar.Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationRR() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4);
        oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 8, 8);
        oliVar.Change_Classification__c = 'No';
        optyLIList.add(oliVar);
        
        test.startTest();
        OpportunityLineItemService.populateClassification(optyLIList);
        test.stopTest();
        
        System.assertEquals('Renewal', oliVar.Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Growth
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationRG() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Cross Sell';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4);
        oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 8, 8);
        oliVar.Change_Classification__c = 'Yes';
        optyLIList.add(oliVar);
        
        test.startTest();
        OpportunityLineItemService.populateClassification(optyLIList);
        test.stopTest();
        
        System.assertEquals('Growth', oliVar.Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Growth
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationR7G() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Cross Sell';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 7, 7);
        oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year()+1, 8, 8);
        oliVar.Change_Classification__c = 'Yes';
        optyLIList.add(oliVar);
        
        test.startTest();
        OpportunityLineItemService.populateClassification(optyLIList);
        test.stopTest();
        
        System.assertEquals('Growth', oliVar.Classification__c);
    }
    
     /*********************************
     * Description: Tests the populateClassification() method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationR7R() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Cross Sell';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 7, 7);
        oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 8, 8);
        oliVar.Change_Classification__c = 'No';
        optyLIList.add(oliVar);
        
        test.startTest();
        OpportunityLineItemService.populateClassification(optyLIList);
        test.stopTest();
        
        System.assertEquals('Renewal', oliVar.Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for New Business
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationNB2() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'RefactoredAcct' LIMIT 1];
        Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Boxes and Bags Others' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(2019, 7, 7);
        oliVar.Contract_End_Date__c = Date.newInstance(2019, 8, 8);
        oliVar.Change_Classification__c = 'No';
        optyLIList.add(oliVar);
        
        test.startTest();
        OpportunityLineItemService.populateClassification(optyLIList);
        test.stopTest();
        
        System.assertEquals('New Business', oliVar.Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void updateClassificationR() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();
        
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.today();
        oliVar.Contract_End_Date__c = Date.today()+10;
        oldRecMap.put(oliVar.Id, oliVar);
        INSERT oliVar;
        
        OpportunityLineItem newOpty = [SELECT Id, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id
                                       FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];
        newOpty.Contract_Start_Date__c = Date.today()+8;
        newOpty.Contract_End_Date__c = Date.today()+15;
        UPDATE newOpty;
        
        optyLIList.add(newOpty);
        
        test.startTest();
        OpportunityLineItemService.updateClassification(optyLIList, oldRecMap);
        test.stopTest();
        
        System.assertEquals('Renewal', newOpty.Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Growth
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void updateClassificationRG() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();
        
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 93.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.today();
        oliVar.Contract_End_Date__c = Date.today()+10;
        oliVar.Change_Classification__c = 'YES';
        oldRecMap.put(oliVar.Id, oliVar);
        
        INSERT oliVar;
        
        OpportunityLineItem newOpty = [SELECT Id, TotalPrice, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id
                                       FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id AND TotalPrice =: 93.00 LIMIT 1];
        newOpty.Contract_End_Date__c = Date.today()+15;
        UPDATE newOpty;

        optyLIList.add(newOpty);
        
        test.startTest();
        OpportunityLineItemService.updateClassification(optyLIList, oldRecMap);
        test.stopTest();
        
        System.assertEquals('Growth', newOpty.Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void updateClassificationR7() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();
        
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 7, 7);
        oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 8, 8);
        oldRecMap.put(oliVar.Id, oliVar);
        INSERT oliVar;
        
        OpportunityLineItem newOpty = [SELECT Id, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id
                                       FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];
        newOpty.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4);
        newOpty.Contract_End_Date__c = Date.newInstance(System.Today().year(), 8, 16);
        UPDATE newOpty;
        
        optyLIList.add(newOpty);
        
        test.startTest();
        OpportunityLineItemService.updateClassification(optyLIList, oldRecMap);
        test.stopTest();
        
        System.assertEquals('Renewal', newOpty.Classification__c);
    }
    
     /*********************************
     * Description: Tests the populateClassification() method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void updateClassificationR9() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();
        
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4);
        oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 10, 16);
        oldRecMap.put(oliVar.Id, oliVar);
        INSERT oliVar;
        
        OpportunityLineItem newOpty = [SELECT Id, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id
                                       FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];
        newOpty.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 9, 9);
        newOpty.Contract_End_Date__c = Date.newInstance(System.Today().year(), 10, 16);
        newOpty.Change_Classification__c = 'No';
        UPDATE newOpty;
        
        optyLIList.add(newOpty);
        
        test.startTest();
        OpportunityLineItemService.updateClassification(optyLIList, oldRecMap);
        test.stopTest();
        
        System.assertEquals('Renewal', newOpty.Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Growth
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void updateClassificationR9G() { 
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();
        
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Cross Sell';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4);
        oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 10, 16);
        oliVar.Change_Classification__c = 'YES';
        oldRecMap.put(oliVar.Id, oliVar);
        INSERT oliVar;
        
        OpportunityLineItem newOpty = [SELECT Id, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id, Change_Classification__c
                                       FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];
        newOpty.Contract_End_Date__c = Date.newInstance(System.Today().year(), 10, 16);
        UPDATE newOpty;
        
        optyLIList.add(newOpty);
        
        test.startTest();
        OpportunityLineItemService.updateClassification(optyLIList, oldRecMap);
        test.stopTest();
        
        System.assertEquals('Growth', newOpty.Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for New Business
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void updateClassificationNB() {
        Account testOrg = [SELECT Id, Name FROM Account WHERE Name = 'WithoutRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Road Express - STE' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();
        
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.today();
        oliVar.Contract_End_Date__c = Date.today()+10;
        oldRecMap.put(oliVar.Id, oliVar);
        INSERT oliVar;
        
        OpportunityLineItem newOpty = [SELECT Id, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id
                                       FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];
        newOpty.Contract_Start_Date__c = Date.today()+8;
        newOpty.Contract_End_Date__c = Date.today()+15;
        UPDATE newOpty;
        
        optyLIList.add(newOpty);
        
        test.startTest();
        OpportunityLineItemService.updateClassification(optyLIList, oldRecMap);
        test.stopTest();
        
        System.assertEquals('New Business', newOpty.Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Cross Sell
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void updateClassificationCS() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'International Bundle' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();
        
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.today();
        oliVar.Contract_End_Date__c = Date.today()+10;
        INSERT oliVar;
        
        OpportunityLineItem newOpty = [SELECT Id, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id
                                       FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];
        newOpty.Contract_Start_Date__c = Date.today()+8;
        newOpty.Contract_End_Date__c = Date.today()+15;
        UPDATE newOpty;
        
        optyLIList.add(newOpty);
        
        test.startTest();
        OpportunityLineItemService.updateClassification(optyLIList, oldRecMap);
        test.stopTest();
        
        System.assertEquals('Cross Sell', newOpty.Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Win Back
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void updateClassificationWB() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Boxes and Bags Others' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();
        
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty.Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.today();
        oliVar.Contract_End_Date__c = Date.today()+10;
        INSERT oliVar;
        
        OpportunityLineItem newOpty = [SELECT Id, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id
                                       FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];
        newOpty.Contract_End_Date__c = Date.today()+15;
        UPDATE newOpty;
        
        optyLIList.add(newOpty);
        
        test.startTest();
        OpportunityLineItemService.updateClassification(optyLIList, oldRecMap);
        test.stopTest();
        
        System.assertEquals('Win Back', newOpty.Classification__c);
    }
    
    /*********************************
     * Description: Tests the beforeDelete method
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void deleteProduct() {
        User testRunAs = [SELECT Id from User WHERE Alias = 'CovSal' LIMIT 1];
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'International Bundle' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();
        // Query your permission set name from Organization to bypass the validation
        List<PermissionSet>  psList = new List<PermissionSet>();
        psList = [SELECT Id FROM PermissionSet WHERE Name = 'ValidationRuleBypassClassicRestrictions' LIMIT 1];
       
        // Assign the above inserted user for the above Permission Set.
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = testRunAs.Id;
        psa.PermissionSetId = psList[0].id;
        insert psa;
        
        test.startTest();
        System.runAs(testRunAs){
            Opportunity oppVar = APT_TestUtil2.createOpportunity(testOrg);
            oppVar.Pre_Entry__c = TRUE;
            oppVar.Closed_Reason__c = 'Functionality';
            oppVar.Data_Integrity_Compliance__c = TRUE;
            oppVar.CloseDate = Date.today();
            oppVar.Offline_Contract_Received__c = TRUE;
            oppVar.StageName = 'Identify';
            INSERT oppVar;
            
            OpportunityLineItem oliVar = new OpportunityLineItem();
            oliVar.OpportunityId = oppVar.Id;
            oliVar.Product2Id = testProd.Id;
            oliVar.Classification__c = 'Growth';
            oliVar.Quantity = 12;
            oliVar.TotalPrice = 24.00;
            oliVar.PricebookEntryId = pbEntry.Id;
            oliVar.Contract_Start_Date__c = Date.today();
            oliVar.Contract_End_Date__c = Date.today()+10;
            oliVar.Contract_Product__c = 'No';
            INSERT oliVar;
            
            Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE Closed_Reason__c = 'Functionality' AND Offline_Contract_Received__c = TRUE LIMIT 1];
            testOpty.Hidden_Restrict_Path_Closure__c =true;
            testOpty.StageName = 'Closed Won';
            UPDATE testOpty;
            
            try{
                OpportunityLineItem newOpty = [SELECT Id, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id
                                               FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];
                DELETE newOpty;
            }catch(DMLException de){
                System.assertEquals(Label.Delete_Opty_Line, de.getDmlMessage(0));
            }
        }
        test.stopTest();
    }
    
    /*********************************
     * Description: Tests the changeClassification() method
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void changeClassTestR() {
        User testRunAs = [SELECT Id, Profile.Name from User WHERE Alias = 'CovSal' LIMIT 1];
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();
        
        // Query your permission set name from Organization to bypass the validation
        List<PermissionSet>  psList = new List<PermissionSet>();
        psList = [SELECT Id FROM PermissionSet WHERE Name = 'ValidationRuleBypassClassicRestrictions' LIMIT 1];
       
        // Assign the above inserted user for the above Permission Set.
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = testRunAs.Id;
        psa.PermissionSetId = psList[0].id;
        insert psa;
        
        test.startTest();
        System.runAs(testRunAs){
            NominalTradeAmount__c ntAmount = NominalTradeAmount__c.getInstance();
            ntAmount.Amount__c = 50;
            UPSERT ntAmount;
            Opportunity oppVar = APT_TestUtil2.createOpportunity(testOrg);
            oppVar.Pre_Entry__c = TRUE;
            oppVar.Closed_Reason__c = 'Functionality';
            oppVar.Data_Integrity_Compliance__c = TRUE;
            oppVar.CloseDate = Date.today();
            oppVar.Offline_Contract_Received__c = TRUE;
            oppVar.StageName = 'Identify';
            INSERT oppVar;
            
            OpportunityLineItem oliVar = new OpportunityLineItem();
            oliVar.OpportunityId = oppVar.Id;
            oliVar.Product2Id = testProd.Id;
            oliVar.Classification__c = 'Renewal';
            oliVar.Quantity = 12;
            oliVar.TotalPrice = 93.00;
            oliVar.PricebookEntryId = pbEntry.Id;
            oliVar.Contract_Start_Date__c = Date.newInstance(2019, 7, 7);
            oliVar.Contract_End_Date__c = Date.newInstance(2019, 8, 8);
            oliVar.Contract_Product__c = 'No';
            oliVar.Change_Classification__c = 'No';
            INSERT oliVar;
            System.assertEquals('Renewal', oliVar.Classification__c);
            oldRecMap.put(oliVar.Id, oliVar);
            
            OpportunityLineItem newOpty = [SELECT Id, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id, TotalPrice
                                           FROM OpportunityLineItem WHERE OpportunityId =: oppVar.Id AND Product2Id =: testProd.Id AND TotalPrice =: 93.00 LIMIT 1];
            System.assertEquals(oliVar.Classification__c, newOpty.Classification__c);
            newOpty.Change_Classification__c = 'Yes';
            UPDATE newOpty;
            
            optyLIList.add(newOpty);
            OpportunityLineItemService.changeClassification(optyLIList,oldRecMap);
            
            System.assertEquals('Growth', newOpty.Classification__c);
            
        }
        test.stopTest();
    }    
    /*********************************
     * Description: Tests the changeClassification() for Growth scenario
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void changeClassTestG() {
        User testRunAs = [SELECT Id, Profile.Name from User WHERE Alias = 'CovSal' LIMIT 1];
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
        Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();
           // Query your permission set name from Organization to bypass the validation.
        List<PermissionSet>  psList = new List<PermissionSet>();
        psList = [SELECT Id FROM PermissionSet WHERE Name = 'ValidationRuleBypassClassicRestrictions' LIMIT 1];
       
        // Assign the above inserted user for the above Permission Set.
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = testRunAs.Id;
        psa.PermissionSetId = psList[0].id;
        insert psa;
        
        
        test.startTest();
        System.runAs(testRunAs){
            NominalTradeAmount__c ntAmount = NominalTradeAmount__c.getInstance();
            ntAmount.Amount__c = 50;
            UPSERT ntAmount;
            Opportunity oppVar = APT_TestUtil2.createOpportunity(testOrg);
            oppVar.Pre_Entry__c = TRUE;
            oppVar.Closed_Reason__c = 'Functionality';
            oppVar.Data_Integrity_Compliance__c = TRUE;
            oppVar.CloseDate = Date.today();
            oppVar.Offline_Contract_Received__c = TRUE;
            oppVar.StageName = 'Identify';
            INSERT oppVar;
            
            OpportunityLineItem oliVar = new OpportunityLineItem();
            oliVar.OpportunityId = oppVar.Id;
            oliVar.Product2Id = testProd.Id;
            oliVar.Classification__c = 'Growth';
            oliVar.Quantity = 12;
            oliVar.TotalPrice = 93.00;
            oliVar.PricebookEntryId = pbEntry.Id;
            oliVar.Contract_Start_Date__c = Date.newInstance(2019, 7, 7);
            oliVar.Contract_End_Date__c = Date.newInstance(2019, 8, 8);
            oliVar.Contract_Product__c = 'No';
            oliVar.Change_Classification__c = 'Yes';
            INSERT oliVar;
            oldRecMap.put(oliVar.Id, oliVar);
            
            OpportunityLineItem newOpty = [SELECT Id, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id, TotalPrice
                                           FROM OpportunityLineItem WHERE OpportunityId =: oppVar.Id AND Product2Id =: testProd.Id AND TotalPrice =: 93.00 LIMIT 1];
            newOpty.Change_Classification__c = 'No';
            UPDATE newOpty;
            
            optyLIList.add(newOpty);
            OpportunityLineItemService.changeClassification(optyLIList,oldRecMap);
            
            System.assertEquals('Renewal', newOpty.Classification__c);
            
        }
        test.stopTest();
    }
}