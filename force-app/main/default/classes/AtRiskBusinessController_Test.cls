/**
 @description Test for Controller for LWC on At Risk Business page
 @author Pratyush Chalasani
 @date 2023-04-20
 @changelog: 
 2023-04-20 - Pratyush Chalasani - Created
**/
@isTest
public class AtRiskBusinessController_Test {

	@isTest
	static void test_getProducts() {
		// =====================================
		// Data Preparation
		// =====================================
		AtRiskBusinessController.revenueDate = Date.newInstance(2023, 7, 1);

		String testYear = '2023';

		Id testAccountId = fflib_IDGenerator.generate(Account.getSObjectType());

		List<Product2> products = ApplicationTestDataFactory.getProducts(1, true);

		products[0].ProductCode = 'test';
		products[0].Name = 'test';
		products[0].APT_Product_type__c = 'test';
		products[0].Product_Level_4__c = 'test';

		List<Budget_And_Revenue__c> testRevenues = ApplicationTestDataFactory.getBudgetAndRevenue(1, testAccountId, true);

		testRevenues[0].Product__c = products[0].Id;
		testRevenues[0].Financial_Year__c = testYear;

		At_Risk_Business__c arb = ApplicationTestDataFactory.getAtRiskBusiness(1, testAccountId, true)[0];
		
		arb.Scale__c = 'Product Specific (Please Specify after save)';
		arb.Products_IDs__c = products[0].Id;

		// =====================================
		// Stubbing
		// =====================================
		AtRiskBusinessSelector mockARBSelector = (AtRiskBusinessSelector)MockUtility.mockSelector(AtRiskBusinessSelector.class);
		BudgetAndRevenueSelector mockRevenueSelector = (BudgetAndRevenueSelector)MockUtility.mockSelector(BudgetAndRevenueSelector.class);
		ProductsSelector mockProductSelector = (ProductsSelector)MockUtility.mockSelector(ProductsSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockARBSelector.selectById(new Set<Id>{arb.Id})).thenReturn(new List<At_Risk_Business__c>{arb});
		MockUtility.Mocks.when(mockRevenueSelector.selectByOrganisationId(new Set<Id>{testAccountId}, new Set<String>{testYear})).thenReturn(testRevenues);
		MockUtility.Mocks.when(mockProductSelector.selectByIdOrderByName(new Set<Id>{products[0].Id},new Set<Object>())).thenReturn(products);
		MockUtility.Mocks.stopStubbing();
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AtRiskBusinessController.ProductData productData = AtRiskBusinessController.getProducts(arb.Id, true);

		Test.stopTest();
		
		Assert.areEqual(1, productData.products.size());
		Assert.areEqual(products[0].Id, productData.selectedIDs[0]);
	}

	@isTest
	static void test_saveSelection() {
		// =====================================
		// Data Preparation
		// =====================================
		Id testARBId = fflib_IDGenerator.generate(At_Risk_Business__c.getSObjectType());

		List<Product2> products = ApplicationTestDataFactory.getProducts(2, true);

		List<String> productIdList = new List<String>();
		Set<Id> productIdSet = new Set<Id>();
		List<String> productNames = new List<String>();

		for (Product2 prod: products) {
			productIdList.add(prod.Id);
			productIdSet.add(prod.Id);
			productNames.add(prod.Name);
		}

		String productIdString = String.join(productIdList, ';');
		String productNameString = String.join(productNames, ';');

		// =====================================
		// Stubbing
		// =====================================
		ProductsSelector mockProductSelector = (ProductsSelector)MockUtility.mockSelector(ProductsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockProductSelector.selectByIdOrderByName(productIdSet, new Set<Object>())).thenReturn(products);
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AtRiskBusinessController.saveSelection(testARBId, productIdList);

		Test.stopTest();
		
		// Check that dmlUpdate was called once
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());

		// Check that fields were updated as expected
		Assert.areEqual(productIdString, AtRiskBusinessController.arb.Products_IDs__c);
		Assert.areEqual(productNameString, AtRiskBusinessController.arb.Products__c);
	}

	@isTest
	static void test_recalculateRevenue() {
		// =====================================
		// Data Preparation
		// =====================================
		Id testAccountId = fflib_IDGenerator.generate(Account.getSObjectType());

		At_Risk_Business__c arb = ApplicationTestDataFactory.getAtRiskBusiness(1, testAccountId, true)[0];
		
		arb.Recalculate_Revenue__c = false;

		// =====================================
		// Stubbing
		// =====================================
		AtRiskBusinessSelector mockARBSelector = (AtRiskBusinessSelector)MockUtility.mockSelector(AtRiskBusinessSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockARBSelector.selectById(new Set<Id>{arb.Id})).thenReturn(new List<At_Risk_Business__c>{arb});
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AtRiskBusinessController.recalculateRevenue(arb.Id);

		Test.stopTest();

		// Check that dmlUpdate was called once
		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
		
		// Check that field was set to expected value
		Assert.areEqual(true, arb.Recalculate_Revenue__c);
	}
}