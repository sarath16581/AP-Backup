/****************************************
 * Description: Test Class for the APTOptyLineItemService class
 * Author: JPalmero
 * History
 *     09/03/2019                               Created
 *     09/13/2019                               Added test methods for populateClassification()
 *     09/30/2019                               Added test method for productControlWhenClosedWon()
 *     09/30/2019  shashwat.nath@accenture.com  Updated Test methods with dynamic dateTime test data to fix test failure due to static dateTime
* 08.10.2024 Ken McGurie removed legacy opc calculations 
***************************************/
@isTest
public class APTOptyLineItemServiceTest {
    @testSetup
    static void setup() {
        Id pricebookId = Test.getStandardPricebookId();
        List<Account> accVarList = new List<Account>();
        List<Opportunity> optyList = new List<Opportunity>();
        List<Product2> productList = new List<Product2>();
        List<PricebookEntry> pbEntryList = new List<PricebookEntry>();
        List<Budget_and_Revenue__c> barList = new List<Budget_and_Revenue__c>();
        List<APT_Opportunity_Product_Line_Item__c> aptoptyLIList = new List<APT_Opportunity_Product_Line_Item__c>();
        List<Apttus_Config2__ProductConfiguration__c> prodConfigList = new List<Apttus_Config2__ProductConfiguration__c>();
        Integer currentYear = Date.today().year();
        
        List<User> userList = new List<User>();
        Profile salesAdminProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Admin'];
        Profile coverageSalesProfile = [SELECT Id FROM Profile WHERE Name = 'Coverage Sales'];
        User user1 = new User(
                Alias = 'sAdmn', Email = 'test@auspost.com.au',
                EmailEncodingKey = 'UTF-8', LastName = 'xTesting', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = salesAdminProfile.Id, isActive = true,
                TimeZoneSidKey = 'America/Los_Angeles', UserName = 'auTestX@auspost.com.au.def',
                EmployeeNumber = '10000'
        );
        userList.add(user1);

        User user2 = new User(
                Alias = 'cvSls', Email = 'test@auspost.com.au',
                EmailEncodingKey = 'UTF-8', LastName = 'yTesting', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = coverageSalesProfile.Id, isActive = true,
                TimeZoneSidKey = 'America/Los_Angeles', UserName = 'auTestY@auspost.com.au',
                EmployeeNumber = '10001'
        );
        userList.add(user2);
        insert userList;
        
        NominalTradeAmount__c ntAmount = NominalTradeAmount__c.getInstance();
        ntAmount.Amount__c = 100;
        upsert ntAmount;
        
        SystemSettings__c sysCS = SystemSettings__c.getInstance();
        sysCS.Disable_Triggers__c = FALSE;
        upsert sysCS;
        
        // Create test Account
        Account accVar = APT_TestUtil2.createOrganisation();
        accVar.Name = 'WithRevenue';
        accVarList.add(accVar);
        
        Account accVar2 = APT_TestUtil2.createOrganisation();
        accVar2.Name = 'WithoutRevenue';
        accVarList.add(accVar2);
        
        Account accVar3 = APT_TestUtil2.createOrganisation();
        accVar.Name = 'AnotherWithRevenue';
        accVarList.add(accVar3);
        
        Account accVar4 = APT_TestUtil2.createOrganisation();
        accVar4.Name = 'RefactoredAcct';
        accVarList.add(accVar4);
        
        insert accVarList;
        
        // Create test Opportunity
        Opportunity oppVar = APT_TestUtil2.createOpportunity(accVar);
        oppVar.Pre_Entry__c = TRUE;
        oppVar.StageName = 'Identify';
        optyList.add(oppVar);
        
        Opportunity oppVar2 = APT_TestUtil2.createOpportunity(accVar2);
        oppVar2.Pre_Entry__c = TRUE;
        oppVar2.StageName = 'Identify';
        optyList.add(oppVar2);
        
        Opportunity oppVar3 = APT_TestUtil2.createOpportunity(accVar3);
        oppVar3.Pre_Entry__c = TRUE;
        oppVar3.StageName = 'Identify';
        optyList.add(oppVar3);
        
        insert optyList;
        
        Product2 bundle1 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('International Bundle', TRUE);
        productList.add(bundle1);
        
        Product2 bundle2 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('Road Express - STE', TRUE);
        productList.add(bundle2);
        
        Product2 bundle3 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('eParcel Express', TRUE);
        productList.add(bundle3);
        
        Product2 bundle4 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct('Boxes and Bags Others', TRUE);
        productList.add(bundle4);
        
        insert productList;
        
        //Create your pricebook entry
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
        
        //Create PriceList
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
    
        //Create Proposal
        Apttus_Proposal__Proposal__c testProposal1 = new Apttus_Proposal__Proposal__c();
        List<Apttus_Proposal__Proposal__c> lstPro = new List<Apttus_Proposal__Proposal__c>();
        testProposal1= APT_TestUtils.getQuoteProposal(accVar.ID, oppVar.ID, 'Proposal', 'Quote', priceList.ID);
        testProposal1.APT_Selected_LP__c = 'Selected Proposal';
        testProposal1.RecordTypeID = [SELECT id from RecordType where Name = 'Renewal Quote'].Id;
        lstPro.add(testProposal1);
        
        Apttus_Proposal__Proposal__c testProposal2 = new Apttus_Proposal__Proposal__c();
        testProposal2= APT_TestUtils.getQuoteProposal(accVar2.ID, oppVar2.ID, 'Proposal', 'Quote', priceList.ID);
        testProposal2.APT_Selected_LP__c = 'Selected Proposal';
        testProposal2.RecordTypeID = [SELECT id from RecordType where Name = 'Renewal Quote'].Id;
        lstPro.add(testProposal2);
        
        Apttus_Proposal__Proposal__c testProposal3 = new Apttus_Proposal__Proposal__c();
        testProposal3= APT_TestUtils.getQuoteProposal(accVar3.ID, oppVar3.ID, 'Proposal', 'Quote', priceList.ID);
        testProposal3.APT_Selected_LP__c = 'Selected Proposal';
        testProposal3.RecordTypeID = [SELECT id from RecordType where Name = 'Renewal Quote'].Id;
        lstPro.add(testProposal3);
        
        insert lstPro;
        
        //Create Product Configuration             
        Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, testProposal1.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);        
        prodConfigList.add(prodconfig);
        
        Apttus_Config2__ProductConfiguration__c prodconfig1 = APT_TestUtils.getProductConfiguration('Product Configuration', 1, testProposal2.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
        prodConfigList.add(prodconfig1);
        
        Apttus_Config2__ProductConfiguration__c prodconfig2 = APT_TestUtils.getProductConfiguration('Product Configuration', 1, testProposal3.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
        prodConfigList.add(prodconfig2);
        
        INSERT prodConfigList;
        
        //Create Budget_and_Revenue__c
        Budget_and_Revenue__c barObj = new Budget_and_Revenue__c();
        barObj.Name = 'Test Name';
        barObj.Organisation__c = accVar.Id;
        barObj.Product__c = bundle3.Id;
        barObj.Jan_Revenue_Amount__c = 50;
        barObj.Feb_Revenue_Amount__c = 50;
        barObj.Mar_Revenue_Amount__c = 50;
        barObj.Apr_Revenue_Amount__c = 50;
        barObj.May_Revenue_Amount__c = 50;
        barObj.Jun_Revenue_Amount__c = 50;
        barObj.Jul_Revenue_Amount__c = 50;
        barObj.Aug_Revenue_Amount__c = 50;
        barObj.Sep_Revenue_Amount__c = 50;
        barObj.Oct_Revenue_Amount__c = 50;
        barObj.Nov_Revenue_Amount__c = 50;
        barObj.Dec_Revenue_Amount__c = 50;
        barObj.Total_Revenue_Amount__c = 600;
        barObj.Financial_Year__c = String.valueOf(currentYear);
        
        barList.add(barObj);
        
        Budget_and_Revenue__c barObjPFY = new Budget_and_Revenue__c();
        barObjPFY.Name = 'Test Name Last Year';
        barObjPFY.Organisation__c = accVar.Id;
        barObjPFY.Product__c = bundle3.Id;
        barObjPFY.Total_Revenue_Amount__c = 0;
        barObjPFY.Financial_Year__c = String.valueOf(currentYear-1);
        
        barList.add(barObjPFY);
        
        Budget_and_Revenue__c barObj2 = new Budget_and_Revenue__c();
        barObj2.Name = 'Revenue1';
        barObj2.Organisation__c = accVar3.Id;
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
        barObj3.Name = 'Revenue2';
        barObj3.Organisation__c = accVar3.Id;
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
        barObj4.Name = 'Revenue2';
        barObj4.Organisation__c = accVar3.Id;
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
        barObj5.Name = 'Revenue3';
        barObj5.Organisation__c = accVar4.Id;
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
        
        Budget_and_Revenue__c barObj6 = new Budget_and_Revenue__c();
        barObj6.Name = 'Revenue3';
        barObj6.Organisation__c = accVar.Id;
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
        barObj7.Name = 'Revenue3';
        barObj7.Organisation__c = accVar.Id;
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
        
        insert barList;
        
        Organisation_Role__c testOrgRole = [SELECT Id, Role_Type__c, Organisation__c FROM Organisation_Role__c WHERE Organisation__c = :accVar.Id];
        testOrgRole.Role_Type__c = 'Customer';
        update testOrgRole;
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationR() {
        List<APT_Opportunity_Product_Line_Item__c> productList = new List<APT_Opportunity_Product_Line_Item__c>();
        Account testAccount = [SELECT Id FROM Account WHERE Name =: 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id FROM Opportunity WHERE AccountId =: testAccount.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c testConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        Apttus_Proposal__Proposal__c testProposal = [SELECT Id FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Account__c =: testAccount.Id LIMIT 1];
        
        //Create Apttus Opty Line Item
        APT_Opportunity_Product_Line_Item__c testProd1 = APT_TestUtils.createOpProdLI('Amendment','Yes', testProd.id, testConfig.id, 1 , testProposal.id, 1, Date.newInstance(System.Today().year(), 8, 27), Date.newInstance(System.Today().year(), 9, 27));
        testProd1.APT_Classification__c = 'Growth';
        testProd1.APT_Change_Classification__c = 'No';
        productList.add(testProd1);
        
        test.startTest();
        APTOptyLineItemService.populateClassification(productList);
        test.stopTest();
        
        System.assertEquals('Renewal', testProd1.APT_Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Growth
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationG() {
        List<APT_Opportunity_Product_Line_Item__c> productList = new List<APT_Opportunity_Product_Line_Item__c>();
        Account testAccount = [SELECT Id FROM Account WHERE Name =: 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id FROM Opportunity WHERE AccountId =: testAccount.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c testConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        Apttus_Proposal__Proposal__c testProposal = [SELECT Id, Apttus_Proposal__Account__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Account__c =: testAccount.Id LIMIT 1];
        
        //Create Apttus Opty Line Item
        APT_Opportunity_Product_Line_Item__c testProd1 = APT_TestUtils.createOpProdLI('Amendment','Yes', testProd.id, testConfig.id, 1 , testProposal.id, 1, Date.newInstance(2019, 8, 27), Date.newInstance(2019, 9, 27));
        testProd1.APT_Classification__c = 'Cross Sell';
        testProd1.APT_Change_Classification__c = 'Yes';
        productList.add(testProd1);
        
        test.startTest();
        APTOptyLineItemService.populateClassification(productList);
        test.stopTest();
        
        System.assertEquals('Growth', testProd1.APT_Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassification1to6() {
        List<APT_Opportunity_Product_Line_Item__c> productList = new List<APT_Opportunity_Product_Line_Item__c>();
        Account testAccount = [SELECT Id FROM Account WHERE Name =: 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id FROM Opportunity WHERE AccountId =: testAccount.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c testConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        Apttus_Proposal__Proposal__c testProposal = [SELECT Id, Apttus_Proposal__Account__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Account__c =: testAccount.Id LIMIT 1];
        
        //Create Apttus Opty Line Item
        APT_Opportunity_Product_Line_Item__c testProd1 = APT_TestUtils.createOpProdLI('Amendment','Yes', testProd.id, testConfig.id, 1 , testProposal.id, 1, Date.newInstance(System.Today().year(), 4, 27), Date.newInstance(System.Today().year(), 9, 27));
        testProd1.APT_Classification__c = 'Growth';
        testProd1.APT_Change_Classification__c = 'No';
        productList.add(testProd1);
        
        test.startTest();
        APTOptyLineItemService.populateClassification(productList);
        test.stopTest();
        
        System.assertEquals('Renewal', testProd1.APT_Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Growth
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassification1to6G() {
        List<APT_Opportunity_Product_Line_Item__c> productList = new List<APT_Opportunity_Product_Line_Item__c>();
        Account testAccount = [SELECT Id FROM Account WHERE Name =: 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id FROM Opportunity WHERE AccountId =: testAccount.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c testConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        Apttus_Proposal__Proposal__c testProposal = [SELECT Id, Apttus_Proposal__Account__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Account__c =: testAccount.Id LIMIT 1];
        
        //Create Apttus Opty Line Item
        APT_Opportunity_Product_Line_Item__c testProd1 = APT_TestUtils.createOpProdLI('Amendment','Yes', testProd.id, testConfig.id, 1 , testProposal.id, 1, Date.newInstance(2019, 4, 27), Date.newInstance(2019, 9, 27));
        testProd1.APT_Classification__c = 'Cross Sell';
        testProd1.APT_Change_Classification__c = 'YES';
        productList.add(testProd1);
        
        test.startTest();
        APTOptyLineItemService.populateClassification(productList);
        test.stopTest();
        
        System.assertEquals('Growth', testProd1.APT_Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Cross Sell
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationCS() {
        List<APT_Opportunity_Product_Line_Item__c> productList = new List<APT_Opportunity_Product_Line_Item__c>();
        Account testAccount = [SELECT Id FROM Account WHERE Name =: 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id FROM Opportunity WHERE AccountId =: testAccount.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'International Bundle' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c testConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        Apttus_Proposal__Proposal__c testProposal = [SELECT Id, Apttus_Proposal__Account__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Account__c =: testAccount.Id LIMIT 1];
        
        //Create Apttus Opty Line Item
        APT_Opportunity_Product_Line_Item__c testProd1 = APT_TestUtils.createOpProdLI('Amendment','Yes', testProd.id, testConfig.id, 1 , testProposal.id, 1, Date.newInstance(2019, 8, 27), Date.newInstance(2019, 9, 27));
        testProd1.APT_Classification__c = 'New Business';
        testProd1.APT_Change_Classification__c = 'No';
        productList.add(testProd1);
        
        test.startTest();
        APTOptyLineItemService.populateClassification(productList);
        test.stopTest();
        
        System.assertEquals('Cross Sell', testProd1.APT_Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for New Business
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationNB() {
        List<APT_Opportunity_Product_Line_Item__c> productList = new List<APT_Opportunity_Product_Line_Item__c>();
        Account testAccount = [SELECT Id FROM Account WHERE Name =: 'WithoutRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id FROM Opportunity WHERE AccountId =: testAccount.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'International Bundle' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c testConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        Apttus_Proposal__Proposal__c testProposal = [SELECT Id, Apttus_Proposal__Account__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Account__c =: testAccount.Id LIMIT 1];
        
        //Create Apttus Opty Line Item
        APT_Opportunity_Product_Line_Item__c testProd1 = APT_TestUtils.createOpProdLI('Amendment','Yes', testProd.id, testConfig.id, 1 , testProposal.id, 1, Date.newInstance(2019, 8, 27), Date.newInstance(2019, 9, 27));
        testProd1.APT_Classification__c = 'New Business';
        testProd1.APT_Change_Classification__c = 'No';
        productList.add(testProd1);
        
        test.startTest();
        APTOptyLineItemService.populateClassification(productList);
        test.stopTest();
        
        System.assertEquals('New Business', testProd1.APT_Classification__c);
    }
    
    /*********************************
     * Description: Tests the populateClassification() method for Win Back
     * Author: Jeoffrey Palmero
     * History:
     * 09/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationWB() {
        List<APT_Opportunity_Product_Line_Item__c> productList = new List<APT_Opportunity_Product_Line_Item__c>();
        Account testAccount = [SELECT Id FROM Account WHERE Name =: 'AnotherWithRevenue' LIMIT 1];
        Opportunity testOpty = [SELECT Id FROM Opportunity WHERE AccountId =: testAccount.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Boxes and Bags Others' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c testConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        Apttus_Proposal__Proposal__c testProposal = [SELECT Id, Apttus_Proposal__Account__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Account__c =: testAccount.Id LIMIT 1];
        
        //Create Apttus Opty Line Item
        APT_Opportunity_Product_Line_Item__c testProd1 = APT_TestUtils.createOpProdLI('Amendment','Yes', testProd.id, testConfig.id, 1 , testProposal.id, 1, Date.newInstance(2019, 8, 27), Date.newInstance(2019, 9, 27));
        testProd1.APT_Classification__c = 'New Business';
        testProd1.APT_Change_Classification__c = 'No';
        productList.add(testProd1);
        
        test.startTest();
        APTOptyLineItemService.populateClassification(productList);
        test.stopTest();
        
        System.assertEquals('Win Back', testProd1.APT_Classification__c);
    }
    
    /*********************************
     * Description: Tests the productControlWhenClosedWon() method
     * Author: Prince Encina
     * History:
     * 09/30/2019       Created
     ********************************/
    @isTest
    static void testProductControlWhenClosedWon() {
        Test.startTest();
        User testRunAs = [SELECT Id from User WHERE Alias = 'cvSls' LIMIT 1];       // Sales User profile
        
        // Query your permission set name from Organization that your want to test.
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'ValidationRuleBypassClassicRestrictions'];
       
        // Assign the above inserted user for the above Permission Set.
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = testRunAs.Id;
        psa.PermissionSetId = ps.id;
        insert psa;
        
        
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        // Opportunity testOpp = [SELECT Id FROM Opportunity WHERE AccountId =: testAccount.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry testPBE = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        Apttus_Config2__ProductConfiguration__c testConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        Apttus_Config2__PriceList__c testPriceList = [SELECT Id FROM Apttus_Config2__PriceList__c LIMIT 1];
        // Update Organization Role
        //Organisation_Role__c testOrgRole = [SELECT Id, Role_Type__c, Organisation__c FROM Organisation_Role__c WHERE Organisation__c = :testAccount.Id];
        //testOrgRole.Role_Type__c = 'Customer';
        //update testOrgRole;
        
        System.runAs(testRunAs) {
            // Create Opportunity
            Opportunity testOpp = new Opportunity();
            testOpp.Name = APT_Constants.STRING_TEST_OPPORTUNITY;
            testOpp.StageName = APT_Constants.OPPORTUNITY_STAGE_PROPOSE;
            testOpp.AccountId = testAccount.Id;
            // Prerequsites for CWG
            testOpp.Offline_Contract_Received__c = true;
            testOpp.Data_Integrity_Compliance__c = true;
            testOpp.Pre_Entry__c = true;
            testOpp.Type = 'Existing Customer';
            testOpp.CloseDate = Date.today().addDays(-1);
            testOpp.StageName = 'Identify';
            insert testOpp;
        
            // Create Apttus Proposal
            Apttus_Proposal__Proposal__c testProposal = new Apttus_Proposal__Proposal__c();
            testProposal = APT_TestUtils.getQuoteProposal(testAccount.Id, testOpp.Id, 'Proposal', 'Quote', testPriceList.ID);
            testProposal.APT_Selected_LP__c = 'Selected Proposal';
            insert testProposal;
        
            // Create Opportunity Product
            Date revenueStartDate = Date.today().addDays(30);
            Date revenueEndDate = Date.today().addDays(60);
            OpportunityLineItem testOLI = new OpportunityLineItem();
            testOLI.Contract_Start_Date__c = revenueStartDate;
            testOLI.Contract_End_Date__c = revenueEndDate;
            testOLI.Quantity = 1000;
            testOLI.UnitPrice = 1.00;
            testOLI.Contract_Product__c = 'Yes';
            testOLI.OpportunityId = testOpp.Id;
            testOLI.Product2Id = testProd.Id;
            testOLI.PricebookEntryId = testPBE.Id;
            insert testOLI;
        
            // Create Opportunity Product Line Item
            APT_Opportunity_Product_Line_Item__c testOPLI1 = APT_TestUtils.createOpProdLI('Growth', 'Yes', testProd.Id, testConfig.Id, 1000,
                                                                                          testProposal.Id, 1, revenueStartDate, revenueEndDate);
            insert testOPLI1;
            
            // Set the Opportunity to Closed Won
            testOpp.StageName = Constants.CLOSED_WON;
            testOpp.Hidden_Restrict_Path_Closure__c=true; 
            testOpp.Closed_Reason__c = 'Capability';
            update testOpp;
            System.assertEquals(Constants.CLOSED_WON, testOpp.StageName);
        
            // ----------------------------------
            // Insert OPLI2: Should fail
            try {
                Product2 testProd2 = [SELECT Id FROM Product2 WHERE Name = 'Road Express - STE' LIMIT 1];
                APT_Opportunity_Product_Line_Item__c testOPLI2 = APT_TestUtils.createOpProdLI('Growth', 'Yes', testProd2.Id, testConfig.Id, 1000,
                                                                                              testProposal.Id, 1, revenueStartDate, revenueEndDate);
                insert testOPLI2;
            } catch (Exception e) {
                System.debug('First Error: ' + e.getMessage());
            }
            
            // Delete OPLI1: Should fail
            try {
                delete testOPLI1;
            } catch (Exception e) {
                System.debug('Second Error: ' + e.getMessage());
            }
            
            // Update OPLI1.Quantity, Contract Product?: Should fail
            try {
                testOPLI1.APT_Quantity__c = 2000;
                testOPLI1.APT_Contract_Product__c = Constants.NO_STRING;
                update testOPLI1;
            } catch (Exception e) {
                System.debug('Third Error: ' + e.getMessage());
            }
        }
        
        
        // Assertion: Insert and Delete blocked
        List<APT_Opportunity_Product_Line_Item__c> OPLIList = [SELECT Id, APT_Quote_Proposal__c, APT_Quantity__c, APT_Contract_Product__c FROM APT_Opportunity_Product_Line_Item__c];
        System.assertEquals(1, OPLIList.size());
        
        // Assertion: Update to fields blocked
        System.assertEquals(1000, OPLIList[0].APT_Quantity__c);
        System.assertEquals(Constants.YES_STRING, OPLIList[0].APT_Contract_Product__c);
        
        Test.stopTest();
    }
    
}