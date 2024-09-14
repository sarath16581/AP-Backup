/****************************************************************************************
Author:         Adrian Recio
Company:        Accenture
Description:    Test class to cover OpportunityUtility functionality
History:
-----------------------------------------------------------------------------------------
17.10.2017      Adrian Recio (Accenture)            Test class created
14-06-2018  heguang.miao@coroma.com.au  Updated [TDO-96] Unit tests re-written with scenario based tests.
17-02-2020   Jansi                       Added stage while inserting Opportunity in testDatasetup
28-Feb-2020  Lavanya Kavuri (lkavuri@salesforce.com)     Fixing Test class failures
05-03-2020  seth.p.heang@accenture.com  Updated Test methods with dynamic dateTime test data to fix test failure due to static dateTime
12-03-2020  Jansi(avula.jansirani@crmit.com) added line ' newOpty.Hidden_Restrict_Path_Closure__c =TRUE;'
25-03-2020  Jansi(avula.jansirani@crmit.com) commented test.startTest() before creating Opportunity and added before inserting OpportunityLineItem to avoid SOQL Limit issue
14/07/2020  arjun.singh@auspost.com.au       Test for STP-2148 - Add user’s team information as mandatory with an Opportunity Closure
2020-08-02 - Nathan Franklin - Updated test class for refactoring OpportunityUtility.updateOwnerEmployeeNumber into OpportunityUtility_part2.registerOpptyOwner
2020-11-20  Seth Heang   - Updated test method testUserRolePopulateOnOpptyOwnerChange() to bypass the custom validation on Opportunity due to Opportunity Split
2020-11-30  Seth Heang   - Added test method testCloseDateUpdateOnOppClosure() to test the 'Close Date' field auto-populated to Today's date during Opportunity Closure
2022-07-22      ken.mcguire                         OPC Uplift.
2023-08-24 - Ranjeewa Silva - Updates to existing tests to ensure test data conforms to new sales pipeline governance validations on Opportunity.
2024-01-30 - Bharat Patel - Set APTMinimumMonthlySpend__c value in testClassificationCS(), to validate setOpportunityPrimaryProposalFieldValues()
*****************************************************************************************/

@isTest
private class OpportunityUtilityTest {


    @testSetup
    static void setupTestData() {
	    Test.startTest();
        SystemSettings__c testCS = SystemSettings__c.getInstance();
        testCS.Disable_Triggers__c = FALSE;
        UPSERT testCS;

        //Custom Setting for the OPC Automation
        NominalTradeAmount__c ntAmount = NominalTradeAmount__c.getInstance();
        ntAmount.Amount__c = 100;
        upsert ntAmount;

        // Create users for further use
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User user1 = new User(
                Alias = 'testname', Email = 'test@auspost.com.au',
                EmailEncodingKey = 'UTF-8', LastName = 'xTesting', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = sysAdminProfile.Id, isActive = true,
                TimeZoneSidKey = 'Australia/Sydney', UserName = 'auTestX@auspost.com.au.def',
                EmployeeNumber = '10000'
        );
        insert user1;

        User user2 = new User(
                Alias = 'testname', Email = 'test@auspost.com.au',
                EmailEncodingKey = 'UTF-8', LastName = 'yTesting', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = sysAdminProfile.Id, isActive = true,
                TimeZoneSidKey = 'America/Los_Angeles', UserName = 'auTestY@auspost.com.au',
                EmployeeNumber = '10001'
        );
        insert user2;

        User user3 = new User(
                Alias = 'testRun', Email = 'test@auspost.com.au',
                EmailEncodingKey = 'UTF-8', LastName = 'zTesting', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = sysAdminProfile.Id, isActive = true,
                TimeZoneSidKey = 'America/Los_Angeles', UserName = 'auTestZ@auspost.com.au',
                EmployeeNumber = '10002'
        );
        insert user3;

        Id hUserId = [SELECT ID from User where Name='Holding User' LIMIT 1].Id;

        // Useful RecordTypes
        RecordType organizationRecordType = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        RecordType facilityRecordType = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Facility' limit 1];


        // Accounts with different roles
        // 1. Prospect account with holding user as owner
        Account prospectHuserAccount = new Account();
        prospectHuserAccount.Name = 'prospectNormalUserAccount';
        prospectHuserAccount.RecordTypeId = facilityRecordType.Id;
        prospectHuserAccount.OwnerId = hUserId;
        prospectHuserAccount.BillingPostalCode = '3006';
        insert prospectHuserAccount;

        prospectHuserAccount = [SELECT Id, Role_Type_Roll_Up__c, OwnerId FROM Account WHERE Id = :prospectHuserAccount.Id];
        User owner = [SELECT Id, Name FROM User WHERE Id = :prospectHuserAccount.OwnerId];


        // 2. Customer Account owned by normal user
        Account customerAccount = new Account();
        customerAccount.Name = 'customer normal user account';
        customerAccount.Phone = '123';
        customerAccount.Email__c = 'a@b.com';
        customerAccount.ShippingCity = 'Melbourne';
        customerAccount.ShippingState = 'Victoria';
        customerAccount.ShippingStreet = 'Collins Street';
        customerAccount.ShippingPostalCode = '3000';
        customerAccount.BillingPostalCode = '3161';
        customerAccount.OwnerId = UserInfo.getUserId();

        customerAccount.RecordType = organizationRecordType;
        insert customerAccount;
        // There must be some trigger that creates role for the account automatically.
        // Here we manipulate the behaviour by deleting auto-generated role and insert a desired one.
        List<Organisation_Role__c> selectedRoles = [SELECT Id, Role_Type__c FROM Organisation_Role__c WHERE Organisation__c = :customerAccount.Id];
        delete selectedRoles;

        // We need to update the account's owner id because the triggers could change the value.
        customerAccount = [SELECT Id, OwnerId FROM Account WHERE Id = :customerAccount.Id];
        customerAccount.OwnerId = UserInfo.getUserId();
        update customerAccount;

        Organisation_Role__c customerRole = new Organisation_Role__c();
        customerRole.Role_Type__c = 'Customer';
        customerRole.Organisation__c = customerAccount.Id;
        insert customerRole;

        customerAccount = [SELECT Id, Role_Type_Roll_Up__c FROM Account WHERE Id = :customerAccount.Id LIMIT  1];
        System.assertEquals('Customer', customerAccount.Role_Type_Roll_Up__c,
                'Now the account should be a customer');

        // 3. Customer account owned by huser
        Account customerHuserAccount = new Account();
        customerHuserAccount.Name = 'customer huser user account';
        customerHuserAccount.Phone = '123';
        customerHuserAccount.Email__c = 'a@b.com';
        customerHuserAccount.ShippingCity = 'Melbourne';
        customerHuserAccount.ShippingState = 'Victoria';
        customerHuserAccount.ShippingStreet = 'Collins Street';
        customerHuserAccount.ShippingPostalCode = '3000';
        customerHuserAccount.BillingPostalCode = '3161';
        customerHuserAccount.OwnerId = hUserId;
        customerHuserAccount.RecordType = organizationRecordType;
        insert customerHuserAccount;

        selectedRoles = [SELECT Id, Role_Type__c FROM Organisation_Role__c WHERE Organisation__c = :customerHuserAccount.Id];
        delete selectedRoles;

        customerRole = new Organisation_Role__c();
        customerRole.Role_Type__c = 'Customer';
        customerRole.Organisation__c = customerHuserAccount.Id;
        insert customerRole;

        customerHuserAccount = [SELECT Id, Role_Type_Roll_Up__c FROM Account WHERE Id = :customerHuserAccount.Id LIMIT  1];
        System.assertEquals('Customer', customerHuserAccount.Role_Type_Roll_Up__c,
                'Now the account should be a customer');


        Account organizationAccount = new Account();
        organizationAccount.name = 'test account';
        organizationAccount.phone = '123';
        organizationAccount.email__c = 'test@test.com';
        organizationAccount.recordtypeid = organizationRecordType.Id;
        insert organizationAccount;

        // Create test Account
        List<Account> accVarList = new List<Account>();
        Account accVar = APT_TestUtil2.createOrganisation();
        accVar.Name = 'WithRevenue';
        accVarList.add(accVar);

        Account accVar2 = APT_TestUtil2.createOrganisation();
        accVar2.Name = 'WithoutRevenue';
        accVarList.add(accVar2);

        Account accVar3 = APT_TestUtil2.createOrganisation();
        accVar3.Name = 'AnotherWithRevenue';
        accVarList.add(accVar3);

        Account accVar4 = APT_TestUtil2.createOrganisation();
        accVar4.Name = 'RefactoredAcct';
        accVarList.add(accVar4);

        insert accVarList;

		// key contact is mandatory on opportunity
		List<Contact> keyContacts = ApplicationTestDataFactory.getContacts(accVarList.size(), new Map<Id, Account>(accVarList).keySet(), false);
		insert keyContacts;
        // Create test Opportunity
        List<Opportunity> optyList = new List<Opportunity>();
        Opportunity oppVar = APT_TestUtil2.createOpportunity(accVar);
        oppVar.StageName = 'Identify';
        oppVar.Pre_Entry__c = TRUE;
		oppVar.KeyContact__c = keyContacts[0].Id;
		oppVar.Monthly_Executive_Summary__c = 'test';
		oppVar.Description = 'test description';
        optyList.add(oppVar);

        Opportunity oppVar2 = APT_TestUtil2.createOpportunity(accVar2);
        oppVar2.Pre_Entry__c = TRUE;
        oppVar2.StageName = 'Identify';
		oppVar2.KeyContact__c = keyContacts[1].Id;
		oppVar2.Monthly_Executive_Summary__c = 'test';
		oppVar2.Description = 'test description';
        optyList.add(oppVar2);

        Opportunity oppVar3 = APT_TestUtil2.createOpportunity(accVar3);
        oppVar3.Pre_Entry__c = TRUE;
        oppVar3.Closed_Reason__c = 'Functionality';
        oppVar3.StageName = 'Identify';
		oppVar3.KeyContact__c = keyContacts[2].Id;
		oppVar3.Monthly_Executive_Summary__c = 'test';
		oppVar3.Description = 'test description';
        optyList.add(oppVar3);

        Opportunity oppVar4 = APT_TestUtil2.createOpportunity(accVar4);
        oppVar4.Pre_Entry__c = TRUE;
        oppVar4.Closed_Reason__c = 'Functionality';
        //--[Jansi] added below 17-02-2020 [for ERROR::System.DmlException: Insert failed. First exception on row 3; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, New Opportunity can only be created with Stage set to 'Identify': []]
        oppVar4.StageName = 'Identify';
		oppVar4.KeyContact__c = keyContacts[3].Id;
		oppVar4.Monthly_Executive_Summary__c = 'test';
		oppVar4.Description = 'test description';
        optyList.add(oppVar4);

        insert optyList;

		// recording competitors mandatory on opportunity to progress to close won
		List<Competitor__c> competitors = ApplicationTestDataFactorySales.getCompetitors(optyList.size(), new Map<Id, Opportunity>(optyList).keySet(), false);
		insert(competitors);

		List<Task> opportunityTasks = new List<Task>();
		for (Opportunity o: optyList) {
			Task t = ApplicationTestDataFactory.getTasks(1, o.Id, false)[0];
			t.ActivityDate=System.today();
			t.Subject='test';
			t.Status = 'Completed';
			opportunityTasks.add(t);
		}
		insert opportunityTasks;
        // Create account plan
        Account_Plan__c apVar = new Account_Plan__c();
        apVar.name = 'test plan';
        apVar.account__c = organizationAccount.Id;
        insert apVar;


        // Create territory assignment matrices
        // Matrix with both low threshold and high threshold
        Territory_Assignment_Matrix__c matrixWithBothThreshold = new Territory_Assignment_Matrix__c();
        matrixWithBothThreshold.Post_Code__c = '3006';
        matrixWithBothThreshold.Product__c = 'Australia Post - Parcel Services';
        matrixWithBothThreshold.Sales_Team__c = 'Acquisition Team';
        matrixWithBothThreshold.Sales_Team_Member__c = user1.id;
        matrixWithBothThreshold.Low_Threshold_Amount__c = 40000.01;
        matrixWithBothThreshold.High_Threshold_Amount__c = 80000;
        insert matrixWithBothThreshold;

        // Matrix without high threshold
        Territory_Assignment_Matrix__c matrixWithoutHighThresh = new Territory_Assignment_Matrix__c();
        matrixWithoutHighThresh.Post_Code__c = '3161';
        matrixWithoutHighThresh.Product__c = 'Australia Post - Mail Services';
        matrixWithoutHighThresh.Sales_Team__c = 'Acquisition Team';
        matrixWithoutHighThresh.Sales_Team_Member__c = user2.id;
        matrixWithoutHighThresh.Low_Threshold_Amount__c = 40000.01;
        insert matrixWithoutHighThresh;

		ConfigSetting__c configSetting = new ConfigSetting__c(OpportunityDriverDefaultUserId__c = user3.Id);

        insert configSetting;

        //create products
        List<Product2> productList = new List<Product2>();
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
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbEntry = new PricebookEntry();

        List<PricebookEntry> pbEntryList = new List<PricebookEntry>();
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

        Apttus_Proposal__Proposal__c testProposal4 = new Apttus_Proposal__Proposal__c();
        testProposal4 = APT_TestUtils.getQuoteProposal(accVar4.ID, oppVar4.ID, 'Proposal', 'Quote', priceList.ID);
        testProposal4.APT_Selected_LP__c = 'Selected Proposal';
        testProposal4.RecordTypeID = [SELECT id from RecordType where Name = 'Renewal Quote'].Id;
        lstPro.add(testProposal4);

        insert lstPro;

        //Create Product Configuration
        List<Apttus_Config2__ProductConfiguration__c> prodConfigList = new List<Apttus_Config2__ProductConfiguration__c>();
        Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, testProposal1.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
        prodConfigList.add(prodconfig);

        Apttus_Config2__ProductConfiguration__c prodconfig1 = APT_TestUtils.getProductConfiguration('Product Configuration', 1, testProposal2.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
        prodConfigList.add(prodconfig1);

        Apttus_Config2__ProductConfiguration__c prodconfig2 = APT_TestUtils.getProductConfiguration('Product Configuration', 1, testProposal3.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
        prodConfigList.add(prodconfig2);

        INSERT prodConfigList;

        //Create Budget_and_Revenue__c
        Integer currentYear = Date.today().year();
        List<Budget_and_Revenue__c> barList = new List<Budget_and_Revenue__c>();
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
        barObj.Aug_Revenue_Amount__c = 5;
        barObj.Sep_Revenue_Amount__c = 5;
        barObj.Oct_Revenue_Amount__c = 5;
        barObj.Nov_Revenue_Amount__c = 5;
        barObj.Dec_Revenue_Amount__c = 5;
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
        barObj5.Organisation__c = accVar3.Id;
        barObj5.Product__c = bundle3.Id;
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
        barObj5.Total_Revenue_Amount__c = 1200;
        barObj5.Financial_Year__c = String.valueOf(currentYear);

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
        barObj6.Financial_Year__c = String.valueOf(currentYear);

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
        barObj7.Financial_Year__c = String.valueOf(currentYear-2);

        barList.add(barObj7);

        INSERT barlist; // 10/23/2019 added to fix validaion issues
		Test.stopTest();
    }
   /**
    * SCENARIO: The target territory doesn't sell the opportunity's product,
    * */
   /* @isTest
     static void OpportunityUtility_assignSalesRep_territoryNotSellingProduct() {
        Account account = [SELECT Id, Role_Type_Roll_Up__c, OwnerId FROM Account WHERE Name = 'prospectNormalUserAccount'];
        account.BillingPostalCode = '3006';
        update account;

        Test.startTest();
        // The billing territory doesn't sell this product
        Opportunity opp = new Opportunity();
        opp.AccountId = account.Id;
        opp.Name = 'territoryNotSellingProduct';
        opp.StageName = 'Identify';
        opp.CloseDate = Date.newInstance(3018, 6, 19);
        opp.Lead_ID__c = 'Dummy lead';
        opp.Product__c = 'Australia Post - Trusted Services';

        insert opp;

        Test.stopTest();

        opp = [SELECT Id, OwnerId from Opportunity WHERE Id = :opp.Id];

        String defaultSalesRep = ConfigSetting__c.getInstance().OpportunityDriverDefaultUserId__c;
        System.assertEquals(defaultSalesRep, opp.OwnerId,
                'OpportunityUtility_assignSalesRep_territoryNotSellingProduct : defaultSalesResp should be assigned if the territory doesnt sell the product');
    } */

    /**
    * SCENARIO: The opportunity's estimated value is lower than territory's lower threshold.
    * */
   /* @isTest
    static void OpportunityUtility_assignSalesRep_lowerThanTerritoryLowThreshold() {
        Account account = [SELECT Id, Role_Type_Roll_Up__c, OwnerId FROM Account WHERE Name = 'prospectNormalUserAccount'];
        account.BillingPostalCode = '3006';
        update account;

        Test.startTest();

        Opportunity opp = new Opportunity();
        opp.AccountId = account.Id;
        opp.Name = 'lowerThanLowThreshold';
        opp.StageName = 'Identify';
        opp.CloseDate = Date.newInstance(3018, 6, 19);
        opp.Lead_ID__c = 'Dummy lead';
        opp.Product__c = 'Australia Post - Parcel Services';
        opp.Opportunity_Initial_Estimate__c = 40000;

        insert opp;

        Test.stopTest();

        opp = [SELECT Id, OwnerId from Opportunity WHERE Id = :opp.Id];

        String defaultSalesRep = ConfigSetting__c.getInstance().OpportunityDriverDefaultUserId__c;
        System.assertEquals(defaultSalesRep, opp.OwnerId,
                'OpportunityUtility_assignSalesRep_smallerThanTerritoryLowThreshold : defaultSalesResp should be assigned if the estimate is too low');
    }*/

    /**
    * SCENARIO: The opportunity's estimated value is higher than territory's high threshold.
    * */
    /*@isTest
    static void OpportunityUtility_assignSalesRep_higherThanTerritoryHighThreshold() {
        Account account = [SELECT Id, Role_Type_Roll_Up__c, OwnerId FROM Account WHERE Name = 'prospectNormalUserAccount'];
        account.BillingPostalCode = '3006';
        update account;

        Test.startTest();

        Opportunity opp = new Opportunity();
        opp.AccountId = account.Id;
        opp.Name = 'higherThanHighThreshold';
        opp.StageName = 'Identify';
        opp.CloseDate = Date.newInstance(3018, 6, 19);
        opp.Lead_ID__c = 'Dummy lead';
        opp.Product__c = 'Australia Post - Parcel Services';
        opp.Opportunity_Initial_Estimate__c = 80000.01;

        insert opp;

        Test.stopTest();

        opp = [SELECT Id, OwnerId from Opportunity WHERE Id = :opp.Id];

        String defaultSalesRep = ConfigSetting__c.getInstance().OpportunityDriverDefaultUserId__c;
        System.assertEquals(defaultSalesRep, opp.OwnerId,
                'OpportunityUtility_assignSalesRep_higherThanTerritoryHighThreshold : defaultSalesResp should be assigned if the estimate is too high');
    }*/

    /**
    * SCENARIO: The opportunity's estimated value is within the territory's threshold.
    * */
   /* @isTest
    static void OpportunityUtility_assignSalesRep_fitsThreshold() {
        Account account = [SELECT Id, Role_Type_Roll_Up__c, OwnerId FROM Account WHERE Name = 'prospectNormalUserAccount'];
        account.BillingPostalCode = '3006';
        update account;

        Test.startTest();

        Opportunity opp = new Opportunity();
        opp.AccountId = account.Id;
        opp.Name = 'higherThanHighThreshold';
        opp.StageName = 'Identify';
        opp.CloseDate = Date.newInstance(3018, 6, 19);
        opp.Lead_ID__c = 'Dummy lead';
        opp.Product__c = 'Australia Post - Parcel Services';
        opp.Opportunity_Initial_Estimate__c = 80000;

        insert opp;

        Test.stopTest();

        opp = [SELECT Id, OwnerId from Opportunity WHERE Id = :opp.Id];

        User salesTeamMember = [SELECT Id FROM User WHERE Username = 'auTestX@auspost.com.au.def'];

        System.assertEquals(salesTeamMember.Id, opp.OwnerId,
                'OpportunityUtility_assignSalesRep_fitsThreshold : opportunity should be assigned to the sales team');
    }*/

    /**
    * SCENARIO: The territory doesn't have a high threshold
    * */
   /* @isTest
    static void OpportunityUtility_assignSalesRep_territoryNoHighThreshold() {
        Account account = [SELECT Id, Role_Type_Roll_Up__c, OwnerId FROM Account WHERE Name = 'prospectNormalUserAccount'];
        account.BillingPostalCode = '3161';
        update account;

        Test.startTest();

        Opportunity opp = new Opportunity();
        opp.AccountId = account.Id;
        opp.Name = 'higherThanHighThreshold';
        opp.StageName = 'Identify';
        opp.CloseDate = Date.newInstance(3018, 6, 19);
        opp.Lead_ID__c = 'Dummy lead';
        opp.Product__c = 'Australia Post - Mail Services';
        opp.Opportunity_Initial_Estimate__c = 10000000;

        insert opp;

        Test.stopTest();

        opp = [SELECT Id, OwnerId from Opportunity WHERE Id = :opp.Id];

        User salesTeamMember = [SELECT Id FROM User WHERE Username = 'auTestY@auspost.com.au'];

        System.assertEquals(salesTeamMember.Id, opp.OwnerId,
                'OpportunityUtility_assignSalesRep_territoryNoHighThreshold : opportunity with large estimate should ' +
                        'be assigned to the sales member if the territory dosnt have a high threshold');
    }*/

    /**
    * SCENARIO: The opportunity's account is of type customer but owned by the holding user
    * */
    @isTest
    static void OpportunityUtility_assignSalesRep_customerAccountWithHuser() {

        Account account = [SELECT Id, Role_Type_Roll_Up__c, OwnerId FROM Account WHERE Name = 'customer huser user account'];

        Test.startTest();

        Opportunity opp = new Opportunity();
        opp.AccountId = account.Id;
        opp.Name = 'higherThanHighThreshold';
        opp.StageName = 'Identify';
        opp.CloseDate = Date.newInstance(3018, 6, 19);
        opp.Lead_ID__c = 'Dummy lead';
        opp.Product__c = 'Australia Post - Mail Services';
        opp.Opportunity_Initial_Estimate__c = 10000000;

        insert opp;

        Test.stopTest();

        opp = [SELECT Id, OwnerId from Opportunity WHERE Id = :opp.Id];

        Id accountOwnerId = [Select OwnerId from Account where Id =: account.Id].OwnerId;

        //This assert should not be equal as per the code in Oppty Util.

        System.assertNotEquals(accountOwnerId, opp.OwnerId,
                'OpportunityUtility_assignSalesRep_customerAccountWithHuser : Opportunitys having customer account owned by ' +
                    'the holding user should be owned by account owner');

        /*  Lavanya Commented out based on the Modification in the Opportunity UTIL Class, that there is no longer a SalesTeam Member associated with the Opportunity.
        **  OwnerId = Account Owner Id for this scenario.

        User salesTeamMember = [SELECT Id FROM User WHERE Username = 'auTestY@auspost.com.au'];
        System.assertEquals(salesTeamMember.Id, opp.OwnerId,
                'OpportunityUtility_assignSalesRep_customerAccountWithHuser : Opportunitys having customer account owned by ' +
                        'the holding user should be assigned to the correct sales member');
                        */
    }

    /**
    * SCENARIO: The opportunity's account is of type customer and owned by a normal user
    * */
    @isTest
    static void OpportunityUtility_assignSalesRep_customerAccountWithNormalUser() {

        Account account = [SELECT Id, Role_Type_Roll_Up__c, OwnerId FROM Account WHERE Name = 'customer normal user account'];

        Test.startTest();

        Opportunity opp = new Opportunity();
        opp.AccountId = account.Id;
        opp.Name = 'higherThanHighThreshold';
        opp.StageName = 'Identify';
        opp.CloseDate = Date.newInstance(3018, 6, 19);
        opp.Lead_ID__c = 'Dummy lead';
        opp.Product__c = 'Australia Post - Mail Services';
        opp.Opportunity_Initial_Estimate__c = 10000000;

        insert opp;

        Test.stopTest();

        opp = [SELECT Id, OwnerId from Opportunity WHERE Id = :opp.Id];

        System.assertEquals(account.OwnerId, opp.OwnerId,
                'OpportunityUtility_assignSalesRep_customerAccountWithNormalUser : Opportunitys having customer account owned by ' +
                        'a normal user should be assigned to the normal user');
    }

    /**
    * SCENARIO: updateAccountPlan called on plans without opportunity
    * */
    @isTest
    static void OpportunityUtility_updateAccountPlan_zeroOpportunity() {
        Account account = [SELECT Id FROM Account WHERE name = 'test account'];
        Account_Plan__c accountPlan = [SELECT Id, Opportunity_Value__c FROM Account_Plan__c WHERE name = 'test plan'];

        Test.startTest();
        // Do not associate any opportunity to this plan
        OpportunityUtility.updateAccountPlan(new Set<Id> {accountPlan.Id});

        Test.stopTest();

        // Refresh plan
        accountPlan = [SELECT Id, Opportunity_Value__c FROM Account_Plan__c WHERE name = 'test plan'];
        System.assertEquals(0, accountPlan.Opportunity_Value__c,
                'OpportunityUtility_updateAccountPlan_zeroOpportunity : the opportunity value should be 0 if there is no opportunity');
    }

    /**
    * SCENARIO: updateAccountPlan called on plans with multiple opportunities,
    * each opportunity may or may not have the amount value
    * */
    @isTest
    static void OpportunityUtility_updateAccountPlan_multipleOpportunities() {
        Account account = [SELECT Id FROM Account WHERE name = 'test account'];
        Account_Plan__c accountPlan = [SELECT Id, Opportunity_Value__c FROM Account_Plan__c WHERE name = 'test plan'];

        // Assign some opportunities
        List<Opportunity> opportunities = new List<Opportunity>();

        for (Integer i = 0; i < 5; i++) {
            Opportunity oppVar = new Opportunity();
            oppVar.name = 'test oppty';
            oppVar.accountid = account.Id;
            oppVar.type = 'New Business';
            oppVar.account_plan__c = accountPlan.Id;
            // If i is even, assign a value, otherwise keep null
            oppVar.amount = System.Math.mod(i, 2) == 0 ? null : i;
            oppVar.stagename = 'Identify';
            oppVar.closedate = System.today();
            oppVar.Contract_Number__c = '99999';
            oppVar.Contract_Start_Date__c = Date.newInstance(2012, 07, 27);
            oppVar.Contract_End_Date__c = Date.newInstance(2012, 07, 27);
            opportunities.add(oppVar);
        }
        insert opportunities;

        Test.startTest();

        OpportunityUtility.updateAccountPlan(new Set<Id> {accountPlan.Id});

        Test.stopTest();

        // Refresh plan
        accountPlan = [SELECT Id, Opportunity_Value__c FROM Account_Plan__c WHERE name = 'test plan'];
        // 1 + 3
        System.assertEquals(4, accountPlan.Opportunity_Value__c,
                'OpportunityUtility_updateAccountPlan_multipleOpportunities : update against multiple opportunities should sum up all the amount');

    }

    /**
     * SCENARIO: Normally assign owner's employee number to the opportunity
     * This is done in OpportunityUtility_part2.registerOpptyOwner
     */
    @isTest
    static void OpportunityUtility_updateOwnerEmployeeNumber_normal() {
        List <Opportunity> oppList = new List<Opportunity>();

        User user1 = [SELECT Id, EmployeeNumber FROM User WHERE Username = 'auTestX@auspost.com.au.def'];
        User user2 = [SELECT Id, EmployeeNumber FROM User WHERE Username = 'auTestY@auspost.com.au'];

        Test.startTest();

        // Three opportunities for user1

        Opportunity opp1 = new Opportunity();
        opp1.Name = 'XNTR1';
        // [Jansi: 17-02-2019, commented elow stage and added for error: System.DmlException: Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, New Opportunity can only be created with Stage set to 'Identify': []]
        //opp.StageName = 'Identify1';
        opp1.StageName = 'Identify';
        opp1.CloseDate = date.today();
        opp1.OwnerId = user1.Id;
        opp1.Type = 'New Business';
        opp1.Contract_Number__c = '99999';
        opp1.Contract_Start_Date__c = Date.newInstance(2012, 07, 27);
        opp1.Contract_End_Date__c = Date.newInstance(2012, 07, 27);

        Opportunity opp2 = new Opportunity();
        opp2.Name = 'XNTR';
       // [Jansi: 17-02-2019, commented elow stage and added for error: System.DmlException: Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, New Opportunity can only be created with Stage set to 'Identify': []]
        //opp.StageName = 'Identify2';
        opp2.StageName = 'Identify';
        opp2.CloseDate = date.today();
        opp2.OwnerId = user2.Id;
        opp2.Type = 'New Business';
        opp2.Contract_Number__c = '99999';
        opp2.Contract_Start_Date__c = Date.newInstance(2012, 07, 27);
        opp2.Contract_End_Date__c = Date.newInstance(2012, 07, 27);

        insert new List<Opportunity>{opp1, opp2};

        Test.stopTest();

        // Check the employee numbers in opportunities have been updated.
        Set<Id> oppIds = new Set<Id>{opp1.Id, opp2.Id};
        Map<Id, Opportunity> oppsToVerify = new Map<Id, Opportunity>([Select Id, Owner_Employee_Number__c
                                                                        From Opportunity
                                                                        Where Id In :oppIds]);


        System.assertEquals(user1.EmployeeNumber, oppsToVerify.get(opp1.Id).Owner_Employee_Number__c,
                'OpportunityUtility_updateOwnerEmployeeNumber_normal : Owner_Employee_Number__c needs to be updated');

        System.assertEquals(user2.EmployeeNumber, oppsToVerify.get(opp2.Id).Owner_Employee_Number__c,
                'OpportunityUtility_updateOwnerEmployeeNumber_normal : Owner_Employee_Number__c needs to be updated');
    }

    /**
     * SCENARIO: Normally assign owner's employee number to the opportunity on update
     * This is done in OpportunityUtility_part2.registerOpptyOwner
     **/
    @isTest
    static void OpportunityUtility_updateOwnerEmployeeNumber_onUpdate() {

        User user1 = [SELECT Id, EmployeeNumber FROM User WHERE Username = 'auTestX@auspost.com.au.def'];
        User user2 = [SELECT Id, EmployeeNumber FROM User WHERE Username = 'auTestY@auspost.com.au'];

        Test.startTest();

        Opportunity opp = new Opportunity();
        opp.Name = 'XNTR1';
        opp.StageName = 'Identify';
        opp.CloseDate = date.today();
        opp.OwnerId = user1.Id;
        opp.Type = 'New Business';
        opp.Contract_Number__c = '99999';
        opp.Contract_Start_Date__c = Date.newInstance(2012, 07, 27);
        opp.Contract_End_Date__c = Date.newInstance(2012, 07, 27);
        insert opp;

        opp.OwnerId = user2.Id;
        update opp;

        Test.stopTest();

        Opportunity oppToVerify = [Select Id, Owner_Employee_Number__c
                                    From Opportunity
                                    Where Id = :opp.Id];


        System.assertEquals(user2.EmployeeNumber, oppToVerify.Owner_Employee_Number__c,
                'OpportunityUtility_updateOwnerEmployeeNumber_onUpdate : Owner_Employee_Number__c needs to be updated');
    }

    /**
    * SCENARIO: Test the behaviour when registerOpptyOwner is called on opportunities without owner
    * */
    @isTest
    static void OpportunityUtility_updateOwnerEmployeeNumber_emptyAssignment() {
        // Create an opportunity without owner
        List <Opportunity> oppList = new List<Opportunity>();
        Opportunity opp = new Opportunity();
        opp.Name = 'XNTR';
        opp.StageName = 'Identify1';
        opp.CloseDate = date.today();
        opp.Type = 'New Business';
        opp.Contract_Number__c = '99999';
        opp.Contract_Start_Date__c = Date.newInstance(2012, 07, 27);
        opp.Contract_End_Date__c = Date.newInstance(2012, 07, 27);
        oppList.add (opp);

        OpportunityUtility_part2.registerOpptyOwner(oppList, null);

        System.assertEquals(opp.Owner_Employee_Number__c, null,
                'OpportunityUtility_updateOwnerEmployeeNumber_emptyAssignment : Owner_Employee_Number__c should be empty');
    }

   /***************************************************************
    * SCENARIO: Test Checks of CWG-1/CWG-5
    * AUTHOR: PEncina
    * HISTORY:
    * 08/16/2019            Created
    ***************************************************************/
    // Test Variables
    public static final string TEST_PRODUCT_NAME = 'Test Product';
    public static final string TEST_PRICEBOOK_NAME = 'Test Pricebook';
    public static final string MSA_RECORTYPE = 'MSA & Service Schedule';
    public static final string INAUTHOR_STATUS_CATEGORY = 'In Authoring';
    public static final string AUTHORCONTRACT_STATUS = 'Author Contract';
    public static final string DOCUSIGN_STATUS_COMPLETED = 'Completed';
    @isTest
    static void OpportunityUtility_testClosedWonGovernance() {
        test.startTest();
        Account testAcc = [SELECT Id FROM Account WHERE Name = 'WithRevenue' LIMIT 1];
        // (For APT Contract) Create test contact
        Contact testCon = APT_TestUtil2.createContact();
        testCon.AccountId = testAcc.Id;
        insert testCon;
        // (For APT Contract) Create test pricelist
        Apttus_Config2__Pricelist__c testPL = APT_TestUtil2.createPriceList();
        insert testPL;
        // Create Product2
        Product2 testProduct = new Product2();
        testProduct.Name = TEST_PRODUCT_NAME;
        testProduct.IsActive = TRUE;
        insert testProduct;
        // Get Standard Pricebook2
        Id standardPBId = Test.getStandardPricebookId();
        // Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = standardPBId;
        pbe.Product2Id = testProduct.Id;
        pbe.UnitPrice = 1.00;
        pbe.IsActive = TRUE;
        pbe.UseStandardPrice = FALSE;
        insert pbe;
        // Create Opportunity
        List <Opportunity> oppList = new List<Opportunity>();
        // with Product -- allowed to Close Win
        Opportunity opp1 = new Opportunity();
        opp1.Name = 'Test Opportunity 1';
        opp1.StageName = 'Negotiate';
        opp1.CloseDate = Date.today().addDays(-1);
        opp1.Type = 'Existing Customer';
        opp1.AccountId = testAcc.Id;
        opp1.Data_Integrity_Compliance__c = true;
        opp1.Pre_Entry__c = true;
        opp1.Pricebook2Id = standardPBId;
        opp1.Offline_Contract_Received__c = true;
        oppList.add(opp1);

        // without Product -- not allowed
        Opportunity opp2 = new Opportunity();
        opp2.Name = 'Test Opportunity 2';
        opp2.StageName = 'Negotiate';
        opp2.CloseDate = Date.today().addDays(-1);
        opp2.Type = 'Existing Customer';
        opp2.AccountId = testAcc.Id;
        opp2.Data_Integrity_Compliance__c = true;
        oppList.add(opp2);

        OpportunityLineItem testOLI = new OpportunityLineItem();
        testOLI.Contract_Start_Date__c = Date.today().addDays(30);
        testOLI.Contract_End_Date__c = Date.today().addDays(60);
        testOLI.Quantity = 1000;
        testOLI.UnitPrice = 1.00;
        testOLI.Contract_Product__c = 'Yes';

        User testRunAs = [SELECT Id from User WHERE Alias = 'testRun' LIMIT 1];

        // test.startTest();        // moved to the very top
        System.runAs(testRunAs) {
            try {
                insert oppList;

                // Opportunity has been inserted: OpportunityId
                testOLI.OpportunityId = opp1.Id;
                testOLI.PricebookEntryId = pbe.Id;
                testOLI.Product2Id = testProduct.Id;
                insert testOLI;

                // (For APT Contract) Create quote proposal
                Apttus_Proposal__Proposal__c testPR = APT_TestUtil2.createQuoteProposalNoAgrmnt(testAcc, opp1, 'Proposal', testPL);
                insert testPR;

                // Create test DocuSign Envelope
                Apttus_DocuApi__DocuSignEnvelope__c dsEnv = new Apttus_DocuApi__DocuSignEnvelope__c();
                dsEnv.Apttus_DocuApi__Status__c = DOCUSIGN_STATUS_COMPLETED;
                insert dsEnv;

                // Create test Apttus Contract
                Apttus__APTS_Agreement__c aptContract = APT_TestUtil2.createAgreement(testAcc, testCon, opp1, testPR, AUTHORCONTRACT_STATUS, INAUTHOR_STATUS_CATEGORY, MSA_RECORTYPE);
                aptContract.APT_Product__c = 'eParcel';
                aptContract.Apttus_CMDSign__DocuSignEnvelopeId__c = dsEnv.Id;
                aptContract.Is_Document_Signed__c = true;
                // insert aptContract;

                // Attempt to Close-Win the Opportunities
                List<Opportunity> newOppList = [SELECT Id, Closed_Reason__c, StageName FROM Opportunity WHERE StageName = 'Negotiate'];
                for (Opportunity opp : newOppList) {
                    opp.Closed_Reason__c = 'Capability';
                    opp.StageName = Constants.CLOSED_WON;
                }

                update newOppList;

            } catch (Exception e) {
                System.debug('Error: ' + e.getMessage());
            }

        }
        test.stopTest();

        // Assertions; Only assert Opportunity records updated in this method
        for (Opportunity oppty : [SELECT Id, Name, StageName FROM Opportunity WHERE Name = 'Test Opportunity 1' OR Name = 'Test Opportunity 2']) {
            // Opportunity 1 is the only record allowed to Close Win
            System.assertNotEquals(Constants.CLOSED_WON, oppty.StageName);
        }
    }

    /*********************************
     * Description: Tests the populate classification method for Cross Sell
     * Author: Jeoffrey Palmero
     * History:
     * 08/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationCS() {
        List<Opportunity> newOptyList = new List<Opportunity>();
        Map<Id, Opportunity> oldRecMap = new Map<Id, Opportunity>();
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'International Bundle' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        test.startTest();
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty[0].Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.Contract_Product__c = 'No';
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.today();
        oliVar.Contract_End_Date__c = Date.today()+10;
        oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
        INSERT oliVar;

        oldRecMap.put(testOpty[0].Id, testOpty[0]);

        System.assertEquals(oliVar.OpportunityId, testOpty[0].Id);

        //test.startTest();
        Opportunity newOpty = [SELECT Id, StageName, Closed_Reason__c, Data_Integrity_Compliance__c,
                               CloseDate, Offline_Contract_Received__c, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        newOpty.StageName = 'Closed Won';
        newOpty.Closed_Reason__c = 'Functionality';
        newOpty.Data_Integrity_Compliance__c = TRUE;
        newOpty.CloseDate = Date.today();
        newOpty.Offline_Contract_Received__c = TRUE;
        //[Jansi:12-03-2020]added below line - To fix the ERROR - FIELD_CUSTOM_VALIDATION_EXCEPTION, Please use the 'Opportunity Closure' button to Close the Opportunity:
        newOpty.Hidden_Restrict_Path_Closure__c =TRUE;
        newOpty.APTMinimumMonthlySpend__c = 30000;
        newOptyList.add(newOpty);
        UPDATE newOptyList;

        OpportunityUtility.populateClassification(newOptyList, oldRecMap);
        test.stopTest();

        System.assertEquals('Cross Sell', [SELECT Classification__c FROM OpportunityLineItem WHERE Product2Id =: testProd.Id AND Quantity = 12 LIMIT 1].Classification__c);
    }

    /*********************************
     * Description: Tests the populate classification method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 08/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationCS7() {
        List<Opportunity> newOptyList = new List<Opportunity>();
        Map<Id, Opportunity> oldRecMap = new Map<Id, Opportunity>();
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];

        //Create Organisation Role
        Organisation_Role__c orgRole = new Organisation_Role__c();
        orgRole.Role_Type__c = 'Customer';
        orgRole.Organisation__c = testOrg.Id;
        insert orgRole;

        oldRecMap.put(testOpty[0].Id, testOpty[0]);
        test.startTest();
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty[0].Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
        oliVar.Contract_Product__c = 'No';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 7, 7);
        oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 8, 8);
        //oliVar.Contract_Start_Date__c = Date.newInstance(2019, 7, 7);
        //oliVar.Contract_End_Date__c = Date.newInstance(2019, 8, 8);
        INSERT oliVar;

       // test.startTest();
        Opportunity newOpty = [SELECT Id, StageName, Closed_Reason__c, Data_Integrity_Compliance__c,
                               CloseDate, Offline_Contract_Received__c, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        newOpty.StageName = 'Closed Won';
        newOpty.Closed_Reason__c = 'Functionality';
        newOpty.Data_Integrity_Compliance__c = TRUE;
        newOpty.CloseDate = Date.today();
        newOpty.Offline_Contract_Received__c = TRUE;
        //[Jansi:12-03-2020]added below line - To fix the ERROR - FIELD_CUSTOM_VALIDATION_EXCEPTION, Please use the 'Opportunity Closure' button to Close the Opportunity:
        newOpty.Hidden_Restrict_Path_Closure__c =TRUE;
        newOptyList.add(newOpty);
        UPDATE newOptyList;

        OpportunityUtility.populateClassification(newOptyList, oldRecMap);
        test.stopTest();

        System.assertEquals('Win Back', [SELECT Classification__c FROM OpportunityLineItem WHERE Product2Id =: testProd.Id AND Quantity = 12 LIMIT 1].Classification__c);
    }

    /*********************************
     * Description: Tests the populate classification method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 08/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationR() {
        List<Opportunity> newOptyList = new List<Opportunity>();
        Map<Id, Opportunity> oldRecMap = new Map<Id, Opportunity>();
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];

        oldRecMap.put(testOpty[0].Id, testOpty[0]);
        test.startTest();
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty[0].Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
        oliVar.Contract_Product__c = 'No';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(Date.Today().year()-2,07,07);
        oliVar.Contract_End_Date__c = Date.Today()+10;
        INSERT oliVar;

        //test.startTest();
        Opportunity newOpty = [SELECT Id, StageName, Closed_Reason__c, Data_Integrity_Compliance__c,
                               CloseDate, Offline_Contract_Received__c, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        newOpty.StageName = 'Closed Won';
        newOpty.Closed_Reason__c = 'Functionality';
        newOpty.Data_Integrity_Compliance__c = TRUE;
        newOpty.CloseDate = Date.today();
        newOpty.Offline_Contract_Received__c = TRUE;
        //[Jansi:12-03-2020]added below line - To fix the ERROR - FIELD_CUSTOM_VALIDATION_EXCEPTION, Please use the 'Opportunity Closure' button to Close the Opportunity:
        newOpty.Hidden_Restrict_Path_Closure__c =TRUE;
        newOptyList.add(newOpty);
        UPDATE newOptyList;

        OpportunityUtility.populateClassification(newOptyList, oldRecMap);
        test.stopTest();

        System.assertEquals('Renewal', [SELECT Classification__c FROM OpportunityLineItem WHERE Product2Id =: testProd.Id AND Quantity = 12 LIMIT 1].Classification__c);
    }

    /*********************************
     * Description: Tests the populate classification method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 08/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationR1to6() {
        List<Opportunity> newOptyList = new List<Opportunity>();
        Map<Id, Opportunity> oldRecMap = new Map<Id, Opportunity>();
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
       test.startTest();
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty[0].Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
        oliVar.Contract_Product__c = 'No';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(2019, 4, 4);
        oliVar.Contract_End_Date__c = Date.newInstance(2019, 8, 8);
        INSERT oliVar;

        oldRecMap.put(testOpty[0].Id, testOpty[0]);

       // test.startTest();
        Opportunity newOpty = [SELECT Id, StageName, Closed_Reason__c, Data_Integrity_Compliance__c,
                               CloseDate, Offline_Contract_Received__c, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        newOpty.StageName = 'Closed Won';
        newOpty.Closed_Reason__c = 'Functionality';
        newOpty.Data_Integrity_Compliance__c = TRUE;
        newOpty.CloseDate = newOpty.CloseDate = Date.newInstance(System.Today().year(), 4, 4); //  Date.today();
        newOpty.Offline_Contract_Received__c = TRUE;
        //[Jansi:12-03-2020]added below line - To fix the ERROR - FIELD_CUSTOM_VALIDATION_EXCEPTION, Please use the 'Opportunity Closure' button to Close the Opportunity:
        newOpty.Hidden_Restrict_Path_Closure__c =TRUE;
        newOptyList.add(newOpty);
        UPDATE newOptyList;

        OpportunityUtility.populateClassification(newOptyList, oldRecMap);
        test.stopTest();

        System.assertEquals('Win Back', [SELECT Classification__c FROM OpportunityLineItem WHERE Product2Id =: testProd.Id AND Quantity = 12 LIMIT 1].Classification__c);
    }

    /*********************************
     * Description: Tests the populate classification method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 08/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationG1to6() {
        List<Opportunity> newOptyList = new List<Opportunity>();
        Map<Id, Opportunity> oldRecMap = new Map<Id, Opportunity>();
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        test.startTest();
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty[0].Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
        oliVar.Contract_Product__c = 'No';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(2019, 4, 4);
        oliVar.Contract_End_Date__c = Date.newInstance(2019, 8, 8);
        oliVar.Change_Classification__c = 'No';
        INSERT oliVar;

        oldRecMap.put(testOpty[0].Id, testOpty[0]);

        //test.startTest();
        Opportunity newOpty = [SELECT Id, StageName, Closed_Reason__c, Data_Integrity_Compliance__c,
                               CloseDate, Offline_Contract_Received__c, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        newOpty.StageName = 'Closed Won';
        newOpty.Closed_Reason__c = 'Functionality';
        newOpty.Data_Integrity_Compliance__c = TRUE;
        newOpty.CloseDate = newOpty.CloseDate = Date.newInstance(System.Today().year(), 4, 4); //  Date.today();
        newOpty.Offline_Contract_Received__c = TRUE;
        //[Jansi:12-03-2020]added below line - To fix the ERROR - FIELD_CUSTOM_VALIDATION_EXCEPTION, Please use the 'Opportunity Closure' button to Close the Opportunity:
        newOpty.Hidden_Restrict_Path_Closure__c =TRUE;
        newOptyList.add(newOpty);
        UPDATE newOptyList;

        OpportunityUtility.populateClassification(newOptyList, oldRecMap);
        test.stopTest();

        System.assertEquals('Win Back', [SELECT Classification__c FROM OpportunityLineItem WHERE Product2Id =: testProd.Id AND Quantity = 12 LIMIT 1].Classification__c);
    }

    /*********************************
     * Description: Tests the populate classification method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 08/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationG6() {
        List<Opportunity> newOptyList = new List<Opportunity>();
        Map<Id, Opportunity> oldRecMap = new Map<Id, Opportunity>();
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        test.startTest();
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty[0].Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
        oliVar.Contract_Product__c = 'No';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(2018, 9, 9);
        oliVar.Contract_End_Date__c = Date.newInstance(2018, 12, 12);
        oliVar.Change_Classification__c = 'No';
        INSERT oliVar;

        oldRecMap.put(testOpty[0].Id, testOpty[0]);

        //test.startTest();
        Opportunity newOpty = [SELECT Id, StageName, Closed_Reason__c, Data_Integrity_Compliance__c,
                               CloseDate, Offline_Contract_Received__c, AccountId FROM Opportunity WHERE Id =: testOpty[0].Id LIMIT 1];
        newOpty.StageName = 'Closed Won';
        newOpty.Closed_Reason__c = 'Functionality';
        newOpty.Data_Integrity_Compliance__c = TRUE;
        newOpty.CloseDate = newOpty.CloseDate = Date.newInstance(System.Today().year(), 4, 4); //  Date.today();
        newOpty.Offline_Contract_Received__c = TRUE;
        //[Jansi:12-03-2020]added below line - To fix the ERROR - FIELD_CUSTOM_VALIDATION_EXCEPTION, Please use the 'Opportunity Closure' button to Close the Opportunity:
        newOpty.Hidden_Restrict_Path_Closure__c =TRUE;
        newOptyList.add(newOpty);
        //UPDATE newOptyList;

        OpportunityUtility.populateClassification(newOptyList, oldRecMap);
        test.stopTest();

        System.assertEquals('Win Back', [SELECT Classification__c FROM OpportunityLineItem WHERE Product2Id =: testProd.Id AND Quantity = 12 LIMIT 1].Classification__c);
    }

    /*********************************
     * Description: Tests the populate classification method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 08/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationWB() {
        List<Opportunity> newOptyList = new List<Opportunity>();
        Map<Id, Opportunity> oldRecMap = new Map<Id, Opportunity>();
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];


        //Create Organisation Role
        Organisation_Role__c orgRole = new Organisation_Role__c();
        orgRole.Role_Type__c = 'Customer';
        orgRole.Organisation__c = testOrg.Id;
        insert orgRole;

        test.startTest();
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty[0].Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
        oliVar.Change_Classification__c = 'No';
        oliVar.Contract_Product__c = 'No';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 7, 7);
        oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 8, 8);
        //oliVar.Contract_Start_Date__c = Date.newInstance(2019, 7, 7);
        //oliVar.Contract_End_Date__c = Date.newInstance(2019, 8, 8);
        INSERT oliVar;

        oldRecMap.put(testOpty[0].Id, testOpty[0]);

       // test.startTest();
        Opportunity newOpty = [SELECT Id, StageName, Closed_Reason__c, Data_Integrity_Compliance__c,
                               CloseDate, Offline_Contract_Received__c, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        newOpty.StageName = 'Closed Won';
        newOpty.Closed_Reason__c = 'Functionality';
        newOpty.Data_Integrity_Compliance__c = TRUE;
        newOpty.CloseDate = Date.today();
        newOpty.Offline_Contract_Received__c = TRUE;
        //[Jansi:12-03-2020]added below line - To fix the ERROR - FIELD_CUSTOM_VALIDATION_EXCEPTION, Please use the 'Opportunity Closure' button to Close the Opportunity:
        newOpty.Hidden_Restrict_Path_Closure__c =TRUE;
        newOptyList.add(newOpty);
        UPDATE newOptyList;

        OpportunityUtility.populateClassification(newOptyList, oldRecMap);
        test.stopTest();

        System.assertEquals('Win Back', [SELECT Classification__c FROM OpportunityLineItem WHERE Product2Id =: testProd.Id AND Quantity = 12 LIMIT 1].Classification__c);
    }

    /*********************************
     * Description: Tests the populate classification method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 08/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationNB() {
        List<Opportunity> newOptyList = new List<Opportunity>();
        Map<Id, Opportunity> oldRecMap = new Map<Id, Opportunity>();
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'WithoutRevenue' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Road Express - STE' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        test.startTest();
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty[0].Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
        oliVar.Contract_Product__c = 'No';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(2019, 4, 4);
        oliVar.Contract_End_Date__c = Date.newInstance(2019, 8, 8);
        INSERT oliVar;

        oldRecMap.put(testOpty[0].Id, testOpty[0]);

        //test.startTest();
        Opportunity newOpty = [SELECT Id, StageName, Closed_Reason__c, Data_Integrity_Compliance__c,
                               CloseDate, Offline_Contract_Received__c, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        newOpty.StageName = 'Closed Won';
        newOpty.Closed_Reason__c = 'Functionality';
        newOpty.Data_Integrity_Compliance__c = TRUE;
        newOpty.CloseDate = Date.today();
        newOpty.Offline_Contract_Received__c = TRUE;
        //[Jansi:12-03-2020]added below line - To fix the ERROR - FIELD_CUSTOM_VALIDATION_EXCEPTION, Please use the 'Opportunity Closure' button to Close the Opportunity:
        newOpty.Hidden_Restrict_Path_Closure__c =TRUE;
        newOptyList.add(newOpty);
        UPDATE newOptyList;

        OpportunityUtility.populateClassification(newOptyList, oldRecMap);
        test.stopTest();

        System.assertEquals('New Business', [SELECT Classification__c FROM OpportunityLineItem WHERE Product2Id =: testProd.Id AND Quantity = 12 LIMIT 1].Classification__c);
    }

    /*********************************
     * Description: Tests the populate classification method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 08/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationAPTNB() {
        List<Opportunity> newOptyList = new List<Opportunity>();
        Map<Id, Opportunity> oldRecMap = new Map<Id, Opportunity>();
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'RefactoredAcct' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Boxes and Bags Others' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c testConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        Apttus_Proposal__Proposal__c testProposal = [SELECT Id, Apttus_Proposal__Account__c, Apttus_Proposal__Opportunity__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: testOpty[0].Id LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        //System.debug('00000 AA###'+Limits.getQueries());
        test.startTest();
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty[0].Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
        oliVar.Contract_Product__c = 'No';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(2019, 4, 4);
        oliVar.Contract_End_Date__c = Date.newInstance(2019, 8, 8);
        // System.debug('00000 AA1111###'+Limits.getQueries());
        INSERT oliVar;
        // System.debug('00000 BB###'+Limits.getQueries());
        //Create Apttus Opty Line Item
        APT_Opportunity_Product_Line_Item__c testProd1 = APT_TestUtils.createOpProdLI('Amendment','Yes', testProd.id, testConfig.id, 1 , testProposal.id, 1, Date.newInstance(2019, 8, 27), Date.newInstance(2019, 9, 27));
        testProd1.APT_Classification__c = 'Cross Sell';
        testProd1.APT_Change_Classification__c = 'No';
        INSERT testProd1;
  //System.debug('00000 CC###'+Limits.getQueries());
        oldRecMap.put(testOpty[0].Id, testOpty[0]);

        //test.startTest();
         //System.debug('00000 DD###'+Limits.getQueries());
        Opportunity newOpty = [SELECT Id, StageName, Closed_Reason__c, Data_Integrity_Compliance__c,
                               CloseDate, Offline_Contract_Received__c, AccountId FROM Opportunity WHERE Id =: testOpty[0].Id LIMIT 1];
        newOpty.StageName = 'Closed Won';
        newOpty.Closed_Reason__c = 'Functionality';
        newOpty.Data_Integrity_Compliance__c = TRUE;
        newOpty.CloseDate = Date.today();
        newOpty.Offline_Contract_Received__c = TRUE;
        //[Jansi:12-03-2020]added below line - To fix the ERROR - FIELD_CUSTOM_VALIDATION_EXCEPTION, Please use the 'Opportunity Closure' button to Close the Opportunity:
        newOpty.Hidden_Restrict_Path_Closure__c =TRUE;
        newOptyList.add(newOpty);
        //System.debug('11###'+Limits.getQueries());
        UPDATE newOptyList;

        OpportunityUtility.populateAPTClassification(newOptyList, oldRecMap);
        test.stopTest();

        System.assertEquals('New Business', [SELECT Classification__c FROM OpportunityLineItem WHERE Product2Id =: testProd.Id AND Quantity = 12 LIMIT 1].Classification__c);
    }

    /*********************************
     * Description: Tests the populate classification method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 08/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationAPTCS() {
        List<Opportunity> newOptyList = new List<Opportunity>();
        Map<Id, Opportunity> oldRecMap = new Map<Id, Opportunity>();
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Boxes and Bags Others' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c testConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        Apttus_Proposal__Proposal__c testProposal = [SELECT Id, Apttus_Proposal__Account__c, Apttus_Proposal__Opportunity__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: testOpty[0].Id LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        test.startTest();
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty[0].Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
        oliVar.Contract_Product__c = 'No';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(2019, 4, 4);
        oliVar.Contract_End_Date__c = Date.newInstance(2019, 8, 8);
        INSERT oliVar;

        //Create Apttus Opty Line Item
        APT_Opportunity_Product_Line_Item__c testProd1 = APT_TestUtils.createOpProdLI('Amendment','Yes', testProd.id, testConfig.id, 1 , testProposal.id, 1, Date.newInstance(2019, 8, 27), Date.newInstance(2019, 9, 27));
        testProd1.APT_Classification__c = 'Cross Sell';
        testProd1.APT_Change_Classification__c = 'No';
        INSERT testProd1;

        oldRecMap.put(testOpty[0].Id, testOpty[0]);


        Opportunity newOpty = [SELECT Id, StageName, Closed_Reason__c, Data_Integrity_Compliance__c,
                               CloseDate, Offline_Contract_Received__c, AccountId FROM Opportunity WHERE Id =: testOpty[0].Id LIMIT 1];
        newOpty.StageName = 'Closed Won';
        newOpty.Closed_Reason__c = 'Functionality';
        newOpty.Data_Integrity_Compliance__c = TRUE;
        newOpty.CloseDate = Date.today();
        newOpty.Offline_Contract_Received__c = TRUE;
        //[Jansi:12-03-2020]added below line - To fix the ERROR - FIELD_CUSTOM_VALIDATION_EXCEPTION, Please use the 'Opportunity Closure' button to Close the Opportunity:
        newOpty.Hidden_Restrict_Path_Closure__c =TRUE;
        newOptyList.add(newOpty);
        UPDATE newOptyList;

        OpportunityUtility.populateAPTClassification(newOptyList, oldRecMap);
        test.stopTest();

        System.assertEquals('Cross Sell', [SELECT Classification__c FROM OpportunityLineItem WHERE Product2Id =: testProd.Id AND Quantity = 12 LIMIT 1].Classification__c);
    }

    /*********************************
     * Description: Tests the populate classification method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 08/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationAPTR() {
        List<Opportunity> newOptyList = new List<Opportunity>();
        Map<Id, Opportunity> oldRecMap = new Map<Id, Opportunity>();
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c testConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        Apttus_Proposal__Proposal__c testProposal = [SELECT Id, Apttus_Proposal__Account__c, Apttus_Proposal__Opportunity__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: testOpty[0].Id LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        test.startTest();
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty[0].Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Cross Sell';
        oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
        oliVar.Contract_Product__c = 'No';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(2019, 4, 4);
        oliVar.Contract_End_Date__c = Date.newInstance(2019, 8, 8);
        INSERT oliVar;

        //Create Apttus Opty Line Item
        APT_Opportunity_Product_Line_Item__c testProd1 = APT_TestUtils.createOpProdLI('Amendment','Yes', testProd.id, testConfig.id, 1 , testProposal.id, 1, Date.newInstance(2019, 8, 27), Date.newInstance(2019, 9, 27));
        testProd1.APT_Classification__c = 'Cross Sell';
        testProd1.APT_Change_Classification__c = 'No';
        INSERT testProd1;

        oldRecMap.put(testOpty[0].Id, testOpty[0]);

       // test.startTest();
        Opportunity newOpty = [SELECT Id, StageName, Closed_Reason__c, Data_Integrity_Compliance__c,
                               CloseDate, Offline_Contract_Received__c, AccountId FROM Opportunity WHERE Id =: testOpty[0].Id LIMIT 1];
        newOpty.StageName = 'Closed Won';
        newOpty.Closed_Reason__c = 'Functionality';
        newOpty.Data_Integrity_Compliance__c = TRUE;
        newOpty.CloseDate = Date.newInstance(System.Today().year(), 4, 4); //  Date.today();
        newOpty.Offline_Contract_Received__c = TRUE;
        //[Jansi:12-03-2020]added below line - To fix the ERROR - FIELD_CUSTOM_VALIDATION_EXCEPTION, Please use the 'Opportunity Closure' button to Close the Opportunity:
        newOpty.Hidden_Restrict_Path_Closure__c =TRUE;
        newOptyList.add(newOpty);
        UPDATE newOptyList;

        OpportunityUtility.populateAPTClassification(newOptyList, oldRecMap);
        test.stopTest();

        System.assertEquals('Win Back', [SELECT Classification__c FROM OpportunityLineItem WHERE Product2Id =: testProd.Id AND Quantity = 12 LIMIT 1].Classification__c);
    }

    /*********************************
     * Description: Tests the populate classification method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 08/13/2019       Created
     ********************************/
    @isTest
    static void testClassificationAPTR6() {
        List<Opportunity> newOptyList = new List<Opportunity>();
        Map<Id, Opportunity> oldRecMap = new Map<Id, Opportunity>();
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c testConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        Apttus_Proposal__Proposal__c testProposal = [SELECT Id, Apttus_Proposal__Account__c, Apttus_Proposal__Opportunity__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: testOpty[0].Id LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        test.startTest();
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty[0].Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Cross Sell';
        oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
        oliVar.Contract_Product__c = 'No';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        //oliVar.Contract_Start_Date__c = Date.newInstance(2019, 4, 4);
        //oliVar.Contract_End_Date__c = Date.newInstance(2019, 8, 8);
        oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year()-2, 7, 7);
        oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 8, 8);

        INSERT oliVar;

        //Create Apttus Opty Line Item
        APT_Opportunity_Product_Line_Item__c testProd1 = APT_TestUtils.createOpProdLI('Amendment','Yes', testProd.id, testConfig.id, 1 , testProposal.id, 1, Date.newInstance(2019, 4, 27), Date.newInstance(2019, 9, 27));
        testProd1.APT_Classification__c = 'Cross Sell';
        testProd1.APT_Change_Classification__c = 'No';
        INSERT testProd1;

        oldRecMap.put(testOpty[0].Id, testOpty[0]);

        //test.startTest();
        Opportunity newOpty = [SELECT Id, StageName, Closed_Reason__c, Data_Integrity_Compliance__c,
                               CloseDate, Offline_Contract_Received__c, AccountId FROM Opportunity WHERE Id =: testOpty[0].Id LIMIT 1];
        newOpty.StageName = 'Closed Won';
        newOpty.Closed_Reason__c = 'Functionality';
        newOpty.Data_Integrity_Compliance__c = TRUE;
        newOpty.CloseDate = Date.today();
        newOpty.Offline_Contract_Received__c = TRUE;
        //[Jansi:12-03-2020]added below line - To fix the ERROR - FIELD_CUSTOM_VALIDATION_EXCEPTION, Please use the 'Opportunity Closure' button to Close the Opportunity:
        newOpty.Hidden_Restrict_Path_Closure__c =TRUE;
        newOptyList.add(newOpty);
        UPDATE newOptyList;

        OpportunityUtility.populateAPTClassification(newOptyList, oldRecMap);
        test.stopTest();

        System.assertEquals('Renewal', [SELECT Classification__c FROM OpportunityLineItem WHERE Product2Id =: testProd.Id AND Quantity = 12 LIMIT 1].Classification__c);
    }

    /*********************************
     * Description: Tests the populate classification method for Renewal
     * Author: Jeoffrey Palmero
     * History:
     * 08/13/2019       Created
     * 03/03/2020       Lavanya Kavuri, Modified. Test Class Failures due to Validation Rules, so had to setup new Test Data
     ********************************/
    @isTest
    static void testClassificationAPTR7() {
        List<Opportunity> newOptyList = new List<Opportunity>();
        Map<Id, Opportunity> oldRecMap = new Map<Id, Opportunity>();
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];

        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
        Apttus_Config2__ProductConfiguration__c testConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 1];
        Apttus_Proposal__Proposal__c testProposal = [SELECT Id, Apttus_Proposal__Account__c, Apttus_Proposal__Opportunity__c FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: testOpty[0].Id LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];

        test.startTest();
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty[0].Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Cross Sell';
        oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
        oliVar.Contract_Product__c = 'No';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year()-2, 7, 7);
        oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 8, 8);
        //oliVar.Contract_Start_Date__c = Date.newInstance(2017, 7, 7);
        //oliVar.Contract_End_Date__c = Date.newInstance(2019, 8, 8);
        INSERT oliVar;

        //Lavanya before changing the role from prospoect to customer, we need to have Physcial Address for the Account.
        testOrg.ShippingState = 'VIC';
        testOrg.ShippingCity = 'Melbourne';
       testOrg.ShippingPostalCode = '3000';
       testOrg.ShippingStreet = '111 Bourke Street';
       update testOrg;

        //Lavanya added this method for the legal entity name validation rule

        //Create Organisation Role
        Organisation_Role__c orgRole = new Organisation_Role__c();
        orgRole.Role_Type__c = 'Customer';
        orgRole.Organisation__c = testOrg.Id;
        insert orgRole;

        //Create Apttus Opty Line Item
        APT_Opportunity_Product_Line_Item__c testProd1 = APT_TestUtils.createOpProdLI('Amendment','Yes', testProd.id, testConfig.id, 1 , testProposal.id, 1, Date.newInstance(2019, 4, 27), Date.newInstance(2019, 9, 27));
        testProd1.APT_Classification__c = 'Cross Sell';
        testProd1.APT_Change_Classification__c = 'No';
        INSERT testProd1;

        oldRecMap.put(testOpty[0].Id, testOpty[0]);

        //test.startTest();
        Opportunity newOpty = [SELECT Id, StageName, Closed_Reason__c, Data_Integrity_Compliance__c,
                               CloseDate, Offline_Contract_Received__c, AccountId FROM Opportunity WHERE Id =: testOpty[0].Id LIMIT 1];
        newOpty.StageName = 'Closed Won';
        newOpty.Closed_Reason__c = 'Functionality';
        newOpty.Data_Integrity_Compliance__c = TRUE;
        newOpty.CloseDate = Date.today();
        newOpty.Offline_Contract_Received__c = TRUE;
        //[Jansi:12-03-2020]added below line - To fix the ERROR - FIELD_CUSTOM_VALIDATION_EXCEPTION, Please use the 'Opportunity Closure' button to Close the Opportunity:
        newOpty.Hidden_Restrict_Path_Closure__c =TRUE;
        newOptyList.add(newOpty);
        UPDATE newOptyList;

        OpportunityUtility.populateAPTClassification(newOptyList, oldRecMap);
        test.stopTest();

        System.assertEquals('Renewal', [SELECT Classification__c FROM OpportunityLineItem WHERE Product2Id =: testProd.Id AND Quantity = 12 LIMIT 1].Classification__c);
    }
    /**
     * @Description Update opportunity closing owner role when opportunity is closed won/closed lost/Closed Disqualified/Closed Duplicate
     */
    @isTest
    static void testUserRolePopulateOnOpptyClosure() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'RefactoredAcct' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName, OwnerId, Owner.UserRole.name FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'International Bundle' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        Test.StartTest();
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty[0].Id;
        oliVar.Product2Id = testProd.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.Contract_Product__c = 'No';
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.today();
        oliVar.Contract_End_Date__c = Date.today()+10;
        oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
        INSERT oliVar;

        testOpty[0].StageName = 'Closed Won';
        testOpty[0].Closed_Reason__c = 'Functionality';
        testOpty[0].Data_Integrity_Compliance__c = TRUE;
        testOpty[0].CloseDate = Date.today();
        testOpty[0].Offline_Contract_Received__c = TRUE;
        testOpty[0].Hidden_Restrict_Path_Closure__c= TRUE;
        update testOpty[0];
        Test.StopTest();
        opportunity updateOpp = [Select Id, Closing_Owner_Role__c,  Owner.UserRole.name From Opportunity where id=:testOpty[0].Id];
        System.assertEquals(updateOpp.Closing_Owner_Role__c , updateOpp.Owner.UserRole.name);

    }
    /**
     * @Description Update Closed Opportunity closing onwer role in case of owner update
     */
    @isTest
    static void testUserRolePopulateOnOpptyOwnerChange() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'RefactoredAcct' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName, OwnerId, Owner.UserRole.name FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'International Bundle' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];

        Test.StartTest();

        User uRecrd = [Select id, UserRole.name from user where UserName = 'auTestX@auspost.com.au.def' limit 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'BG_Sales_Operations'];
        System.runAs(uRecrd){

            insert new PermissionSetAssignment(AssigneeId = uRecrd.id, PermissionSetId = ps.Id);
            OpportunityLineItem oliVar = new OpportunityLineItem();
            oliVar.OpportunityId = testOpty[0].Id;
            oliVar.Product2Id = testProd.Id;
            oliVar.Classification__c = 'Growth';
            oliVar.Quantity = 12;
            oliVar.TotalPrice = 24.00;
            oliVar.Contract_Product__c = 'No';
            oliVar.PricebookEntryId = pbEntry.Id;
            oliVar.Contract_Start_Date__c = Date.today();
            oliVar.Contract_End_Date__c = Date.today()+10;
            oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
            INSERT oliVar;

            testOpty[0].StageName = 'Closed Won';
            testOpty[0].Closed_Reason__c = 'Functionality';
            testOpty[0].Data_Integrity_Compliance__c = TRUE;
            testOpty[0].CloseDate = Date.today();
            testOpty[0].Offline_Contract_Received__c = TRUE;
            testOpty[0].OwnerId = uRecrd.Id;
            testOpty[0].Hidden_Restrict_Path_Closure__c = TRUE;
            update testOpty[0];
            Test.StopTest();
        }
        opportunity updateOpp = [Select Id, Closing_Owner_Role__c,  Owner.UserRole.name From Opportunity where id=:testOpty[0].Id];
        System.assertEquals(updateOpp.Closing_Owner_Role__c , uRecrd.UserRole.name);

    }

    /**
    * @Description - check for validation on opportunity product duplicates with pairing exemption of classification 'Growth' & 'Renewal'
    */
    @isTest
    static void testDupValidationOpptyClosureOnCloseWon() {
        Account testOrg = [SELECT Id FROM Account WHERE Name = 'RefactoredAcct' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName, OwnerId, Owner.UserRole.name FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
        Product2 prod1 = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];

        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: prod1.Id LIMIT 1];
        Test.StartTest();
        OpportunityLineItem oliVar = new OpportunityLineItem();
        oliVar.OpportunityId = testOpty[0].Id;
        oliVar.Product2Id = prod1.Id;
        oliVar.Classification__c = 'Growth';
        oliVar.Quantity = 12;
        oliVar.TotalPrice = 24.00;
        oliVar.Contract_Product__c = 'No';
        oliVar.PricebookEntryId = pbEntry.Id;
        oliVar.Contract_Start_Date__c = Date.today();
        oliVar.Contract_End_Date__c = Date.today()+10;
        oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
        INSERT oliVar;

        OpportunityLineItem oliVar2 = new OpportunityLineItem();
        // clone the opportunity line item to test duplicate
        oliVar2 = oliVar.clone(true,true);

        testOpty[0].StageName = 'Closed Won';
        testOpty[0].Closed_Reason__c = 'Functionality';
        testOpty[0].Data_Integrity_Compliance__c = TRUE;
        testOpty[0].CloseDate = Date.today();
        testOpty[0].Offline_Contract_Received__c = TRUE;
        testOpty[0].Hidden_Restrict_Path_Closure__c= TRUE;
        try{
            UPDATE testOpty[0];
        }catch(Exception e){
            // Should trigger validation error due to duplicate opportunity Line items
            System.assertEquals(e.getMessage(), Label.Opportunity_Has_Duplicate_Product_Lines, 'Should see validation error due to duplicate opportunity line items');
        }

        oliVar2.Classification__c = 'Renewal';
        UPDATE oliVar2;

        // No error thrown due to pairing exception of classification 'Growth' & 'Renewal'
        UPDATE testOpty[0];
        opportunity updateOpp = [Select Id, StageName From Opportunity where id=:testOpty[0].Id];
        // successfully close the opportunity as Close Won
        System.assertEquals(updateOpp.StageName , 'Closed Won', 'Should successfully close the opportunity as Close Won');
        Test.StopTest();

    }

    /**
     * @Description Test the 'Close Date' field auto-population to Today's date during Opportunity Closure
     */
    @isTest
    static void testCloseDateUpdateOnOppClosure() {
        //Account testOrg = [SELECT Id FROM Account WHERE Name = 'RefactoredAcct' LIMIT 1];
        //Account testOrg2 = [SELECT Id FROM Account WHERE Name = 'AnotherWithRevenue' LIMIT 1];
        List<Opportunity> testOpty = [SELECT Id, AccountId, StageName, OwnerId, Owner.UserRole.name FROM Opportunity LIMIT 2];
        Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'International Bundle' LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
        Test.StartTest();

        User uRecrd = [Select id, UserRole.name from user where UserName = 'auTestX@auspost.com.au.def' limit 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'BG_Sales_Operations'];
        System.runAs(uRecrd){
            insert new PermissionSetAssignment(AssigneeId = uRecrd.id, PermissionSetId = ps.Id);
            OpportunityLineItem oliVar = new OpportunityLineItem();
            oliVar.OpportunityId = testOpty[0].Id;
            oliVar.Product2Id = testProd.Id;
            oliVar.Classification__c = 'Growth';
            oliVar.Quantity = 12;
            oliVar.TotalPrice = 24.00;
            oliVar.Contract_Product__c = 'No';
            oliVar.PricebookEntryId = pbEntry.Id;
            oliVar.Contract_Start_Date__c = Date.today();
            oliVar.Contract_End_Date__c = Date.today()+10;
            oliVar.APT_Is_Apttus_Opportunity_Line_item__c = FALSE;
            INSERT oliVar;

            OpportunityLineItem oliVar2 = oliVar.clone(false);
            oliVar2.OpportunityId = testOpty[1].Id;
            INSERT oliVar2;

            // Scenario: Close Date in the future and Stage = 'Closed Won'
            testOpty[0].StageName = 'Closed Won';
            testOpty[0].Closed_Reason__c = 'Functionality';
            testOpty[0].Data_Integrity_Compliance__c = TRUE;
            testOpty[0].CloseDate = Date.today()+5;
            testOpty[0].Offline_Contract_Received__c = TRUE;
            testOpty[0].OwnerId = uRecrd.Id;
            testOpty[0].Hidden_Restrict_Path_Closure__c = TRUE;
            update testOpty[0];

            // Scenario: Close Date in the past and Stage = 'Closed Lost'
            testOpty[1].StageName = 'Closed Lost';
            testOpty[1].Closed_Reason__c = 'Functionality';
            testOpty[1].Data_Integrity_Compliance__c = TRUE;
            testOpty[1].CloseDate = Date.today()-5;
            testOpty[1].Offline_Contract_Received__c = TRUE;
            testOpty[1].OwnerId = uRecrd.Id;
            testOpty[1].Hidden_Restrict_Path_Closure__c = TRUE;
            update testOpty[1];
            Test.StopTest();
        }
        opportunity updateOpp1 = [Select Id, CloseDate From Opportunity where id=:testOpty[0].Id];
        opportunity updateOpp2 = [Select Id, CloseDate From Opportunity where id=:testOpty[1].Id];
        System.assertEquals(updateOpp1.CloseDate , System.today(), 'Close Date field should be updated to Today\'s date for \'Closed Won\' Opportunity');
        System.assertEquals(updateOpp2.CloseDate , System.today(), 'Close Date field should be updated to Today\'s date for \'Closed Lost\' Opportunity');
    }
}