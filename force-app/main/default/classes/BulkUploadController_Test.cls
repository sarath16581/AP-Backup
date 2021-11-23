/***
 * @author Ranjeewa Silva
 * @date 2021-03-09
 * @group Tests
 * @tag BulkUpload, Tests
 * @domain Core
 * @description Test Scenarios for bulk upload
 * @changelog
 * 2021-03-09 - Ranjeewa Silva - Created.
 */

@IsTest
private class BulkUploadController_Test {

    @IsTest
    static void testLoadConfig() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        BulkUploadService mockService = (BulkUploadService)MockUtility.mockUtility(BulkUploadService.class);
        Map<String, BulkUploadService.FieldMappingConfigItem> mockFieldMapping = new Map<String, BulkUploadService.FieldMappingConfigItem>();
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockService.getFieldMapping((BulkUploadService.UploadType)fflib_Match.eq(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS))).thenReturn(mockFieldMapping);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        Map<String, Object> config = BulkUploadController.loadConfig(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name());

        Test.stopTest();

        System.assertNotEquals(null, config, 'Expected config for upload type; but got null.');
        System.assertNotEquals(null, config.get('fieldMapping'), 'Expected field mapping for upload type; but got null.');
        System.assertEquals(mockFieldMapping, config.get('fieldMapping'), 'Expected field mapping for upload type; but got something else.');
    }

    @IsTest
    static void testLoadConfigUnexpectedException() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        BulkUploadService mockService = (BulkUploadService)MockUtility.mockUtility(BulkUploadService.class);
        Map<String, BulkUploadService.FieldMappingConfigItem> mockFieldMapping = new Map<String, BulkUploadService.FieldMappingConfigItem>();
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockService.getFieldMapping((BulkUploadService.UploadType)fflib_Match.eq(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS))).thenThrow(new BulkUploadService.BulkUploadException());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        try {
            Map<String, Object> config = BulkUploadController.loadConfig(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name());
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException auraEx) {
            //expected
        } catch (Exception ex) {
            System.assert(false, 'Expected AuraHandledException; but got some other exception');
        }

        Test.stopTest();
    }

    @IsTest
    static void testCreateRequest() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c newRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, false)[0];

        // =====================================
        // Stubbing
        // =====================================
        BulkUploadService mockService = (BulkUploadService)MockUtility.mockUtility(BulkUploadService.class);
        BulkUploadService.BulkUploadRequestSaveResult saveResults = new BulkUploadService.BulkUploadRequestSaveResult();
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockService.createRequest((BulkLoadRequest__c)fflib_Match.eq(newRequest), fflib_Match.eqBoolean(true))).thenReturn(saveResults);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadService.BulkUploadRequestSaveResult results = BulkUploadController.createRequest(newRequest, true);

        Test.stopTest();

        System.assertNotEquals(null, results, 'Expected valid save results; but got null.');
    }

    @IsTest
    static void testCreateRequestUnexpectedException() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c newRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, false)[0];

        // =====================================
        // Stubbing
        // =====================================
        BulkUploadService mockService = (BulkUploadService)MockUtility.mockUtility(BulkUploadService.class);
        BulkUploadService.BulkUploadRequestSaveResult saveResults = new BulkUploadService.BulkUploadRequestSaveResult();
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockService.createRequest((BulkLoadRequest__c)fflib_Match.eq(newRequest), fflib_Match.eqBoolean(true))).thenThrow(new BulkUploadService.BulkUploadException());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        try {
            BulkUploadService.BulkUploadRequestSaveResult results = BulkUploadController.createRequest(newRequest, true);
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException auraEx) {
            //expected
        } catch (Exception ex) {
            System.assert(false, 'Expected AuraHandledException; but got some other exception');
        }

        Test.stopTest();
    }

    @IsTest
    static void testUploadLineItems() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c request = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];
        List<BulkLoadRequestLineItem__c> lineItems = ApplicationTestDataFactory.getBulkLoadRequestLineItems(3, request.Id, false);

        // =====================================
        // Stubbing
        // =====================================
        BulkUploadService mockService = (BulkUploadService)MockUtility.mockUtility(BulkUploadService.class);
        BulkUploadService.LineItemsSaveResult saveResults = new BulkUploadService.LineItemsSaveResult();
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockService.createLineItems((Id)fflib_Match.eq(request.Id), (List<BulkLoadRequestLineItem__c>)fflib_Match.eqList(lineItems))).thenReturn(saveResults);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadService.LineItemsSaveResult results = BulkUploadController.uploadLineItems(request, lineItems);

        Test.stopTest();

        System.assertNotEquals(null, results, 'Expected valid save results; but got null.');
    }

    @IsTest
    static void testUploadLineItemsUnexpectedException() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c request = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];
        List<BulkLoadRequestLineItem__c> lineItems = ApplicationTestDataFactory.getBulkLoadRequestLineItems(3, request.Id, false);

        // =====================================
        // Stubbing
        // =====================================
        BulkUploadService mockService = (BulkUploadService)MockUtility.mockUtility(BulkUploadService.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockService.createLineItems((Id)fflib_Match.eq(request.Id), (List<BulkLoadRequestLineItem__c>)fflib_Match.eqList(lineItems))).thenThrow(new BulkUploadService.BulkUploadException());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        try {
            BulkUploadService.LineItemsSaveResult results = BulkUploadController.uploadLineItems(request, lineItems);
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException auraEx) {
            //expected
        } catch (Exception ex) {
            System.assert(false, 'Expected AuraHandledException; but got some other exception');
        }

        Test.stopTest();
    }

    @IsTest
    static void testFinaliseRequest() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c request = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];

        // =====================================
        // Stubbing
        // =====================================
        BulkUploadService mockService = (BulkUploadService)MockUtility.mockUtility(BulkUploadService.class);
        MockUtility.Mocks.startStubbing();
        ((BulkUploadService)MockUtility.Mocks.doAnswer(new DoNothingAnswer(), mockService)).finaliseUploading((BulkLoadRequest__c)fflib_Match.eq(request), fflib_Match.eqBoolean(true));
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadController.finaliseRequest(request, true);

        Test.stopTest();

        ((BulkUploadService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).finaliseUploading((BulkLoadRequest__c)fflib_Match.eq(request), fflib_Match.eqBoolean(true));
    }

    @IsTest
    static void testFinaliseRequestUnexpectedException() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c request = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];

        // =====================================
        // Stubbing
        // =====================================
        BulkUploadService mockService = (BulkUploadService)MockUtility.mockUtility(BulkUploadService.class);
        MockUtility.Mocks.startStubbing();
        ((BulkUploadService)MockUtility.Mocks.doAnswer(new ThrowBulkUploadExceptionAnswer(), mockService)).finaliseUploading((BulkLoadRequest__c)fflib_Match.eq(request), fflib_Match.eqBoolean(true));
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        try {
            BulkUploadController.finaliseRequest(request, true);
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException auraEx) {
            //expected
        } catch (Exception ex) {
            System.assert(false, 'Expected AuraHandledException; but got some other exception');
        }

        Test.stopTest();
    }

    @IsTest
    static void testGetBulkLoadRequests() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        BulkLoadRequestSelector mockSelector = (BulkLoadRequestSelector)MockUtility.mockSelector(BulkLoadRequestSelector.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByTypeAndUploadDate((Integer)fflib_Match.anyObject(), (Set<String>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject())).thenReturn(new Map<Id, BulkLoadRequest__c>());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        List<BulkLoadRequest__c> results = BulkUploadController.getBulkLoadRequestsByTypeAndCreatedDate(30, BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name());

        Test.stopTest();

        System.assertNotEquals(null, results, 'Expected to get a list of bulk load requests; but got null');

    }

    @IsTest
    static void testGetLineItems() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c request = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];

        // =====================================
        // Stubbing
        // =====================================
        BulkLoadRequestLineItemsSelector mockSelector = (BulkLoadRequestLineItemsSelector)MockUtility.mockSelector(BulkLoadRequestLineItemsSelector.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByBulkLoadRequestAndStatus((Id)fflib_Match.eq(request.Id), (Set<String>) fflib_Match.anyObject())).thenReturn(new Map<Id, BulkLoadRequestLineItem__c>());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        List<BulkLoadRequestLineItem__c> results = BulkUploadController.getLineItems(request.Id);

        Test.stopTest();

        System.assertNotEquals(null, results, 'Expected to get a list of line items; but got null');

    }

    public class DoNothingAnswer implements fflib_Answer {
        public Object answer(fflib_InvocationOnMock invocation)
        {
            return null;
        }
    }

    public class ThrowBulkUploadExceptionAnswer implements fflib_Answer {
        public Object answer(fflib_InvocationOnMock invocation)
        {
            throw new BulkUploadService.BulkUploadException();
        }
    }
}