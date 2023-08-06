/**************************************************
Type:       Test Class - Trigger Handler for OpportunityLineItem Object
Purpose:    Test Class - Handle Triggers for the OpportunityLineItem Object for a cleaner code coverage
--------------------------------------------------
August 2, 2018 - Created by conrad.c.v.borbon (Created logic)
Modified by daric.antoni.a.dava (Integreded test data factory)
18.01.2019      John.Mapanao@auspost.com.au     Added test methods to cover logic for Email links for MW0003089 - Opportunity Complexity rating in Salesforce
11.02.2021      Madhuri.awasthi@auspost.com.au	: REQ2368013 Create Revuenue Schedule test data
02/05/2023 Ken McGuire modified opc recalculation calls to newly refactored methods.
**************************************************/
// Created by conrad.c.v.borbon - August 2, 2018 - START
@IsTest
public class OpportunityLineItemTriggerHandler_Test {
    
    public static final String TEST_PROFILE_NAME = 'System Administrator';
    
    // Test method to create user account
    public static testMethod Account createUserAccount(){
        RecordType orgrectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        
        // Build Test holding user
        User u1 = new User();
        u1 = OpptyLineItemTriggerHandler_TestUtil.getTestUser(OpportunityLineItemTriggerHandler_Test.TEST_PROFILE_NAME);                                       
        insert u1;
        
        // Create Test Account
        Account accVar = new Account();
        accVar = OpptyLineItemTriggerHandler_TestUtil.getTestAccount(u1.Id,orgrectype.Id);
        insert accVar;
        
        return accVar;
    }
    
    //Test method to generate an OpportunityLineItem that has one complex product
    public static testMethod OpportunityLineItem createOliDataOneComplex(){
        Account accVar = createUserAccount();
        
        // Create Product
        Product2 prodVar1 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('Exception Product 1',true);
        insert prodVar1;
        
        // Get Standard PBID
        ID standardPBID = Test.getStandardPricebookId();
        
        // Create Pricebook
        Pricebook2 pbVar1 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebook('Test Pricebook 1',true);
        insert pbVar1;
        
        // Standard PBE
        PricebookEntry standardPrice1 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebookEntry(standardPBID, prodVar1.Id, 10000);
        insert standardPrice1;
        
        // Create PricebookEntry
        PricebookEntry pbeVar1 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebookEntry(pbVar1.ID, prodVar1.ID, 1);
        insert pbeVar1;
        
        //create opportunity
        Opportunity oppVar = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunity(accVar.Id);
        insert oppVar;
        
        // Create Opportunity Line Item
        OpportunityLineItem oliVar1 = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunityLineItem(oppVar.ID,pbeVar1.ID,prodVar1.ID);
        insert oliVar1;
        
        return oliVar1;
    }  
    
    // Test method to generate an OpportunityLineItem that has multiple complex products
    public static testMethod OpportunityLineItem createOliDataMultiComplex(){
        Account accVar = createUserAccount(); 
        
        // Create Product
        Product2 prodVar1 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('Exception Product 1',true);
        Product2 prodVar2 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('Exception Product 2','EP 2',true);
        insert new List<Product2>{prodVar1,prodVar2};
        
        // Get Standard PBID
        ID standardPBID = Test.getStandardPricebookId();
        
        // Create Pricebook
        Pricebook2 pbVar1 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebook('Test Pricebook 1',true);
        Pricebook2 pbVar2 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebook('Test Pricebook 2',true);
        insert new List<Pricebook2>{pbVar1,pbVar2};
        
        // Standard PBE
        PricebookEntry standardPrice1 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebookEntry(standardPBID, prodVar1.Id, 10000);
        PricebookEntry standardPrice2 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebookEntry(standardPBID, prodVar2.Id, 10000);
        insert new List<PricebookEntry>{standardPrice1,standardPrice2};
        
        // Create PricebookEntry
        PricebookEntry pbeVar1 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebookEntry(pbVar1.ID, prodVar1.ID, 1);
        PricebookEntry pbeVar2 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebookEntry(pbVar2.ID, prodVar2.ID, 1);
        insert new List<PricebookEntry>{pbeVar1,pbeVar2};
        
        //create opportunity
        Opportunity oppVar = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunity(accVar.Id);
        insert oppVar;
        
        // Create Opportunity Line Item
        OpportunityLineItem oliVar1 = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunityLineItem(oppVar.ID,pbeVar1.ID,prodVar1.ID);
        oliVar1.Description = 'test oli desc 1';
        
        OpportunityLineItem oliVar2 = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunityLineItem(oppVar.ID,pbeVar1.ID,prodVar2.ID);
        oliVar2.Description = 'test oli desc 2';
        oliVar2.Contract_Start_Date__c = Date.newInstance(2013, 07 ,27);
        oliVar2.Contract_End_Date__c = Date.newInstance(2014, 07 ,27);
        insert new List<OpportunityLineItem>{oliVar1,oliVar2};
            
        //Create Revenue Schedule
        Revenue_Schedule__c rs = new Revenue_Schedule__c();  
        rs.Contract_End_Date__c =Date.today();
        rs.Contract_Start_Date__c =Date.today()+1;
        rs.Opportunity__c = oppVar.ID;
        insert rs;
        
        return oliVar1;
    }  
    
    // Test method to delete an OpportunityLineItem in an Opportunity that has one complex product
    public static testMethod void testDeleteOliDataOneComplex(){
        
        OpportunityLineItem delOli = createOliDataOneComplex();
        // Assert that the expected Complexity rating is 3 since there is an existing complex product
        Opportunity oldOppVarDel = [SELECT Id, Product_Complexity_Rating__C FROM Opportunity where Name = 'test oppty 1' limit 1];
        
        
        
        test.startTest();
        List<OpportunityLineItem> toDel = new List<OpportunityLineItem>();
        toDel = [select id from OpportunityLineItem where Description = 'test oli desc 1'];
        delete toDel;
        test.stopTest();
        
        // Assert that the expected Complexity rating is 0 since there is no longer an existing complex product
        Opportunity updOppVarDel = [SELECT Id, Product_Complexity_Rating__C FROM Opportunity where Name = 'test oppty 1' limit 1];
        
        system.assertEquals(3, oldOppVarDel.Product_Complexity_Rating__C);
        system.assertEquals(0, updOppVarDel.Product_Complexity_Rating__C);
    }  
    
    // Test method to delete an OpportunityLineItem in an Opportunity that has multiple complex products
    public static testMethod void testDeleteOliDataMultiComplex(){
        
        OpportunityLineItem delOli = createOliDataMultiComplex();
        System.debug('OPLI_TEST:Product2: 2, '+[SELECT COUNT() FROM Product2]);
        System.debug('OPLI_TEST:Pricebook2: 2, '+[SELECT COUNT() FROM Pricebook2]);
        System.debug('OPLI_TEST:PricebookEntry: 4, '+[SELECT COUNT() FROM PricebookEntry]);
        System.debug('OPLI_TEST:OpportunityLineItem: 2, '+[SELECT COUNT() FROM OpportunityLineItem]);
        
        // Assert that the expected Complexity rating is 3 since there is an existing complex product
        Opportunity oldOppVarDel = [SELECT Id, Product_Complexity_Rating__C FROM Opportunity where Name = 'test oppty 1' limit 1];
        //Opportunity oldOppVarDel = [SELECT Id, Product_Complexity_Rating__C FROM Opportunity where id = :delOli.OpportunityId limit 1];
        
        test.startTest();
        List<OpportunityLineItem> toDel = new List<OpportunityLineItem>();
        toDel = [select id from OpportunityLineItem where Description = 'test oli desc 1'];
        //toDel = [select id from OpportunityLineItem where Id = :delOli.Id];
        delete toDel;
        test.stopTest();
        
        // Assert that the expected Complexity rating is 3 since there is still an existing complex product
        Opportunity updOppVarDel = [SELECT Id, Product_Complexity_Rating__C FROM Opportunity where Name = 'test oppty 1' limit 1];
        
        
        system.assertEquals(3, oldOppVarDel.Product_Complexity_Rating__C);
        system.assertEquals(3, updOppVarDel.Product_Complexity_Rating__C);
    }
    // Created by conrad.c.v.borbon - August 2, 2018 - END

    /*
     * Test Scenario Opportunity Line Item After Delete Trigger Event
     * Resulting NotRequired
     */
    public static testMethod void test_afterDeleteNoRequired() {
        OpportunityLineItem tempOli = createOliDataOneComplex();

        Product2 tempProduct = [SELECT Id, Product_Level_2__c FROM Product2 WHERE Id =: tempOli.Product2Id];
        tempProduct.Product_Level_2__c = 'Express Post';
        update tempProduct;

        Test.startTest();
            delete tempOli;
        Test.stopTest();

        System.assertEquals('NotRequired', [SELECT Hidden_B_G_Forum_Attendance__c FROM Opportunity].Hidden_B_G_Forum_Attendance__c);
    }

    /*
     * Test Scenario Opportunity Line Item After Delete Trigger Event
     * Resulting DealDesk
     */
    public static testMethod void test_afterDeleteDealDesk() {
        Account accVar = createUserAccount();

        //create opportunity
        Opportunity opp = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunity(accVar.Id);
            opp.Implementation_or_Onboarding_Complexity__c = 'No';
        insert opp;

        Id pricebookId = Test.getStandardPricebookId();

        //OLI 1 START
        //Create your product
        Product2 prod1 = new Product2(Name = 'Product 1',ProductCode = 'Pro-1',isActive = true,Product_Level_2__c = 'Pro Test 1');
        insert prod1;

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod1.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli;
        //OLI 1 END

        //OLI 2 START
        //Create your product
        Product2 prod2 = new Product2(Name = 'Product 2',ProductCode = 'Pro-2',isActive = true,Product_Level_2__c = 'Pro Test 2');
        insert prod2;

        //Create your pricebook entry
        PricebookEntry pbEntry2 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod2.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry2;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry2.Id,
                TotalPrice = 5 * pbEntry2.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli2;
        //OLI 2 END

        //OLI 3 START
        //Create your product
        Product2 prod3 = new Product2(Name = 'Product 3',ProductCode = 'Pro-3',isActive = true,Product_Level_2__c = 'Pro Test 3');
        insert prod3;

        //Create your pricebook entry
        PricebookEntry pbEntry3 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod3.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry3;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry3.Id,
                TotalPrice = 5 * pbEntry3.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli3;
        //OLI 3 END

        Test.startTest();
            delete oli3;
        Test.stopTest();

        System.assertEquals('DealDesk', [SELECT Hidden_B_G_Forum_Attendance__c FROM Opportunity].Hidden_B_G_Forum_Attendance__c);
    }

    /*
     * Test Scenario Opportunity Line Item After Delete Trigger Event
     * Resulting CommitToAction
     */
    public static testMethod void test_afterDeleteCommitToAction() {
        Account accVar = createUserAccount();

        //create opportunity
        Opportunity opp = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunity(accVar.Id);
        opp.Implementation_or_Onboarding_Complexity__c = 'No';
        insert opp;

        Id pricebookId = Test.getStandardPricebookId();

        //OLI 1 START
        //Create your product
        Product2 prod1 = new Product2(Name = 'Product 1',ProductCode = 'Pro-1',isActive = true,Product_Level_2__c = 'Pro Test 1');
        insert prod1;

        //Create your pricebook entry
        PricebookEntry pbEntry1 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod1.Id,UnitPrice = 1000000.00,IsActive = true);
        insert pbEntry1;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry1.Id,
                TotalPrice = 5 * pbEntry1.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli1;
        //OLI 1 END

        //OLI 2 START
        //Create your product
        Product2 prod2 = new Product2(Name = 'Product 2',ProductCode = 'Pro-2',isActive = true,Product_Level_2__c = 'Pro Test 2');
        insert prod2;

        //Create your pricebook entry
        PricebookEntry pbEntry2 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod2.Id,UnitPrice = 1000000.00,IsActive = true);
        insert pbEntry2;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry2.Id,
                TotalPrice = 5 * pbEntry2.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli2;
        //OLI 2 END

        //OLI 3 START
        //Create your product
        Product2 prod3 = new Product2(Name = 'Product 3',ProductCode = 'Pro-3',isActive = true,Product_Level_2__c = 'Pro Test 3');
        insert prod3;

        //Create your pricebook entry
        PricebookEntry pbEntry3 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod3.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry3;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry3.Id,
                TotalPrice = 5 * pbEntry3.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli3;
        //OLI 3 END

        Test.startTest();
        delete oli3;
        Test.stopTest();

        System.assertEquals('CommitToAction', [SELECT Hidden_B_G_Forum_Attendance__c FROM Opportunity].Hidden_B_G_Forum_Attendance__c);
    }

    /*
     * Test Scenario Opportunity Line Item After Insert Trigger Event
     * Where Opportunity has no existing Opportunity Line Items
     * Resulting NotRequired
     */
    public static testMethod void test_afterInsertNoExistingOliNotRequired() {
        Account accVar = createUserAccount();

        //create opportunity
        Opportunity opp = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunity(accVar.Id);
        insert opp;

        Id pricebookId = Test.getStandardPricebookId();

        //OLI 1 START
        //Create your product
        Product2 prod1 = new Product2(Name = 'Product 1',ProductCode = 'Pro-1',isActive = true,Product_Level_2__c = 'Pro Test 1');
        insert prod1;

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod1.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry;

        Test.startTest();
        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli;
        Test.stopTest();

        System.assertEquals('NotRequired', [SELECT Hidden_B_G_Forum_Attendance__c FROM Opportunity].Hidden_B_G_Forum_Attendance__c);
    }

    /*
     * Test Scenario Opportunity Line Item After Insert Trigger Event
     * Where Opportunity has existing Opportunity Line Items
     * Resulting NotRequired
     */
    public static testMethod void test_afterInsertWithExistingOliNotRequired() {
        Account accVar = createUserAccount();

        //create opportunity
        Opportunity opp = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunity(accVar.Id);
        insert opp;

        Id pricebookId = Test.getStandardPricebookId();

        //OLI 1 START
        //Create your product
        Product2 prod1 = new Product2(Name = 'Product 1',ProductCode = 'Pro-1',isActive = true,Product_Level_2__c = 'Pro Test 1');
        insert prod1;

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod1.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli;

        Product2 prod2 = new Product2(Name = 'Product 2',ProductCode = 'Pro-2',isActive = true,Product_Level_2__c = 'Pro Test 2');
        insert prod2;

        //Create your pricebook entry
        PricebookEntry pbEntry2 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod2.Id,UnitPrice = 1000000.00,IsActive = true);
        insert pbEntry2;

        Test.startTest();
        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry2.Id,
                TotalPrice = 5 * pbEntry2.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli2;
        Test.stopTest();

        System.assertEquals('NotRequired', [SELECT Hidden_B_G_Forum_Attendance__c FROM Opportunity].Hidden_B_G_Forum_Attendance__c);
    }

    /*
     * Test Scenario Opportunity Line Item After Insert Trigger Event
     * Resulting DealDesk
     */
    public static testMethod void test_afterInsertDealDesk() {
        Account accVar = createUserAccount();

        //create opportunity
        Opportunity opp = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunity(accVar.Id);
        opp.Implementation_or_Onboarding_Complexity__c = 'No';
        insert opp;

        Id pricebookId = Test.getStandardPricebookId();

        //OLI 1 START
        //Create your product
        Product2 prod1 = new Product2(Name = 'Product 1',ProductCode = 'Pro-1',isActive = true,Product_Level_2__c = 'Pro Test 1');
        insert prod1;

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod1.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli;
        //OLI 1 END

        //OLI 2 START
        //Create your product
        Product2 prod2 = new Product2(Name = 'Product 2',ProductCode = 'Pro-2',isActive = true,Product_Level_2__c = 'Pro Test 2');
        insert prod2;

        //Create your pricebook entry
        PricebookEntry pbEntry2 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod2.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry2;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry2.Id,
                TotalPrice = 5 * pbEntry2.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli2;
        //OLI 2 END

        //Create your product
        Product2 prod3 = new Product2(Name = 'Product 3',ProductCode = 'Pro-3',isActive = true,Product_Level_2__c = 'Pro Test 3');
        insert prod3;

        //Create your pricebook entry
        PricebookEntry pbEntry3 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod3.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry3;

        Test.startTest();
        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry3.Id,
                TotalPrice = 5 * pbEntry3.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli3;
        Test.stopTest();

        System.assertEquals('DealDesk', [SELECT Hidden_B_G_Forum_Attendance__c FROM Opportunity].Hidden_B_G_Forum_Attendance__c);
    }

    /*
     * Test Scenario Opportunity Line Item After Insert Trigger Event
     * Resulting CommitToAction
     */
    public static testMethod void test_afterInsertCommitToAction() {
        Account accVar = createUserAccount();

        //create opportunity
        Opportunity opp = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunity(accVar.Id);
        opp.Implementation_or_Onboarding_Complexity__c = 'No';
        insert opp;

        Id pricebookId = Test.getStandardPricebookId();

        //OLI 1 START
        //Create your product
        Product2 prod1 = new Product2(Name = 'Product 1',ProductCode = 'Pro-1',isActive = true,Product_Level_2__c = 'Pro Test 1');
        insert prod1;

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod1.Id,UnitPrice = 1000000.00,IsActive = true);
        insert pbEntry;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli;
        //OLI 1 END

        //OLI 2 START
        //Create your product
        Product2 prod2 = new Product2(Name = 'Product 2',ProductCode = 'Pro-2',isActive = true,Product_Level_2__c = 'Pro Test 2');
        insert prod2;

        //Create your pricebook entry
        PricebookEntry pbEntry2 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod2.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry2;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry2.Id,
                TotalPrice = 5 * pbEntry2.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli2;
        //OLI 2 END

        //Create your product
        Product2 prod3 = new Product2(Name = 'Product 3',ProductCode = 'Pro-3',isActive = true,Product_Level_2__c = 'Pro Test 3');
        insert prod3;

        //Create your pricebook entry
        PricebookEntry pbEntry3 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod3.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry3;

        Test.startTest();
        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry3.Id,
                TotalPrice = 5 * pbEntry3.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli3;
        Test.stopTest();

        System.assertEquals('CommitToAction', [SELECT Hidden_B_G_Forum_Attendance__c FROM Opportunity].Hidden_B_G_Forum_Attendance__c);
    }

    /*
     * TRIGGER POINT: Opportunity object
     * SCENARIO: Opportunity BEFORE UPDATE Trigger Event
     * RESULT: NotRequired
     */
    public static testMethod void test_beforeUpdateNotRequired() {
        Account accVar = createUserAccount();

        //create opportunity
        Opportunity opp = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunity(accVar.Id);
        opp.Implementation_or_Onboarding_Complexity__c = 'No';
        insert opp;

        Id pricebookId = Test.getStandardPricebookId();

        //OLI 1 START
        //Create your product
        Product2 prod1 = new Product2(Name = 'Product 1',ProductCode = 'Pro-1',isActive = true,Product_Level_2__c = 'Pro Test 1');
        insert prod1;

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod1.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli;

        System.assertEquals('No', [SELECT Implementation_or_Onboarding_Complexity__c FROM Opportunity].Implementation_or_Onboarding_Complexity__c);

        Test.startTest();
        opp.Implementation_or_Onboarding_Complexity__c = 'Yes';
        update opp;
        Test.stopTest();

        System.assertEquals('NotRequired', [SELECT Hidden_B_G_Forum_Attendance__c FROM Opportunity].Hidden_B_G_Forum_Attendance__c);
    }

    /*
     * TRIGGER POINT: Opportunity object
     * SCENARIO: Opportunity BEFORE UPDATE Trigger Event
     * RESULT: DealDesk
     */
    public static testMethod void test_beforeUpdateDealDesk() {
        Account accVar = createUserAccount();

        //create opportunity
        Opportunity opp = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunity(accVar.Id);
        insert opp;

        Id pricebookId = Test.getStandardPricebookId();

        //OLI 1 START
        //Create your product
        Product2 prod1 = new Product2(Name = 'Product 1',ProductCode = 'Pro-1',isActive = true,Product_Level_2__c = 'Pro Test 1');
        insert prod1;

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod1.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli;
        //OLI 1 END

        //OLI 2 START
        //Create your product
        Product2 prod2 = new Product2(Name = 'Product 2',ProductCode = 'Pro-2',isActive = true,Product_Level_2__c = 'Pro Test 2');
        insert prod2;

        //Create your pricebook entry
        PricebookEntry pbEntry2 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod2.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry2;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry2.Id,
                TotalPrice = 5 * pbEntry2.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli2;
        //OLI 2 END

        //Create your product
        Product2 prod3 = new Product2(Name = 'Product 3',ProductCode = 'Pro-3',isActive = true,Product_Level_2__c = 'Pro Test 3');
        insert prod3;

        //Create your pricebook entry
        PricebookEntry pbEntry3 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod3.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry3;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry3.Id,
                TotalPrice = 5 * pbEntry3.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli3;

        Test.startTest();

        // this a hack fix since the opportunity has already been updated in this transaction
        // in normal circumstances, the opportunity would not have been previously updated prior to this value below being changed.
        // this will allow the opportunity to be processed again (to get around the recursion stopper)
        OpportunityLineItemTriggerHandler.processedOpportunitiesForScoringUpdate.clear();

        opp.Implementation_or_Onboarding_Complexity__c = 'No';
        update opp;

        Test.stopTest();

        System.assertEquals('DealDesk', [SELECT Hidden_B_G_Forum_Attendance__c FROM Opportunity].Hidden_B_G_Forum_Attendance__c);
    }

    /*
     * TRIGGER POINT: Opportunity object
     * SCENARIO: Opportunity BEFORE UPDATE Trigger Event
     * RESULT: CommitToAction
     */
    public static testMethod void test_beforeUpdateCommitToAction() {
        Account accVar = createUserAccount();

        //create opportunity
        Opportunity opp = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunity(accVar.Id);
        insert opp;

        Id pricebookId = Test.getStandardPricebookId();

        //OLI 1 START
        //Create your product
        Product2 prod1 = new Product2(Name = 'Product 1',ProductCode = 'Pro-1',isActive = true,Product_Level_2__c = 'Pro Test 1');
        insert prod1;

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod1.Id,UnitPrice = 1000000.00,IsActive = true);
        insert pbEntry;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli;
        //OLI 1 END

        //OLI 2 START
        //Create your product
        Product2 prod2 = new Product2(Name = 'Product 2',ProductCode = 'Pro-2',isActive = true,Product_Level_2__c = 'Pro Test 2');
        insert prod2;

        //Create your pricebook entry
        PricebookEntry pbEntry2 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod2.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry2;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry2.Id,
                TotalPrice = 5 * pbEntry2.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli2;
        //OLI 2 END

        //Create your product
        Product2 prod3 = new Product2(Name = 'Product 3',ProductCode = 'Pro-3',isActive = true,Product_Level_2__c = 'Pro Test 3');
        insert prod3;

        //Create your pricebook entry
        PricebookEntry pbEntry3 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = prod3.Id,UnitPrice = 100.00,IsActive = true);
        insert pbEntry3;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId = opp.Id,Quantity = 5,PricebookEntryId = pbEntry3.Id,
                TotalPrice = 5 * pbEntry3.UnitPrice,Contract_Start_Date__c = Date.today(),Contract_End_Date__c = Date.today().addDays(3));
        insert oli3;

        Test.startTest();

        // this a hack fix since the opportunity has already been updated in this transaction
        // in normal circumstances, the opportunity would not have been previously updated prior to this value below being changed.
        // this will allow the opportunity to be processed again (to get around the recursion stopper)
        OpportunityLineItemTriggerHandler.processedOpportunitiesForScoringUpdate.clear();

        opp.Implementation_or_Onboarding_Complexity__c = 'No';
        update opp;
        Test.stopTest();

        System.assertEquals('CommitToAction', [SELECT Hidden_B_G_Forum_Attendance__c FROM Opportunity].Hidden_B_G_Forum_Attendance__c);
    }
}