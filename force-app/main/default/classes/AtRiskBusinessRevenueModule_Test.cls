/**
 * @description Domain Module to handle At_Risk_Business__c object functionality
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * @author Pratyush Chalasani
 * @group Domain
 * @domain AtRiskBusiness
 * @changelog
 * 2023-04-21 - Pratyush Chalasani - Created
 *
 */
@isTest
public class AtRiskBusinessRevenueModule_Test {
    
	@isTest
	static void test_onBeforeUpdate_selectedProducts() {
		// =====================================
		// Data Preparation
		// =====================================
		AtRiskBusinessRevenueModule.calculationDate = Date.newInstance(2023, 7, 1);

		String testYear = '2023';

		Id testAccountId = fflib_IDGenerator.generate(Account.getSObjectType());
		Id testProductId = fflib_IDGenerator.generate(Product2.getSObjectType());

		List<Budget_And_Revenue__c> testRevenues = ApplicationTestDataFactory.getBudgetAndRevenue(1, testAccountId, true);

		testRevenues[0].Product__c = testProductId;
		testRevenues[0].Financial_Year__c = testYear;

		List<At_Risk_Business__c> arbs = ApplicationTestDataFactory.getAtRiskBusiness(1, testAccountId, false);
		
		arbs[0].Scale__c = 'Product Specific (Please Specify)';
		arbs[0].Products_IDs__c = testProductId;

		Map<Id, At_Risk_Business__c> oldARBs = new Map<Id, At_Risk_Business__c>{arbs[0].Id => arbs[0].clone(true, true, true, true)};

		oldARBs.values()[0].Products_IDs__c = null;

		// =====================================
		// Stubbing
		// =====================================
		BudgetAndRevenueSelector mockRevenueSelector = (BudgetAndRevenueSelector)MockUtility.mockSelector(BudgetAndRevenueSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockRevenueSelector.selectByOrganisationId(new Set<Id>{testAccountId}, new Set<String>{testYear})).thenReturn(testRevenues);
		MockUtility.Mocks.stopStubbing();
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AtRiskBusinessRevenueModule module = AtRiskBusinessRevenueModule.newInstance();

		module.onBeforeUpdate(arbs, oldARBs, null);

		Test.stopTest();
		
		Assert.areEqual(AtRiskBusinessRevenueModule.calculationDate, arbs[0].Date_of_Revenue_Calculation__c);
		Assert.areEqual(12000, arbs[0].Value_of_Business_at_Risk__c);
	}

	@isTest
	static void test_onBeforeUpdate_WholeOfBusiness() {
		// =====================================
		// Data Preparation
		// =====================================
		AtRiskBusinessRevenueModule.calculationDate = Date.newInstance(2023, 7, 1);

		String testYear = '2023';

		Id testAccountId = fflib_IDGenerator.generate(Account.getSObjectType());
		Id testProductId = fflib_IDGenerator.generate(Product2.getSObjectType());

		List<Budget_And_Revenue__c> testRevenues = ApplicationTestDataFactory.getBudgetAndRevenue(1, testAccountId, true);

		testRevenues[0].Product__c = testProductId;
		testRevenues[0].Financial_Year__c = testYear;

		List<At_Risk_Business__c> arbs = ApplicationTestDataFactory.getAtRiskBusiness(1, testAccountId, false);
		
		arbs[0].Scale__c = 'Whole of Business';
		arbs[0].Products_IDs__c = testProductId;
		arbs[0].Products__c = 'test';

		Map<Id, At_Risk_Business__c> oldARBs = new Map<Id, At_Risk_Business__c>{arbs[0].Id => arbs[0].clone(true, true, true, true)};

		oldARBs.values()[0].Scale__c = 'Product Specific (Please Specify)';

		// =====================================
		// Stubbing
		// =====================================
		BudgetAndRevenueSelector mockRevenueSelector = (BudgetAndRevenueSelector)MockUtility.mockSelector(BudgetAndRevenueSelector.class);

		// set up our responses
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockRevenueSelector.selectByOrganisationId(new Set<Id>{testAccountId}, new Set<String>{testYear})).thenReturn(testRevenues);
		MockUtility.Mocks.stopStubbing();
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		AtRiskBusinessRevenueModule module = AtRiskBusinessRevenueModule.newInstance();

		module.onBeforeUpdate(arbs, oldARBs, null);

		Test.stopTest();
		
		// Make sure product selections are cleared
		Assert.areEqual(null, arbs[0].Products__c);
		Assert.areEqual(null, arbs[0].Products_IDs__c);

		Assert.areEqual(AtRiskBusinessRevenueModule.calculationDate, arbs[0].Date_of_Revenue_Calculation__c);
		Assert.areEqual(12000, arbs[0].Value_of_Business_at_Risk__c);
	}
}