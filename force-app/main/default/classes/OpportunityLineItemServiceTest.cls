/****************************************
* Description: Test Class for the OpportunityLineItemService class
* Author: JPalmero
* History
* 09/03/2019 Created
* 09/13/2019 Added test methods for populateClassification()
* 05/03/2020 seth.p.heang@accenture.com Updated Test methods with dynamic dateTime test data to fix test failure due to static dateTime
* 01/06/2020 shashwat.a.nath@accenture.com Updated Methods to assign PS to running user to bypass Opportunity Creation Restriction in Classic
* 28/06/2022 	KMcGuire	Modified for including related account sales in OPC classification
* 29/2/2023	Ken McGurie	allow for OPC override and forward planning
* 2023-05-04	Ken McGuire - Resolve testing issues by making the date of opp line items relative to current FY
* 2023-08-24 - Ranjeewa Silva - Updates to existing tests to ensure test data conforms to new sales pipeline governance validations on Opportunity.
7/10/2024 Ken McGuire Removed obsolete line item opc classification methods.
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
		Integer yearAdjust = Date.today().month() >6 ? 0 : -1;
		Profile covSales = [SELECT Id FROM Profile WHERE Name = 'Coverage Sales'];

		User user1 = new User(
				Alias = 'CovSal', Email = 'test@auspost.com.au',
				EmailEncodingKey = 'UTF-8', LastName = 'xTesting', LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US', ProfileId = covSales.Id, isActive = true,
				TimeZoneSidKey = 'America/Los_Angeles', UserName = 'auTestX@auspost.com.au.def',
				EmployeeNumber = '10000'
		);

		INSERT user1;

		NominalTradeAmount__c ntAmount = NominalTradeAmount__c.getInstance();
		ntAmount.Amount__c = 99;
		upsert ntAmount;

		SystemSettings__c sysCS = SystemSettings__c.getInstance();
		sysCS.Disable_Triggers__c = FALSE;
		upsert sysCS;

		// Create test Accounts

		Account accountWithoutRevenue = APT_TestUtil2.createOrganisation();
		accountWithoutRevenue.Name = 'Without Revenue';
		accIdSet.add(accountWithoutRevenue.Id);
		accVarList.add(accountWithoutRevenue);

		Account accountBelowNominalRevenue = APT_TestUtil2.createOrganisation();
		accountBelowNominalRevenue.Name = 'Below Nominal Revenue';
		accIdSet.add(accountBelowNominalRevenue.Id);
		accVarList.add(accountBelowNominalRevenue);

		Account accountWithNominalRevenue = APT_TestUtil2.createOrganisation();
		accountWithNominalRevenue.Name = 'With Nominal Revenue';
		accIdSet.add(accountWithNominalRevenue.Id);
		accVarList.add(accountWithNominalRevenue);

		Account refactoredAccount = APT_TestUtil2.createOrganisation();
		refactoredAccount.Name = 'Refactored';
		accIdSet.add(refactoredAccount.Id);
		accVarList.add(refactoredAccount);

		insert accVarList;

		// create key contact for opportunity
		Contact keyContact = ApplicationTestDataFactory.getContacts(1, accountWithNominalRevenue.Id, false)[0];
		keyContact.FirstName = 'testfname';
		keyContact.LastName = 'testlname';
		keyContact.Email = 'testemail@invalid.invalid';
		insert keyContact;

		//Create Roles
		orgRoleList = [SELECT Id, Role_Type__c FROM Organisation_Role__c WHERE Organisation__c IN : accIdSet OR Role_Type__c =: 'Prospect'];
		for(Organisation_Role__c orgRole : orgRoleList){
			orgRole.Role_Type__c = 'Customer';
			newOrgRoleList.add(orgRole);
		}

		UPDATE newOrgRoleList;

		// Create test Opportunity
		Opportunity belowNominalOpportunity = APT_TestUtil2.createOpportunity(accountBelowNominalRevenue);
		belowNominalOpportunity.Pre_Entry__c = TRUE;
		belowNominalOpportunity.StageName = 'Identify';
		optyList.add(belowNominalOpportunity);

		Opportunity withoutRevenueOpportunity = APT_TestUtil2.createOpportunity(accountWithoutRevenue);
		withoutRevenueOpportunity.Pre_Entry__c = TRUE;
		withoutRevenueOpportunity.StageName = 'Identify';
		optyList.add(withoutRevenueOpportunity);

		Opportunity nominalRevenueOpportunity = APT_TestUtil2.createOpportunity(accountWithNominalRevenue);
		nominalRevenueOpportunity.Pre_Entry__c = TRUE;
		nominalRevenueOpportunity.Closed_Reason__c = 'Functionality';
		nominalRevenueOpportunity.StageName = 'Identify';
		optyList.add(nominalRevenueOpportunity);

		Opportunity refactoredOpportunity = APT_TestUtil2.createOpportunity(refactoredAccount);
		refactoredOpportunity.Pre_Entry__c = TRUE;
		refactoredOpportunity.Closed_Reason__c = 'Functionality';
		refactoredOpportunity.StageName = 'Identify';
		optyList.add(refactoredOpportunity);

		insert optyList;

		//create products
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

		//Create Budget_and_Revenue__c
		Budget_and_Revenue__c barObj = new Budget_and_Revenue__c();
		barObj.Name = 'Below Nominal Current Year';
		barObj.Organisation__c = accountBelowNominalRevenue.Id;
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
		barObj.Financial_Year__c = String.valueOf(currentYear+yearAdjust);

		barList.add(barObj);

		Budget_and_Revenue__c barObjPFY = new Budget_and_Revenue__c();
		barObjPFY.Name = 'Below Nominal Last Year';
		barObjPFY.Organisation__c = accountBelowNominalRevenue.Id;
		barObjPFY.Product__c = bundle3.Id;
		barObjPFY.Total_Revenue_Amount__c = 0;
		barObjPFY.Financial_Year__c = String.valueOf(currentYear+yearAdjust-1);

		barList.add(barObjPFY);


		Budget_and_Revenue__c barObj4 = new Budget_and_Revenue__c();
		barObj4.Name = 'Nominal Revenue Next Year';
		barObj4.Organisation__c = accountWithNominalRevenue.Id;
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
		barObj4.Financial_Year__c = String.valueOf(currentYear+yearAdjust+1);

		barList.add(barObj4);

 		Budget_and_Revenue__c barObj2 = new Budget_and_Revenue__c();
		barObj2.Name = 'Nominal Revenue current Year';
		barObj2.Organisation__c = accountWithNominalRevenue.Id;
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
		barObj2.Financial_Year__c = String.valueOf(currentYear+yearAdjust);

		barList.add(barObj2);

		Budget_and_Revenue__c barObj3 = new Budget_and_Revenue__c();
		barObj3.Name = 'Nominal Revenue One Year Ago';
		barObj3.Organisation__c = accountWithNominalRevenue.Id;
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
		barObj3.Financial_Year__c = String.valueOf(currentYear+yearAdjust-1);

		barList.add(barObj3);

		Budget_and_Revenue__c barObj6 = new Budget_and_Revenue__c();
		barObj6.Name = 'Nominal Revenue two years ago';
		barObj6.Organisation__c = accountWithNominalRevenue.Id;
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
		barObj6.Financial_Year__c = String.valueOf(currentYear+yearAdjust-2);

		barList.add(barObj6);

		Budget_and_Revenue__c barObj7 = new Budget_and_Revenue__c();
		barObj7.Name = 'Nominal Revenue three years ago';
		barObj7.Organisation__c = accountWithNominalRevenue.Id;
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
		barObj7.Financial_Year__c = String.valueOf(currentYear+yearAdjust-3);

		barList.add(barObj7);

		Budget_and_Revenue__c barObj5 = new Budget_and_Revenue__c();
		barObj5.Name = 'Refactored Revenue current year';
		barObj5.Organisation__c = refactoredAccount.Id;
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
		barObj5.Financial_Year__c = String.valueOf(currentYear+yearAdjust);

		barList.add(barObj5);

		insert barList;
 
	}
	/*********************************
	* Description: Tests the populateClassification() method for Cross Sell
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void testClassificationCS() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();
 
		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
		Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'International Bundle' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();

		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = testProd.Id;
		oliVar.Classification__c = Constants.CLSS_GROWTH;
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 24.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4); // Date.today();
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 14); // Date.today()+10;
		optyLIList.add(oliVar);

		test.startTest();
		//OpportunityLineItemService.populateClassification(optyLIList);
		test.stopTest();

		//System.assertEquals('Cross Sell', oliVar.Classification__c);


	}



	/*********************************
	* Description: Tests the populateClassification() method for Win Back
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void testClassificationWB() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();
		test.startTest();
 
		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
		Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Boxes and Bags Others' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();

		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = testProd.Id;
		oliVar.Classification__c = Constants.CLSS_GROWTH;
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 24.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4);// Date.today();
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 14); // Date.today()+10;
		optyLIList.add(oliVar);


		//OpportunityLineItemService.populateClassification(optyLIList);
		test.stopTest();

		//System.assertEquals('Win Back', oliVar.Classification__c);
	}

	/*********************************
	* Description: Tests the populateClassification() method for Win Back
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void testClassificationWB2() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();

 
		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
		Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Boxes and Bags Others' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();

		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = testProd.Id;
		oliVar.Classification__c = Constants.CLSS_GROWTH;
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 24.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4); // Date.newInstance(2019, 03, 01);
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 14); // Date.today()+10;
		optyLIList.add(oliVar);

		test.startTest();
		//OpportunityLineItemService.populateClassification(optyLIList);
		test.stopTest();

		//System.assertEquals('Win Back', oliVar.Classification__c);
	}

	/*********************************
	* Description: Tests the populateClassification() method for New Business
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void testClassificationNB() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();

 
		Account testOrg = [SELECT Id, Name FROM Account WHERE Name = 'Without Revenue' LIMIT 1];
		Opportunity testOpty = [SELECT Id FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Road Express - STE' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();

		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = testProd.Id;
		oliVar.Classification__c = Constants.CLSS_GROWTH;
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 24.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4);// Date.today();
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 14);//Date.today()+10;
		optyLIList.add(oliVar);

		test.startTest();
		//OpportunityLineItemService.populateClassification(optyLIList);
		test.stopTest();

		//System.assertEquals('New Business', oliVar.Classification__c);
	}

	/*********************************
	* Description: Tests the populateClassification() method for Renewal
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void testClassificationRR() {
		
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();

 
		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
		Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();

		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = testProd.Id;
		oliVar.Classification__c = Constants.CLSS_GROWTH;
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 24.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4);
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 8, 8);
		oliVar.Change_Classification__c = 'No';
		optyLIList.add(oliVar);

		test.startTest();
		//OpportunityLineItemService.populateClassification(optyLIList);
		test.stopTest();

		//System.assertEquals(Constants.CLSS_RENEWAL, oliVar.Classification__c);
	}

	/*********************************
	* Description: Tests the populateClassification() method for Growth
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
		static void testClassificationRG() {
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();
 
		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
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
		oliVar.OPCOverride__c = 'No';
		optyLIList.add(oliVar);

		test.startTest();
		//OpportunityLineItemService.populateClassification(optyLIList);
		test.stopTest();

		//System.assertEquals(Constants.CLSS_GROWTH, oliVar.Classification__c);
	}

	/*********************************
	* Description: Tests the populateClassification() method for Growth
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void testClassificationR7G() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();
 
		Account testOrg = [SELECT Id FROM Account WHERE Name = 'Below Nominal Revenue' LIMIT 1];
		Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
		Integer monthToUse = Date.today().month() >6 ? 7 : 4;
		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = testProd.Id;
		oliVar.Classification__c = 'Cross Sell';
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 24.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), monthToUse, monthToUse);
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year()+1, monthToUse+1, monthToUse+1);
		oliVar.Change_Classification__c = 'Yes';
		oliVar.OPCOverride__c = 'No';
		optyLIList.add(oliVar);


		test.startTest();
		//OpportunityLineItemService.populateClassification(optyLIList);
		test.stopTest();

		//System.assertEquals(Constants.CLSS_GROWTH, oliVar.Classification__c);
	}

	 /*********************************
	* Description: Tests the populateClassification() method for Renewal
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void testClassificationR7R() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();
 
		Account testOrg = [SELECT Id FROM Account WHERE Name = 'Below Nominal Revenue' LIMIT 1];
		Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
		Integer monthToUse = Date.today().month() >6 ? 7 : 4;
		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = testProd.Id;
		oliVar.Classification__c = 'Cross Sell';
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 24.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), monthToUse, monthToUse);
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), monthToUse+1, monthToUse+1);
		oliVar.Change_Classification__c = 'No';
		optyLIList.add(oliVar);


		test.startTest();
		//OpportunityLineItemService.populateClassification(optyLIList);
		test.stopTest();

		//System.assertEquals(Constants.CLSS_RENEWAL, oliVar.Classification__c);
	}

	/*********************************
	* Description: Tests the populateClassification() method for New Business
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void testClassificationNB2() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();

		Account testOrg = [SELECT Id FROM Account WHERE Name = 'Refactored' LIMIT 1];
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
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 7, 7);
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 8, 8);
		oliVar.Change_Classification__c = 'No';
		oliVar.OPCOverride__c = 'No';
		optyLIList.add(oliVar);

		test.startTest();
		//OpportunityLineItemService.populateClassification(optyLIList);
		test.stopTest();

		//System.assertEquals('New Business', oliVar.Classification__c);
	}

	/*********************************
	* Description: Tests the recalculateClassification() method for Renewal
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
		static void updateClassificationR() {
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();
 
		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
		Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
		Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();

		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = testProd.Id;
		oliVar.Classification__c = Constants.CLSS_GROWTH;
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 24.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4); // Date.today();
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 14); // Date.today()+10;

		oldRecMap.put(oliVar.Id, oliVar);
		INSERT oliVar;
		OpportunityLineItem newOpty = [SELECT Id, OpportunityId, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id,Change_Classification__c,OPCOverride__c
									 FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];
		oldRecMap.put(newOpty.id,newOpty);
		newOpty.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 12);// Date.today()+8;
		newOpty.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 19); // Date.today()+15;
		optyLIList.add(newOpty);



		test.startTest();
		//OpportunityLineItemService.recalculateClassification(optyLIList, oldRecMap);
		test.stopTest();
		//
		//System.assertEquals(Constants.CLSS_RENEWAL, newOpty.Classification__c);
	}

	/*********************************
	* Description: Tests the populateClassification() method for Growth
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void updateClassificationRG() {
		
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();
 
		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
		Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
		Map<Id,OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();

		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = testProd.Id;
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 93.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4);// Date.today();
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 10);// Date.today()+10;
		oliVar.Classification__c = Constants.CLSS_GROWTH;
		oliVar.Change_Classification__c = 'YES';
		INSERT oliVar;
		oldRecMap.put(oliVar.Id, oliVar);
		OpportunityLineItem newOpty = [SELECT Id, OpportunityId, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id,Change_Classification__c,OPCOverride__c
									 FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];
		newOpty.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 19); //Date.today()+15;
		UPDATE newOpty;

		optyLIList.add(newOpty);


		test.startTest();
		//OpportunityLineItemService.recalculateClassification(optyLIList, oldRecMap);
		test.stopTest();
		//
		//System.assertEquals(Constants.CLSS_GROWTH, newOpty.Classification__c);
	}
	/*********************************
	* Description: Tests the populateClassification() method for Renewal
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void updateClassificationR7() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();
 
		Account testOrg = [SELECT Id FROM Account WHERE Name = 'Below Nominal Revenue' LIMIT 1];
		Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
		Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();

		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = testProd.Id;
		oliVar.Classification__c = Constants.CLSS_GROWTH;
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 24.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 7, 7);
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 8, 8);

		INSERT oliVar;
		oldRecMap.put(oliVar.Id, oliVar);
		OpportunityLineItem newOpty = [SELECT Id, OpportunityId, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id,Change_Classification__c,OPCOverride__c
									 FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];

		newOpty.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4);
		newOpty.Contract_End_Date__c = Date.newInstance(System.Today().year(), 8, 16);
		UPDATE newOpty;

		optyLIList.add(newOpty);


		test.startTest();
		//OpportunityLineItemService.recalculateClassification(optyLIList, oldRecMap);
		test.stopTest();

		//System.assertEquals(Constants.CLSS_RENEWAL, newOpty.Classification__c);
	}

	/*********************************
	* Description: Tests the populateClassification() method for Renewal
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void updateClassificationR9() {
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();

		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
		Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();

	Integer monthToUse = Date.today().month() >6 ? 7 : 4;
		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = testProd.Id;
		oliVar.Classification__c = Constants.CLSS_GROWTH;
		oliVar.Change_Classification__c = 'Yes';
		oliVar.OPCOverride__c = 'No';
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 24.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), monthToUse, 4);
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), monthToUse+1, 16);
		INSERT oliVar;
		oldRecMap.put(oliVar.Id, oliVar);

		List<OpportunityLineItem> optyLIList = [SELECT Id, OpportunityId, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id,Change_Classification__c,OPCOverride__c
									 FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];

		OpportunityLineItem newOptyLI = optyLIList[0];


		newOptyLI.Contract_Start_Date__c = Date.newInstance(System.Today().year(), monthToUse, 9);
		newOptyLI.Contract_End_Date__c = Date.newInstance(System.Today().year(), monthToUse+1, 16);
		newOptyLI.Change_Classification__c = 'No';
		//UPDATE newOptyLI;

	//	System.assertEquals(Constants.CLSS_GROWTH, newOptyLI.Classification__c);
		test.startTest();
		//OpportunityLineItemService.recalculateClassification(optyLIList, oldRecMap);
		test.stopTest();
		//System.assertEquals(Constants.CLSS_RENEWAL, newOptyLI.Classification__c);

	}

	/*********************************
	* Description: Tests the populateClassification() method for Growth
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void updateClassificationR9G() {
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();

		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
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
 oliVar.Classification__c = Constants.CLSS_GROWTH;
		oliVar.Change_Classification__c = 'YES';
		oliVar.OPCOverride__c = 'No';
		INSERT oliVar;
		oldRecMap.put(oliVar.Id, oliVar);

		OpportunityLineItem newOpty = [SELECT Id, OpportunityId, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id,Change_Classification__c,OPCOverride__c
									 FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];
		newOpty.Contract_End_Date__c = Date.newInstance(System.Today().year(), 10, 16);
		UPDATE newOpty;

		optyLIList.add(newOpty);


		test.startTest();
		//OpportunityLineItemService.recalculateClassification(optyLIList, oldRecMap);
		test.stopTest();

		//System.assertEquals(Constants.CLSS_GROWTH, newOpty.Classification__c);
	}

	/*********************************
	* Description: Tests the populateClassification() method for New Business
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void updateClassificationNB() {
 

		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();


		Account testOrg = [SELECT Id, Name FROM Account WHERE Name = 'Without Revenue'
						 LIMIT 1];
		Opportunity testOpty = [SELECT Id FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Road Express - STE' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
		Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();

		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = testProd.Id;
		oliVar.Classification__c = Constants.CLSS_GROWTH;
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 24.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4); //Date.today();
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 14); // Date.today()+10;
		INSERT oliVar;
		oldRecMap.put(oliVar.Id, oliVar);

		OpportunityLineItem newOpty = [SELECT Id, OpportunityId, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id,Change_Classification__c,OPCOverride__c
									 FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];
		newOpty.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 12); //Date.today()+8;
		newOpty.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 19); //Date.today()+15;
		UPDATE newOpty;
		optyLIList.add(newOpty);
		test.startTest();
		//OpportunityLineItemService.recalculateClassification(optyLIList, oldRecMap);
		test.stopTest();

		//System.assertEquals('New Business', newOpty.Classification__c);
	}

	/*********************************
	* Description: Tests the populateClassification() method for Cross Sell
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void updateClassificationCS() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();
 
		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
		Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'International Bundle' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
		Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();

		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = testProd.Id;
		oliVar.Classification__c = Constants.CLSS_GROWTH;
		oliVar.Change_Classification__c = 'No';
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 24.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4); // Date.today();
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 14); // Date.today()+10;
		INSERT oliVar;

		OpportunityLineItem newOpty = [SELECT Id, Contract_End_Date__c, Classification__c,Change_Classification__c, Contract_Start_Date__c, Product2Id,OPCOverride__c
									 FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];
		oldRecMap.put(newOpty.id,newOpty);

		Integer monthToUse = Date.today().month() >6 ? 7 : 4;
		newOpty.Contract_Start_Date__c = Date.newInstance(System.Today().year(), monthToUse, 12);
		newOpty.Contract_End_Date__c = Date.newInstance(System.Today().year(), monthToUse+1, 19);


		optyLIList.add(newOpty);


		test.startTest();
		//OpportunityLineItemService.recalculateClassification(optyLIList, oldRecMap);
		test.stopTest();

		//System.assertEquals('Cross Sell', newOpty.Classification__c);
	}

	/*********************************
	* Description: Tests the populateClassification() method for Win Back
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void updateClassificationWB() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();

		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
		Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Boxes and Bags Others' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
		Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();

		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = testProd.Id;
		oliVar.Classification__c =Constants.CLSS_GROWTH;
		oliVar.Change_Classification__c = 'No';
		oliVar.OPCOverride__c = 'No';
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 24.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4); // Date.today();
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 14);// Date.today()+10;
		INSERT oliVar;
		oldRecMap.put(oliVar.Id, oliVar);
		OpportunityLineItem newOpty = [SELECT Id, Contract_End_Date__c, Classification__c,Change_Classification__c, Contract_Start_Date__c, Product2Id,OPCOverride__c
									 FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];
		newOpty.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 19);// Date.today()+15;
		UPDATE newOpty;

		optyLIList.add(newOpty);

		test.startTest();
		//OpportunityLineItemService.recalculateClassification(optyLIList, oldRecMap);
		test.stopTest();

		//System.assertEquals('Win Back', newOpty.Classification__c);
	}

	/*********************************
	* Description: Tests the beforeDelete method
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void deleteProduct() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();

 
		User testRunAs = [SELECT Id from User WHERE Alias = 'CovSal' LIMIT 1];
		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
		Contact keyContact = [Select Id from Contact Where AccountId=:testOrg.Id];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'International Bundle' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		// Query your permission set name from Organization to bypass the validation
		List<PermissionSet> psList = new List<PermissionSet>();
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
			oppVar.CloseDate = Date.newInstance(System.Today().year(), 4, 4); //Date.today();
			oppVar.Offline_Contract_Received__c = TRUE;
			oppVar.StageName = 'Identify';
			INSERT oppVar;

			Integer monthToUse = Date.today().month() >6 ? 7 : 4;
			OpportunityLineItem oliVar = new OpportunityLineItem();
			oliVar.OpportunityId = oppVar.Id;
			oliVar.Product2Id = testProd.Id;
			oliVar.Classification__c = Constants.CLSS_GROWTH;
			oliVar.Quantity = 12;
			oliVar.TotalPrice = 93.00;
			oliVar.PricebookEntryId = pbEntry.Id;
			oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), monthToUse, monthToUse);
			oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), monthToUse+1, monthToUse+1);
			oliVar.Contract_Product__c = 'No';
			oliVar.Change_Classification__c = 'Yes';
			oliVar.OPCOverride__c = 'Yes';
			INSERT oliVar;

			// recording competitors mandatory on opportunity to progress to close won
			List<Competitor__c> competitors = ApplicationTestDataFactorySales.getCompetitors(1, oppVar.Id, false);
			insert(competitors);

			Task opportunityTask = ApplicationTestDataFactory.getTasks(1, oppVar.Id, false)[0];
			opportunityTask.ActivityDate=System.today();
			opportunityTask.Status = 'Completed';
			insert opportunityTask;

			Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE Closed_Reason__c = 'Functionality' AND Offline_Contract_Received__c = TRUE LIMIT 1];
			testOpty.Hidden_Restrict_Path_Closure__c =true;
			testOpty.StageName = 'Closed Won';
			testOpty.Description = 'test';
			testOpty.KeyContact__c = keyContact.Id;
			testOpty.Monthly_Executive_Summary__c = 'test';
			UPDATE testOpty;

			try{
				OpportunityLineItem newOpty = [SELECT Id, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id
											 ,Change_Classification__c,OPCOverride__c FROM OpportunityLineItem WHERE OpportunityId =: testOpty.Id LIMIT 1];
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
	* 09/13/2019 Created
	********************************/
	@isTest
	static void changeClassTestR() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();

		User testRunAs = [SELECT Id, Profile.Name from User WHERE Alias = 'CovSal' LIMIT 1];
		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
		Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();

		// Query your permission set name from Organization to bypass the validation
		List<PermissionSet> psList = new List<PermissionSet>();
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
			oppVar.CloseDate = Date.newInstance(System.Today().year(), 4, 4); //Date.today();
			oppVar.Offline_Contract_Received__c = TRUE;
			oppVar.StageName = 'Identify';
			INSERT oppVar;

			Integer monthToUse = Date.today().month() >6 ? 7 : 4;
			OpportunityLineItem oliVar = new OpportunityLineItem();
			oliVar.OpportunityId = oppVar.Id;
			oliVar.Product2Id = testProd.Id;
			oliVar.Classification__c = Constants.CLSS_GROWTH;
			oliVar.Quantity = 12;
			oliVar.TotalPrice = 93.00;
			oliVar.PricebookEntryId = pbEntry.Id;
			oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), monthToUse, monthToUse);
			oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), monthToUse+1, monthToUse+1);
			oliVar.Contract_Product__c = 'No';
			oliVar.Change_Classification__c = 'Yes';
			oliVar.OPCOverride__c = 'No';
			INSERT oliVar;

			oldRecMap.put(oliVar.Id, oliVar);

			OpportunityLineItem newOpty = [SELECT Id, OpportunityId, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id, TotalPrice, Change_Classification__c,OPCOverride__c FROM OpportunityLineItem WHERE OpportunityId =: oppVar.Id AND Product2Id =: testProd.Id AND TotalPrice =: 93.00 LIMIT 1];

			//System.assertEquals(oliVar.Classification__c, newOpty.Classification__c);
			newOpty.Change_Classification__c = 'No';
			//UPDATE newOpty;

			optyLIList.add(newOpty);
		//	OpportunityLineItemService.recalculateClassification(optyLIList,oldRecMap);

		//	System.assertEquals(Constants.CLSS_RENEWAL, newOpty.Classification__c);

		}
		test.stopTest();
	}

	/*********************************
	* Description: Tests the changeClassification() for Growth scenario
	* Author: Jeoffrey Palmero
	* History:
	* 09/13/2019 Created
	********************************/
	@isTest
	static void changeClassTestG() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();

 
		User testRunAs = [SELECT Id, Profile.Name from User WHERE Alias = 'CovSal' LIMIT 1];
		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
		Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();
		// Query your permission set name from Organization to bypass the validation.
		List<PermissionSet> psList = new List<PermissionSet>();
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
			oppVar.CloseDate = Date.newInstance(System.Today().year(), 4, 4); // Date.today();
			oppVar.Offline_Contract_Received__c = TRUE;
			oppVar.StageName = 'Identify';
			INSERT oppVar;
			Integer monthToUse = Date.today().month() >6 ? 7 : 4;
			OpportunityLineItem oliVar = new OpportunityLineItem();
			oliVar.OpportunityId = oppVar.Id;
			oliVar.Product2Id = testProd.Id;
			oliVar.Classification__c = Constants.CLSS_GROWTH;
			oliVar.Quantity = 12;
			oliVar.TotalPrice = 93.00;
			oliVar.PricebookEntryId = pbEntry.Id;
			oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), monthToUse, monthToUse);
			oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), monthToUse+1, monthToUse+1);
			oliVar.Contract_Product__c = 'No';
			oliVar.Change_Classification__c = 'Yes';
			oliVar.OPCOverride__c = 'No';
			INSERT oliVar;
			oldRecMap.put(oliVar.Id, oliVar);

			OpportunityLineItem newOpty = [SELECT Id, OpportunityId, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id, TotalPrice,Change_Classification__c,OPCOverride__c
											 FROM OpportunityLineItem WHERE OpportunityId =: oppVar.Id AND Product2Id =: testProd.Id AND TotalPrice =: 93.00 LIMIT 1];
			newOpty.Change_Classification__c = 'No';
			//UPDATE newOpty;

			optyLIList.add(newOpty);
		//	OpportunityLineItemService.recalculateClassification(optyLIList,oldRecMap);

		//	System.assertEquals(Constants.CLSS_RENEWAL, newOpty.Classification__c);

		}
		test.stopTest();
	}


	 /*********************************
	* Description: Tests the changeClassification() for Growth scenario on forward planning
	* Author: Ken McGuire
	* History:
	* 23/02/2022 Created
	********************************/
	@isTest
	static void testChangeClassTestGFP() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();

 
		User testRunAs = [SELECT Id, Profile.Name from User WHERE Alias = 'CovSal' LIMIT 1];
		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
		Map<Id, OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();
		// Query your permission set name from Organization to bypass the validation.
		List<PermissionSet> psList = new List<PermissionSet>();
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
			oppVar.CloseDate = Date.newInstance(System.Today().year()+1, 4, 4); // Date.today();
			oppVar.Offline_Contract_Received__c = TRUE;
			oppVar.StageName = 'Identify';
			INSERT oppVar;
			Integer monthToUse = Date.today().month() >6 ? 7 : 4;
			OpportunityLineItem oliVar = new OpportunityLineItem();
			oliVar.OpportunityId = oppVar.Id;
			oliVar.Product2Id = testProd.Id;
			oliVar.Classification__c = Constants.CLSS_GROWTH;
			oliVar.Quantity = 12;
			oliVar.TotalPrice = 93.00;
			oliVar.PricebookEntryId = pbEntry.Id;
			oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), monthToUse, monthToUse);
			oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), monthToUse+1, monthToUse+1);
			oliVar.Contract_Product__c = 'No';
			oliVar.Change_Classification__c = 'Yes';
			oliVar.OPCOverride__c = 'No';
			INSERT oliVar;
			oldRecMap.put(oliVar.Id, oliVar);

			OpportunityLineItem newOpty = [SELECT Id, OpportunityId, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id, TotalPrice,Change_Classification__c,OPCOverride__c
											 FROM OpportunityLineItem WHERE OpportunityId =: oppVar.Id AND Product2Id =: testProd.Id AND TotalPrice =: 93.00 LIMIT 1];
			newOpty.Change_Classification__c = 'No';
			//UPDATE newOpty;

			optyLIList.add(newOpty);
		//	OpportunityLineItemService.recalculateClassification(optyLIList,oldRecMap);

		//	System.assertEquals(Constants.CLSS_RENEWAL, newOpty.Classification__c);

		}
		test.stopTest();
	}


	/*********************************
	* Description: Tests the populateClassification() method for an OPC related account business renewal
	* Author: Ken McGuire
	* History:
	* 2022-05-10 Created
	********************************/
	@isTest
	static void testClassificationOPCRelatedCrossSell() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();

		Account parentOrg = [SELECT Id, Name FROM Account WHERE Name = 'Without Revenue' LIMIT 1];
		Account relatedOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];

		AccountRelationship__c opcRelationship = new AccountRelationship__c(ParentAccount__c = parentOrg.id,RelatedAccount__c = relatedOrg.Id,Relationship__c = 'OPC');
		insert(opcRelationship);

		// parent opportunity
		Opportunity testOpty = [SELECT Id FROM Opportunity WHERE AccountId =: parentOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Road Express - STE' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: testProd.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();

		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = testProd.Id;
		oliVar.Classification__c = Constants.CLSS_GROWTH;
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 24.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4); // Date.today();
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 14); // Date.today()+10;
		optyLIList.add(oliVar);

		// related account sales history

		test.startTest();
		//OpportunityLineItemService.populateClassification(optyLIList);
		test.stopTest();

		//System.assertEquals('Cross Sell', oliVar.Classification__c);

	}

	/*********************************
	* Description: Tests to populateRevenueDate() method when a Opportunity Product record is inserted
	* Author: Nasir Jawed
	* History:
	* 2023-03-15 Created
	********************************/
	@isTest
	static void testPopulateRevenueDate() {
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class);
		MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>();
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
		MockUtility.Mocks.stopStubbing();

		//Creating Account record
		Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert account;
		//Creating Contact record
		Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		insert con;
		//Creating Opportunity record
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
		opp.IsStartrackProposal__c = 'No';
		opp.stagename = 'Identify';
		opp.KeyContact__c =con.id;
		insert opp;
		//Creating Product record
		Product2 product =APT_TestUtils.createAPPCProduct('Car',APT_Constants.PRODUCT_CODE_APPC,'Postal Services');
		product.APT_Product_type__c = 'Workforce Verification';//add product type to product
		insert product;
		//Creating PriceBook record
		Pricebook2 standardPricebook = new Pricebook2(
				Id = Test.getStandardPricebookId(),
				IsActive = true
			);
		Update standardPricebook;
		//Creating PricebookEntry record
		PricebookEntry pbe = new PricebookEntry();
		pbe.Pricebook2Id = standardPricebook.id;
		pbe.Product2Id = product.Id;
		pbe.UnitPrice = 10000;
		pbe.IsActive = true;
		insert pbe;
		List<opportunityLineItem> oliList= new List<opportunityLineItem>();
		opportunityLineItem oli= APT_TestDataFactory.getOpportunityLineItemRecord(1,opp.id,false)[0];
		oli.product2id=product.id;
		oli.PriceBookEntryId = pbe.id;
		oli.Contract_Number__c = 'Q-00185808';
		oliList.add(oli);


		test.startTest();
		OpportunityLineItemService.populateRevenueDate(oliList);
		test.stopTest();
		system.assertNOTEquals(oliList,null);
	}

	 /*********************************
	* Description: Tests product substitution for renewal
	* Author: Ken McGuire
	* History:
	* 16/03/2022 Created
	********************************/
	@isTest
	static void productSubstitution() {
 
 
 		Account testOrg = [SELECT Id FROM Account WHERE Name = 'With Nominal Revenue' LIMIT 1];
		Opportunity testOpty = [SELECT Id, AccountId FROM Opportunity WHERE AccountId =: testOrg.Id LIMIT 1];
		Product2 testProd = [SELECT Id FROM Product2 WHERE Name = 'Road Express - STE' LIMIT 1];
		Product2 replacementProduct = [SELECT Id FROM Product2 WHERE Name = 'eParcel Express' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id =: replacementProduct.Id LIMIT 1];
		List<OpportunityLineItem> optyLIList = new List<OpportunityLineItem>();
		Map<Id,OpportunityLineItem> oldRecMap = new Map<Id,OpportunityLineItem>();
 
		ProductRelationship__c substiteProduct = new ProductRelationship__c();
		substiteProduct.ParentProduct__c = replacementProduct.id;
		substiteProduct.RelatedProduct__c = testProd.id;
		substiteProduct.Relationship__c = 'Replaces';
 
		// set up responses
		ProductRelationshipsSelector relationshipSelector = (ProductRelationshipsSelector)MockUtility.mockSelector(ProductRelationshipsSelector.class); 
				MockUtility.Mocks.startStubbing();
		List<ProductRelationship__c> relatedProductList = new List<ProductRelationship__c>{substiteProduct};
		MockUtility.Mocks.when(relationshipSelector.selectByRelatedAndParent((Set<id>)fflib_Match.anyObject(), (Set<id>)fflib_Match.anyObject())).thenReturn(relatedProductList);
				MockUtility.Mocks.stopStubbing();

 
		OpportunityLineItem oliVar = new OpportunityLineItem();
		oliVar.OpportunityId = testOpty.Id;
		oliVar.Product2Id = replacementProduct.Id;
		oliVar.Quantity = 12;
		oliVar.TotalPrice = 93.00;
		oliVar.PricebookEntryId = pbEntry.Id;
		oliVar.Contract_Start_Date__c = Date.newInstance(System.Today().year(), 4, 4);// Date.today();
		oliVar.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 10);// Date.today()+10;
		oliVar.Change_Classification__c = 'No';

		INSERT oliVar;
		oldRecMap.put(oliVar.Id, oliVar);
		OpportunityLineItem newOpty = [SELECT Id, OpportunityId, Contract_End_Date__c, Classification__c, Contract_Start_Date__c, Product2Id,Change_Classification__c,OPCOverride__c
									 FROM OpportunityLineItem WHERE Id =: oliVar.Id LIMIT 1];
		newOpty.Contract_End_Date__c = Date.newInstance(System.Today().year(), 4, 19); //Date.today()+15;
		UPDATE newOpty;

		optyLIList.add(newOpty);

		test.startTest();
		//OpportunityLineItemService.recalculateClassification(optyLIList, oldRecMap);
		test.stopTest();

		//System.assertEquals(Constants.CLSS_RENEWAL, newOpty.Classification__c);
	}
    

	// TradingHistoryMapsTest coverage - to be removed 

    @IsTest
    public static void testAddTradedProduct() {
        // Create instance of the TradingHistoryMaps class
        OpportunityLineItemService.TradingHistoryMaps tradingHistory = new OpportunityLineItemService.TradingHistoryMaps();

        // Define test Account Id and Product Id
        Id testAccountId = Id.valueOf('001000000000001AAA');
        Id testProductId = Id.valueOf('01t000000000001AAA');

        // Add traded product
        tradingHistory.addTradedProduct(testAccountId, testProductId);

        // Verify that the traded product was added
        System.assert(tradingHistory.tradedProductSet.containsKey(testAccountId), 'Account should exist in tradedProductSet');
        System.assert(tradingHistory.tradedProductSet.get(testAccountId).contains(testProductId), 'Product should be in the traded products for the account');
    }

    @IsTest
    public static void testAddSignificantTradedProduct() {
        // Create instance of the TradingHistoryMaps class
        OpportunityLineItemService.TradingHistoryMaps tradingHistory = new OpportunityLineItemService.TradingHistoryMaps();
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Product2 prod = ApplicationTestDataFactory.getProducts(1,true)[0];

        // Define test Account Id and Product Id
        Id testAccountId = account.Id;
        Id testProductId = prod.Id;

        // Add significant traded product
        tradingHistory.addSignificantTradedProduct(testAccountId, testProductId);

        // Verify that the significant traded product was added
        System.assert(tradingHistory.significantTradedProductSet.containsKey(testAccountId), 'Account should exist in significantTradedProductSet');
        System.assert(tradingHistory.significantTradedProductSet.get(testAccountId).contains(testProductId), 'Product should be in the significant traded products for the account');
    }

    @IsTest
    public static void testProductPreviouslyTraded() {
        // Create instance of the TradingHistoryMaps class
        OpportunityLineItemService.TradingHistoryMaps tradingHistory = new OpportunityLineItemService.TradingHistoryMaps();

        // Define test Account Id and Product Id
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Product2 prod = ApplicationTestDataFactory.getProducts(1,true)[0];

        // Define test Account Id and Product Id
        Id testAccountId = account.Id;
        Id testProductId = prod.Id;

        // Initially, product should not be marked as previously traded
        System.assert(!tradingHistory.productPreviouslyTraded(testAccountId, testProductId), 'Product should not be previously traded initially');

        // Add traded product and check again
        tradingHistory.addTradedProduct(testAccountId, testProductId);
        System.assert(tradingHistory.productPreviouslyTraded(testAccountId, testProductId), 'Product should be marked as previously traded after adding it');
    }

    @IsTest
    public static void testProductSignificantlyTraded() {
        // Create instance of the TradingHistoryMaps class
        OpportunityLineItemService.TradingHistoryMaps tradingHistory = new OpportunityLineItemService.TradingHistoryMaps();

        // Define test Account Id and Product Id
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Product2 prod = ApplicationTestDataFactory.getProducts(1,true)[0];

        // Define test Account Id and Product Id
        Id testAccountId = account.Id;
        Id testProductId = prod.Id;

        // Initially, product should not be marked as significantly traded
        System.assert(!tradingHistory.productSignificantlyTraded(testAccountId, testProductId), 'Product should not be significantly traded initially');

        // Add significant traded product and check again
        tradingHistory.addSignificantTradedProduct(testAccountId, testProductId);
        System.assert(tradingHistory.productSignificantlyTraded(testAccountId, testProductId), 'Product should be marked as significantly traded after adding it');
    }

    @IsTest
    public static void testAnyProductSignificantlyTraded() {
        // Create instance of the TradingHistoryMaps class
        OpportunityLineItemService.TradingHistoryMaps tradingHistory = new OpportunityLineItemService.TradingHistoryMaps();
		Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Product2 prod = ApplicationTestDataFactory.getProducts(1,true)[0];

        // Define test Account Id and Product Id
        Id testAccountId = account.Id;
        Id testProductId = prod.Id;


        // Initially, there should be no significantly traded products for the account
        System.assert(!tradingHistory.anyProductSignificantlyTraded(testAccountId), 'No products should be significantly traded for the account initially');

        tradingHistory.addSignificantTradedProduct(testAccountId, testProductId);

        // Now, there should be at least one significantly traded product for the account
        System.assert(tradingHistory.anyProductSignificantlyTraded(testAccountId), 'There should be a significantly traded product for the account');
    }
}