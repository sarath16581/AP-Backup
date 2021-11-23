/**
 * @description Handler for bulk uploading Credit Dispute Claims.
 * @author Ranjeewa Silva
 * @date 2021-01-22
 * @tag Case
 * @domain Credit Claim
 * @changelog
 * 2020-01-22 - Ranjeewa Silva - Created
 **/
public inherited sharing class CreditDisputeClaimsBulkUploadHandler extends BulkUploadService.BulkUploadRequestHandler implements BulkUploadService.IBulkUploadRequestHandler {

    // Disputed Credit Claim CSV Column names
    @TestVisible private static final String CSV_COLUMN_BUSINESS_NAME = 'Business Name';
    @TestVisible private static final String CSV_COLUMN_BUSINESS_ACCOUNT_NUMBER = 'Business Account Number';
    @TestVisible private static final String CSV_COLUMN_NAME = 'Name';
    @TestVisible private static final String CSV_COLUMN_EMAIL = 'Email';
    @TestVisible private static final String CSV_COLUMN_PHONE = 'Phone';
    @TestVisible private static final String CSV_COLUMN_ACCOUNT_HELD_WITH = 'Account Held With';
    @TestVisible private static final String CSV_COLUMN_DISPUTE_TYPE = 'Dispute Type';
    @TestVisible private static final String CSV_COLUMN_REASON_FOR_CREDIT_CLAIM = 'Reason For Credit Claim';
    @TestVisible private static final String CSV_COLUMN_TOTAL_AMOUNT_CLAIMED = 'Total Amount Claimed';
    @TestVisible private static final String CSV_COLUMN_DESCRIPTION = 'Description';
    @TestVisible private static final String CSV_COLUMN_DOCUMENT_DOWNLOAD_URL = 'Document Download URL';
    @TestVisible private static final String CSV_COLUMN_DOCUMENT_WEB_URL = 'Document Web URL';
    @TestVisible private static final String CSV_COLUMN_CLAIM_IDENTIFIER = 'Claim Identifier';
    @TestVisible private static final String CSV_COLUMN_INVOICE_NUMBER = 'Invoice Number';
    @TestVisible private static final String CSV_COLUMN_TRANSACTION_ID = 'Transaction Id';
    @TestVisible private static final String CSV_COLUMN_CONNOTE = 'Connote #';
    @TestVisible private static final String CSV_COLUMN_AMOUNT_CLAIMED = 'Amount Claimed';
    @TestVisible private static final String CSV_COLUMN_AMOUNT_CHARGED = 'Amount Charged';
    @TestVisible private static final String CSV_COLUMN_CASE_KEY = 'Case Key';
    @TestVisible private static final String CSV_COLUMN_CLAIM_SOURCE = 'Claim Source';

    @TestVisible private static final String EXECUTION_CTX_KEY_CASEID_MAP = 'caseidmap';

    // business unit names relevant for credit dispute claims
    @TestVisible private static final String BUSINESSUNIT_AUSTRALIAPOST = 'Australia Post';
    @TestVisible private static final String BUSINESSUNIT_STARTRACK = 'StarTrack';

    // credit dispute case record type developer name
    @TestVisible private static final String CASE_RECORDTYPE_DEVELOPER_NAME = 'Enterprise_Credit_Dispute_Claim';

    // default case origin to set for bulk uploaded cases
    @TestVisible private static final String CASE_ORIGIN = 'Bulk Upload';

    // default purpose to set for credit dispute cases
    @TestVisible private static final String CASE_PURPOSE = 'Credit Claim';

    // record type details for credit dispute claim
    private static final RecordType CREDIT_DISPUTE_CLAIM_CASE_RECORDTYPE {
        get {
            if (CREDIT_DISPUTE_CLAIM_CASE_RECORDTYPE == null) {
                CREDIT_DISPUTE_CLAIM_CASE_RECORDTYPE = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{CASE_RECORDTYPE_DEVELOPER_NAME}).values()[0];
            }
            return CREDIT_DISPUTE_CLAIM_CASE_RECORDTYPE;
        }
        private set;
    }

    // case assignment rule to execute on case insert
    private static final AssignmentRule CASE_ASSIGNMENT_RULE {
        get {
            if (CASE_ASSIGNMENT_RULE == null) {
                List<AssignmentRule> assignmentRules = [select Id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
                if (assignmentRules.size() == 1) {
                    CASE_ASSIGNMENT_RULE = assignmentRules[0];
                } else {
                    CASE_ASSIGNMENT_RULE = new AssignmentRule();
                }
            }
            return CASE_ASSIGNMENT_RULE;
        }
        private set;
    }

    // dependent picklist values for Enquiry_Type__c field applicable for each controlling filed (Call_Purpose__c) value.
    // dependent pick list values are based on field describes.
    private static final Map<String, List<String>> ENQUIRYTYPE_DEPENDENTPICKLISTVALUES {
        get {
            if (ENQUIRYTYPE_DEPENDENTPICKLISTVALUES == null) {
                ENQUIRYTYPE_DEPENDENTPICKLISTVALUES = AP_FieldDescribeUtil.getDependentPicklistValues(Case.Enquiry_Type__c, Case.Call_Purpose__c);
            }
            return ENQUIRYTYPE_DEPENDENTPICKLISTVALUES;
        }
        set;
    }

    // dependent picklist values for ReasonforCreditClaim__c field applicable for each controlling filed (Enquiry_Type__c) value.
    // dependent pick list values are based on field describes.
    private static final Map<String, List<String>> REASONFORCREDITCLAIM_DEPENDENTPICKLISTVALUES {
        get {
            if (REASONFORCREDITCLAIM_DEPENDENTPICKLISTVALUES == null) {
                REASONFORCREDITCLAIM_DEPENDENTPICKLISTVALUES = AP_FieldDescribeUtil.getDependentPicklistValues(Case.ReasonforCreditClaim__c, Case.Enquiry_Type__c);
            }
            return REASONFORCREDITCLAIM_DEPENDENTPICKLISTVALUES;
        }
        set;
    }

    // bulk upload settings for credit dispute claim
    private static final BulkUploadSettings__mdt CREDIT_DISPUTE_BULKUPLOAD_SETTINGS {
        get {
            if (CREDIT_DISPUTE_BULKUPLOAD_SETTINGS == null) {
                CREDIT_DISPUTE_BULKUPLOAD_SETTINGS = [Select Id, DeveloperName, ProcessingBatchSize__c, HandlerSettings__c from BulkUploadSettings__mdt Where DeveloperName = :BulkUploadService.UploadType.DISPUTED_CREDIT_CLAIMS.name()];
            }
            return CREDIT_DISPUTE_BULKUPLOAD_SETTINGS;
        }
        private set;
    }

    /**
     * Return field metadata for 'Credit Dispute Claims' upload. Field metadata include:
     *  - field labels (CSV column name)
     *  - field type (for validations)
     *  - maximum field length
     *  - is this a mandatory field
     * @return field metadata.
     */
    public override Map<String, BulkUploadService.FieldMappingConfigItem> getFieldMappingConfig() {
        Map<String, BulkUploadService.FieldMappingConfigItem> fieldMapping = new Map<String, BulkUploadService.FieldMappingConfigItem>();
        fieldMapping.put(CSV_COLUMN_BUSINESS_NAME.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_BUSINESS_NAME, CSV_COLUMN_BUSINESS_NAME, BulkUploadService.FIELD_TYPE_STRING, false, 255));
        fieldMapping.put(CSV_COLUMN_BUSINESS_ACCOUNT_NUMBER.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_BUSINESS_ACCOUNT_NUMBER, CSV_COLUMN_BUSINESS_ACCOUNT_NUMBER, BulkUploadService.FIELD_TYPE_STRING, true, 255));
        fieldMapping.put(CSV_COLUMN_NAME.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_NAME, CSV_COLUMN_NAME, BulkUploadService.FIELD_TYPE_STRING, false, 255));
        fieldMapping.put(CSV_COLUMN_EMAIL.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_EMAIL, CSV_COLUMN_EMAIL, BulkUploadService.FIELD_TYPE_EMAIL, false, 80));
        fieldMapping.put(CSV_COLUMN_PHONE.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_PHONE, CSV_COLUMN_PHONE, BulkUploadService.FIELD_TYPE_STRING, false, 40));
        fieldMapping.put(CSV_COLUMN_ACCOUNT_HELD_WITH.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_ACCOUNT_HELD_WITH, CSV_COLUMN_ACCOUNT_HELD_WITH, BulkUploadService.FIELD_TYPE_PICKLIST, true));
        fieldMapping.put(CSV_COLUMN_DISPUTE_TYPE.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_DISPUTE_TYPE, CSV_COLUMN_DISPUTE_TYPE, BulkUploadService.FIELD_TYPE_PICKLIST, false));
        fieldMapping.put(CSV_COLUMN_REASON_FOR_CREDIT_CLAIM.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_REASON_FOR_CREDIT_CLAIM, CSV_COLUMN_REASON_FOR_CREDIT_CLAIM, BulkUploadService.FIELD_TYPE_PICKLIST, false));
        fieldMapping.put(CSV_COLUMN_TOTAL_AMOUNT_CLAIMED.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_TOTAL_AMOUNT_CLAIMED, CSV_COLUMN_TOTAL_AMOUNT_CLAIMED, BulkUploadService.FIELD_TYPE_CURRENCY, false));
        fieldMapping.put(CSV_COLUMN_DESCRIPTION.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_DESCRIPTION, CSV_COLUMN_DESCRIPTION, BulkUploadService.FIELD_TYPE_STRING, false, 32000));
        fieldMapping.put(CSV_COLUMN_DOCUMENT_DOWNLOAD_URL.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_DOCUMENT_DOWNLOAD_URL, CSV_COLUMN_DOCUMENT_DOWNLOAD_URL, BulkUploadService.FIELD_TYPE_URL, false, 2048));
        fieldMapping.put(CSV_COLUMN_DOCUMENT_WEB_URL.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_DOCUMENT_WEB_URL, CSV_COLUMN_DOCUMENT_WEB_URL, BulkUploadService.FIELD_TYPE_URL, false, 2048));
        fieldMapping.put(CSV_COLUMN_CLAIM_IDENTIFIER.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_CLAIM_IDENTIFIER, CSV_COLUMN_CLAIM_IDENTIFIER, BulkUploadService.FIELD_TYPE_STRING, false, 255));
        fieldMapping.put(CSV_COLUMN_INVOICE_NUMBER.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_INVOICE_NUMBER, CSV_COLUMN_INVOICE_NUMBER, BulkUploadService.FIELD_TYPE_STRING, false, 12));
        fieldMapping.put(CSV_COLUMN_TRANSACTION_ID.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_TRANSACTION_ID, CSV_COLUMN_TRANSACTION_ID, BulkUploadService.FIELD_TYPE_STRING, false, 50));
        fieldMapping.put(CSV_COLUMN_CONNOTE.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_CONNOTE, CSV_COLUMN_CONNOTE, BulkUploadService.FIELD_TYPE_STRING, false, 20));
        fieldMapping.put(CSV_COLUMN_AMOUNT_CLAIMED.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_AMOUNT_CLAIMED, CSV_COLUMN_AMOUNT_CLAIMED, BulkUploadService.FIELD_TYPE_CURRENCY, false));
        fieldMapping.put(CSV_COLUMN_AMOUNT_CHARGED.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_AMOUNT_CHARGED, CSV_COLUMN_AMOUNT_CHARGED, BulkUploadService.FIELD_TYPE_CURRENCY, false));
        fieldMapping.put(CSV_COLUMN_CASE_KEY.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_CASE_KEY, CSV_COLUMN_CASE_KEY, BulkUploadService.FIELD_TYPE_STRING, false, 255));
        fieldMapping.put(CSV_COLUMN_CLAIM_SOURCE.toLowerCase(), new BulkUploadService.FieldMappingConfigItem(CSV_COLUMN_CLAIM_SOURCE, CSV_COLUMN_CLAIM_SOURCE, BulkUploadService.FIELD_TYPE_STRING, false, 50));
        return fieldMapping;
    }

    public Integer getProcessingBatchSize() {
        return Integer.valueOf(CREDIT_DISPUTE_BULKUPLOAD_SETTINGS.ProcessingBatchSize__c);
    }

    /**
     * Validate a batch of Credit Dispute Claim line items. Details of validation errors are populated
     * in 'ErrorMessage__c' field in each of the line item.
     *
     * @param lineItems batch of line items to validate
     */
    public void validateLineItems(List<BulkLoadRequestLineItem__c> lineItems) {
        for (BulkLoadRequestLineItem__c lineItem: lineItems) {
            Map<String, Object> lineItemPayloadData = parseLineItemPayloadIgnoreCaseForPropertyNames(lineItem);

            // validate field types and required fields
            String fieldTypeErrors = validateFieldTypesAndRequiredFields(lineItemPayloadData);

            // validate business unit and check one of transaction id or connote # is populated.
            String businessUnitErrors = validateBusinessUnit(lineItemPayloadData);

            // validate dependent picklist values based on their controller field values.
            String dependentPicklistErrors = validateDependentPicklistFieldValues(lineItemPayloadData);

            if (String.isNotBlank(fieldTypeErrors) || String.isNotBlank(businessUnitErrors) || String.isNotBlank(dependentPicklistErrors)) {
                // finally populate 'ErrorMessage__c' field.
                lineItem.ErrorMessage__c = fieldTypeErrors + businessUnitErrors + dependentPicklistErrors;
            }
        }
    }

    /**
     * Process a batch of Credit Dispute Claim line items and create Cases and Disputed Items. Line item status is
     * updated with the results together with details of any errors encountered.
     *
     * @param lineItems batch of line items to validate
     * @param executionContext a collection of key-value pairs that hold contextual information.
     *
     * @return processing results with error and success counts.
     */
    public BulkUploadService.LineItemsProcessResult process(List<BulkLoadRequestLineItem__c> lineItems, Map<String, Object> executionContext) {

        // this method can be called multiple times for a bulk load request to process it's line items in batches. As case
        // creation is a resource-intensive process, line items are to be processed in smaller batches to ensure scalability.
        // use execution context to store Ids of new cases created in each batch, so that if we get a line item in a later batch that needs to
        // be linked to a case that has been previously created, we can locate the case id via execution context.
        if (executionContext.get(EXECUTION_CTX_KEY_CASEID_MAP) == null) {
            // add a new map to hold case ids into execution context. this is only required when processing the first
            // batch of line items. subsequent batches can simply access the case id map via execution context.
            executionContext.put(EXECUTION_CTX_KEY_CASEID_MAP, new Map<String, Id>());
        }

        Map<String, BulkUploadService.FieldMappingConfigItem> fieldDefinitions = getFieldMappingConfig();

        Map<String, Case> casesToCreate = new Map<String, Case>();
        List<CreditDisputeClaimLineItemWrapper> creditDisputeClaimLineItemWrappers = new List<CreditDisputeClaimLineItemWrapper>();

        for (BulkLoadRequestLineItem__c lineItem: lineItems) {
            Map<String, Object> parsedLineItemPayload = parseLineItemPayloadIgnoreCaseForPropertyNames(lineItem);

            // determine the key to lookup parent case in existing cases.
            String parentCaseLookupKey = getParentCaseLookupKey(parsedLineItemPayload, Integer.valueOf(lineItem.LineNumber__c));
            Disputed_Item__c disputedItem = newDisputedItem(parsedLineItemPayload, fieldDefinitions);
            Case caseRecord = null;

            // check if we have a case for the parent case lookup key. if so, link the new disputed item to that case.
            // if no cases are found, create a new case and link that case to disputed item.
            if (((Map<String,Id>)executionContext.get(EXECUTION_CTX_KEY_CASEID_MAP)).containsKey(parentCaseLookupKey)) {
                disputedItem.Case__c = ((Map<String,Id>)executionContext.get(EXECUTION_CTX_KEY_CASEID_MAP)).get(parentCaseLookupKey);
            } else {
                caseRecord = casesToCreate.get(parentCaseLookupKey);
                if (caseRecord == null) {
                    //new case to be created
                    caseRecord = newCase(parsedLineItemPayload, fieldDefinitions, lineItem.BulkLoadRequest__r.FileName__c);
                    casesToCreate.put(parentCaseLookupKey, caseRecord);
                }
            }

            // create a wrapper instance to hold the source line item, parsed payload, disputed item and the case.
            CreditDisputeClaimLineItemWrapper lineItemWrapper = new CreditDisputeClaimLineItemWrapper(lineItem, parsedLineItemPayload, disputedItem, caseRecord);
            creditDisputeClaimLineItemWrappers.add(lineItemWrapper);
        }

        if (!casesToCreate.isEmpty()) {
            // insert new cases and resolve case ids in wrapper instances.
            insertCases(casesToCreate.values(), creditDisputeClaimLineItemWrappers);

            for (String parentCaseLookupKey : casesToCreate.keySet()) {
                if (casesToCreate.get(parentCaseLookupKey).Id != null) {
                    // update the execution context with newly created case ids.
                    ((Map<String,Id>) executionContext.get(EXECUTION_CTX_KEY_CASEID_MAP)).put(parentCaseLookupKey, casesToCreate.get(parentCaseLookupKey).Id);
                }
            }
        }

        if (!creditDisputeClaimLineItemWrappers.isEmpty()) {
            // insert new disputed items. set line item status in wrappers to either 'Success' or 'Error'
            insertDisputedItems(creditDisputeClaimLineItemWrappers);
        }

        // update line item status and return results.
        return updateLineItemStatus(lineItems);
    }

    public override void onProcessingCompleted(Id bulkLoadRequestId, Map<String, Object> executionContext) {
        if (executionContext != null && !executionContext.isEmpty()) {
            Integer batchSize = (Integer) getHandlerSetting('retrieveDocumentsBatchSize');
            Decimal maxFileSize = (Decimal) getHandlerSetting('retrieveDocumentsMaxFileSizeInMB');
            Integer requestTimeout = (Integer) getHandlerSetting('retrieveDocumentsRequestTimeoutInSeconds');
            Boolean enableApplicationLogs = (Boolean) getHandlerSetting('retrieveDocumentsEnableApplicationLogs');
            RetrieveDisputedCreditDocumentsBatchable retrieveDocumentsBatchable = new RetrieveDisputedCreditDocumentsBatchable(((Map<String, Id>) executionContext.get(EXECUTION_CTX_KEY_CASEID_MAP)).values(), maxFileSize, requestTimeout, enableApplicationLogs);
            Database.executeBatch(retrieveDocumentsBatchable, (batchSize != null ? batchSize : 5));
        }
    }

    private String validateBusinessUnit(Map<String, Object> lineItemPayloadData) {
        String errorMessage = '';
        // transaction id is required if business unit = Australia Post and connote # is required if business unit = Startrack
        String businessUnit = (String) lineItemPayloadData.get(CSV_COLUMN_ACCOUNT_HELD_WITH.toLowerCase());
        String transactionId = (String) lineItemPayloadData.get(CSV_COLUMN_TRANSACTION_ID.toLowerCase());
        String connoteNumber = (String) lineItemPayloadData.get(CSV_COLUMN_CONNOTE.toLowerCase());

        if (!(BUSINESSUNIT_AUSTRALIAPOST.equalsIgnoreCase(businessUnit) || BUSINESSUNIT_STARTRACK.equalsIgnoreCase(businessUnit)))  {
            errorMessage += ('Invalid field value [' + CSV_COLUMN_ACCOUNT_HELD_WITH + '='+ businessUnit + ']; ');
        } else if (BUSINESSUNIT_AUSTRALIAPOST.equalsIgnoreCase(businessUnit) && String.isBlank(transactionId)) {
            errorMessage += (CSV_COLUMN_TRANSACTION_ID + ' cannot be blank for '+ businessUnit + ' accounts; ');
        } else if (BUSINESSUNIT_STARTRACK.equalsIgnoreCase(businessUnit) && String.isBlank(connoteNumber)) {
            errorMessage += (CSV_COLUMN_CONNOTE + ' cannot be blank for '+ businessUnit + ' accounts; ');
        }
        return errorMessage;
    }

    private String validateDependentPicklistFieldValues(Map<String, Object> lineItemPayloadData) {
        String errorMessage = '';
        String enquiryType = (String) lineItemPayloadData.get(CSV_COLUMN_DISPUTE_TYPE.toLowerCase());
        if (!isDependentPicklistValueValid(ENQUIRYTYPE_DEPENDENTPICKLISTVALUES, enquiryType, CASE_PURPOSE)) {
            errorMessage += ('Invalid field value [' + CSV_COLUMN_DISPUTE_TYPE + '='+ enquiryType + ']; ');
        }

        String reasonForCreditClaim = (String) lineItemPayloadData.get(CSV_COLUMN_REASON_FOR_CREDIT_CLAIM.toLowerCase());
        if (!isDependentPicklistValueValid(REASONFORCREDITCLAIM_DEPENDENTPICKLISTVALUES, reasonForCreditClaim, enquiryType)) {
            errorMessage += ('Invalid dependent field value [' + CSV_COLUMN_REASON_FOR_CREDIT_CLAIM + '=' + reasonForCreditClaim + '] for controlling value [' + CSV_COLUMN_DISPUTE_TYPE + '=' + enquiryType + ']; ');
        }

        return errorMessage;
    }

    private Boolean isDependentPicklistValueValid(Map<String, List<String>> validPicklistDependencies, String fieldValue, String controllingFieldValue) {
        List<String> validPicklistValues = validPicklistDependencies.get(controllingFieldValue);

        // validate dependent values only if field value is not empty. empty values (translates to null) allowed for
        // non mandatory picklist fields.
        if (String.isNotEmpty(fieldValue) && (validPicklistValues == null || !validPicklistValues.contains(fieldValue))) {
            return false;
        }
        return true;
    }

    /**
     * Return a new Disputed_Item__c record with all relevant fields populated from the line item payload data passed in.
     *
     * @param parsedLineItemPayload parsed line item payload
     * @param fieldDefinitions field metadata
     *
     * @return new Disputed_Item__c record (not inserted)
     */
    private Disputed_Item__c newDisputedItem(Map<String, Object> parsedLineItemPayload, Map<String, BulkUploadService.FieldMappingConfigItem> fieldDefinitions) {
        Disputed_Item__c disputedItem = new Disputed_Item__c();
        disputedItem.Invoice_Number__c = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_INVOICE_NUMBER.toLowerCase()));
        disputedItem.Transaction_ID__c = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_TRANSACTION_ID.toLowerCase()));
        disputedItem.Connote__c = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_CONNOTE.toLowerCase()));
        disputedItem.Amount_Claimed__c = (Decimal) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_AMOUNT_CLAIMED.toLowerCase()));
        disputedItem.Amount__c = (Decimal) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_AMOUNT_CHARGED.toLowerCase()));
        disputedItem.SupportingDocumentDownloadURL__c = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_DOCUMENT_DOWNLOAD_URL.toLowerCase()));
        disputedItem.SupportingDocumentWebURL__c = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_DOCUMENT_WEB_URL.toLowerCase()));
        return disputedItem;
    }

    private String getParentCaseLookupKey(Map<String, Object> parsedLineItemPayload, Integer lineNumber) {

        // if 'case key' is set, use 'case key' to lookup parent cases. else use 'external identifier' if available.
        // 'case key' is set by Customer Resolutions staff to control how DI line items must be allocated to cases.
        // if both external identifier and case key is blank use billing account number & line number as the parent case lookup key to ensure uniqueness

        String parentCaseLookupKey = parsedLineItemPayload.get(CSV_COLUMN_BUSINESS_ACCOUNT_NUMBER.toLowerCase()) + '_' + lineNumber;

        if (String.isNotBlank((String) parsedLineItemPayload.get(CSV_COLUMN_CASE_KEY.toLowerCase()))) {
            parentCaseLookupKey = (String) parsedLineItemPayload.get(CSV_COLUMN_CASE_KEY.toLowerCase());
        } else if (String.isNotBlank((String) parsedLineItemPayload.get(CSV_COLUMN_CLAIM_IDENTIFIER.toLowerCase()))) {
            parentCaseLookupKey = (String) parsedLineItemPayload.get(CSV_COLUMN_CLAIM_IDENTIFIER.toLowerCase());
        }

        return parentCaseLookupKey;
    }

    /**
     * Return a new Case record with all relevant fields populated from the line item payload data passed in.
     *
     * @param parsedLineItemPayload parsed line item payload
     * @param fieldDefinitions field metadata
     * @param fileName name of the source csv file.
     *
     * @return new case record (not inserted)
     */
    private Case newCase(Map<String, Object> parsedLineItemPayload, Map<String, BulkUploadService.FieldMappingConfigItem> fieldDefinitions, String fileName) {
        Case caseRec = new Case();
        caseRec.Billing_Number__c = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_BUSINESS_ACCOUNT_NUMBER.toLowerCase()));
        caseRec.Business_Name__c = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_BUSINESS_NAME.toLowerCase()));
        caseRec.Name__c = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_NAME.toLowerCase()));
        caseRec.Email_Address__c = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_EMAIL.toLowerCase()));
        caseRec.Phone__c = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_PHONE.toLowerCase()));
        caseRec.Business_Unit__c = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_ACCOUNT_HELD_WITH.toLowerCase()));
        caseRec.Enquiry_Type__c = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_DISPUTE_TYPE.toLowerCase()));
        caseRec.ReasonforCreditClaim__c = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_REASON_FOR_CREDIT_CLAIM.toLowerCase()));
        caseRec.Amount_Claimed__c = (Decimal) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_TOTAL_AMOUNT_CLAIMED.toLowerCase()));
        caseRec.Description = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_DESCRIPTION.toLowerCase()));
        caseRec.ReferenceID__c = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_CLAIM_IDENTIFIER.toLowerCase()));
        String claimSource = (String) get(parsedLineItemPayload, fieldDefinitions.get(CSV_COLUMN_CLAIM_SOURCE.toLowerCase()));
        caseRec.Reason_for_Claim__c = 'filename=' + fileName + ';' + (String.isNotBlank(claimSource) ? 'claimsource=' + claimSource + ';' : '');
        caseRec.Origin = CASE_ORIGIN;
        caseRec.Call_Purpose__c = CASE_PURPOSE;
        caseRec.RecordTypeId = CREDIT_DISPUTE_CLAIM_CASE_RECORDTYPE.Id;

        // if there is an active case assignment rule set the DML Options to ensure assignment rule is executed on case insert
        if (CASE_ASSIGNMENT_RULE.Id != null) {
            Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.assignmentRuleHeader.assignmentRuleId= CASE_ASSIGNMENT_RULE.Id;
            caseRec.setOptions(dmlOptions);
        }

        return caseRec;
    }

    /**
     * Insert list of cases and update the results in line items wrappers passed in.
     *
     * @param casesToCreate list of cases to insert
     * @param creditDisputeClaimLineItemWrappers list of line item wrappers that needs to be updated with case insert results.
     */
    private void insertCases(List<Case> casesToCreate, List<CreditDisputeClaimLineItemWrapper> creditDisputeClaimLineItemWrappers) {
        Database.SaveResult[] caseSaveResults = ApplicationDatabase.getInstance().dmlInsert(casesToCreate, false);
        Map<Case, List<CreditDisputeClaimLineItemWrapper>> creditDisputeClaimLineItemWrappersByCases = getDisputedItemsByCreditCasesMap(creditDisputeClaimLineItemWrappers);

        for (Integer i=0; i <  casesToCreate.size(); i++) {
            Case caseRecord = casesToCreate[i];
            List<CreditDisputeClaimLineItemWrapper> lineItemWrappersForCase = (List<CreditDisputeClaimLineItemWrapper>) creditDisputeClaimLineItemWrappersByCases.get(caseRecord);

            Database.SaveResult caseSaveResult = caseSaveResults[i];
            if (!caseSaveResult.isSuccess()) {
                // case has failed to insert. set status of all line items dependent on this case to 'Error'.
                for (CreditDisputeClaimLineItemWrapper lineItemWrapper:  lineItemWrappersForCase) {
                    lineItemWrapper.lineItem.ErrorMessage__c = getErrorMessageDetails('Failed to create Case.', caseSaveResult.errors);
                    lineItemWrapper.lineItem.Status__c = BulkUploadService.LINEITEM_STATUS_ERROR;
                }
            } else {
                // case has been inserted successfully. resolve case id on disputed items dependent on this case.
                for (CreditDisputeClaimLineItemWrapper lineItemWrapper:  lineItemWrappersForCase) {
                    lineItemWrapper.resolveCaseIdOnDisputedItem();
                }
            }
        }
    }

    private Map<Case, List<CreditDisputeClaimLineItemWrapper>> getDisputedItemsByCreditCasesMap(List<CreditDisputeClaimLineItemWrapper> creditDisputeClaimLineItemWrappers) {
        Map<Case, List<CreditDisputeClaimLineItemWrapper>> disputedItemsByCaseMap = new Map<Case, List<CreditDisputeClaimLineItemWrapper>>();
        for (CreditDisputeClaimLineItemWrapper lineItemWrapper: creditDisputeClaimLineItemWrappers) {
            List<CreditDisputeClaimLineItemWrapper> disputedItemsForCase = (List<CreditDisputeClaimLineItemWrapper>) disputedItemsByCaseMap.get(lineItemWrapper.caseRecord);
            if (disputedItemsForCase == null) {
                disputedItemsForCase = new List<CreditDisputeClaimLineItemWrapper>();
                disputedItemsByCaseMap.put(lineItemWrapper.caseRecord, disputedItemsForCase);
            }
            disputedItemsForCase.add(lineItemWrapper);
        }

        return disputedItemsByCaseMap;
    }

    /**
     * Insert disputed items and update results in line items wrappers passed in.
     *
     * @param creditDisputeClaimLineItemWrappers line item wrappers
     */
    private void insertDisputedItems(List<CreditDisputeClaimLineItemWrapper> creditDisputeClaimLineItemWrappers) {
        List<Disputed_Item__c> disputedItemRecordsToInsert = new List<Disputed_Item__c>();
        List<CreditDisputeClaimLineItemWrapper> creditDisputeClaimLineItemWrappersToInsert = new List<CreditDisputeClaimLineItemWrapper>();

        for (CreditDisputeClaimLineItemWrapper wrapper: creditDisputeClaimLineItemWrappers) {

            // check if line item status is already set to 'Error'. this may happen if parent case has failed to insert.
            // only collect the disputed items for successfully inserted cases.
            if (wrapper.lineItem.Status__c != BulkUploadService.LINEITEM_STATUS_ERROR) {
                disputedItemRecordsToInsert.add(wrapper.disputedItem);
                creditDisputeClaimLineItemWrappersToInsert.add(wrapper);
            }
        }

        if (!disputedItemRecordsToInsert.isEmpty()) {
            Database.SaveResult[] saveResults = ApplicationDatabase.getInstance().dmlInsert(disputedItemRecordsToInsert, false);

            for (Integer i=0; i < disputedItemRecordsToInsert.size(); i++) {
                Database.SaveResult saveResult = saveResults[i];

                BulkLoadRequestLineItem__c lineItem = creditDisputeClaimLineItemWrappersToInsert[i].lineItem;
                if (!saveResult.isSuccess()) {
                    lineItem.Status__c = BulkUploadService.LINEITEM_STATUS_ERROR;
                    lineItem.ErrorMessage__c = getErrorMessageDetails('Disputed Item save error. ', saveResult.errors);
                } else {
                    lineItem.Status__c = BulkUploadService.LINEITEM_STATUS_SUCCESS;
                }
            }
        }
    }

    private String getErrorMessageDetails(String message, List<Database.Error> errors) {
        String errorMessage= message + '; Root Cause - [';
        for (Database.Error error: errors) {
            errorMessage += (error.getMessage() + ', ');
        }
        errorMessage = errorMessage.removeEnd(', ');
        errorMessage += ']; ';
        return errorMessage;
    }

    private BulkUploadService.LineItemsProcessResult updateLineItemStatus(List<BulkLoadRequestLineItem__c> lineItems) {
        BulkUploadService.LineItemsProcessResult result = new BulkUploadService.LineItemsProcessResult();

        List<BulkLoadRequestLineItem__c> lineItemsToUpdate = new List<BulkLoadRequestLineItem__c>();

        for (BulkLoadRequestLineItem__c lineItem: lineItems) {
            BulkLoadRequestLineItem__c lineItemToUpdate = new BulkLoadRequestLineItem__c(Id=lineItem.Id);
            lineItemToUpdate.Status__c = lineItem.Status__c;
            if (lineItem.Status__c == BulkUploadService.LINEITEM_STATUS_ERROR) {
                lineItemToUpdate.ErrorMessage__c = lineItem.ErrorMessage__c;
                result.errorCount++;
            } else if (lineItem.Status__c == BulkUploadService.LINEITEM_STATUS_SUCCESS) {
                result.successCount++;
            }
            lineItemsToUpdate.add(lineItemToUpdate);
        }

        ApplicationDatabase.getInstance().dmlUpdate(lineItemsToUpdate, false);
        return result;
    }

    private Object getHandlerSetting(String name) {
        if (CREDIT_DISPUTE_BULKUPLOAD_SETTINGS.HandlerSettings__c != null) {
            Map<String, Object> handlerSettings = (Map<String, Object>) JSON.deserializeUntyped(CREDIT_DISPUTE_BULKUPLOAD_SETTINGS.HandlerSettings__c);
            return handlerSettings.get(name);
        }
        return null;
    }

    private class CreditDisputeClaimLineItemWrapper {
        BulkLoadRequestLineItem__c lineItem;
        Map<String, Object> parsedLineItemPayload;
        Case caseRecord;
        Disputed_Item__c disputedItem;

        private CreditDisputeClaimLineItemWrapper(BulkLoadRequestLineItem__c lineItem, Map<String, Object> parsedLineItemPayload, Disputed_Item__c disputedItem, Case caseRecord) {
            this.lineItem = lineItem;
            this.parsedLineItemPayload = parsedLineItemPayload;
            this.disputedItem = disputedItem;
            this.caseRecord = caseRecord;
            if (this.caseRecord == null && this.disputedItem.Case__c != null) {
                this.caseRecord = new Case(Id=this.disputedItem.Case__c);
            }
        }

        private void resolveCaseIdOnDisputedItem() {
            if (this.disputedItem.Case__c == null && this.caseRecord.Id != null) {
                this.disputedItem.Case__c = this.caseRecord.Id;
            }
        }
    }






}