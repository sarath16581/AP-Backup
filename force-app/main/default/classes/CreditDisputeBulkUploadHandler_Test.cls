/***
 * @author Ranjeewa Silva
 * @date 2021-03-02
 * @group Tests
 * @tag CreditDisputeClaims, Tests
 * @domain Credit Claim
 * @description Test Scenarios for Credit Dispute Claim bulk upload
 * @changelog
 * 2021-03-02 - Ranjeewa Silva - Created.
 */

@IsTest
private class CreditDisputeBulkUploadHandler_Test {
    @IsTest
    public static void testGetFieldMappingConfig() {

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

        Map<String, BulkUploadService.FieldMappingConfigItem> fieldMetadata = new CreditDisputeClaimsBulkUploadHandler().getFieldMappingConfig();

        Test.stopTest();

        System.assertNotEquals(null, fieldMetadata, 'Expected valid field metadata to be returned always');
        System.assert(!fieldMetadata.isEmpty(), 'Expected valid field metadata to be returned always');
    }

    @IsTest
    public static void testValidateLineItems() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c bulkLoadRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];

        Map<String, Object> blankPayload = newCreditDisputeLineItemPayloadWithEmptyValues();

        Map<String, Object> startrackBlankConnotePayload = newCreditDisputeLineItemPayload('10000', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, '', null);

        Map<String, Object> auspostBlankTransactionIdPayload = newCreditDisputeLineItemPayload('10000', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_AUSTRALIAPOST, null, '');

        Map<String, Object> startrackMandatoryFieldsSetPayload = newCreditDisputeLineItemPayload('10000', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, 'CN_11111', null);

        Map<String, Object> auspostMandatoryFieldsSetPayload = newCreditDisputeLineItemPayload('10000', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_AUSTRALIAPOST, null, '222222222222');

        Map<String, Object> onlyMandatoryFieldsSetPayload = new Map<String, Object> {
            CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_BUSINESS_ACCOUNT_NUMBER => '22222',
            CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_ACCOUNT_HELD_WITH => CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK,
            CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CONNOTE => 'CN_11111'
        };

        Map<String, Object> invalidDisputeTypePayload = newCreditDisputeLineItemPayload('10000', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_AUSTRALIAPOST, null, '222222222222');
        invalidDisputeTypePayload.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_DISPUTE_TYPE, 'INVALID');

        Map<String, Object> invalidReasonForCreditClaimPayload = newCreditDisputeLineItemPayload('10000', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, 'CN_11111', null);
        invalidReasonForCreditClaimPayload.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_DISPUTE_TYPE, 'Billing Dispute');
        invalidReasonForCreditClaimPayload.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_REASON_FOR_CREDIT_CLAIM, 'INVALID');

        Map<String, Object> validDependentPicklistValuesPayload = newCreditDisputeLineItemPayload('10000', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, 'CN_11111', null);
        validDependentPicklistValuesPayload.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_DISPUTE_TYPE, 'Billing Dispute');
        validDependentPicklistValuesPayload.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_REASON_FOR_CREDIT_CLAIM, 'Duplicate Charge');

        List<BulkLoadRequestLineItem__c> lineItems = ApplicationTestDataFactory.getBulkLoadRequestLineItems(9, bulkLoadRequest.Id, false);
        lineItems[0].LineItemPayload__c = JSON.serialize(blankPayload);
        lineItems[1].LineItemPayload__c = JSON.serialize(startrackBlankConnotePayload);
        lineItems[2].LineItemPayload__c = JSON.serialize(auspostBlankTransactionIdPayload);
        lineItems[3].LineItemPayload__c = JSON.serialize(startrackMandatoryFieldsSetPayload);
        lineItems[4].LineItemPayload__c = JSON.serialize(auspostMandatoryFieldsSetPayload);
        lineItems[5].LineItemPayload__c = JSON.serialize(onlyMandatoryFieldsSetPayload);
        lineItems[6].LineItemPayload__c = JSON.serialize(invalidDisputeTypePayload);
        lineItems[7].LineItemPayload__c = JSON.serialize(invalidReasonForCreditClaimPayload);
        lineItems[8].LineItemPayload__c = JSON.serialize(validDependentPicklistValuesPayload);

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        new CreditDisputeClaimsBulkUploadHandler().validateLineItems(lineItems);

        Test.stopTest();

        System.assertNotEquals(null, lineItems[0].ErrorMessage__c, 'Expected mandatory field missing error; but not set.');
        System.assertNotEquals(null, lineItems[1].ErrorMessage__c, 'Expected mandatory field missing error; but not set.');
        System.assertNotEquals(null, lineItems[2].ErrorMessage__c, 'Expected mandatory field missing error; but not set.');
        System.assertEquals(null, lineItems[3].ErrorMessage__c, 'Expected no errors; but received errors.');
        System.assertEquals(null, lineItems[4].ErrorMessage__c, 'Expected no errors; but received errors.');
        System.assertEquals(null, lineItems[5].ErrorMessage__c, 'Expected no errors; but received errors.');
        System.assertNotEquals(null, lineItems[6].ErrorMessage__c, 'Expected invalid dependent field error; but received no errors.');
        System.assertNotEquals(null, lineItems[7].ErrorMessage__c, 'Expected invalid dependent field error; but received no errors.');
        System.assertEquals(null, lineItems[8].ErrorMessage__c, 'Expected no errors; but received errors.');

    }

    @IsTest
    public static void testProcessLineItems_CaseCreation() {

        // =====================================
        // Data Preparation
        // =====================================

        BulkLoadRequest__c bulkLoadRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];

        // --------------------------------- TEST SCENARIO -----------------------------------------
        //  Business Account Number | Claim Identifier  | Case Key  ==> Expected Results
        //  111111                  | A100000           | key1      ==> Case#1 (Based on Case key. Claim Identifier is ignored)
        //  111111                  | A100001           | key1      ==> Case#1 (Based on Case key. Claim Identifier is ignored)
        //  111111                  | B999999           |           ==> Case#2 (Based on Claim Identifier)
        //  111111                  | B999999           |           ==> Case#2 (Based on Claim Identifier)
        //  111111                  |                   |           ==> Case#3 (Default behaviour is to create a new case for each line if both Claim Identifier and Case Key is blank)
        //  222222                  |                   |           ==> Case#4 (Default behaviour is to create a new case for each line if both Claim Identifier and Case Key is blank)
        //  333333                  |                   | key3      ==> Case#5 (Based on Case Key)
        //  333333                  |                   | key3      ==> Case#5 (Based on Case Key)
        //---------------------------------------------------------------------------------------------

        Map<String, Object> payload1 = newCreditDisputeLineItemPayload('111111', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, '2222', null);
        payload1.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CLAIM_IDENTIFIER, 'A100000');
        payload1.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CASE_KEY, 'key1');

        Map<String, Object> payload2 = newCreditDisputeLineItemPayload('111111', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, '2222', null);
        payload2.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CLAIM_IDENTIFIER, 'A100001');
        payload2.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CASE_KEY, 'key1');

        Map<String, Object> payload3 = newCreditDisputeLineItemPayload('111111', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, '2222', null);
        payload3.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CLAIM_IDENTIFIER, 'B999999');

        Map<String, Object> payload4 = newCreditDisputeLineItemPayload('111111', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, '2222', null);
        payload4.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CLAIM_IDENTIFIER, 'B999999');

        Map<String, Object> payload5 = newCreditDisputeLineItemPayload('111111', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, '2222', null);

        Map<String, Object> payload6 = newCreditDisputeLineItemPayload('222222', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, '2222', null);

        Map<String, Object> payload7 = newCreditDisputeLineItemPayload('333333', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, '2222', null);
        payload7.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CASE_KEY, 'key3');

        Map<String, Object> payload8 = newCreditDisputeLineItemPayload('333333', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, '2222', null);
        payload8.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CASE_KEY, 'key3');

        List<BulkLoadRequestLineItem__c> lineItems = ApplicationTestDataFactory.getBulkLoadRequestLineItems(8, bulkLoadRequest.Id, true);
        lineItems[0].LineItemPayload__c = JSON.serialize(payload1);
        lineItems[1].LineItemPayload__c = JSON.serialize(payload2);
        lineItems[2].LineItemPayload__c = JSON.serialize(payload3);
        lineItems[3].LineItemPayload__c = JSON.serialize(payload4);
        lineItems[4].LineItemPayload__c = JSON.serialize(payload5);
        lineItems[5].LineItemPayload__c = JSON.serialize(payload6);
        lineItems[6].LineItemPayload__c = JSON.serialize(payload7);
        lineItems[7].LineItemPayload__c = JSON.serialize(payload8);

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadService.LineItemsProcessResult results = new CreditDisputeClaimsBulkUploadHandler().process(lineItems, new Map<String,Object>());

        Test.stopTest();

        System.assertEquals(8, results.successCount, 'Expected all line items to be successfully processed; but some didn\'t');
        System.assertEquals(0, results.errorCount, 'Expected no errors; but recieved few errors.');

        List<Case> casesCreated = [Select Id, CaseNumber, ReferenceID__c, (Select Id from Disputed_Items__r) from Case];
        System.assertEquals(5, casesCreated.size(), 'Expected 5 cases to be created for the line items processed');

        Case caseOne = [Select Id, CaseNumber, ReferenceID__c, (Select Id from Disputed_Items__r) from Case Where ReferenceID__c IN ('A100000', 'A100001') AND Billing_Number__c = '111111'];
        Case caseTwo = [Select Id, CaseNumber, ReferenceID__c, (Select Id from Disputed_Items__r) from Case Where ReferenceID__c = 'B999999' AND Billing_Number__c = '111111'];
        Case caseThree = [Select Id, CaseNumber, ReferenceID__c, (Select Id from Disputed_Items__r) from Case Where ReferenceID__c = null AND Billing_Number__c = '111111'];
        Case caseFour = [Select Id, CaseNumber, ReferenceID__c, (Select Id from Disputed_Items__r) from Case Where ReferenceID__c = null AND Billing_Number__c = '222222'];
        Case caseFive = [Select Id, CaseNumber, ReferenceID__c, (Select Id from Disputed_Items__r) from Case Where ReferenceID__c = null AND Billing_Number__c = '333333'];

        System.assertEquals(2, caseOne.Disputed_Items__r.size(), 'Expected 2 disputed items on case#1');
        System.assertEquals(2, caseTwo.Disputed_Items__r.size(), 'Expected 2 disputed items on case#2');
        System.assertEquals(1, caseThree.Disputed_Items__r.size(), 'Expected 1 disputed item on case#3');
        System.assertEquals(1, caseFour.Disputed_Items__r.size(), 'Expected 1 disputed item on case#4');
        System.assertEquals(2, caseFive.Disputed_Items__r.size(), 'Expected 2 disputed item on case#5');
    }

    @IsTest
    public static void testProcessLineItems_CaseCreationWithTwoBatches() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c bulkLoadRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];

        // --------------------------------- TEST SCENARIO -----------------------------------------
        //  Business Account Number | Claim Identifier  | Case Key  ==> Expected Results
        //  111111                  | A100000           | key1      ==> Case#1 (Based on Case key. Claim Identifier is ignored)
        //  111111                  | A100001           | key1      ==> Case#1 (Based on Case key. Claim Identifier is ignored)
        //  111111                  | B999999           |           ==> Case#2 (Based on Claim Identifier)
        //  111111                  | B999999           |           ==> Case#2 (Based on Claim Identifier)
        //  111111                  |                   |           ==> Case#3 (Default behaviour is to create a new case for each line if both Claim Identifier and Case Key is blank)
        //---------------------------------------------------------------------------------------------

        Map<String, Object> payload1 = newCreditDisputeLineItemPayload('111111', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, '2222', null);
        payload1.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CLAIM_IDENTIFIER, 'A100000');
        payload1.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CASE_KEY, 'key1');

        Map<String, Object> payload2 = newCreditDisputeLineItemPayload('111111', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, '2222', null);
        payload2.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CLAIM_IDENTIFIER, 'A100001');
        payload2.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CASE_KEY, 'key1');

        Map<String, Object> payload3 = newCreditDisputeLineItemPayload('111111', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, '2222', null);
        payload3.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CLAIM_IDENTIFIER, 'B999999');

        Map<String, Object> payload4 = newCreditDisputeLineItemPayload('111111', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, '2222', null);
        payload4.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CLAIM_IDENTIFIER, 'B999999');

        Map<String, Object> payload5 = newCreditDisputeLineItemPayload('111111', CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK, '2222', null);


        List<BulkLoadRequestLineItem__c> lineItemsBatch1 = ApplicationTestDataFactory.getBulkLoadRequestLineItems(1, bulkLoadRequest.Id, true);
        lineItemsBatch1[0].LineItemPayload__c = JSON.serialize(payload1);

        // create a new instance of execution context. this should be passed in with all batches
        Map<String, Object> executionContext = new Map<String, Object>();
        new CreditDisputeClaimsBulkUploadHandler().process(lineItemsBatch1, executionContext);

        List<BulkLoadRequestLineItem__c> lineItemsBatch2 = ApplicationTestDataFactory.getBulkLoadRequestLineItems(4, bulkLoadRequest.Id, true);
        lineItemsBatch2[0].LineItemPayload__c = JSON.serialize(payload2);
        lineItemsBatch2[1].LineItemPayload__c = JSON.serialize(payload3);
        lineItemsBatch2[2].LineItemPayload__c = JSON.serialize(payload4);
        lineItemsBatch2[3].LineItemPayload__c = JSON.serialize(payload5);

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        //pass the execution context
        new CreditDisputeClaimsBulkUploadHandler().process(lineItemsBatch2, executionContext);

        Test.stopTest();

        List<Case> casesCreated = [Select Id, CaseNumber, ReferenceID__c, (Select Id from Disputed_Items__r) from Case];
        System.assertEquals(3, casesCreated.size(), 'Expected 3 cases to be created for the line items processed');

        Case caseOne = [Select Id, CaseNumber, ReferenceID__c, (Select Id from Disputed_Items__r) from Case Where ReferenceID__c IN ('A100000' , 'A100001') AND Billing_Number__c = '111111'];
        Case caseTwo = [Select Id, CaseNumber, ReferenceID__c, (Select Id from Disputed_Items__r) from Case Where ReferenceID__c = 'B999999' AND Billing_Number__c = '111111'];
        Case caseThree = [Select Id, CaseNumber, ReferenceID__c, (Select Id from Disputed_Items__r) from Case Where ReferenceID__c = null AND Billing_Number__c = '111111'];

        System.assertEquals(2, caseOne.Disputed_Items__r.size(), 'Expected 2 disputed items on case#1');
        System.assertEquals(2, caseTwo.Disputed_Items__r.size(), 'Expected 2 disputed items on case#2');
        System.assertEquals(1, caseThree.Disputed_Items__r.size(), 'Expected 1 disputed item on case#3');
    }

    @IsTest
    public static void testProcessLineItems_FieldValues() {

        // =====================================
        // Data Preparation
        // =====================================
        BulkLoadRequest__c bulkLoadRequest = ApplicationTestDataFactory.getBulkLoadRequests(1, true)[0];

        Map<String, Object> payload = new Map<String, Object>{
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_BUSINESS_NAME => 'test123',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_BUSINESS_ACCOUNT_NUMBER => '12121212',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_NAME => 'joebloggs',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_EMAIL => 'jbttt@ttt.test.invalid',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_PHONE => '999999',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_ACCOUNT_HELD_WITH => CreditDisputeClaimsBulkUploadHandler.BUSINESSUNIT_STARTRACK,
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_DISPUTE_TYPE => 'Billing Dispute',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_REASON_FOR_CREDIT_CLAIM => 'Duplicate Charge',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_TOTAL_AMOUNT_CLAIMED => '25.50',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_DESCRIPTION => 'test description',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_DOCUMENT_DOWNLOAD_URL => 'https://google.com/d',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_DOCUMENT_WEB_URL => 'https://google.com/w',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CLAIM_IDENTIFIER => 'cid12222',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_INVOICE_NUMBER => '1231231',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_TRANSACTION_ID => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CONNOTE => 'CN1232332',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_AMOUNT_CLAIMED => '25.50',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_AMOUNT_CHARGED => '25.50',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CASE_KEY => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CLAIM_SOURCE => 'ttt'
        };

        List<BulkLoadRequestLineItem__c> lineItems = ApplicationTestDataFactory.getBulkLoadRequestLineItems(1, bulkLoadRequest.Id, true);
        lineItems[0].LineItemPayload__c = JSON.serialize(payload);

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        BulkUploadService.LineItemsProcessResult results = new CreditDisputeClaimsBulkUploadHandler().process(lineItems, new Map<String,Object>());

        Test.stopTest();

        System.assertEquals(1, results.successCount, 'Expected all line items to be successfully processed; but some didn\'t');
        System.assertEquals(0, results.errorCount, 'Expected no errors; but recieved few errors.');

        Disputed_Item__c disputedItem = [Select Id, Invoice_Number__c, Transaction_ID__c, Connote__c, Amount_Claimed__c, Amount__c,
                SupportingDocumentDownloadURL__c, SupportingDocumentWebURL__c, Case__c, Case__r.Billing_Number__c, Case__r.Business_Name__c, Case__r.Name__c,
                Case__r.Email_Address__c, Case__r.Phone__c, Case__r.Business_Unit__c, Case__r.Enquiry_Type__c,
                Case__r.ReasonforCreditClaim__c, Case__r.Amount_Claimed__c, Case__r.Description, Case__r.ReferenceID__c,
                Case__r.Reason_for_Claim__c, Case__r.Origin, Case__r.Call_Purpose__c, Case__r.RecordType.DeveloperName
                From Disputed_Item__c][0];

        // verify case field values
        System.assertEquals(String.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_BUSINESS_NAME)), disputedItem.Case__r.Business_Name__c, 'Expected value not populated on Case->Business_Name__c field');
        System.assertEquals(String.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_BUSINESS_ACCOUNT_NUMBER)), disputedItem.Case__r.Billing_Number__c, 'Expected value not populated on Case->Billing_Number__c field');
        System.assertEquals(String.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_NAME)), disputedItem.Case__r.Name__c, 'Expected value not populated on Case->Name__c field');
        System.assertEquals(String.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_EMAIL)), disputedItem.Case__r.Email_Address__c, 'Expected value not populated on Case->Email_Address__c field');
        System.assertEquals(String.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_PHONE)), disputedItem.Case__r.Phone__c, 'Expected value not populated on Case->Phone__c field');
        System.assertEquals(String.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_ACCOUNT_HELD_WITH)), disputedItem.Case__r.Business_Unit__c, 'Expected value not populated on Case->Business_Unit__c field');
        System.assertEquals(String.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_DISPUTE_TYPE)), disputedItem.Case__r.Enquiry_Type__c, 'Expected value not populated on Case->Enquiry_Type__c field');
        System.assertEquals(String.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_REASON_FOR_CREDIT_CLAIM)), disputedItem.Case__r.ReasonforCreditClaim__c, 'Expected value not populated on Case->ReasonforCreditClaim__c field');
        System.assertEquals(Decimal.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_TOTAL_AMOUNT_CLAIMED).toString()), disputedItem.Case__r.Amount_Claimed__c, 'Expected value not populated on Case->Amount_Claimed__c field');
        System.assertEquals(String.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_DESCRIPTION)), disputedItem.Case__r.Description, 'Expected value not populated on Case->Description field');
        System.assertEquals(String.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CLAIM_IDENTIFIER)), disputedItem.Case__r.ReferenceID__c, 'Expected value not populated on Case->ReferenceID__c field');
        System.assertEquals(CreditDisputeClaimsBulkUploadHandler.CASE_ORIGIN, disputedItem.Case__r.Origin, 'Expected value not populated on Case->Origin field');
        System.assertEquals(CreditDisputeClaimsBulkUploadHandler.CASE_PURPOSE, disputedItem.Case__r.Call_Purpose__c, 'Expected value not populated on Case->CASE_PURPOSE field');
        System.assertEquals(CreditDisputeClaimsBulkUploadHandler.CASE_RECORDTYPE_DEVELOPER_NAME, disputedItem.Case__r.RecordType.DeveloperName, 'Expected value not populated on Case->Origin field');

        // verify disputed item field values
        System.assertEquals(String.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_INVOICE_NUMBER)), disputedItem.Invoice_Number__c, 'Expected value not populated on Disputed Item->Invoice_Number__c field');
        System.assertEquals(String.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CONNOTE)), disputedItem.Connote__c, 'Expected value not populated on Disputed Item->Connote__c field');
        System.assertEquals(String.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_DOCUMENT_DOWNLOAD_URL)), disputedItem.SupportingDocumentDownloadURL__c, 'Expected value not populated on Disputed Item->SupportingDocumentDownloadURL__c field');
        System.assertEquals(String.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_DOCUMENT_WEB_URL)), disputedItem.SupportingDocumentWebURL__c, 'Expected value not populated on Disputed Item->SupportingDocumentWebURL__c field');
        System.assertEquals(Decimal.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_AMOUNT_CLAIMED).toString()), disputedItem.Amount_Claimed__c, 'Expected value not populated on Disputed Item->Amount_Claimed__c field');
        System.assertEquals(Decimal.valueOf(payload.get(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_AMOUNT_CHARGED).toString()), disputedItem.Amount__c, 'Expected value not populated on Disputed Item->Amount__c field');

    }

    private static Map<String, Object> newCreditDisputeLineItemPayload(String businessAccountNumber, String accountHeldWith, String connote, String transactionId) {
        Map<String, Object> payload = newCreditDisputeLineItemPayloadWithEmptyValues();
        payload.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_BUSINESS_ACCOUNT_NUMBER, businessAccountNumber);
        payload.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_ACCOUNT_HELD_WITH, accountHeldWith);
        payload.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CONNOTE, connote);
        payload.put(CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_TRANSACTION_ID, transactionId);
        return payload;
    }

    private static Map<String, Object> newCreditDisputeLineItemPayloadWithEmptyValues() {
        return new Map<String, Object>{
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_BUSINESS_NAME => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_BUSINESS_ACCOUNT_NUMBER => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_NAME => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_EMAIL => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_PHONE => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_ACCOUNT_HELD_WITH => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_DISPUTE_TYPE => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_REASON_FOR_CREDIT_CLAIM => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_TOTAL_AMOUNT_CLAIMED => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_DESCRIPTION => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_DOCUMENT_DOWNLOAD_URL => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_DOCUMENT_WEB_URL => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CLAIM_IDENTIFIER => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_INVOICE_NUMBER => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_TRANSACTION_ID => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CONNOTE => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_AMOUNT_CLAIMED => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_AMOUNT_CHARGED => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CASE_KEY => '',
                CreditDisputeClaimsBulkUploadHandler.CSV_COLUMN_CLAIM_SOURCE => ''
        };
    }
}