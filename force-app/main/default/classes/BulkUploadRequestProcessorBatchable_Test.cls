/***
 * @author Ranjeewa Silva
 * @date 2021-03-09
 * @group Tests
 * @tag BulkUpload, Tests
 * @domain Core
 * @description Test Scenarios for bulk upload request processor batch
 * @changelog
 * 2021-03-09 - Ranjeewa Silva - Created.
 */

@IsTest
private class BulkUploadRequestProcessorBatchable_Test {

    @IsTest
    static void testBatchStart() {
        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c request = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];

        // =====================================
        // Stubbing
        // =====================================
        BulkLoadRequestLineItemsSelector mockSelector = (BulkLoadRequestLineItemsSelector)MockUtility.mockSelector(BulkLoadRequestLineItemsSelector.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByBulkLoadRequestAndStatusQueryLocator((Id)fflib_Match.eq(request.Id), (Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(null);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadRequestProcessorBatchable batch = new BulkUploadRequestProcessorBatchable(request.Id, BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS);
        batch.start(null);

        Test.stopTest();

        //verify that selector is called once with bulk load request id to get the query locator
        ((BulkLoadRequestLineItemsSelector)MockUtility.Mocks.verify(mockSelector, MockUtility.Mocks.times(1))).selectByBulkLoadRequestAndStatusQueryLocator((Id)fflib_Match.eq(request.Id), (Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());
    }

    @IsTest
    static void testBatchExecute() {
        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c request = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];

        List<BulkLoadRequestLineItem__c> lineItems = ApplicationTestDataFactory.getBulkLoadRequestLineItems(5, request.Id, true);

        // =====================================
        // Stubbing
        // =====================================
        BulkUploadService mockService = (BulkUploadService)MockUtility.mockUtility(BulkUploadService.class);

        MockUtility.Mocks.startStubbing();
        BulkUploadService.LineItemsProcessResult processResults = new BulkUploadService.LineItemsProcessResult();
        processResults.successCount = 5;
        processResults.errorCount = 0;
        MockUtility.Mocks.when(mockService.processLineItems((BulkUploadService.UploadType)fflib_Match.eq(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS), (List<BulkLoadRequestLineItem__c>)fflib_Match.eqList(lineItems), (Map<String,Object>)fflib_Match.anyObject())).thenReturn(processResults);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadRequestProcessorBatchable batch = new BulkUploadRequestProcessorBatchable(request.Id, BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS);
        batch.execute(null, lineItems);

        Test.stopTest();

        //verify that BulkUploadService.processLineItems(..) is called once with the list of line items to process them
        ((BulkUploadService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).processLineItems((BulkUploadService.UploadType)fflib_Match.eq(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS), (List<BulkLoadRequestLineItem__c>)fflib_Match.eqList(lineItems), (Map<String,Object>)fflib_Match.anyObject());

    }

    @IsTest
    static void testBatchFinish() {
        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c request = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];

        // =====================================
        // Stubbing
        // =====================================
        BulkUploadService mockService = (BulkUploadService)MockUtility.mockUtility(BulkUploadService.class);

        MockUtility.Mocks.startStubbing();
        ((BulkUploadService)MockUtility.Mocks.doAnswer(new DoNothingAnswer(), mockService)).finaliseProcessing((BulkUploadService.UploadType)fflib_Match.eq(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS), fflib_Match.eqId(request.Id),  (BulkUploadService.LineItemsProcessResult)fflib_Match.anyObject(), (Map<String,Object>)fflib_Match.anyObject());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadRequestProcessorBatchable batch = new BulkUploadRequestProcessorBatchable(request.Id, BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS);
        batch.finish(null);

        Test.stopTest();

        //verify that BulkUploadService.finaliseProcessing(..) is called once with the request id to perform post processing logic
        ((BulkUploadService)MockUtility.Mocks.verify(mockService, MockUtility.Mocks.times(1))).finaliseProcessing((BulkUploadService.UploadType)fflib_Match.eq(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS), fflib_Match.eqId(request.Id),  (BulkUploadService.LineItemsProcessResult)fflib_Match.anyObject(), (Map<String,Object>)fflib_Match.anyObject());
    }

    private class DoNothingAnswer implements fflib_Answer {
        public Object answer(fflib_InvocationOnMock invocation)
        {
            return null;
        }
    }
}