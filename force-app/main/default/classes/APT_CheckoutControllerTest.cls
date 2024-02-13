/**
* @author Yatika bansal
* @date 2023-17-03
* @group Tests
* @tag ApexController
* @domain Apttus
* @description A test class for APT_CheckoutController
* @changelog
* 2023-08-14 - Yatika Bansal - Added test for docGenerationRequired
* 2024-02-13 - SteveL - Added test for getProposalDocGenerationProgress
*/
@IsTest
public class APT_CheckoutControllerTest {

	/**
	 * Test: when the method checkCreditAssessment is called, validate that the method successfully checks if credit assessment is complete
	 */
	@IsTest
	public static void checkCreditAssessmentTest_Complete() {
		Account tempacct = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, tempacct.Id, true)[0];
		Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, tempacct.Id, null, true)[0];
        APT_Credit_Assessment__c cred = APT_TestDataFactory.getApttusCreditAssessment(1, quote.Id, true)[0];

        APT_CreditAssessmentSelector mockSelector1 = (APT_CreditAssessmentSelector) MockUtility.mockSelector(APT_CreditAssessmentSelector.class);
		ApplicationDatabase mockDatabase1 = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector1.selectByProposalAndAssessStatus(new Set<Id>{(ID)quote.Id},
														new Set<String> {APT_Constants.CREDIT_ASSESSMENT_STATUS_APPROVED, APT_Constants.CREDIT_ASSESSMENT_STATUS_AUTO_APPROVED})).thenReturn(
			new List<APT_Credit_Assessment__c>(new List<APT_Credit_Assessment__c>{cred}));
		MockUtility.Mocks.stopStubbing();
        
		Test.startTest();
			String status = APT_CheckoutController.checkCreditAssessmentAndExecuteRateCardLogic(quote.id);
			boolean result = APT_CheckoutController.initiateRateCardGeneration(quote.id);
		Test.stoptest();

		System.assertEquals(status, APT_Constants.STRING_RESPONSE_COMPLETE, 'Credit Assessment is completed');
	}
    
    /**
	 * Test: when the method checkCreditAssessment is called, validate that the method successfully checks if credit assessment is due
	 */
	@IsTest
	public static void checkCreditAssessmentTest_Incomplete() {
		Account tempacct = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, tempacct.Id, true)[0];
		Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, tempacct.Id, null, true)[0];
       
		Test.startTest();
			String status = APT_CheckoutController.checkCreditAssessmentAndExecuteRateCardLogic(quote.id);
			boolean result = APT_CheckoutController.initiateRateCardGeneration(quote.id);
		Test.stoptest();

		System.assertEquals(status, APT_Constants.STRING_RESPONSE_INCOMPLETE, 'Credit Assessment is due');
	}
    

	/**
	 * Test: when the method checkoutOnly is called, validate that the method successfully finalizes the config
	 */
	@IsTest
	public static void checkoutOnlyTest() {
		Account tempacct = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert tempacct;
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, tempacct.Id, false)[0];
		insert opp;
		//
		Product2 product =APT_TestUtils.createAPPCProduct('Car',APT_Constants.PRODUCT_CODE_APPC,'Postal Services');
		product.APT_Product_type__c = 'Workforce Verification';//add product type to product
		insert product;

		//get Price List and Price List Item
		Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
		insert priceList;
		Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
		insert priceListItem;


		//
		Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, tempacct.Id, null, false)[0];
		insert quote;
		Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, tempacct.Id, quote.Id, false)[0];
		insert prodConfig;
		//
		//get summary group, Product Option Component, Classification and Hierarchy
		Apttus_Config2__SummaryGroup__c summaryGroup = APT_TestDataFactory.getSummaryGroupRecord(1, prodConfig.Id, 78, 45, false)[0];
		insert summaryGroup;
		Apttus_Config2__ProductOptionComponent__c prodOptionComponent = APT_TestDataFactory.getProductOptionComponentRecord(1, 2, false)[0];
		insert prodOptionComponent;
		Apttus_Config2__ClassificationName__c category = APT_TestDataFactory.getClassificationNameRecord(1, 'Test', 'High', 'Offering', 'Sample', false)[0];
		insert category;
		Apttus_Config2__ClassificationHierarchy__c classHierarchy = APT_TestDataFactory.getClassificationHierarchyRecord(1, category.id, 'Sample', false)[0];
		insert classHierarchy;
		Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getConfigLineItemRecords(1,prodConfig.id,summaryGroup.id, 2, product.id, prodOptionComponent.id,
		product.id,classHierarchy.id, 2.3,false,'',2,priceList.id,priceListItem.Id,'','','','', 22.00,24.00, 34.00,23.00,33.50, false)[0];
		lineItem.Apttus_Config2__ConfigurationId__c = prodConfig.id;
		insert lineItem;

		LineItemsSelector mockSelector1 = (LineItemsSelector) MockUtility.mockSelector(LineItemsSelector.class);
		ApplicationDatabase mockDatabase1 = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector1.selectByProdConfId(new set<ID>{(ID)prodConfig.Id})).thenReturn(
			new List<Apttus_Config2__LineItem__c>(new List<Apttus_Config2__LineItem__c>{lineItem}));
		MockUtility.Mocks.stopStubbing();
        
        LineItemsSelector mockSelector2 = (LineItemsSelector) MockUtility.mockSelector(LineItemsSelector.class);
		ApplicationDatabase mockDatabase2 = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelector2.selectByProdConfIdAndProductName(new set<ID>{(ID)prodConfig.Id}, new set<String>{'Australia Post Parcel Contract'})).thenReturn(
			new List<Apttus_Config2__LineItem__c>(new List<Apttus_Config2__LineItem__c>{lineItem}));
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
			String output = APT_CheckoutController.checkoutOnly(prodConfig.id);
			Boolean checkWorkVeri = APT_CheckoutController.checkWorkVerification(prodConfig.id);
        	Boolean docGenReq = APT_CheckoutController.docGenerationRequired(prodConfig.id);
		Test.stoptest();

		System.assert(output.contains('Error'), 'Checkout operation should not be completed due to missing data');
	}

	/**
	 * Test: when the methods are used in vf page, validate that the method successfully work
	 */
	@IsTest
	public static void vfPageTest() {
		Account tempacct = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, tempacct.Id, true)[0];
		Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, tempacct.Id, null, false)[0];
		Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, tempacct.Id, quote.Id, true)[0];

		PageReference testPage = Page.APT_CheckOut;
		Test.setCurrentPage(testPage);
		testPage.getParameters().put('Id', String.valueOf(prodConfig.Id));
		testPage.getParameters().put('businessObjectId', String.valueOf(quote.Id));
		testPage.getParameters().put('url', '/test');

		Test.startTest();
			APT_CheckoutController cc = new APT_CheckoutController();
			 System.assert(!String.isEmpty(cc.checkoutAttributes) , 'Attributes value should not be empty');
		Test.stoptest();
	}

	 /**
	 * Test: when the method validateConfiguration is called, validate that the method successfully validates the cart
	 */
	@IsTest
	public static void validateConfigurationTest() {
		Account tempacct = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, tempacct.Id, true)[0];
		Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, tempacct.Id, null, true)[0];
		Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, tempacct.Id, quote.Id, true)[0];
		Apttus_Config2__LineItem__c configLI = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];

		LineItemsSelector mockSelectorLI = (LineItemsSelector) MockUtility.mockSelector(LineItemsSelector.class);
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(mockSelectorLI.selectByProdConfigLineTypeAndStatus((set<Id>)fflib_Match.eq(new Set<Id>{configLI.id}),
																					(Set<String>)fflib_Match.eq(new Set<String>{APT_Constants.LABEL_LINE_TYPE_OPTION}),
																					(Set<String>)fflib_Match.eq(new Set<String>{APT_Constants.LABEL_LINE_STATUS,
																						APT_Constants.LABEL_LINE_STATUS_DEF_PENDING}))).
			thenReturn(new List<Apttus_Config2__LineItem__c>{configLI});
		MockUtility.Mocks.stopStubbing();

		Test.startTest();
			String output = APT_CheckoutController.validateConfiguration(prodConfig.id);
		Test.stoptest();

		System.assertEquals(APT_Constants.SUCCESS_LABEL_SMALL, output, 'Validation should succeed');
	}

	@IsTest
	private static void testGetProposalDocGenerationProgress() {
		Account acc = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, acc.Id, true)[0];
		Apttus_Proposal__Proposal__c proposal = APT_TestDataFactory.getAPTProposalRecord(1, opp.Id, acc.Id, null, true)[0];

		APT_ProposalObjectsSelector selector = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
		MockUtility.Mocks.startStubbing();
		MockUtility.Mocks.when(selector.selectByConfigIds((Set<Id>)fflib_Match.anyObject())).thenReturn(new List<Apttus_Proposal__Proposal__c>{proposal});
		MockUtility.Mocks.stopStubbing();

		System.assertEquals(proposal.APT_Document_Generation_in_Progress__c, APT_CheckoutController.getProposalDocGenerationProgress(proposal.Id), 'Method did not correctly locate the target Apttus_Proposal__Proposal__c record');
	}
}