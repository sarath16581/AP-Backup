/**
	* @author Seth Heang
	* @date 2022-04-08
	* @group Tests
	* @tag ApexController
	* @domain Apttus
	* @description A test class for APT_CompassPricingController
	* @changelog
	* 2022-04-08 - seth.heang@auspost.com.au - Created
	* * 2022-08-11 - nasir.jawed@auspost.com.au - Created a method "testSuccessfulLinkingPSRForStandardDelegatedPricingSameTier"
	which test the update of Product Attribute value record and proposal from DSR
	2022-08-23 - bharat.patel30@auspost.com.au - Updated for Conga API(s) related execution validation and respected data set
	2023-03-07 - deepak.kemidi@auspost.com.au - CI-828 Updated for removing check for validation on lodgment zone metro
	2024-07-24 - sarath.burra@auspost.com.au - CI-904 Test class changes to accomodate Changes to I2 as part of Fixed Term Optimization
	*/
	@IsTest
	public with sharing class APT_CompassPricingController_Test {

		/**
		 * Test: when the method getPSRList is called, validate that the method successfully queries the APPC PSR records based on opportunity Id passed in as the parameter and other
		 * criteria such as Product Name and Record type being 'Australia Post Parcel Contract'
		 */
		@IsTest
		public static void testSuccessfulRetrievingPSRList(){
			// =====================================
			// Data Preparation
			// =====================================
			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, true)[0];
			Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];
			Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
			pav.APT_Customer_Tier__c = 'T05';
			List<Deal_Support_Request__c> dealSupportReqList = ApplicationTestDataFactory.getDealSupportRequests(2, opportunityRecord.Id, account.Id, true);
			Id psrAPPCRecTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Deal_Support_Request__c', new Set<String>{APT_Constants.PSR_APPC_RECORD_TYPE_APINAME}).values()[0].Id;
			dealSupportReqList[0].recordtypeId = dealSupportReqList[1].recordtypeId = psrAPPCRecTypeId;
			dealSupportReqList[0].product__c = dealSupportReqList[1].product__c = APT_Constants.PSR_APPC_PRODUCT_NAME;
			dealSupportReqList[0].stage__c = dealSupportReqList[1].stage__c = APT_Constants.PSR_STAGE_COMPLETE;
			dealSupportReqList[0].status__c = dealSupportReqList[1].status__c = APT_Constants.PSR_STATUS_COMPLETE;


			Map<String, Object> searchParams = new Map<String, Object>();
			searchParams.put('opportunityIds', new Set<Id>{opportunityRecord.Id});
			searchParams.put('recTypeIds', new Set<Id>{psrAPPCRecTypeId});
			searchParams.put('productNames', new Set<String>{APT_Constants.PSR_APPC_PRODUCT_NAME});
			// =====================================
			// Stubbing
			// =====================================
			DealSupportRequestsSelector mockSelector = (DealSupportRequestsSelector) MockUtility.mockSelector(DealSupportRequestsSelector.class);
			APT_ProductAttributeValuesSelector pavSelector = (APT_ProductAttributeValuesSelector) MockUtility.mockSelector(APT_ProductAttributeValuesSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(
				mockSelector.search((Map<String, Object>)fflib_Match.anyObject(),
				(Set<Object>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyObject())).thenReturn(dealSupportReqList);
			MockUtility.Mocks.when(pavSelector.selectByLineItemId((Set<id>)fflib_Match.anyObject())).thenReturn(
			new List<Apttus_Config2__ProductAttributeValue__c>(new List<Apttus_Config2__ProductAttributeValue__c>{pav}));

			MockUtility.Mocks.stopStubbing();

			// =====================================
			// Testing
			// =====================================
			Test.startTest();
			List<Deal_Support_Request__c> dsrList = APT_CompassPricingController.getPSRList(opportunityRecord.Id, lineItem.Id);
			Test.stopTest();

			System.assertEquals(dsrList[0].product__c, dealSupportReqList[0].product__c, 'Expected PSR product must be Australia Post Parcel Contract');
			System.assertEquals(dsrList[0].Opportunity__c, opportunityRecord.Id, 'Expected opportunity does not match');
			System.assertEquals(dsrList[1].stage__c, dealSupportReqList[1].stage__c, 'Expected PSR stage does not match');
			System.assertEquals(dsrList[1].status__c, dealSupportReqList[1].status__c, 'Expected PSR status does not match');
			System.assertEquals(dsrList.size(), dealSupportReqList.size(), 'Expected PSR count is not correct');
		}

		/**
		 * Test: when the method getPSRList is called and there is no PSR returned, validate that the method failed to query the APPC PSR records and an exception has occurred.
		 * On the LWC view, the user will see a custom error message related to no PSR records have been raised against the current opportunity.
		 */
		@IsTest
		public static void testFailingRetrievingPSRListNoPSRRaisedException(){
			// =====================================
			// Data Preparation
			// =====================================
			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
			RecordType appcRecDSR = RecordTypesSelector.newInstance().selectByDeveloperName('Deal_Support_Request__c', new Set<String>{APT_Constants.PSR_APPC_RECORD_TYPE_APINAME}).values()[0];
			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, true)[0];
			Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];
			Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
			pav.APT_Customer_Tier__c = 'T10';
			List<Deal_Support_Request__c> dealSupportReqList = new List<Deal_Support_Request__c>();



			Map<String, Object> searchParams = new Map<String, Object>();
			searchParams.put('opportunityIds', new Set<Id>{opportunityRecord.Id});
			searchParams.put('recTypeIds', new Set<Id>{appcRecDSR.Id});
			searchParams.put('productNames', new Set<String>{APT_Constants.PSR_APPC_PRODUCT_NAME});
			// =====================================
			// Stubbing
			// =====================================
			DealSupportRequestsSelector mockSelector = (DealSupportRequestsSelector) MockUtility.mockSelector(DealSupportRequestsSelector.class);
			APT_ProductAttributeValuesSelector pavSelector = (APT_ProductAttributeValuesSelector) MockUtility.mockSelector(APT_ProductAttributeValuesSelector.class);
			RecordTypesSelector recTypeSelector = (RecordTypesSelector) MockUtility.mockSelector(RecordTypesSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(recTypeSelector.selectByDeveloperName((String)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(new Map<Id, RecordType>{appcRecDSR.Id => appcRecDSR});
			MockUtility.Mocks.when(mockSelector.search((Map<String, Set<Id>>)fflib_Match.eq(searchParams),(Set<Object>)fflib_Match.eq(new Set<Object>()),fflib_Match.eqBoolean(true))).thenReturn(dealSupportReqList);
			MockUtility.Mocks.when(pavSelector.selectByLineItemId((Set<id>)fflib_Match.anyObject())).thenReturn(
			new List<Apttus_Config2__ProductAttributeValue__c>(new List<Apttus_Config2__ProductAttributeValue__c>{pav}));
			MockUtility.Mocks.stopStubbing();

			// =====================================
			// Testing
			// =====================================
			Test.startTest();
			try{
				List<Deal_Support_Request__c> dsrList = new List<Deal_Support_Request__c>();
				dsrList = APT_CompassPricingController.getPSRList(opportunityRecord.Id, lineItem.Id);
				System.assert(false, 'Expected No PSR Raised Exception is not thrown.');
			}catch(Exception e){
				System.assert(true, 'No PSR Raised Exception should be thrown');
			}
			Test.stopTest();
		}

		/**
		 * Test: when the method fetchConfigRequestId is called, validate that the method successfully query the Apttus_Config2__TempObject__c record
		 * by searching for related Apttus_Config2__ProductConfiguration__c and return the matching Apttus_Config2__TempObject__c Id
		 */
		@IsTest
		public static void testFetchConfigRequestId(){
			// =====================================
			// Data Preparation
			// =====================================
			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, true)[0];
			Apttus_Config2__TempObject__c configTempObj = APT_TestDataFactory.getAPTConfigTempObj(1, prodConfig.Id, true)[0];
			// =====================================
			// Stubbing
			// =====================================

			APT_ConfigTempObjectsSelector mockSelector = (APT_ConfigTempObjectsSelector) MockUtility.mockSelector(APT_ConfigTempObjectsSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelector.selectByConfigId((Set<Id>)fflib_Match.eq(new Set<Id>{prodConfig.Id}))).thenReturn(
				new List<Apttus_Config2__TempObject__c>{configTempObj});
			MockUtility.Mocks.stopStubbing();
			// =====================================
			// Testing
			// =====================================

			Test.startTest();
			Id configReqId = APT_CompassPricingController.fetchConfigRequestId(prodConfig.Id);
			Test.stopTest();

			System.assertEquals(configTempObj.Id, configReqId, 'Expected Configuration Request Id does not match');
		}

		/**
		 * Test: when the method onApply is called, validate that the linking PSR functionality is failed and multiple exceptions have occurred.
		 * Three exceptions are tested below including expired quote validity date, lodgement zone mismatch between PSR and product selected in shopping cart
		 * and a general exception such as invalid Id passed in as parameter.
		 */
		@IsTest
		public static void testFailedValidationWhenLinkingPSR(){
			// =====================================
			// Data Preparation
			// =====================================
			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, true)[0];
			Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];
			APT_Lodgement_Zone__c lodgementZone = APT_TestDataFactory.getAPTLodgementZone(1, true)[0];
			Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
			pav.APT_Lodgement_Zone__c = lodgementZone.Id;
			pav = (Apttus_Config2__ProductAttributeValue__c)ApplicationTestDataFactory.setUnwritableFields(pav,
					new Map<String, Object>{
						'APT_Selected_Lodgement_Zone__c' => 'Capital'
					});
			pav.APT_Additional_Lodgement_Zone_1__c = 'Capital';
			pav.APT_Additional_Lodgement_Zone_2__c = 'Capital';
			lineItem.Apttus_Config2__AttributeValueId__c = pav.Id;
			Deal_Support_Request__c dealSupportReq = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
			dealSupportReq.Approved_Event__c = APT_Constants.PSR_APPC_STANDARD_DELEGATED_PRICING;


			// =====================================
			// Stubbing
			// =====================================
			APT_ProductAttributeValuesSelector mockSelector = (APT_ProductAttributeValuesSelector) MockUtility.mockSelector(APT_ProductAttributeValuesSelector.class);
			ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelector.selectByLineItemId((Set<id>)fflib_Match.eq(new Set<Id>{lineItem.Id}))).thenReturn(
				new List<Apttus_Config2__ProductAttributeValue__c>(new List<Apttus_Config2__ProductAttributeValue__c>{pav}));
			MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.eq(prodConfig))).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
			MockUtility.Mocks.stopStubbing();
			// =====================================
			// Testing
			// =====================================
			Test.startTest();

			try{
				dealSupportReq.Quote_Validity_End_Date__c = Date.Today()-1;
				APT_CompassPricingController.onApply(dealSupportReq,prodConfig.Id,lineItem.Id);
				System.assert(false, 'Expected Quote Validity Exception is not thrown.');
			}catch(Exception e){
				System.assert(true, 'Quote Validity Exception should be thrown');
			}

			try{
				dealSupportReq.Approved_lodgement_zone__c = 'Capital';
				APT_CompassPricingController.onApply(dealSupportReq,'invalid prodConfigId',lineItem.Id);
				System.assert(false, 'Expected Exception is not thrown');
			}catch(Exception e){
				System.assert(true, 'Exception should be thrown');
			}
			Test.stopTest();
		}

		/**
		 *  Test: when the method onApply is called, validate that the linking PSR functionality is completed successfully without any error.
		 *  Will cover the Apply PSR functionality and following Conga CPQ API(s) during the execution flow:
		 *  Apttus_CPQApi.CPQWebService.associateConstraintRules()
		 *  Apttus_CPQApi.CPQWebService.applyConstraintRules()
		 *  Apttus_CPQApi.CPQWebService.getConstraintRuleResult()
		 *  Apttus_CpqApi.CPQWebService.updatePriceForCart()
		*/
		@IsTest
		public static void testSuccessfulLinkingPSRForStandardDelegatedPricingSameTier(){

			// =====================================
			// Data Preparation
			// =====================================
			Account tempacct = ApplicationTestDataFactory.getAccounts(1, false)[0];
			tempacct.Legacy_Id__c = '60000000';
			insert tempacct;
			//Contact con = APT_TestDataFactory.getAPTContactRecord(1, tempacct.Id, false)[0];

			Contact con = ApplicationTestDataFactory.getContacts(1, tempacct.Id, false)[0];
			insert con;

			Opportunity opp = ApplicationTestDataFactory.getOpportunities(1, tempacct.Id, false)[0];
			insert opp;

			//get Product and set Product Type
			Product2 product =APT_TestUtils.createAPPCProduct('Car',APT_Constants.PRODUCT_CODE_APPC,'Postal Services');
			product.APT_Product_type__c = 'Workforce Verification';//add product type to product
			insert product;

			//get Price List and Price List Item
			Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
			insert priceList;
			Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
			insert priceListItem;

			//get Proposal/Quote and Product Configuration
			Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opp.id, tempacct.Id, con.id, false)[0];
			insert quote;
			Apttus_Config2__ProductConfiguration__c config = APT_TestDataFactory.getAPTProductConfig(1, tempacct.Id, null, false)[0];
			config.Apttus_QPConfig__Proposald__c=quote.id;
			config.Apttus_Config2__PriceListId__c=priceList.id;
			insert config;

			//get summary group, Product Option Component, Classification and Hierarchy
			Apttus_Config2__SummaryGroup__c summaryGroup = APT_TestDataFactory.getSummaryGroupRecord(1, config.Id, 78, 45, false)[0];
			insert summaryGroup;
			Apttus_Config2__ProductOptionComponent__c prodOptionComponent = APT_TestDataFactory.getProductOptionComponentRecord(1, 2, false)[0];
			insert prodOptionComponent;
			Apttus_Config2__ClassificationName__c category = APT_TestDataFactory.getClassificationNameRecord(1, 'Test', 'High', 'Offering', 'Sample', false)[0];
			insert category;
			Apttus_Config2__ClassificationHierarchy__c classHierarchy = APT_TestDataFactory.getClassificationHierarchyRecord(1, category.id, 'Sample', false)[0];
			insert classHierarchy;

			//get line item's data
			Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getConfigLineItemRecords(1,config.id,summaryGroup.id, 2, product.id, prodOptionComponent.id,
					product.id,classHierarchy.id, 2.3,false,'',2,priceList.id,priceListItem.Id,'','','','', 22.00,24.00, 34.00,23.00,33.50, false)[0];
			lineItem.Apttus_Config2__ConfigurationId__c = config.id;
			insert lineItem;

			List<Apttus_Config2__LineItem__c> lineItemList= new List<Apttus_Config2__LineItem__c>();
			List<ID> pavIDList= new List<ID>();

				//get Lodgement zone
			APT_Lodgement_Zone__c lodgementZone = APT_TestDataFactory.getAPTLodgementZone(1, true)[0];

			//get Product Attribute Value record and set LZ, Tier, LI information
			Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
			pav.APT_Lodgement_Zone__c = lodgementZone.Id;
			pav = (Apttus_Config2__ProductAttributeValue__c)ApplicationTestDataFactory.setUnwritableFields(pav,
					new Map<String, Object>{
						'APT_Selected_Lodgement_Zone__c' => 'Capital'
					});
			pav.APT_Additional_Lodgement_Zone_1__c = 'Capital';
			pav.APT_Additional_Lodgement_Zone_2__c = 'Capital';
			pav.APT_Customer_Tier__c = 'T04';
			pav.Apttus_Config2__LineItemId__c = lineItem.Id;
			lineItem.Apttus_Config2__AttributeValueId__c = pav.Id;
			lineItem.Apttus_Config2__LineType__c = 'Option';

			lineItemList.add(lineItem);
			pavIDList.add(lineItem.Apttus_Config2__AttributeValueId__c);

			// =====================================
			// Stubbing
			// =====================================
			APT_ProductAttributeValuesSelector mockSelector = (APT_ProductAttributeValuesSelector) MockUtility.mockSelector(APT_ProductAttributeValuesSelector.class);
			ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelector.selectByLineItemId((Set<id>)fflib_Match.eq(new Set<Id>{lineItem.Id}))).thenReturn(
				new List<Apttus_Config2__ProductAttributeValue__c>(new List<Apttus_Config2__ProductAttributeValue__c>{pav}));
			MockUtility.Mocks.when(mockSelector.selectByconfigIDAndLineType(new List<Id>{config.Id})).thenReturn(
				new Map<Id, Apttus_Config2__ProductAttributeValue__c>(new List<Apttus_Config2__ProductAttributeValue__c>{pav}));
			MockUtility.Mocks.stopStubbing();

			//Query Selector for Line item
			LineItemsSelector mockSelector1 = (LineItemsSelector) MockUtility.mockSelector(LineItemsSelector.class);
			MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelector1.selectByProdConfId(new set<ID>{(ID)config.Id})).thenReturn(
				new List<Apttus_Config2__LineItem__c>(new List<Apttus_Config2__LineItem__c>{lineItem}));
			MockUtility.Mocks.stopStubbing();

			//Query Selector for Product Attribute Values
			APT_ProductAttributeValuesSelector mockSelector2 = (APT_ProductAttributeValuesSelector) MockUtility.mockSelector(APT_ProductAttributeValuesSelector.class);
			MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelector2.selectByPavID((List<Id>)fflib_Match.eq(pavIDList))).thenReturn(
				new List<Apttus_Config2__ProductAttributeValue__c>(new List<Apttus_Config2__ProductAttributeValue__c>{pav}));
			MockUtility.Mocks.stopStubbing();

			//Query Selector for Product Configuration
			ProductConfigurationSelector mockSelector3 = (ProductConfigurationSelector) MockUtility.mockSelector(ProductConfigurationSelector.class);
			MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelector3.selectByConfigId(new set<ID>{(ID)config.Id})).thenReturn(
				new List<Apttus_Config2__ProductConfiguration__c>(new List<Apttus_Config2__ProductConfiguration__c>{config}));
			MockUtility.Mocks.stopStubbing();

			//Query Selector for Proposal
			APT_ProposalObjectsSelector mockSelector4 = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
			MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelector4.selectByConfigId(new set<ID>{(ID)config.Id})).thenReturn(
				new Map<Id,Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote}));
			MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
			MockUtility.Mocks.stopStubbing();

			List<Deal_Support_Request__c> dealSupportReqList = ApplicationTestDataFactory.getDealSupportRequests(2, opp.Id, tempacct.Id, true);
			Id psrAPPCRecTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Deal_Support_Request__c', new Set<String>{APT_Constants.PSR_APPC_RECORD_TYPE_APINAME}).values()[0].Id;
			dealSupportReqList[0].recordtypeId = dealSupportReqList[1].recordtypeId = psrAPPCRecTypeId;
			dealSupportReqList[0].product__c = dealSupportReqList[1].product__c = APT_Constants.PSR_APPC_PRODUCT_NAME;
			dealSupportReqList[0].stage__c = dealSupportReqList[1].stage__c = APT_Constants.PSR_STAGE_COMPLETE;
			dealSupportReqList[0].status__c = dealSupportReqList[1].status__c = APT_Constants.PSR_STATUS_COMPLETE;

			dealSupportReqList[0].Approved_Event__c = APT_Constants.PSR_APPC_STANDARD_DELEGATED_PRICING;

				//Query Selector for DSR
				dealSupportReqList[0].Approved_lodgement_zone__c = 'Capital';
				dealSupportReqList[0].Quote_Validity_End_Date__c= Date.today() + 60;
				dealSupportReqList[0].Approved_Tier__c='T04';
				dealSupportReqList[0].Approved_Pricing_Structure__c= 'Z006';

			// building compass pricing attributes to test a getter method
			APT_CompassPricingController compassPricingCon = new APT_CompassPricingController();
			compassPricingCon.lineItemId = lineItem.Id;
			compassPricingCon.configId = config.Id;
			compassPricingCon.opportunityId = opp.Id;

			// code coverage for the goBack() PageReference method
			PageReference pageRef = Page.APT_Link_PSR;
			Test.setCurrentPage(pageRef);
			pageRef.getParameters().put('url','www.auspost.com');
			APT_CompassPricingController.goBack();

			// =====================================
			// Testing
			// =====================================
			Test.startTest();
				String successMsg = APT_CompassPricingController.onApply(dealSupportReqList[0],config.Id,lineItem.Id);
				APT_CompassPricingController.applyConstraintRules(config.Id, true);
			Test.stopTest();

			System.assertNotEquals(null, compassPricingCon.compassPricingAttributes, 'Instance variables should not be null');
			System.assertEquals(successMsg, System.Label.APT_LinkPSRSuccess, 'Link PSR must be successful');
		}


		@IsTest
		public static void testUpdatePriceForCart(){
			// =====================================
			// Data Preparation
			// =====================================
			Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
			account.LEGACY_ID__c = '4604376';
			insert account;
			Contact con = APT_TestDataFactory.getAPTContactRecord(1, account.Id, false)[0];
			insert con;
			Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, false)[0];
			insert opportunityRecord;
			Apttus_Proposal__Proposal__c proposal = APT_TestDataFactory.getAPTProposalRecord(1, opportunityRecord.id, account.Id, con.id, false)[0];
			insert proposal;
			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, false)[0];
			insert prodConfig;

			APT_CompassPricingController.updatePriceForCart(prodConfig.id,false);
		}



			@isTest
		public static void makeCustomPricingInvalidID() {
			Test.setMock(HttpCalloutMock.class, new APT_HttpCallouts_Mock.APT_HttpCallouts_MockInvalidCusID());

			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			account.LEGACY_ID__c = '46043';
			Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

			APT_Lodgement_Zone__c lodgementZone = APT_TestDataFactory.getAPTLodgementZone(1, true)[0];
			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, true)[0];
			Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];
			lineItem.Apttus_Config2__LineType__c = 'Option';

			List<Apttus_Config2__ProductAttributeValue__c> pavList= new List<Apttus_Config2__ProductAttributeValue__c>();
			Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
			pav.APT_Lodgement_Zone__c = lodgementZone.Id;
			pav.APT_Additional_Lodgement_Zone_1__c = 'Capital';
			pav.APT_Additional_Lodgement_Zone_2__c = 'Capital';
			pav.APT_Customer_Tier__c = 'T04';
			pavList.add(pav);

			List<ID> lineItemIDList= new List<ID>();
			List<Apttus_Config2__LineItem__c> lineItemList= new List<Apttus_Config2__LineItem__c>();
			lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
			lineItemList.add(lineItem);
			lineItemIDList.add(lineItem.id);

			Deal_Support_Request__c dealSupportReq = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
			dealSupportReq.Approved_Event__c = APT_Constants.PSR_APPC_CUSTOM_PRICING;
			dealSupportReq.Approved_lodgement_zone__c = 'Capital';
			dealSupportReq.Quote_Validity_End_Date__c=system.today() + 60;
			dealSupportReq.Approved_Tier__c='T07';
			dealSupportReq.Approved_Pricing_Structure__c= 'Z006';
			dealSupportReq.Organisation__c =  account.id;
			dealSupportReq.Opportunity__c = opportunityRecord.id;
			dealSupportReq.Compass_Quote_Reference__c = 'PDA-COMPASS-0000000103';


			Test.startTest();
			try{
				APT_CompassPricingController.HttpRequestWrapper reqWrap= new APT_CompassPricingController.HttpRequestWrapper(dealSupportReq.Compass_Quote_Reference__c, account.LEGACY_ID__c, 'PD');
				HttpResponse res = APT_HttpCallouts.makeCompassAPIRequest(reqWrap);
				system.assertEquals(400,res.getStatusCode());
				//CI-904 Test class changes to accomodate Changes to I2,removed a method parameter as its no longer in use
				APT_CompassPricingController.updateCartForCustomPricing(dealSupportReq,prodConfig.id,lineItem.Id);
			}catch(Exception e){

			}
			Test.stopTest();
		}


			@isTest
		public static void makeCustomPricingDataNotFound() {
			Test.setMock(HttpCalloutMock.class, new APT_HttpCallouts_Mock.APT_HttpCallouts_MockDataNotFound());

			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			account.LEGACY_ID__c = '4604376';
			Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

			APT_Lodgement_Zone__c lodgementZone = APT_TestDataFactory.getAPTLodgementZone(1, true)[0];
			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, true)[0];
			Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];
			lineItem.Apttus_Config2__LineType__c = 'Option';

			List<Apttus_Config2__ProductAttributeValue__c> pavList= new List<Apttus_Config2__ProductAttributeValue__c>();
			Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
			pav.APT_Lodgement_Zone__c = lodgementZone.Id;
			pav.APT_Additional_Lodgement_Zone_1__c = 'Capital';
			pav.APT_Additional_Lodgement_Zone_2__c = 'Capital';
			pav.APT_Customer_Tier__c = 'T04';
			pavList.add(pav);

			List<ID> lineItemIDList= new List<ID>();
			List<Apttus_Config2__LineItem__c> lineItemList= new List<Apttus_Config2__LineItem__c>();
			lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
			lineItemList.add(lineItem);
			lineItemIDList.add(lineItem.id);

			Deal_Support_Request__c dealSupportReq = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
			dealSupportReq.Approved_Event__c = APT_Constants.PSR_APPC_CUSTOM_PRICING;
			dealSupportReq.Approved_lodgement_zone__c = 'Capital';
			dealSupportReq.Quote_Validity_End_Date__c=system.today() + 60;
			dealSupportReq.Approved_Tier__c='T07';
			dealSupportReq.Approved_Pricing_Structure__c= 'Z006';
			dealSupportReq.Organisation__c =  account.id;
			dealSupportReq.Opportunity__c = opportunityRecord.id;
			dealSupportReq.Compass_Quote_Reference__c = 'PDA-COMPASS-0000000000';

			Test.startTest();
			try{
				APT_CompassPricingController.HttpRequestWrapper reqWrap= new APT_CompassPricingController.HttpRequestWrapper(dealSupportReq.Compass_Quote_Reference__c, account.LEGACY_ID__c, 'PD');
				HttpResponse res = APT_HttpCallouts.makeCompassAPIRequest(reqWrap);
				system.assertEquals(400,res.getStatusCode());
				//CI-904 Test class changes to accomodate Changes to I2,removed a method parameter as its no longer in use
				APT_CompassPricingController.updateCartForCustomPricing(dealSupportReq,prodConfig.id,lineItem.Id);
			}catch(Exception e){

			}
			Test.stopTest();
		}


			@isTest
		public static void makeCustomPricingInvalidRatingModel() {
			Test.setMock(HttpCalloutMock.class, new APT_HttpCallouts_Mock.APT_HttpCallouts_MockInvalidRatingModel());

			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			account.LEGACY_ID__c = '4604376';
			Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

			APT_Lodgement_Zone__c lodgementZone = APT_TestDataFactory.getAPTLodgementZone(1, true)[0];
			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, true)[0];
			Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];
			lineItem.Apttus_Config2__LineType__c = 'Option';

			List<Apttus_Config2__ProductAttributeValue__c> pavList= new List<Apttus_Config2__ProductAttributeValue__c>();
			Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
			pav.APT_Lodgement_Zone__c = lodgementZone.Id;
			pav.APT_Additional_Lodgement_Zone_1__c = 'Capital';
			pav.APT_Additional_Lodgement_Zone_2__c = 'Capital';
			pav.APT_Customer_Tier__c = 'T04';
			pavList.add(pav);

			List<ID> lineItemIDList= new List<ID>();
			List<Apttus_Config2__LineItem__c> lineItemList= new List<Apttus_Config2__LineItem__c>();
			lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
			lineItemList.add(lineItem);
			lineItemIDList.add(lineItem.id);


			Deal_Support_Request__c dealSupportReq = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
			dealSupportReq.Approved_Event__c = APT_Constants.PSR_APPC_CUSTOM_PRICING;
			dealSupportReq.Approved_lodgement_zone__c = 'Capital';
			dealSupportReq.Quote_Validity_End_Date__c=system.today() + 60;
			dealSupportReq.Approved_Tier__c='T07';
			dealSupportReq.Approved_Pricing_Structure__c= 'Z006';
			dealSupportReq.Organisation__c =  account.id;
			dealSupportReq.Opportunity__c = opportunityRecord.id;
			dealSupportReq.Compass_Quote_Reference__c = 'PDA-COMPASS-0000000000';

			Test.startTest();
			try{
				APT_CompassPricingController.HttpRequestWrapper reqWrap= new APT_CompassPricingController.HttpRequestWrapper(dealSupportReq.Compass_Quote_Reference__c, account.LEGACY_ID__c, 'PD');
				HttpResponse res = APT_HttpCallouts.makeCompassAPIRequest(reqWrap);
				system.assertEquals(400,res.getStatusCode());
				//CI-904 Test class changes to accomodate Changes to I2,removed a method parameter as its no longer in use
				APT_CompassPricingController.updateCartForCustomPricing(dealSupportReq,prodConfig.id,lineItem.Id);
			}catch(Exception e){

			}
			Test.stopTest();
		}

		@isTest
		public static void makeCustomPricingInvalidQuote() {
			Test.setMock(HttpCalloutMock.class, new APT_HttpCallouts_Mock.APT_HttpCallouts_MockINVALID_QUOTE());

			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			account.LEGACY_ID__c = '4604376';
			Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

			APT_Lodgement_Zone__c lodgementZone = APT_TestDataFactory.getAPTLodgementZone(1, true)[0];
			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, true)[0];
			Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];
			lineItem.Apttus_Config2__LineType__c = 'Option';

			List<Apttus_Config2__ProductAttributeValue__c> pavList= new List<Apttus_Config2__ProductAttributeValue__c>();
			Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
			pav.APT_Lodgement_Zone__c = lodgementZone.Id;
			pav.APT_Additional_Lodgement_Zone_1__c = 'Capital';
			pav.APT_Additional_Lodgement_Zone_2__c = 'Capital';
			pav.APT_Customer_Tier__c = 'T04';
			pavList.add(pav);

			List<ID> lineItemIDList= new List<ID>();
			List<Apttus_Config2__LineItem__c> lineItemList= new List<Apttus_Config2__LineItem__c>();
			lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
			lineItemList.add(lineItem);
			lineItemIDList.add(lineItem.id);


			Deal_Support_Request__c dealSupportReq = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
			dealSupportReq.Approved_Event__c = APT_Constants.PSR_APPC_CUSTOM_PRICING;
			dealSupportReq.Approved_lodgement_zone__c = 'Capital';
			dealSupportReq.Quote_Validity_End_Date__c=system.today() + 60;
			dealSupportReq.Approved_Tier__c='T07';
			dealSupportReq.Approved_Pricing_Structure__c= 'Z006';
			dealSupportReq.Organisation__c =  account.id;
			dealSupportReq.Opportunity__c = opportunityRecord.id;
			dealSupportReq.Compass_Quote_Reference__c = 'PDA-COMPASS-0000000000';

			Test.startTest();
			try{
				APT_CompassPricingController.HttpRequestWrapper reqWrap= new APT_CompassPricingController.HttpRequestWrapper(dealSupportReq.Compass_Quote_Reference__c, account.LEGACY_ID__c, 'PD');
				HttpResponse res = APT_HttpCallouts.makeCompassAPIRequest(reqWrap);
				system.assertEquals(400,res.getStatusCode());
				//CI-904 Test class changes to accomodate Changes to I2,removed a method parameter as its no longer in use
				APT_CompassPricingController.updateCartForCustomPricing(dealSupportReq,prodConfig.id,lineItem.Id);
			}catch(Exception e){

			}
			Test.stopTest();
		}

		@isTest
		public static void makeCustomPricingExpiredQuote() {
			Test.setMock(HttpCalloutMock.class, new APT_HttpCallouts_Mock.APT_HttpCallouts_MockEXPIRED_QUOTE());

			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			account.LEGACY_ID__c = '4604376';
			Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

			APT_Lodgement_Zone__c lodgementZone = APT_TestDataFactory.getAPTLodgementZone(1, true)[0];
			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, true)[0];
			Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];
			lineItem.Apttus_Config2__LineType__c = 'Option';

			List<Apttus_Config2__ProductAttributeValue__c> pavList= new List<Apttus_Config2__ProductAttributeValue__c>();
			Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
			pav.APT_Lodgement_Zone__c = lodgementZone.Id;
			pav.APT_Additional_Lodgement_Zone_1__c = 'Capital';
			pav.APT_Additional_Lodgement_Zone_2__c = 'Capital';
			pav.APT_Customer_Tier__c = 'T04';
			pavList.add(pav);

			List<ID> lineItemIDList= new List<ID>();
			List<Apttus_Config2__LineItem__c> lineItemList= new List<Apttus_Config2__LineItem__c>();
			lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
			lineItemList.add(lineItem);
			lineItemIDList.add(lineItem.id);


			Deal_Support_Request__c dealSupportReq = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
			dealSupportReq.Approved_Event__c = APT_Constants.PSR_APPC_CUSTOM_PRICING;
			dealSupportReq.Approved_lodgement_zone__c = 'Capital';
			dealSupportReq.Quote_Validity_End_Date__c=system.today() + 60;
			dealSupportReq.Approved_Tier__c='T07';
			dealSupportReq.Approved_Pricing_Structure__c= 'Z006';
			dealSupportReq.Organisation__c =  account.id;
			dealSupportReq.Opportunity__c = opportunityRecord.id;
			dealSupportReq.Compass_Quote_Reference__c = 'PDA-COMPASS-0000000000';

			Test.startTest();
			try{
				APT_CompassPricingController.HttpRequestWrapper reqWrap= new APT_CompassPricingController.HttpRequestWrapper(dealSupportReq.Compass_Quote_Reference__c, account.LEGACY_ID__c, 'PD');
				HttpResponse res = APT_HttpCallouts.makeCompassAPIRequest(reqWrap);
				system.assertEquals(400,res.getStatusCode());
				//CI-904 Test class changes to accomodate Changes to I2,removed a method parameter as its no longer in use
				APT_CompassPricingController.updateCartForCustomPricing(dealSupportReq,prodConfig.id,lineItem.Id);
			}catch(Exception e){

			}
			Test.stopTest();
		}

			@isTest
		public static void makeCustomPricingSYSTEM_ERROR() {
			Test.setMock(HttpCalloutMock.class, new APT_HttpCallouts_Mock.APT_HttpCallouts_MockSYSTEM_ERROR());

			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			account.LEGACY_ID__c = '4604376';
			Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

			APT_Lodgement_Zone__c lodgementZone = APT_TestDataFactory.getAPTLodgementZone(1, true)[0];
			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, true)[0];
			Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];
			lineItem.Apttus_Config2__LineType__c = 'Option';

			List<Apttus_Config2__ProductAttributeValue__c> pavList= new List<Apttus_Config2__ProductAttributeValue__c>();
			Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
			pav.APT_Lodgement_Zone__c = lodgementZone.Id;
			pav.APT_Additional_Lodgement_Zone_1__c = 'Capital';
			pav.APT_Additional_Lodgement_Zone_2__c = 'Capital';
			pav.APT_Customer_Tier__c = 'T04';
			pavList.add(pav);

			List<ID> lineItemIDList= new List<ID>();
			List<Apttus_Config2__LineItem__c> lineItemList= new List<Apttus_Config2__LineItem__c>();
			lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
			lineItemList.add(lineItem);
			lineItemIDList.add(lineItem.id);


			Deal_Support_Request__c dealSupportReq = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
			dealSupportReq.Approved_Event__c = APT_Constants.PSR_APPC_CUSTOM_PRICING;
			dealSupportReq.Approved_lodgement_zone__c = 'Capital';
			dealSupportReq.Quote_Validity_End_Date__c=system.today() + 60;
			dealSupportReq.Approved_Tier__c='T07';
			dealSupportReq.Approved_Pricing_Structure__c= 'Z006';
			dealSupportReq.Organisation__c =  account.id;
			dealSupportReq.Opportunity__c = opportunityRecord.id;
			dealSupportReq.Compass_Quote_Reference__c = 'PDA-COMPASS-0000000000';

			Test.startTest();
			try{
				APT_CompassPricingController.HttpRequestWrapper reqWrap= new APT_CompassPricingController.HttpRequestWrapper(dealSupportReq.Compass_Quote_Reference__c, account.LEGACY_ID__c, 'PD');
				HttpResponse res = APT_HttpCallouts.makeCompassAPIRequest(reqWrap);
				system.assertEquals(500,res.getStatusCode());
				//CI-904 Test class changes to accomodate Changes to I2,removed a method parameter as its no longer in use
				APT_CompassPricingController.updateCartForCustomPricing(dealSupportReq,prodConfig.id,lineItem.Id);
			}catch(Exception e){

			}
			Test.stopTest();
		}

		@isTest
		public static void testFailAPT_HttpCallouts(){
			Test.setMock(HttpCalloutMock.class, new APT_HttpCallouts_Mock.APT_HttpCallouts_MockInvalidHttpCall());
			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			account.LEGACY_ID__c = '4604376';
			Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

			APT_Lodgement_Zone__c lodgementZone = APT_TestDataFactory.getAPTLodgementZone(1, true)[0];
			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, true)[0];
			Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];
			lineItem.Apttus_Config2__LineType__c = 'Option';

			List<Apttus_Config2__ProductAttributeValue__c> pavList= new List<Apttus_Config2__ProductAttributeValue__c>();
			Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
			pav.APT_Lodgement_Zone__c = lodgementZone.Id;
			pav.APT_Additional_Lodgement_Zone_1__c = 'Capital';
			pav.APT_Additional_Lodgement_Zone_2__c = 'Capital';
			pav.APT_Customer_Tier__c = 'T04';
			pavList.add(pav);

			List<ID> lineItemIDList= new List<ID>();
			List<Apttus_Config2__LineItem__c> lineItemList= new List<Apttus_Config2__LineItem__c>();
			lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
			lineItemList.add(lineItem);
			lineItemIDList.add(lineItem.id);

			Deal_Support_Request__c dealSupportReq = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
			dealSupportReq.Approved_Event__c = APT_Constants.PSR_APPC_CUSTOM_PRICING;
			dealSupportReq.Approved_lodgement_zone__c = 'Capital';
			dealSupportReq.Quote_Validity_End_Date__c=system.today() + 60;
			dealSupportReq.Approved_Tier__c='T07';
			dealSupportReq.Approved_Pricing_Structure__c= 'Z006';
			dealSupportReq.Organisation__c =  account.id;
			dealSupportReq.Opportunity__c = opportunityRecord.id;
			dealSupportReq.Compass_Quote_Reference__c = 'PDA-COMPASS-0000000103';


			Test.startTest();
			try{
			APT_CompassPricingController.HttpRequestWrapper reqWrap= new APT_CompassPricingController.HttpRequestWrapper(dealSupportReq.Compass_Quote_Reference__c, account.LEGACY_ID__c, 'PD');
			APT_HttpCallouts.makeCompassAPIRequest(reqWrap);
			//CI-904 Test class changes to accomodate Changes to I2,removed a method parameter as its no longer in use
			APT_CompassPricingController.updateCartForCustomPricing(dealSupportReq,prodConfig.id,lineItem.Id);
			}Catch(exception e){

			}
			Test.stopTest();

		}

			@isTest
		public static void makeCustomPricingDATA_NOT_FOUND404() {
			Test.setMock(HttpCalloutMock.class, new APT_HttpCallouts_Mock.APT_HttpCallouts_MockDataNotFound404());

			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			account.LEGACY_ID__c = '4604376';
			Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];

			APT_Lodgement_Zone__c lodgementZone = APT_TestDataFactory.getAPTLodgementZone(1, true)[0];
			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, true)[0];
			Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];
			lineItem.Apttus_Config2__LineType__c = 'Option';

			List<Apttus_Config2__ProductAttributeValue__c> pavList= new List<Apttus_Config2__ProductAttributeValue__c>();
			Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
			pav.APT_Lodgement_Zone__c = lodgementZone.Id;
			pav.APT_Additional_Lodgement_Zone_1__c = 'Capital';
			pav.APT_Additional_Lodgement_Zone_2__c = 'Capital';
			pav.APT_Customer_Tier__c = 'T04';
			pavList.add(pav);

			List<ID> lineItemIDList= new List<ID>();
			List<Apttus_Config2__LineItem__c> lineItemList= new List<Apttus_Config2__LineItem__c>();
			lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
			lineItemList.add(lineItem);
			lineItemIDList.add(lineItem.id);


			Deal_Support_Request__c dealSupportReq = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
			dealSupportReq.Approved_Event__c = APT_Constants.PSR_APPC_CUSTOM_PRICING;
			dealSupportReq.Approved_lodgement_zone__c = 'Capital';
			dealSupportReq.Quote_Validity_End_Date__c=system.today() + 60;
			dealSupportReq.Approved_Tier__c='T07';
			dealSupportReq.Approved_Pricing_Structure__c= 'Z006';
			dealSupportReq.Organisation__c =  account.id;
			dealSupportReq.Opportunity__c = opportunityRecord.id;
			dealSupportReq.Compass_Quote_Reference__c = 'PDA-COMPASS-0000000000';

			Test.startTest();
			try{
			APT_CompassPricingController.HttpRequestWrapper reqWrap= new APT_CompassPricingController.HttpRequestWrapper(dealSupportReq.Compass_Quote_Reference__c, account.LEGACY_ID__c, 'PD');
			APT_HttpCallouts.makeCompassAPIRequest(reqWrap);
			//CI-904 Test class changes to accomodate Changes to I2,removed a method parameter as its no longer in use
			APT_CompassPricingController.updateCartForCustomPricing(dealSupportReq,prodConfig.id,lineItem.Id);
			//APT_CompassPricingController.updateRecordForCustomPricing(prodConfig.id,dealSupportReq);
			}catch(exception e){

			}
			Test.stopTest();
		}

		@IsTest
		public static void testFetchConfigRequestId2(){
			// =====================================
			// Data Preparation
			// =====================================
			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, true)[0];
			// =====================================
			// Stubbing
			// =====================================

			APT_ConfigTempObjectsSelector mockSelector = (APT_ConfigTempObjectsSelector) MockUtility.mockSelector(APT_ConfigTempObjectsSelector.class);
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelector.selectByConfigId((Set<Id>)fflib_Match.eq(new Set<Id>{prodConfig.Id}))).thenThrow(new MockException());
			MockUtility.Mocks.stopStubbing();
			// =====================================
			// Testing
			// =====================================

			Test.startTest();
			Id configReqId;
			try{
				configReqId = APT_CompassPricingController.fetchConfigRequestId(prodConfig.Id);
			}catch(exception e){
				System.assertEquals(configReqId, null, 'Expected exception to be thrown');
			}

			Test.stopTest();
		}

		@isTest
		public static void setCustTierDefaultTest() {
			Test.setMock(HttpCalloutMock.class, new APT_HttpCallouts_Mock());
			Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
			account.LEGACY_ID__c = '61918806';

			Contact con = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];


			Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];


				//get Product and set Product Type
			Product2 product =APT_TestUtils.createAPPCProduct('Car',APT_Constants.PRODUCT_CODE_APPC,'Postal Services');
			product.APT_Product_type__c = 'Workforce Verification';//add product type to product


			//get Price List and Price List Item
			Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();

			Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');


			//get Proposal/Quote and Product Configuration
			Apttus_Proposal__Proposal__c quote = APT_TestDataFactory.getAPTProposalRecord(1, opportunityRecord.id, account.Id, con.id, true)[0];

			Apttus_Config2__ProductConfiguration__c config = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, true)[0];
			config.Apttus_QPConfig__Proposald__c=quote.id;
			config.Apttus_Config2__PriceListId__c=priceList.id;

			List<ID> configIDList = new List<ID>();
			configIDList.add(config.id);

			//get summary group, Product Option Component, Classification and Hierarchy
			Apttus_Config2__SummaryGroup__c summaryGroup = APT_TestDataFactory.getSummaryGroupRecord(1, config.Id, 78, 45, true)[0];

			Apttus_Config2__ProductOptionComponent__c prodOptionComponent = APT_TestDataFactory.getProductOptionComponentRecord(1, 2, true)[0];

			Apttus_Config2__ClassificationName__c category = APT_TestDataFactory.getClassificationNameRecord(1, 'Test', 'High', 'Offering', 'Sample', true)[0];

			Apttus_Config2__ClassificationHierarchy__c classHierarchy = APT_TestDataFactory.getClassificationHierarchyRecord(1, category.id, 'Sample', true)[0];


			//get line item's data
			Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getConfigLineItemRecords(1,config.id,summaryGroup.id, 2, product.id, prodOptionComponent.id,
					product.id,classHierarchy.id, 2.3,false,'',2,priceList.id,priceListItem.Id,'','','','', 22.00,24.00, 34.00,23.00,33.50, true)[0];
			lineItem.Apttus_Config2__ConfigurationId__c = config.id;
			lineItem.Apttus_Config2__LineType__c = APT_Constants.LABEL_LINE_TYPE_OPTION;
			lineItem.Compass_LineItem_Identifier__c = 'MHS-LD_SU000';


			Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];

			List<Apttus_Config2__ProductAttributeValue__c> pavListQuery = new List<Apttus_Config2__ProductAttributeValue__c>();
			List<ID> pavIDList = new List<ID>();
			pavIDList.add(lineItem.Apttus_Config2__AttributeValueId__c);
			pavListQuery.add(pav);

			Deal_Support_Request__c dealSupportReq = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
			dealSupportReq.Quote_Validity_End_Date__c=system.today() + 60;
			dealSupportReq.Approved_Event__c = APT_Constants.PSR_APPC_CUSTOM_PRICING;
			dealSupportReq.Approved_lodgement_zone__c = 'Capital';
			dealSupportReq.Approved_Tier__c='T07';
			dealSupportReq.Approved_Pricing_Structure__c= 'Z006';
			dealSupportReq.Compass_Quote_Reference__c = 'PDA-COMPASS-0000000103';
			dealSupportReq.RecordTypeID= RecordTypesSelector.newInstance().selectByDeveloperName('Deal_Support_Request__c', new Set<String>{APT_Constants.PSR_APPC_RECORD_TYPE_APINAME}).values()[0].Id;
			dealSupportReq.Speed__c='Standard';
			dealSupportReq.Returns__c=true;
			dealSupportReq.Features__c='Signature on delivery';
			dealSupportReq.Surcharges__c='Manual handling surcharge';

			Deal_Support_Request__c dealSupportReq2 = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
			dealSupportReq2.Quote_Validity_End_Date__c=system.today() + 60;
			dealSupportReq2.Approved_Event__c = APT_Constants.PSR_APPC_STANDARD_DELEGATED_PRICING;
			dealSupportReq2.Approved_lodgement_zone__c = 'Capital';
			dealSupportReq2.Approved_Tier__c='T07';
			dealSupportReq2.Approved_Pricing_Structure__c= 'Z006';
			dealSupportReq2.Compass_Quote_Reference__c = 'PDA-COMPASS-0000000103';
			dealSupportReq2.RecordTypeID= RecordTypesSelector.newInstance().selectByDeveloperName('Deal_Support_Request__c', new Set<String>{APT_Constants.PSR_APPC_RECORD_TYPE_APINAME}).values()[0].Id;
			dealSupportReq2.Speed__c='Standard';
			dealSupportReq2.Returns__c=true;
			dealSupportReq2.Features__c='Signature on delivery';
			dealSupportReq2.Surcharges__c='Manual handling surcharge';


			List<APT_UPT_Dimension4Value__c> aList = new List<APT_UPT_Dimension4Value__c>();
			APT_UPT_Dimension4Value__c uptDimension4BRValuesSetting = new APT_UPT_Dimension4Value__c();
			uptDimension4BRValuesSetting.Name = APT_Constants.APT_KG_Rate;
			uptDimension4BRValuesSetting.BR_KR__c = '_KR';
			aList.add(uptDimension4BRValuesSetting);

			APT_UPT_Dimension4Value__c uptDimension4KRValuesSetting = new APT_UPT_Dimension4Value__c();
			uptDimension4KRValuesSetting.Name = APT_Constants.APT_Basic_Rate;
			uptDimension4KRValuesSetting.BR_KR__c = '_BR';
			aList.add(uptDimension4KRValuesSetting);
			insert aList;

			APT_ProductAttributeValuesSelector mockSelectorPav = (APT_ProductAttributeValuesSelector) MockUtility.mockSelector(APT_ProductAttributeValuesSelector.class);
			MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelectorPav.selectByPavID(pavIDList)).thenReturn(
				new List<Apttus_Config2__ProductAttributeValue__c>(new List<Apttus_Config2__ProductAttributeValue__c>{pav}));
			MockUtility.Mocks.stopStubbing();

			APT_ProductAttributeValuesSelector mockSelector = (APT_ProductAttributeValuesSelector) MockUtility.mockSelector(APT_ProductAttributeValuesSelector.class);
			ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelector.selectByconfigIDAndLineType(configIDList)).thenReturn(
				new Map<Id, Apttus_Config2__ProductAttributeValue__c>(new List<Apttus_Config2__ProductAttributeValue__c>{pav}));
			MockUtility.Mocks.stopStubbing();

			LineItemsSelector mockSelector1 = (LineItemsSelector) MockUtility.mockSelector(LineItemsSelector.class);
			MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelector1.selectByProdConfId(new set<ID>{(ID)config.Id})).thenReturn(
				new List<Apttus_Config2__LineItem__c>(new List<Apttus_Config2__LineItem__c>{lineItem}));
			MockUtility.Mocks.stopStubbing();

			LineItemsSelector mockSelector2 = (LineItemsSelector) MockUtility.mockSelector(LineItemsSelector.class);
			MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelector2.selectByProdConfId(config.Id)).thenReturn(
				new Map<id,Apttus_Config2__LineItem__c>(new List<Apttus_Config2__LineItem__c>{lineItem}));
			MockUtility.Mocks.stopStubbing();

				//Query Selector for Product Configuration
			ProductConfigurationSelector mockSelector3 = (ProductConfigurationSelector) MockUtility.mockSelector(ProductConfigurationSelector.class);
			MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelector3.selectByConfigId(new set<ID>{(ID)config.Id})).thenReturn(
				new List<Apttus_Config2__ProductConfiguration__c>(new List<Apttus_Config2__ProductConfiguration__c>{config}));
			MockUtility.Mocks.stopStubbing();

			//Query Selector for Proposal
			APT_ProposalObjectsSelector mockSelector4 = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
			MockUtility.mockDatabase();
			MockUtility.Mocks.startStubbing();
			MockUtility.Mocks.when(mockSelector4.selectByConfigId(new set<ID>{(ID)config.Id})).thenReturn(
				new Map<Id,Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{quote}));
			MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
			MockUtility.Mocks.stopStubbing();

			Test.startTest();
			String defaultTier = APT_CompassPricingController.setCustTierDefault(config.id,dealSupportReq);
			//CI-904 Test class changes to accomodate Changes to I2,removed a method parameter as its no longer in use
			APT_CompassPricingController.updateCartForCustomPricing(dealSupportReq,config.id,lineItem.Id);
			APT_CompassPricingController.updateCartForCustomPricing(dealSupportReq2,config.id,lineItem.Id);
			APT_CompassPricingController.cleanUpInvalidLineItems(config.id,true,new list<Apttus_Config2__LineItem__c>{lineItem});
			Test.stopTest();

			System.assertNotEquals(defaultTier, null, 'Expected default customer tier to be returned');
		}

		private class MockException extends Exception
		{
		}
	}