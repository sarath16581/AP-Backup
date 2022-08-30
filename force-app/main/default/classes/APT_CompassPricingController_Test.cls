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
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(
            mockSelector.search((Map<String, Object>)fflib_Match.anyObject(),
            (Set<Object>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyObject())).thenReturn(dealSupportReqList);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        List<Deal_Support_Request__c> dsrList = APT_CompassPricingController.getPSRList(opportunityRecord.Id);
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
        Id psrAPPCRecTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Deal_Support_Request__c', new Set<String>{APT_Constants.PSR_APPC_RECORD_TYPE_APINAME}).values()[0].Id;
        List<Deal_Support_Request__c> dealSupportReqList = new List<Deal_Support_Request__c>();

        Map<String, Object> searchParams = new Map<String, Object>();
        searchParams.put('opportunityIds', new Set<Id>{opportunityRecord.Id});
        searchParams.put('recTypeIds', new Set<Id>{psrAPPCRecTypeId});
        searchParams.put('productNames', new Set<String>{APT_Constants.PSR_APPC_PRODUCT_NAME});
        // =====================================
        // Stubbing
        // =====================================
        DealSupportRequestsSelector mockSelector = (DealSupportRequestsSelector) MockUtility.mockSelector(DealSupportRequestsSelector.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.search((Map<String, Set<Id>>)fflib_Match.eq(searchParams),(Set<Object>)fflib_Match.eq(new Set<Object>()),fflib_Match.eqBoolean(true))).thenReturn(dealSupportReqList);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        try{
            List<Deal_Support_Request__c> dsrList = new List<Deal_Support_Request__c>();
            dsrList = APT_CompassPricingController.getPSRList(opportunityRecord.Id);
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
     * Test: when the method onApply is called, validate that the linking PSR functionality is completed successfully without any error.
     * Then, the product config record should be updated with pricing pending set to TRUE and a success message is returned.
     */
    @IsTest
    public static void testSuccessfulLinkingPSRForStandardDelegatedPricing(){
        // =====================================
        // Data Preparation
        // =====================================
        Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Contact con = APT_TestDataFactory.getAPTContactRecord(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        Apttus_Proposal__Proposal__c proposal = APT_TestDataFactory.getAPTProposalRecord(1, opportunityRecord.id, account.Id, con.id, true)[0];
        Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, null, true)[0];
        Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];             
        List<Apttus_Config2__LineItem__c> lineItemList= new List<Apttus_Config2__LineItem__c>();
        Map<Id, Apttus_Config2__ProductConfiguration__c> productConfig;
        List<ID> pavIDList= new List<ID>();

        APT_Lodgement_Zone__c lodgementZone = APT_TestDataFactory.getAPTLodgementZone(1, true)[0];

        List<Apttus_Config2__ProductAttributeValue__c> pavList= new List<Apttus_Config2__ProductAttributeValue__c>(); 
        Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
        pav.APT_Lodgement_Zone__c = lodgementZone.Id;
        pav.APT_Additional_Lodgement_Zone_1__c = 'Capital';
        pav.APT_Additional_Lodgement_Zone_2__c = 'Capital';
        pav.APT_Customer_Tier__c = 'T04';
        pavList.add(pav);

        lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
        lineItem.Apttus_Config2__LineType__c = 'Option';
        lineItemList.add(lineItem); 
        pavIDList.add(lineItem.Apttus_Config2__AttributeValueId__c);
        
        //Query Selector for DSR
        Deal_Support_Request__c dealSupportReq = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
        dealSupportReq.Approved_Event__c = APT_Constants.PSR_APPC_STANDARD_DELEGATED_PRICING;
        dealSupportReq.Approved_lodgement_zone__c = 'Capital';
        dealSupportReq.Quote_Validity_End_Date__c=system.today() + 60;
        dealSupportReq.Approved_Tier__c='T07';
        dealSupportReq.Approved_Pricing_Structure__c= 'Z006';
        
        // building compass pricing attributes to test a getter method
        APT_CompassPricingController compassPricingCon = new APT_CompassPricingController();
        compassPricingCon.lineItemId = lineItem.Id;
        compassPricingCon.configId = prodConfig.Id;
        compassPricingCon.opportunityId = opportunityRecord.Id;

        // code coverage for the goBack() PageReference method
        PageReference pageRef = Page.APT_Link_PSR;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('url','www.test.com');
        APT_CompassPricingController.goBack();

        // =====================================
        // Stubbing
        // =====================================
        APT_ProductAttributeValuesSelector mockSelector = (APT_ProductAttributeValuesSelector) MockUtility.mockSelector(APT_ProductAttributeValuesSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByLineItemId((Set<id>)fflib_Match.eq(new Set<Id>{lineItem.Id}))).thenReturn(
            new List<Apttus_Config2__ProductAttributeValue__c>(new List<Apttus_Config2__ProductAttributeValue__c>{pav}));
        MockUtility.Mocks.stopStubbing();

        //Query Selector for Line item
        LineItemsSelector mockSelector1 = (LineItemsSelector) MockUtility.mockSelector(LineItemsSelector.class);
        ApplicationDatabase mockDatabase1 = MockUtility.mockDatabase();
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector1.selectByProdConfId(new set<ID>{(ID)prodConfig.Id})).thenReturn(
            new List<Apttus_Config2__LineItem__c>(new List<Apttus_Config2__LineItem__c>{lineItem}));      
        MockUtility.Mocks.stopStubbing();
        
        //Query Selector for Product Attribute Values
        APT_ProductAttributeValuesSelector mockSelector2 = (APT_ProductAttributeValuesSelector) MockUtility.mockSelector(APT_ProductAttributeValuesSelector.class);
        ApplicationDatabase mockDatabase2 = MockUtility.mockDatabase();
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector2.selectByPavID((List<Id>)fflib_Match.eq(pavIDList))).thenReturn(
            new List<Apttus_Config2__ProductAttributeValue__c>(new List<Apttus_Config2__ProductAttributeValue__c>{pav}));     
        MockUtility.Mocks.stopStubbing();
        
        //Query Selector for Product Configuration
        ProductConfigurationSelector mockSelector3 = (ProductConfigurationSelector) MockUtility.mockSelector(ProductConfigurationSelector.class);
        ApplicationDatabase mockDatabase3 = MockUtility.mockDatabase();
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector3.selectByConfigId(new set<ID>{(ID)prodConfig.Id})).thenReturn(
            new List<Apttus_Config2__ProductConfiguration__c>(new List<Apttus_Config2__ProductConfiguration__c>{prodConfig}));     
        MockUtility.Mocks.stopStubbing();

        //Query Selector for Proposal
        APT_ProposalObjectsSelector mockSelector4 = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
        ApplicationDatabase mockDatabase4 = MockUtility.mockDatabase();
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector4.selectByConfigId(new set<ID>{(ID)prodConfig.Id})).thenReturn(
            new Map<Id,Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{proposal}));     
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
        MockUtility.Mocks.stopStubbing();


        
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        String successMsg = APT_CompassPricingController.onApply(dealSupportReq,prodConfig.Id,lineItem.Id);
        Test.stopTest();
        System.assertNotEquals(null, compassPricingCon.compassPricingAttributes, 'Instance variables should not be null');
        System.assertEquals(successMsg, System.Label.APT_LinkPSRSuccess, 'Link PSR must be successful');
        fflib_ArgumentCaptor updateRecCaptor = fflib_ArgumentCaptor.forClass(List<SObject>.class);
        //verify dml update has been made
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(2))).dmlUpdate((List<SObject>)updateRecCaptor.capture());
        for(SObject obj: (List<SObject>)updateRecCaptor.getValue()){
            if(obj instanceOf  Apttus_Config2__ProductConfiguration__c){
                Apttus_Config2__ProductConfiguration__c prodConfigResult = (Apttus_Config2__ProductConfiguration__c)obj;
                System.assertEquals(true, prodConfigResult.Apttus_Config2__IsPricePending__c, 'Price Pending is not set to TRUE');
            }
        }
        
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
            String result = APT_CompassPricingController.onApply(dealSupportReq,prodConfig.Id,lineItem.Id);
            System.assert(false, 'Expected Quote Validity Exception is not thrown.');
        }catch(Exception e){
            System.assert(true, 'Quote Validity Exception should be thrown');
        }

        try{
            dealSupportReq.Quote_Validity_End_Date__c = Date.Today();
            dealSupportReq.Approved_lodgement_zone__c = 'Metro';
            String result2 = APT_CompassPricingController.onApply(dealSupportReq,prodConfig.Id,lineItem.Id);
            System.assert(false, 'Expected Lodgement Zone Mismatch Exception is not thrown.');
        }catch(Exception e){
            System.assert(true, 'Lodgement Zone Mismatch Exception should be thrown');
        }

        try{
            dealSupportReq.Approved_lodgement_zone__c = 'Capital';
            String result = APT_CompassPricingController.onApply(dealSupportReq,'invalid prodConfigId',lineItem.Id);
            System.assert(false, 'Expected Exception is not thrown');
        }catch(Exception e){
            System.assert(true, 'Exception should be thrown');
        }
        Test.stopTest();
    }
     /**
     * Test: when the method onApply is called, validate that the linking PSR functionality is successfull .
     * It updates the Product Attribute value and Proposal record from DSR record.
     */    
    @IsTest
    public static void testSuccessfulLinkingPSRForStandardDelegatedPricingSameTier(){
        // =====================================
        // Data Preparation
        // =====================================
        Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Contact con = APT_TestDataFactory.getAPTContactRecord(1, account.Id, true)[0];
        Opportunity opportunityRecord = ApplicationTestDataFactory.getOpportunities(1, account.Id, true)[0];
        Apttus_Proposal__Proposal__c proposal = APT_TestDataFactory.getAPTProposalRecord(1, opportunityRecord.id, account.Id, con.id, true)[0];
        Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, account.Id, proposal.id, true)[0];
        Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, prodConfig.Id, true)[0];             
        List<Apttus_Config2__LineItem__c> lineItemList= new List<Apttus_Config2__LineItem__c>();
        
        List<ID> pavIDList= new List<ID>();

        APT_Lodgement_Zone__c lodgementZone = APT_TestDataFactory.getAPTLodgementZone(1, true)[0];

        List<Apttus_Config2__ProductAttributeValue__c> pavList= new List<Apttus_Config2__ProductAttributeValue__c>(); 
        Apttus_Config2__ProductAttributeValue__c pav = APT_TestDataFactory.getAPTProductAttributeValues(1, lineItem.Id, true)[0];
        pav.APT_Lodgement_Zone__c = lodgementZone.Id;
        pav.APT_Additional_Lodgement_Zone_1__c = 'Capital';       
        pav.APT_Customer_Tier__c = 'T04';
        pavList.add(pav);

        lineItem.Apttus_Config2__AttributeValueId__c = pav.id;
        lineItem.Apttus_Config2__LineType__c = 'Option';
        lineItemList.add(lineItem); 
        pavIDList.add(lineItem.Apttus_Config2__AttributeValueId__c);
        
        //Query Selector for DSR
        Deal_Support_Request__c dealSupportReq = ApplicationTestDataFactory.getDealSupportRequests(1, opportunityRecord.Id, account.Id, true)[0];
        dealSupportReq.Approved_Event__c = APT_Constants.PSR_APPC_STANDARD_DELEGATED_PRICING;
        dealSupportReq.Approved_lodgement_zone__c = 'Capital';
        dealSupportReq.Quote_Validity_End_Date__c=system.today() + 60;
        dealSupportReq.Approved_Tier__c='T04';
        dealSupportReq.Approved_Pricing_Structure__c= 'Z006';        
       

        // =====================================
        // Stubbing
        // =====================================
        //Query Selector for Product Attribute Values
        APT_ProductAttributeValuesSelector mockSelector = (APT_ProductAttributeValuesSelector) MockUtility.mockSelector(APT_ProductAttributeValuesSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByLineItemId((Set<id>)fflib_Match.eq(new Set<Id>{lineItem.Id}))).thenReturn(
            new List<Apttus_Config2__ProductAttributeValue__c>(new List<Apttus_Config2__ProductAttributeValue__c>{pav}));
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.eq(prodConfig))).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
        MockUtility.Mocks.stopStubbing();

        //Query Selector for Line item
        LineItemsSelector mockSelector1 = (LineItemsSelector) MockUtility.mockSelector(LineItemsSelector.class);
        ApplicationDatabase mockDatabase1 = MockUtility.mockDatabase();
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector1.selectByProdConfId(new set<ID>{(ID)prodConfig.Id})).thenReturn(
            new List<Apttus_Config2__LineItem__c>(new List<Apttus_Config2__LineItem__c>{lineItem}));      
        MockUtility.Mocks.stopStubbing();
        
        //Query Selector for Product Attribute Values
        APT_ProductAttributeValuesSelector mockSelector2 = (APT_ProductAttributeValuesSelector) MockUtility.mockSelector(APT_ProductAttributeValuesSelector.class);
        ApplicationDatabase mockDatabase2 = MockUtility.mockDatabase();
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector2.selectByPavID((List<Id>)fflib_Match.eq(pavIDList))).thenReturn(
            new List<Apttus_Config2__ProductAttributeValue__c>(new List<Apttus_Config2__ProductAttributeValue__c>{pav}));     
        MockUtility.Mocks.stopStubbing();
        
        //Query Selector for Product Configuration
        ProductConfigurationSelector mockSelector3 = (ProductConfigurationSelector) MockUtility.mockSelector(ProductConfigurationSelector.class);
        ApplicationDatabase mockDatabase3 = MockUtility.mockDatabase();
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector3.selectByConfigId(new set<ID>{(ID)prodConfig.Id})).thenReturn(
            new List<Apttus_Config2__ProductConfiguration__c>(new List<Apttus_Config2__ProductConfiguration__c>{prodConfig}));     
        MockUtility.Mocks.stopStubbing();
        
        //Query Selector for Proposal
        APT_ProposalObjectsSelector mockSelector4 = (APT_ProposalObjectsSelector) MockUtility.mockSelector(APT_ProposalObjectsSelector.class);
        ApplicationDatabase mockDatabase4 = MockUtility.mockDatabase();
        MockUtility.Mocks.startStubbing();
                                                                          MockUtility.Mocks.when(mockSelector4.selectByConfigId(new set<ID>{(ID)proposal.id})).thenReturn(
            new Map<Id,Apttus_Proposal__Proposal__c>(new List<Apttus_Proposal__Proposal__c>{proposal}));     
        MockUtility.Mocks.stopStubbing();


        
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        String successMsg = APT_CompassPricingController.onApply(dealSupportReq,prodConfig.Id,lineItem.Id);
        Test.stopTest();
        System.assertEquals(dealSupportReq.Approved_Tier__c,pav.APT_Customer_Tier__c, 'Tier should be same');
        System.assertEquals(successMsg, System.Label.APT_LinkPSRSuccess, 'Link PSR must be successful');
        fflib_ArgumentCaptor updatedProdConfigCaptor = fflib_ArgumentCaptor.forClass(List<Apttus_Config2__ProductConfiguration__c>.class);
        
    }
   
}