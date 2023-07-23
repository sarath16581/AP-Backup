/****************************************
 * Description: Test Class for the OPCUtility class
 * Author: Ken McGuire
 * History
 * 24/03/2023	Ken McGuire Created
 * 14/07/2023 Ken McGuire Fixed field not queried issues
 ********************************************/
@isTest
private class OPCUtility_Test {
	@TestSetup
	static void setupTestData() {
		// Get recordtypes
		RecordType orgrectype = [SELECT Id 
		FROM RecordType 
		WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
		// create Account
		Account testAccount = new Account(
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
			ShippingPostalCode='12345'
		);
		insert testAccount;	
		Opportunity testOpportunity = new Opportunity(AccountId = testAccount.id, name ='testOpp',StageName='Identify',CloseDate = date.today().addDays(20));
		insert(testOpportunity);
		// create product
		Product2 testProduct = new Product2(
			Name = 'Sample Product',
			IsActive = true,
			ProductCode = 'TEST'
		);
		insert testProduct;	
		
		string currentYear = String.valueOf(Date.today().year());
		string priorYear = String.valueOf(Date.today().year()-1);
		// create OPC
		Opp_Product_Classification__c opc = new Opp_Product_Classification__c(
				Account__c = testAccount.Id, 
				Product__c = testProduct.Id, 
				Classification__c = 'Growth', 
				Financial_Year__c = currentYear,
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
				Dec_Schedule_Amount__c = 12 
			);
			insert opc;	
 
		//Create Budget_and_Revenue__c
		Budget_and_Revenue__c tbr1 = new Budget_and_Revenue__c();
		tbr1.Name = 'Current Year';
		tbr1.Organisation__c = testAccount.Id;
		tbr1.Product__c = testProduct.Id;
		tbr1.Jan_Revenue_Amount__c = 250;
		tbr1.Feb_Revenue_Amount__c = 250;
		tbr1.Mar_Revenue_Amount__c = 250;
		tbr1.Apr_Revenue_Amount__c = 250;
		tbr1.May_Revenue_Amount__c = 250;
		tbr1.Jun_Revenue_Amount__c = 250;
		tbr1.Jul_Revenue_Amount__c = 250;
		tbr1.Aug_Revenue_Amount__c = 250; 
		tbr1.Sep_Revenue_Amount__c = 250;
		tbr1.Oct_Revenue_Amount__c = 250;
		tbr1.Nov_Revenue_Amount__c = 250;
		tbr1.Dec_Revenue_Amount__c = 250;
		tbr1.Total_Revenue_Amount__c = 600;
		tbr1.Financial_Year__c = currentYear;
 
		Budget_and_Revenue__c tbr2 = new Budget_and_Revenue__c();
		tbr2.Name = 'Previous Year';
		tbr2.Organisation__c = testAccount.Id;
		tbr2.Product__c = testProduct.Id;
		tbr2.Jan_Revenue_Amount__c = 250;
		tbr2.Feb_Revenue_Amount__c = 250;
		tbr2.Mar_Revenue_Amount__c = 250;
		tbr2.Apr_Revenue_Amount__c = 250;
		tbr2.May_Revenue_Amount__c = 250;
		tbr2.Jun_Revenue_Amount__c = 250;
		tbr2.Jul_Revenue_Amount__c = 250;
		tbr2.Aug_Revenue_Amount__c = 250;
		tbr2.Sep_Revenue_Amount__c = 250;
		tbr2.Oct_Revenue_Amount__c = 250;
		tbr2.Nov_Revenue_Amount__c = 250;
		tbr2.Dec_Revenue_Amount__c = 250;
		tbr2.Total_Revenue_Amount__c = 600;
		tbr2.Financial_Year__c = priorYear;
		insert(new list<Budget_and_Revenue__c>{tbr1,tbr2});
	}

	private static List<Opp_Product_Classification__c> getOppProductClassification(integer recordLimit) {
		return [SELECT 
		Account__c, Product__c, Classification__c, Financial_Year__c,
		Jan_Schedule_Amount__c, Feb_Schedule_Amount__c, Mar_Schedule_Amount__c, 
		Apr_Schedule_Amount__c,May_Schedule_Amount__c, Jun_Schedule_Amount__c,
		Jul_Schedule_Amount__c, Aug_Schedule_Amount__c, Sep_Schedule_Amount__c , 
		Oct_Schedule_Amount__c , Nov_Schedule_Amount__c , Dec_Schedule_Amount__c,
		Jan_NRT_Adjustment__c, Feb_NRT_Adjustment__c, Mar_NRT_Adjustment__c, 
		Apr_NRT_Adjustment__c,May_NRT_Adjustment__c, Jun_NRT_Adjustment__c, 
		Jul_NRT_Adjustment__c, Aug_NRT_Adjustment__c, Sep_NRT_Adjustment__c , 
		Oct_NRT_Adjustment__c , Nov_NRT_Adjustment__c , Dec_NRT_Adjustment__c
		FROM Opp_Product_Classification__c LIMIT :recordLimit];
	} 

	private static List<Budget_and_Revenue__c> getBudgetAndRevenue(integer recordLimit) {
		return [SELECT 
		Name,Organisation__c,Product__c,
		Jan_Revenue_Amount__c,Feb_Revenue_Amount__c,Mar_Revenue_Amount__c,
		Apr_Revenue_Amount__c,May_Revenue_Amount__c,Jun_Revenue_Amount__c,
		Jul_Revenue_Amount__c,Aug_Revenue_Amount__c,Sep_Revenue_Amount__c,
		Oct_Revenue_Amount__c,Nov_Revenue_Amount__c,Dec_Revenue_Amount__c,
		Total_Revenue_Amount__c,Financial_Year__c
		FROM Budget_and_Revenue__c LIMIT : recordLimit];
	}

	/**
	 * Test method to validate the functionality of deleteOPCList() in OPCUtility class.
	 */
	@isTest
	static void testDeleteOPCList() {
		// given
		List<Opp_Product_Classification__c> testOpcList = [SELECT Id FROM Opp_Product_Classification__c];
		List<String> idList = new List<String>{testOpcList[0].id}; 
		//when
		Test.startTest();
			OPCUtility.deleteOPCList(idList);
		Test.stopTest();

		// then
		List<Opp_Product_Classification__c> deletedOPCList = [SELECT Id FROM Opp_Product_Classification__c WHERE IsDeleted = true AND Id IN :idList];
		System.assertEquals(0, deletedOPCList.size(), 'The deleted records should be cleared from the list.');
	}
	
	/**
	 * Test method to validate the functionality of appendGrowthClassifications() in OPCUtility class.
	 */
	@isTest
	public static void testAppendGrowthClassifications() {
		// given
		List<Revenue_Schedule__c> revenueScheduleList = new List<Revenue_Schedule__c>();
		Revenue_Schedule__c rs1 = new Revenue_Schedule__c(Classification_c__c = 'Growth', Contract_Start_Date__c = date.today());
		Revenue_Schedule__c rs2 = new Revenue_Schedule__c(Classification_c__c = 'Renewal', Contract_Start_Date__c = date.today().addDays(5));
		revenueScheduleList.add(rs1);
		revenueScheduleList.add(rs2);
		
		Map<String, String> renewalUpsellMap = new Map<String, String>();
		
		// when
		OPCUtility.appendGrowthClassifications(revenueScheduleList, renewalUpsellMap);
		
		// then
		System.assertEquals(1, renewalUpsellMap.size());
		System.assertEquals('Renewal', renewalUpsellMap.get(OPCUtility.createRevenueScheduleOpcUid(rs1)));
		System.assertEquals(null, renewalUpsellMap.get(OPCUtility.createRevenueScheduleOpcUid(rs2)));
	}
 
	/**
	 * Test method to validate the functionality of createOPCMap() in OPCUtility class.
	 */
	@isTest
		public static void testCreateOPCMap() {
		// given
		List<Revenue_Schedule__c> rsList = new List<Revenue_Schedule__c>();
		Revenue_Schedule__c rs1 = new Revenue_Schedule__c(Classification_c__c = 'Growth', Contract_Start_Date__c = date.today());
		Revenue_Schedule__c rs2 = new Revenue_Schedule__c(Classification_c__c = 'Renewal', Contract_Start_Date__c = date.today().addDays(5));
		rsList.add(rs1);
		rsList.add(rs2);
		
		Map<String, Opp_Product_Classification__c> idOPCMap = new Map<String, Opp_Product_Classification__c>();
		Map<String, Revenue_Schedule__c> idRSMap = new Map<String, Revenue_Schedule__c>();
		
		// when
		OPCUtility.createOPCMap(rsList, idOPCMap, idRSMap);
		
		//then
		System.assertEquals(2, idOPCMap.size());
		System.assertEquals(2, idRSMap.size());
		
	}
 
	/**
	 * Test method to validate the functionality of checkIfOPCExist() in OPCUtility class.
	 */
	@IsTest
		public static void testCheckIfOPCExist() {
		// Create test data
		Map<String, Opp_Product_Classification__c> idOPCMap = new Map<String, Opp_Product_Classification__c>();
		Map<String, Opp_Product_Classification__c> idOPCExistingMap = new Map<String, Opp_Product_Classification__c>();
		List<Opp_Product_Classification__c> insertOPCList = new List<Opp_Product_Classification__c>();
		List<Opp_Product_Classification__c> updateOPCList = new List<Opp_Product_Classification__c>();
		
		Account testAccount = [SELECT Id FROM Account LIMIT 1];
		Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
		// Create sample Opp_Product_Classification__c records
		Opp_Product_Classification__c opc1 = new Opp_Product_Classification__c(Account__c = testAccount.Id, Product__c = testProduct.Id, Classification__c = 'Growth', Financial_Year__c = 'FY2023');
		Opp_Product_Classification__c opc2 = new Opp_Product_Classification__c(Account__c = testAccount.Id, Product__c = testProduct.id, Classification__c = 'Growth', Financial_Year__c = 'FY2023');
		idOPCMap.put(opc1.Id, opc1);
		idOPCMap.put(opc2.Id, opc2);
		
		
		
		// Call the method to be tested
		OPCUtility.checkIfOPCExist(idOPCMap, idOPCExistingMap, insertOPCList, updateOPCList);
		
		// Verify the results
		System.assertEquals(1, insertOPCList.size());
		System.assertEquals(opc2, insertOPCList[0]);
		System.assertEquals(0, updateOPCList.size());
	}

	/**
	 * Test method to validate the functionality of generateOPCBatchable() in OPCUtility class.
	 */
	@isTest
	static void testGenerateOPCBatchable() {
		GenerateOPCBatchable gob = new GenerateOPCBatchable();
		gob.testRun = true;
		Id OPCID = Database.executeBatch(gob);
		System.assertNotEquals(null, OPCID);
	}

	/**
	 * Test method to validate the functionality of addOPC() in OPCUtility class.
	 */
	@isTest
	static void testAddOPC() {
		Account testAccount = [SELECT Id FROM Account LIMIT 1];
		Opportunity testOpportunity = [SELECT Id,AccountId FROM Opportunity LIMIT 1];
		Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
		Revenue_Schedule__c testrs = new Revenue_Schedule__c();
				testrs.Product__c= testProduct.id;
				testrs.Classification_c__c ='Growth';
				testrs.CalendarYear__c = String.valueOf(Date.today().year());
				testrs.Opportunity__c = testOpportunity.id;
		
		Opp_Product_Classification__c opc3 = OPCUtility.addOPC(new Opp_Product_Classification__c() ,testrs);
		system.assertEquals('Growth',opc3.Classification__c);
	}

	/**
	 * Test method to validate the functionality of updateExistingOPC() in OPCUtility class.
	 */
	@isTest
	static void testUpdateExistingOPC() {
		Opp_Product_Classification__c opc = getOppProductClassification(1)[0];
		Opp_Product_Classification__c newOPC = new Opp_Product_Classification__c();
		OPCUtility.updateExistingOPC(opc, newOPC);
		system.assertEquals(opc.Mar_Schedule_Amount__c,newOPC.Mar_Schedule_Amount__c);
	}

	/**
	 * Test method to validate the functionality of populateOpcCalculatedFields() in OPCUtility class.
	 */
	@isTest
	static void testPopulateOpcCalculatedFields() {
		Opp_Product_Classification__c opc =  getOppProductClassification(1)[0];
		List<Budget_and_Revenue__c> testBudgetAndRevenue = getBudgetAndRevenue(2);
		
		string revenueKey = OPCUtility.constructRevenueKey(opc.Account__c, opc.Product__c, opc.Financial_Year__c);
		OPCUtility.ParentAccountRevenue testParentAccountRevenue = new OPCUtility.ParentAccountRevenue(opc.Account__c, testBudgetAndRevenue[0], false);
		testParentAccountRevenue.add(testBudgetAndRevenue[1], false);
		// Creating revenue maps
		Map<String, OPCUtility.ParentAccountRevenue> accountRevenueMap = new Map<String, OPCUtility.ParentAccountRevenue>();
		Map<String, Revenue_Schedule__c> opcRevenueScheduleMap = new Map<String, Revenue_Schedule__c>();

		accountRevenueMap.put(revenueKey,testParentAccountRevenue);
		Revenue_Schedule__c rs1 = new Revenue_Schedule__c(Classification_c__c = 'Growth', Contract_Start_Date__c = date.today().addDays(-365),Contract_End_Date__c = date.today().addDays(365));
		opcRevenueScheduleMap.put(opc.id,rs1);


		Test.startTest();

		// Call the method to test
		OPCUtility.populateOpcCalculatedFields(opc, accountRevenueMap, opcRevenueScheduleMap);

		Test.stopTest();

		// Fetch the updated record
		opc = [SELECT Id, Classification__c FROM Opp_Product_Classification__c WHERE Id = :opc.Id];

		System.assertEquals('Growth', opc.Classification__c);
	}

	/**
	 * Test method to validate the functionality of relateRevenueScheduleToOPC() in OPCUtility class.
	 */
	@isTest 
	static void testRelateRevenueScheduleToOPC() {
	// Create test data
	List<Opp_Product_Classification__c> opcList = getOppProductClassification(1);
		List<Revenue_Schedule__c> rsList = new List<Revenue_Schedule__c>{new Revenue_Schedule__c(Opportunity_Product_Classification__c =opcList[0].Id, Classification_c__c = 'Growth', Contract_Start_Date__c = date.today())};
		Map<String, Id> uniqueIdopcIdMap = new Map<String, Id>();
		Map<String, Revenue_Schedule__c> opcIdRSMap = new Map<String, Revenue_Schedule__c>();


		// Execute the method
		Test.startTest();
		OPCUtility.relateRevenueScheduleToOPC(opcList, rsList, uniqueIdopcIdMap, opcIdRSMap);
		Test.stopTest();

		// Verify the map
		System.assertEquals(opcList[0].Id, uniqueIdopcIdMap.get(OPCUtility.createRevenueOPCLinkUid(opcList[0])), 'Unique Id to OPC Id Map is not correct');
		System.assertEquals(rsList[0], opcIdRSMap.get(opcList[0].Id), 'OPC Id to Revenue Schedule Map is not correct');
	}

	/**
	 * Test method to validate the functionality of relateRevenueScheduleToOPC1() in OPCUtility class.
	 */
	@isTest 
	static void testRelateRevenueScheduleToOPC1() {
		// Create test data
		List<Opp_Product_Classification__c> opcList = getOppProductClassification(1);
		List<Revenue_Schedule__c> rsList = new List<Revenue_Schedule__c>{new Revenue_Schedule__c(Opportunity_Product_Classification__c =opcList[0].Id, Classification_c__c = 'Growth', Contract_Start_Date__c = date.today())};

		// Execute the method
		Test.startTest();
		OPCUtility.relateRevenueScheduleToOPC1(opcList, rsList);
		Test.stopTest();
		
		System.assertEquals(opcList[0].Id, rsList[0].Opportunity_Product_Classification__c);
	}

	/**
	 * Test method to validate the functionality of checkForException() in OPCUtility class.
	 */
	@isTest 
	static void testCheckForException() {
		// Create test data
		List<Opp_Product_Classification__c> opcList = getOppProductClassification(1);
		
		
		Map<String, OPCUtility.ParentAccountRevenue> idBARMap = new Map<String, OPCUtility.ParentAccountRevenue>();
		Map<String, Revenue_Schedule__c> opcIdRSMap = new Map<String, Revenue_Schedule__c>();
		List<Case> caseList = new List<Case>();
		String rtId = 'testRtId';
		List<Revenue_Schedule__c> rsList = new List<Revenue_Schedule__c>();

		// Add data to opcList


		// Add data to rsList
		Revenue_Schedule__c rs = new Revenue_Schedule__c(Opportunity_Product_Classification__c =opcList[0].Id, Classification_c__c = 'Growth', Contract_Start_Date__c = date.today());
		// insert rs;
		rsList.add(rs);

		// Call the method being tested
		Test.startTest();
		OPCUtility.checkForException(opcList, idBARMap, opcIdRSMap, caseList, rtId, rsList);
		Test.stopTest();

		// Verify the method updated the data correctly
		Opp_Product_Classification__c updatedOpc = [SELECT Id FROM Opp_Product_Classification__c WHERE Id = :opcList[0].Id];
		System.assertNotEquals(null, updatedOpc, 'OPC was not updated correctly');
	}

	@isTest 
	static void testRequeryOPCList() {
		// Create test data
		List<Opp_Product_Classification__c> opcList = getOppProductClassification(1);


		// Call the method being tested
		Test.startTest();
		List<Opp_Product_Classification__c> result = OPCUtility.requeryOPCList(opcList);
		Test.stopTest();

		// Assert the method returned the data correctly
		System.assertNotEquals(null, result, 'OPC list was not re-queried correctly');
		System.assertEquals(1, result.size(), 'OPC list size does not match expected');
		System.assertEquals(opcList[0].Id, result[0].Id, 'OPC Id does not match expected');
	}

	/**
	 * Test method to validate the functionality of requeryOPCList() in OPCUtility class.
	 */
	@isTest 
	static void testCalculateParentAccountRevenueMap1() {
		// Create test data
		List<String> acctIdList = new List<String>();
		List<String> revenueSchedueProductIds = new List<String>();

		Account acct = [SELECT Id FROM Account LIMIT 1];
		Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

		acctIdList.add(acct.Id);
		revenueSchedueProductIds.add(prod.Id);
		
		// Call the method being tested
		Test.startTest();
		OPCUtility.calculateParentAccountRevenueMap(acctIdList, revenueSchedueProductIds);
		Test.stopTest();

		System.assertNotEquals(null, OPCUtility.parentAccountRevenueMap, 'parentAccountRevenueMap is null');
	}

	/**
	 * Test method to validate the functionality of calculateParentAccountRevenueMap() in OPCUtility class.
	 */
	@isTest 
	static void testCalculateParentAccountRevenueMap2() {
		// Create test data
		Set<String> acctIdList = new Set<String>();
		Set<String> opportunityProductIds = new Set<String>();

		Account acct = [SELECT Id FROM Account LIMIT 1];
		Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

		acctIdList.add(acct.Id);
		opportunityProductIds.add(prod.Id);

		// Call the method being tested
		Test.startTest();
		OPCUtility.calculateParentAccountRevenueMap(acctIdList, opportunityProductIds);
		Test.stopTest();

		System.assertNotEquals(null, OPCUtility.parentAccountRevenueMap, 'parentAccountRevenueMap is null');
	}
}