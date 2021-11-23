/***
 * @author Ranjeewa Silva
 * @date 2021-03-09
 * @group Tests
 * @tag BulkUpload, Tests
 * @domain Core
 * @description Test Scenarios for bulk upload service
 * @changelog
 * 2021-03-09 - Ranjeewa Silva - Created.
 */

@IsTest
private class BulkUploadService_Test {

    @IsTest
    static void testGetHandler() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadService.IBulkUploadRequestHandler handler = BulkUploadService.getInstance().getHandler(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS);
        System.assertNotEquals(null, handler, 'Expected an instance of CreditDisputeClaimsBulkUploadHandler; but got null');
        System.assert((handler instanceof CreditDisputeClaimsBulkUploadHandler), 'Expected an instance of CreditDisputeClaimsBulkUploadHandler; but got something else');

        try {
            handler = BulkUploadService.getInstance().getHandler(null);
            System.assert(false, 'Expected to throw BulkUploadException when an invalid upload type is passed in; but not thrown.');
        } catch (BulkUploadService.BulkUploadException bulkUploadException) {
            //expected
        } catch (Exception ex) {
            System.assert(false, 'Expected to throw BulkUploadException when an invalid upload type is passed in; but some other exception thrown.');
        }

        Test.stopTest();
    }

    @IsTest
    static void testGetFieldMapping() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        CreditDisputeClaimsBulkUploadHandler mockHandler = (CreditDisputeClaimsBulkUploadHandler)MockUtility.mockUtility(CreditDisputeClaimsBulkUploadHandler.class);

        Map<String, BulkUploadService.FieldMappingConfigItem> mockFieldMapping = new Map<String, BulkUploadService.FieldMappingConfigItem>();
        mockFieldMapping.put('test', new BulkUploadService.FieldMappingConfigItem('test', 'test', BulkUploadService.FIELD_TYPE_STRING, true));

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockHandler.getFieldMappingConfig()).thenReturn(mockFieldMapping);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        Map<String, BulkUploadService.FieldMappingConfigItem> fieldMapping = BulkUploadService.getInstance().getFieldMapping(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS);

        Test.stopTest();

        System.assertNotEquals(null, fieldMapping, 'Expected field mapping from request handler; but got null.');
        System.assertEquals(mockFieldMapping, fieldMapping, 'Expected field mapping from request handler; but got something else.');
    }

    @IsTest
    static void testCreateDuplicateRequestWithDuplicateCheckEnabled() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c existingRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];

        // =====================================
        // Stubbing
        // =====================================
        BulkLoadRequestSelector mockBulkLoadRequestSelector = (BulkLoadRequestSelector)MockUtility.mockSelector(BulkLoadRequestSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockBulkLoadRequestSelector.selectByTypeAndFileName(fflib_Match.eqString(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name()), (Set<String>) fflib_Match.anyObject())).thenReturn(new Map<Id, BulkLoadRequest__c> {existingRequest.Id => existingRequest});
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        BulkLoadRequest__c newRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, false)[0];
        newRequest.Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        BulkUploadService.BulkUploadRequestSaveResult saveResult = BulkUploadService.getInstance().createRequest(newRequest, true);
        Test.stopTest();

        System.assertNotEquals(null, saveResult, 'Expected save results; but received null');
        System.assertEquals(null, saveResult.requestId, 'Expected request to be not inserted when duplicate check fails.');
        System.assertNotEquals(null, saveResult.errorMessage, 'Expected error details to be returned when duplicate check fails.');

        // should not have attempted to insert a new request
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlInsert(new List<SObject>{newRequest});
    }

    @IsTest
    static void testCreateDuplicateRequestWithNoDuplicateCheck() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c newRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, false)[0];
        newRequest.Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();

        // =====================================
        // Stubbing
        // =====================================
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.listContains(newRequest))).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        BulkUploadService.BulkUploadRequestSaveResult saveResult = BulkUploadService.getInstance().createRequest(newRequest, false);
        Test.stopTest();

        System.assertNotEquals(null, saveResult, 'Expected save results; but received null');
        System.assertNotEquals(null, saveResult.requestId, 'Expected duplicate request to be inserted when no duplicate check done.');
        System.assertEquals(null, saveResult.errorMessage, 'Expected no errors to be returned when request is inserted.');

        // should have inserted the new request
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{newRequest});
    }

    @IsTest
    static void testCreateRequestWithDuplicateCheck() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c newRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, false)[0];
        newRequest.Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();

        // =====================================
        // Stubbing
        // =====================================
        BulkLoadRequestSelector mockBulkLoadRequestSelector = (BulkLoadRequestSelector)MockUtility.mockSelector(BulkLoadRequestSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockBulkLoadRequestSelector.selectByTypeAndFileName(fflib_Match.eqString(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name()), (Set<String>) fflib_Match.anyObject())).thenReturn(new Map<Id, BulkLoadRequest__c>());
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.listContains(newRequest))).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        newRequest.Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        BulkUploadService.BulkUploadRequestSaveResult saveResult = BulkUploadService.getInstance().createRequest(newRequest, false);
        Test.stopTest();

        System.assertNotEquals(null, saveResult, 'Expected save results; but received null');
        System.assertNotEquals(null, saveResult.requestId, 'Expected duplicate request to be inserted when no duplicate check done.');
        System.assertEquals(null, saveResult.errorMessage, 'Expected no errors to be returned when request is inserted.');

        // should have inserted the new request
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{newRequest});
    }

    @IsTest
    static void testCreateRequestDMLException() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c newRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, false)[0];
        newRequest.Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();

        // =====================================
        // Stubbing
        // =====================================
        BulkLoadRequestSelector mockBulkLoadRequestSelector = (BulkLoadRequestSelector)MockUtility.mockSelector(BulkLoadRequestSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockBulkLoadRequestSelector.selectByTypeAndFileName(fflib_Match.eqString(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name()), (Set<String>) fflib_Match.anyObject())).thenReturn(new Map<Id, BulkLoadRequest__c>());
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.listContains(newRequest))).thenThrow(new MockException());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadService.BulkUploadRequestSaveResult saveResult = BulkUploadService.getInstance().createRequest(newRequest, false);
        Test.stopTest();

        System.assertNotEquals(null, saveResult, 'Expected save results; but received null');
        System.assertEquals(null, saveResult.requestId, 'Expected request id to be null due to failure to insert.');
        System.assertNotEquals(null, saveResult.errorMessage, 'Expected error details to be returned when insert failed due to exception.');

        // should have attempted to insert the new request
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(new List<SObject>{newRequest});

    }

    @IsTest
    static void testCreateLineItemsOnRequestAlreadyProcessed() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c bulkLoadRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];
        bulkLoadRequest.Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        bulkLoadRequest.Status__c = BulkUploadService.REQUEST_STATUS_PROCESSED;

        List<BulkLoadRequestLineItem__c> lineItems = ApplicationTestDataFactory.getBulkLoadRequestLineItems(5, bulkLoadRequest.Id, false);

        // =====================================
        // Stubbing
        // =====================================
        BulkLoadRequestSelector mockBulkLoadRequestSelector = (BulkLoadRequestSelector)MockUtility.mockSelector(BulkLoadRequestSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockBulkLoadRequestSelector.selectById((Set<Id>) fflib_Match.anyObject())).thenReturn(new Map<Id, BulkLoadRequest__c> {bulkLoadRequest.Id => bulkLoadRequest});
        //MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        try {
            BulkUploadService.getInstance().createLineItems(bulkLoadRequest.Id,  lineItems);
            System.assert(false, 'Expected to throw BulkUploadException if request is already processed.');
        } catch (BulkUploadService.BulkUploadException bulkUploadException) {
            //expected
        } catch (Exception ex) {
            System.debug(ex.getStackTraceString());
            System.assert(false, 'Expected to throw BulkUploadException if the request is already processed.');
        }

        Test.stopTest();

        // should not have attempted to insert the new request
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlInsert(lineItems);
    }

    @IsTest
    static void testCreateLineItemsValidationFailure() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c bulkLoadRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];
        bulkLoadRequest.Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        bulkLoadRequest.Status__c = BulkUploadService.REQUEST_STATUS_NEW;

        List<BulkLoadRequestLineItem__c> lineItems = ApplicationTestDataFactory.getBulkLoadRequestLineItems(5, bulkLoadRequest.Id, false);

        // =====================================
        // Stubbing
        // =====================================
        BulkLoadRequestSelector mockBulkLoadRequestSelector = (BulkLoadRequestSelector)MockUtility.mockSelector(BulkLoadRequestSelector.class);
        CreditDisputeClaimsBulkUploadHandler mockHandler = (CreditDisputeClaimsBulkUploadHandler)MockUtility.mockUtility(CreditDisputeClaimsBulkUploadHandler.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockBulkLoadRequestSelector.selectById((Set<Id>) fflib_Match.anyObject())).thenReturn(new Map<Id, BulkLoadRequest__c>{bulkLoadRequest.Id => bulkLoadRequest});
        // set up validation errors on line items #2 and #3
        Map<Integer,String> invalidLineItems = new Map<Integer, String> {
                2 => 'Filed length exceeded',
                3 => 'Required field blank'
        };
        ((CreditDisputeClaimsBulkUploadHandler)MockUtility.Mocks.doAnswer(new AnswerValidateLineItems(invalidLineItems), mockHandler)).validateLineItems((List<BulkLoadRequestLineItem__c>) fflib_Match.eqList(lineItems));
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadService.LineItemsSaveResult results = BulkUploadService.getInstance().createLineItems(bulkLoadRequest.Id,  lineItems);

        Test.stopTest();

        System.assertNotEquals(null, results, 'Expected save results to be returned on validation failure');
        System.assertEquals(3, results.successCount, 'Expect only 2 line items to fail validations; rest should pass validations');
        System.assertEquals(2, results.errorCount, 'Expect only 2 line items to fail validations; rest should pass validations');
        System.assertEquals(2, results.invalidLineItems.size(), 'Expect only 2 line items to fail validations');

        // should not have attempted to insert line items
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlInsert(lineItems);
    }

    @IsTest
    static void testCreateLineItemsDMLError() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c bulkLoadRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];
        bulkLoadRequest.Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        bulkLoadRequest.Status__c = BulkUploadService.REQUEST_STATUS_NEW;

        List<BulkLoadRequestLineItem__c> lineItems = ApplicationTestDataFactory.getBulkLoadRequestLineItems(1, bulkLoadRequest.Id, false);

        // =====================================
        // Stubbing
        // =====================================
        CreditDisputeClaimsBulkUploadHandler mockHandler = (CreditDisputeClaimsBulkUploadHandler)MockUtility.mockUtility(CreditDisputeClaimsBulkUploadHandler.class);
        BulkLoadRequestSelector mockBulkLoadRequestSelector = (BulkLoadRequestSelector)MockUtility.mockSelector(BulkLoadRequestSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockBulkLoadRequestSelector.selectById((Set<Id>) fflib_Match.anyObject())).thenReturn(new Map<Id, BulkLoadRequest__c>{bulkLoadRequest.Id => bulkLoadRequest});
        ((CreditDisputeClaimsBulkUploadHandler)MockUtility.Mocks.doAnswer(new AnswerValidateLineItems(), mockHandler)).validateLineItems((List<BulkLoadRequestLineItem__c>) fflib_Match.eqList(lineItems));
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.eqList(lineItems), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLFailed());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadService.LineItemsSaveResult results = BulkUploadService.getInstance().createLineItems(bulkLoadRequest.Id,  lineItems);

        Test.stopTest();

        System.assertNotEquals(null, results, 'Expected save results to be returned on DML error');
        System.assertEquals(0, results.successCount, 'Expect all line items to fail on DML error');
        System.assertEquals(lineItems.size(), results.errorCount, 'Expect all line items to fail on DML error');
        System.assertEquals(lineItems.size(), results.invalidLineItems.size(), 'Expect all line items to on DML error');

        // should have attempted to insert line items
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(lineItems, false);
    }

    @IsTest
    static void testCreateLineItems() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c bulkLoadRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];
        bulkLoadRequest.Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        bulkLoadRequest.Status__c = BulkUploadService.REQUEST_STATUS_NEW;
        bulkLoadRequest.TotalLineItems__c = 5;

        List<BulkLoadRequestLineItem__c> lineItems = ApplicationTestDataFactory.getBulkLoadRequestLineItems(3, bulkLoadRequest.Id, false);

        // =====================================
        // Stubbing
        // =====================================
        CreditDisputeClaimsBulkUploadHandler mockHandler = (CreditDisputeClaimsBulkUploadHandler)MockUtility.mockUtility(CreditDisputeClaimsBulkUploadHandler.class);
        BulkLoadRequestSelector mockBulkLoadRequestSelector = (BulkLoadRequestSelector)MockUtility.mockSelector(BulkLoadRequestSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockBulkLoadRequestSelector.selectById((Set<Id>) fflib_Match.anyObject())).thenReturn(new Map<Id, BulkLoadRequest__c>{bulkLoadRequest.Id => bulkLoadRequest});
        ((CreditDisputeClaimsBulkUploadHandler)MockUtility.Mocks.doAnswer(new AnswerValidateLineItems(), mockHandler)).validateLineItems((List<BulkLoadRequestLineItem__c>) fflib_Match.eqList(lineItems));
        MockUtility.Mocks.when(mockDatabase.dmlInsert((List<SObject>)fflib_Match.eqList(lineItems), fflib_Match.anyBoolean())).thenAnswer(new MockUtility.AnswerGenericDMLInserted());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadService.LineItemsSaveResult results = BulkUploadService.getInstance().createLineItems(bulkLoadRequest.Id,  lineItems);

        Test.stopTest();

        System.assertNotEquals(null, results, 'Expected save results to be returned');
        System.assertEquals(lineItems.size(), results.successCount, 'Expect all line items be inserted with no errors.');
        System.assertEquals(0, results.errorCount, 'Expect all line items to be inserted with no errors.');
        System.assertEquals(0, results.invalidLineItems.size(), 'Expect all line items be inserted with no errors.');

        // should have attempted to insert line items
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlInsert(lineItems, false);

    }

    @IsTest
    static void testFinaliseUploadAllLineItemsValid() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c bulkLoadRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];
        bulkLoadRequest.Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        bulkLoadRequest.Status__c = BulkUploadService.REQUEST_STATUS_NEW;

        // =====================================
        // Stubbing
        // =====================================
        // TODO - Batch class mocking
        //CreditDisputeClaimsBulkUploadHandler mockHandler = (CreditDisputeClaimsBulkUploadHandler)MockUtility.mockUtility(CreditDisputeClaimsBulkUploadHandler.class);
        //BulkLoadRequestSelector mockBulkLoadRequestSelector = (BulkLoadRequestSelector)MockUtility.mockSelector(BulkLoadRequestSelector.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        //MockUtility.Mocks.when(mockBulkLoadRequestSelector.selectById((Set<Id>) fflib_Match.anyObject())).thenReturn(new Map<Id, BulkLoadRequest__c>{bulkLoadRequest.Id => bulkLoadRequest});
        //((CreditDisputeClaimsBulkUploadHandler)MockUtility.Mocks.doAnswer(new AnswerValidateLineItems(), mockHandler)).validateLineItems((List<BulkLoadRequestLineItem__c>) fflib_Match.eqList(lineItems));
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadService.getInstance().finaliseUploading(bulkLoadRequest,  true);

        Test.stopTest();

        // should have attempted to updated request
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
    }

    @IsTest
    static void testFinaliseUploadSomeLineItemsFailedValidation() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c bulkLoadRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];
        bulkLoadRequest.Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        bulkLoadRequest.Status__c = BulkUploadService.REQUEST_STATUS_NEW;

        // =====================================
        // Stubbing
        // =====================================
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadService.getInstance().finaliseUploading(bulkLoadRequest,  false);

        Test.stopTest();

        // should have attempted to delete request
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlDelete((List<SObject>)fflib_Match.anyObject());
    }

    @IsTest
    static void testProcessLineItems() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c bulkLoadRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];
        bulkLoadRequest.Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        bulkLoadRequest.Status__c = BulkUploadService.REQUEST_STATUS_NEW;

        List<BulkLoadRequestLineItem__c> lineItems = ApplicationTestDataFactory.getBulkLoadRequestLineItems(3, bulkLoadRequest.Id, true);

        // =====================================
        // Stubbing
        // =====================================
        CreditDisputeClaimsBulkUploadHandler mockHandler = (CreditDisputeClaimsBulkUploadHandler)MockUtility.mockUtility(CreditDisputeClaimsBulkUploadHandler.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        Map<String, Object> executionContext = new Map<String,Object>();
        MockUtility.Mocks.when(mockHandler.process((List<BulkLoadRequestLineItem__c>)fflib_Match.eqList(lineItems), (Map<String, Object>) fflib_Match.eq(executionContext))).thenAnswer(new AnswerProcessLineItems());
        MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadService.LineItemsProcessResult results = BulkUploadService.getInstance().processLineItems(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS, lineItems,  executionContext);

        Test.stopTest();

        System.assertNotEquals(null, results, 'Expected to get processing results; but got null');
        System.assertEquals(lineItems.size(), results.successCount, 'Expected all line items to be processed successfully.');
        System.assertEquals(0, results.errorCount, 'Expected all line items to be processed successfully with no errors');

        // should have attempted to delete line items processed successfully
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlDelete((List<SObject>)fflib_Match.listContains(lineItems[0]));
    }

    @IsTest
    static void testProcessLineItemsWithSomeLineItemsFailing() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c bulkLoadRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];
        bulkLoadRequest.Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        bulkLoadRequest.Status__c = BulkUploadService.REQUEST_STATUS_NEW;

        List<BulkLoadRequestLineItem__c> lineItems = ApplicationTestDataFactory.getBulkLoadRequestLineItems(3, bulkLoadRequest.Id, true);

        // =====================================
        // Stubbing
        // =====================================
        CreditDisputeClaimsBulkUploadHandler mockHandler = (CreditDisputeClaimsBulkUploadHandler)MockUtility.mockUtility(CreditDisputeClaimsBulkUploadHandler.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        Map<String, Object> executionContext = new Map<String,Object>();
        //set up line item errors
        Map<Integer, String> lineItemErrors = new Map<Integer, String> { 2 => 'Unexpected error'};
        MockUtility.Mocks.when(mockHandler.process((List<BulkLoadRequestLineItem__c>)fflib_Match.eqList(lineItems), (Map<String, Object>) fflib_Match.eq(executionContext))).thenAnswer(new AnswerProcessLineItems(lineItemErrors));
        MockUtility.Mocks.when(mockDatabase.dmlDelete((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLDeleted());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadService.LineItemsProcessResult results = BulkUploadService.getInstance().processLineItems(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS, lineItems,  executionContext);

        Test.stopTest();

        System.assertNotEquals(null, results, 'Expected to get processing results; but got null');
        System.assertEquals(2, results.successCount, 'Expected 2 line items to be successful. Line Item #2 should return an error');
        System.assertEquals(1, results.errorCount, 'Expected line item #2 to fail with an error');

        // should have attempted to delete line items processed successfully
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlDelete((List<SObject>)fflib_Match.listContains(lineItems[0]));
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlDelete((List<SObject>)fflib_Match.listContains(lineItems[2]));
        // should not attempt to delete line item failed to process
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(0))).dmlDelete((List<SObject>)fflib_Match.listContains(lineItems[1]));
    }

    @IsTest
    static void testFinaliseProcessing() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c bulkLoadRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];
        bulkLoadRequest.Type__c = BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name();
        bulkLoadRequest.Status__c = BulkUploadService.REQUEST_STATUS_NEW;

        // =====================================
        // Stubbing
        // =====================================
        CreditDisputeClaimsBulkUploadHandler mockHandler = (CreditDisputeClaimsBulkUploadHandler)MockUtility.mockUtility(CreditDisputeClaimsBulkUploadHandler.class);
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

        MockUtility.Mocks.startStubbing();
        Map<String, Object> executionContext = new Map<String,Object>();
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
        //MockUtility.Mocks.when(mockHandler.onProcessingCompleted((Id)fflib_Match.eq(bulkLoadRequest.Id), (Map<String, Object>) fflib_Match.eq(executionContext))).thenAnswer(new AnswerProcessLineItems());
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadService.LineItemsProcessResult results = new BulkUploadService.LineItemsProcessResult();
        results.successCount = 10;
        results.errorCount = 2;

        BulkUploadService.getInstance().finaliseProcessing(BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS, bulkLoadRequest.Id,  results, executionContext);

        Test.stopTest();

        // should have attempted to update the request
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject(), fflib_Match.eqBoolean(false));
        ((CreditDisputeClaimsBulkUploadHandler)MockUtility.Mocks.verify(mockHandler, MockUtility.Mocks.times(1))).onProcessingCompleted((Id)fflib_Match.eq(bulkLoadRequest.Id), (Map<String,Object>)fflib_Match.eq(executionContext));

    }

    @IsTest
    static void tesBaseRequestHandlerFieldValidations() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c bulkLoadRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];

        Map<String, Object> requiredFieldMissingPayload = new Map<String, Object> {
                'field2' => '22222',
                'field3' => '20'
        };

        Map<String, Object> fieldLengthExceededPayload = new Map<String, Object> {
                'field1' => 'valueexceedsfieldlength',
                'field3' => '20'
        };

        Map<String, Object> invalidCurrencyPayload = new Map<String, Object> {
                'field1' => '1234',
                'field3' => 'a'
        };

        Map<String, Object> invalidURLPayload = new Map<String, Object> {
                'field1' => '1234',
                'field4' => 'a'
        };

        Map<String, Object> invalidEmailPayload = new Map<String, Object> {
                'field1' => '1234',
                'field5' => 'a'
        };

        Map<String, Object> validPayload = new Map<String, Object> {
                'field1' => '1234',
                'field3' => '23',
                'field4' => 'https://auspost.com.au',
                'field5' => 'testemail@ttt.ttt'
        };

        List<BulkLoadRequestLineItem__c> lineItems = ApplicationTestDataFactory.getBulkLoadRequestLineItems(9, bulkLoadRequest.Id, false);
        lineItems[0].LineItemPayload__c = JSON.serialize(requiredFieldMissingPayload);
        lineItems[1].LineItemPayload__c = JSON.serialize(fieldLengthExceededPayload);
        lineItems[2].LineItemPayload__c = JSON.serialize(invalidCurrencyPayload);
        lineItems[3].LineItemPayload__c = JSON.serialize(invalidURLPayload);
        lineItems[4].LineItemPayload__c = JSON.serialize(invalidEmailPayload);
        lineItems[5].LineItemPayload__c = JSON.serialize(validPayload);

        Test.startTest();

        MockCustomRequestHandler handler = new MockCustomRequestHandler();
        handler.validateLineItems(lineItems);

        Test.stopTest();

        System.assertNotEquals(null, lineItems[0].ErrorMessage__c, 'Expected line item to fail validation check - required field missing');
        System.assertNotEquals(null, lineItems[1].ErrorMessage__c, 'Expected line item to fail validation check - field length exceeded');
        System.assertNotEquals(null, lineItems[2].ErrorMessage__c, 'Expected line item to fail validation check - invalid currency value');
        System.assertNotEquals(null, lineItems[3].ErrorMessage__c, 'Expected line item to fail validation check - invalid URL');
        System.assertNotEquals(null, lineItems[4].ErrorMessage__c, 'Expected line item to fail validation check - invalid Email');
        System.assertEquals(null, lineItems[5].ErrorMessage__c, 'Expected line item to pass validation check');

    }

    public class MockCustomRequestHandler extends BulkUploadService.BulkUploadRequestHandler {

        public override Map<String, BulkUploadService.FieldMappingConfigItem> getFieldMappingConfig() {
            Map<String,BulkUploadService.FieldMappingConfigItem> fieldMetadata = new Map<String, BulkUploadService.FieldMappingConfigItem>();
            fieldMetadata.put('field1', new BulkUploadService.FieldMappingConfigItem('field1', 'Field 1', BulkUploadService.FIELD_TYPE_STRING, true, 10));
            fieldMetadata.put('field2', new BulkUploadService.FieldMappingConfigItem('field2', 'Field 2', BulkUploadService.FIELD_TYPE_STRING, false, 10));
            fieldMetadata.put('field3', new BulkUploadService.FieldMappingConfigItem('field3', 'Field 3', BulkUploadService.FIELD_TYPE_CURRENCY, false));
            fieldMetadata.put('field4', new BulkUploadService.FieldMappingConfigItem('field4', 'Field 4', BulkUploadService.FIELD_TYPE_URL, false));
            fieldMetadata.put('field5', new BulkUploadService.FieldMappingConfigItem('field5', 'Field 5', BulkUploadService.FIELD_TYPE_EMAIL, false));
            return fieldMetadata;
        }

        public void validateLineItems(List<BulkLoadRequestLineItem__c> lineItems) {
            for (BulkLoadRequestLineItem__c lineItem: lineItems) {
                Map<String, Object> lineItemPayloadData = parseLineItemPayloadIgnoreCaseForPropertyNames(lineItem);
                String errorMessage = super.validateFieldTypesAndRequiredFields(lineItemPayloadData);
                if (String.isNotBlank(errorMessage)) {
                    lineItem.ErrorMessage__c = errorMessage;
                }
            }
        }

        public BulkUploadService.LineItemsProcessResult process(List<BulkLoadRequestLineItem__c> lineItems, Map<String, Object> executionContext) {
            return null;
        }

        public Integer getProcessingBatchSize() {
            return 20;
        }
    }

    private class MockException extends Exception {
    }

    public class AnswerValidateLineItems implements fflib_Answer {

        private Map<Integer, String> lineItemErrorDetails;

        public AnswerValidateLineItems() {}
        public AnswerValidateLineItems(Map<Integer, String> lineItemErrorDetails) {
            this.lineItemErrorDetails = lineItemErrorDetails;
        }

        public Object answer(fflib_InvocationOnMock invocation) {
            List<BulkLoadRequestLineItem__c> lineItems = (List<BulkLoadRequestLineItem__c>)invocation.getArgument(0);

            if (lineItemErrorDetails != null && !lineItemErrorDetails.isEmpty()) {
                for (BulkLoadRequestLineItem__c lineItem: lineItems) {
                    if (lineItemErrorDetails.containsKey(Integer.valueOf(lineItem.LineNumber__c))) {
                        lineItem.ErrorMessage__c = (String) lineItemErrorDetails.get(Integer.valueOf(lineItem.LineNumber__c));
                    }
                }
            }
            return null;
        }
    }

    public class AnswerProcessLineItems implements fflib_Answer {

        private Map<Integer, String> lineItemErrorDetails = new Map<Integer, String>();

        public AnswerProcessLineItems() {}
        public AnswerProcessLineItems(Map<Integer, String> lineItemErrorDetails) {
            this.lineItemErrorDetails = lineItemErrorDetails;
        }

        public Object answer(fflib_InvocationOnMock invocation) {
            BulkUploadService.LineItemsProcessResult results = new BulkUploadService.LineItemsProcessResult();
            List<BulkLoadRequestLineItem__c> lineItems = (List<BulkLoadRequestLineItem__c>)invocation.getArgument(0);
            for (BulkLoadRequestLineItem__c lineItem: lineItems) {
                if (lineItemErrorDetails.containsKey(Integer.valueOf(lineItem.LineNumber__c))) {
                    lineItem.ErrorMessage__c = (String) lineItemErrorDetails.get(Integer.valueOf(lineItem.LineNumber__c));
                    lineItem.Status__c = BulkUploadService.LINEITEM_STATUS_ERROR;
                } else {
                    lineItem.Status__c = BulkUploadService.LINEITEM_STATUS_SUCCESS;
                }
            }
            results.errorCount = lineItemErrorDetails.size();
            results.successCount = lineItems.size() - lineItemErrorDetails.size();
            return results;
        }
    }
}