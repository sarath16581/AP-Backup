/**
 * @description Generic service layer for managing Bulk Uploads including uploading and processing line items. Delegates
 *              to an implementation of IBulkUploadRequestHandler based on the upload type for behaviour specific to
 *              each upload type.
 *              Bulk upload is initiated by uploading a CSV data file of an agreed format. Uploading a file creates a
 *              record in BulkLoadRequest__c and the line items in BulkLoadRequestLineItem__c. Line item payload is stored
 *              in JSON format on BulkLoadRequestLineItem__c to keep the implementation generic.
 * @author Ranjeewa Silva
 * @date 2021-01-22
 * @group BulkUpload
 * @domain Core
 * @changelog
 * 2020-01-22 - Ranjeewa Silva - Created
 **/
public inherited sharing class BulkUploadService {

    // field types supported. used for data validations.
    public static final String FIELD_TYPE_STRING = 'STRING';
    public static final String FIELD_TYPE_CURRENCY = 'CURRENCY';
    public static final String FIELD_TYPE_URL = 'URL';
    public static final String FIELD_TYPE_EMAIL = 'EMAIL';
    public static final String FIELD_TYPE_PICKLIST = 'PICKLIST';

    // line item status
    public static final String LINEITEM_STATUS_NEW = 'New';
    public static final String LINEITEM_STATUS_ERROR = 'Error';
    public static final String LINEITEM_STATUS_SUCCESS = 'Success';

    // bulk upload request status
    public static final String REQUEST_STATUS_NEW = 'New';
    public static final String REQUEST_STATUS_PENDING = 'Pending';
    public static final String REQUEST_STATUS_PROCESSED = 'Processed';

    /**
     * Creates a new instance of the service. This allows use to use dependency injection for mocking
     * @return the new instance
     */
    public static BulkUploadService getInstance() {
        return (BulkUploadService) Application.Utilities.getInstance(BulkUploadService.class);
    }

    /**
     * Retrieve field metadata for the upload type.
     * @param uploadType type of the upload. determines how line item payload is validated and processed.
     * @return the configuration applicable for the upload type.
     */
    public Map<String, FieldMappingConfigItem> getFieldMapping(UploadType uploadType) {
        IBulkUploadRequestHandler handler = getHandler(uploadType);
        // delegate to handler
        return handler.getFieldMappingConfig();
    }

    /**
     * Creates a new BulkLoadRequest__c record. This is a pre-requisite for uploading line items.
     * @param request new bulk load request to create.
     * @param duplicateRequestCheck if true, check for duplicate requests based on file name. BulkLoadRequest__c record
     *                              is not created if duplicates found and returns an error
     *
     * @return Save results with the id of newly created BulkLoadRequest__c if successful. Contains error details in case
     *         of failure.
     */
    public BulkUploadRequestSaveResult createRequest(BulkLoadRequest__c request, Boolean duplicateRequestCheck) {

        BulkUploadRequestSaveResult saveResult = new BulkUploadRequestSaveResult();

        if (duplicateRequestCheck) {
            // Check for duplicate requests by file name.
            Map<Id, BulkLoadRequest__c> existingRequests = BulkLoadRequestSelector.newInstance(1).selectByTypeAndFileName(request.Type__c, new Set<String>{request.FileName__c});
            if (!existingRequests.isEmpty()) {
                saveResult.fileName = request.FileName__c;
                saveResult.errorMessage = 'Bulk upload request for file [' + request.FileName__c + '] already existing.';
                return saveResult;
            }
        }

        try {
            ApplicationDatabase.getInstance().dmlInsert(new List<BulkLoadRequest__c>{request});
            saveResult.requestId = request.Id;
            saveResult.fileName = request.FileName__c;
        } catch (Exception ex) {
            saveResult.errorMessage = ex.getMessage();
        }

        return saveResult;
    }

    /**
     * Create child line items on the BulkLoadRequest__c specified. This may be called multiple times to allow
     * uploading line items in batches.
     * Uploading line items is supported only when parent BulkLoadRequest__c is in 'New' status. After all batches of
     * line items are uploaded the caller is required to call "finaliseRequest" method to indicate completion of
     * uploading of all line items and make BulkLoadRequest__c available for processing.
     *
     * @param requestId Id of the parent BulkLoadRequest__c
     * @param lineItems list of line items to upload in current batch
     *
     * @return Summary of Line Items save operation.
     */
    public LineItemsSaveResult createLineItems(Id requestId, List<BulkLoadRequestLineItem__c> lineItems) {

        BulkLoadRequest__c request = BulkLoadRequestSelector.newInstance().selectById(new Set<Id>{requestId}).get(requestId);

        // check if line items can be added to the parent request.
        if (!REQUEST_STATUS_NEW.equalsIgnoreCase(request.Status__c)) {
            String errorMessage = 'Cannot upload line items to Bulk load request in [' + request.Status__c + '] status.';
            throw new BulkUploadException(errorMessage);
        }

        // validate individual line items.
        LineItemsSaveResult saveResults = validateLineItems(request, lineItems);

        // if there are errors, none of the records get inserted. return errors back so it can be retried after addressing
        // errors.
        if (saveResults.errorCount == 0) {
            Database.SaveResult[] dbSaveResults = ApplicationDatabase.getInstance().dmlInsert(lineItems, false);
            for (Integer i=0; i < lineItems.size(); i++) {
                Database.SaveResult dbSaveResult = dbSaveResults[i];
                BulkLoadRequestLineItem__c lineItem = lineItems[i];
                if (!dbSaveResult.isSuccess()) {
                    // encountered an error on insert.
                    // adjust the error count / success count on the LineItemsSaveResult instance.
                    saveResults.errorCount++;
                    saveResults.successCount--;

                    for (Database.Error error: dbSaveResult.errors) {
                        String fields = String.join(error.getFields(),', ');
                        lineItem.ErrorMessage__c += (error.getMessage() + ' [' + fields + ']; ');
                    }

                    saveResults.invalidLineItems.add(lineItem);
                }
            }
        }

        return saveResults;
    }

    /**
     * Finalise uploading Bulk Load Request data. This method must be called when all line items in this Bulk Load Request has
     * been uploaded. Finalising the request closes bulk load request and no new line items can be added after
     * finalising the request.
     *
     * 'allLineItemsValid' parameter controls the finalization action. If set to true, the Bulk Load Request status is
     * updated to 'Pending' and start processing line items asynchronously via batch apex. If set to false, delete the
     * Bulk Load Request so that the file can be uploaded again after addressing validation errors.
     *
     * @param request the bulk load request to finalise.
     * @param allLineItemsValid indicates if all line items for this request has been uploaded successfully.
     */
    public void finaliseUploading(BulkLoadRequest__c request, Boolean allLineItemsValid) {
        BulkLoadRequest__c req = new BulkLoadRequest__c(Id = request.Id);
        if (allLineItemsValid) {
            req.Status__c = REQUEST_STATUS_PENDING;
            req.TotalLineItems__c = request.TotalLineItems__c;
            ApplicationDatabase.getInstance().dmlUpdate(new List<BulkLoadRequest__c>{req});

            UploadType uploadType = UPLOAD_TYPES.get(request.Type__c);
            IBulkUploadRequestHandler handler = getHandler(uploadType);
            // schedule apex batch to process line items
            BulkUploadRequestProcessorBatchable processorBatchable = new BulkUploadRequestProcessorBatchable(request.Id, uploadType);
            Database.executeBatch(processorBatchable, handler.getProcessingBatchSize());

            handler.onUploadCompleted(request.Id);
        } else {
            ApplicationDatabase.getInstance().dmlDelete(new List<BulkLoadRequest__c>{req});
        }
    }

    /**
     * Process the list of line items passed in. Delegates to corresponding handler based on upload type to process
     * line items.
     *
     * Supports processing line items in batches. Allow callers to pass in 'executionContext', a collection of key-value
     * pairs that can be used by handlers to share data across multiple invocations of this method. Data stored in
     * 'executionContext' is controlled by each handler / upload type and only used by specific handlers.
     *
     * After processing, only those line items that failed are retained. Line items processed successfully
     * are no longer required and deleted to reclaim the storage capacity.
     *
     * @param uploadType Upload type that determine the processing logic(i.e. the handler that process this request)
     * @param lineItems List of line items to process in current batch.
     * @param executionContext a collection of key-value pairs to share data across end-to-end processing cycle.
     *
     * @return Line item process result including success and error counts.
     */
    public LineItemsProcessResult processLineItems(UploadType uploadType, List<BulkLoadRequestLineItem__c> lineItems, Map<String,Object> executionContext) {
        IBulkUploadRequestHandler handler = getHandler(uploadType);
        LineItemsProcessResult results = handler.process(lineItems, executionContext);
        deleteSuccessfullyProcessedLineItems(lineItems);
        return results;
    }

    /**
     * Finalise processing Bulk Load Request. This method must be called when all line items in this Bulk Load Request has
     * been processed. Delegates to corresponding handler based on upload type to execute any post-processing actions.
     *
     * @param uploadType Upload type that determines the post-processing actions (i.e. the handler that process this request)
     * @param bulkLoadRequestId Id of the parent BulkLoadRequest__c
     * @param results Line items processing results for this request.
     * @param executionContext a collection of key-value pairs to share data across end-to-end processing cycle.
     */
    public void finaliseProcessing(UploadType uploadType, Id bulkLoadRequestId, LineItemsProcessResult results, Map<String,Object> executionContext) {

        BulkLoadRequest__c request = new BulkLoadRequest__c(Id=bulkLoadRequestId);
        request.TotalSuccessful__c = results.successCount;
        request.TotalFailed__c = results.errorCount;
        request.Status__c = REQUEST_STATUS_PROCESSED;
        request.ProcessedTimestamp__c = System.now();

        ApplicationDatabase.getInstance().dmlUpdate(new List<BulkLoadRequest__c>{request}, false);

        IBulkUploadRequestHandler handler = getHandler(uploadType);
        handler.onProcessingCompleted(bulkLoadRequestId, executionContext);
    }

    /**
     * Validate line items passes in. Delegates to corresponding handler based on upload type to validate line items.
     *
     * @param request parent Bulk Load Request
     * @param lineItems line items to validate
     *
     * @return an instance of LineItemsSaveResult with validation results
     */
    private LineItemsSaveResult validateLineItems(BulkLoadRequest__c request, List<BulkLoadRequestLineItem__c> lineItems) {
        LineItemsSaveResult saveResults = new LineItemsSaveResult();
        saveResults.requestId = request.Id;
        saveResults.fileName = request.FileName__c;

        IBulkUploadRequestHandler handler = getHandler(UPLOAD_TYPES.get(request.Type__c));
        //delegate to handler
        handler.validateLineItems(lineItems);

        //inspect line items for errors
        for (BulkLoadRequestLineItem__c lineItem: lineItems) {
            lineItem.BulkLoadRequest__c = request.Id;
            if (String.isBlank(lineItem.ErrorMessage__c)) {
                saveResults.successCount++;
            } else {
                saveResults.errorCount++;
                saveResults.invalidLineItems.add(lineItem);
            }
        }

        return saveResults;
    }

    /**
     * Returns the handler configured for the upload type.
     *
     * @param uploadType upload type such as 'DISPUTED_CREDIT_CLAIMS'
     * @return the handler instance
     */
    @TestVisible private IBulkUploadRequestHandler getHandler(UploadType uploadType) {
        if (uploadType != null) {
            List<BulkUploadSettings__mdt> bulkUploadSettings = [Select Id, HandlerClassName__c from BulkUploadSettings__mdt Where DeveloperName = :uploadType.name()];

            if (!bulkUploadSettings.isEmpty() && Type.forName(bulkUploadSettings[0].HandlerClassName__c) != null) {
                //return (IBulkUploadRequestHandler) Application.Utilities.getInstance(requestHandlerMapping.get(uploadType));
                return (IBulkUploadRequestHandler) Application.Utilities.getInstance(Type.forName(bulkUploadSettings[0].HandlerClassName__c));
            }
        }
        throw new BulkUploadException('Unsupported upload type [' + uploadType + ']. Handler not available for this upload type.');
    }

    /**
     * Delete successfully processed line items out of the line items passed in.
     *
     * @param lineItems line items
     */
    private void deleteSuccessfullyProcessedLineItems(List<BulkLoadRequestLineItem__c> lineItems) {
        List<BulkLoadRequestLineItem__c> lineItemsToDelete = new List<BulkLoadRequestLineItem__c>();
        for (BulkLoadRequestLineItem__c lineItem: lineItems) {
            if (lineItem.Status__c == LINEITEM_STATUS_SUCCESS) {
                lineItemsToDelete.add(lineItem);
            }
        }
        ApplicationDatabase.getInstance().dmlDelete(lineItemsToDelete);
    }

    /**
     * Interface describing work performed on uploading and processing Bulk Load Requests and associated line items.
     *
     * Concrete implementations are expected to handle a specific upload type such as DISPUTED_CREDIT_CLAIMS.
     */
    public interface IBulkUploadRequestHandler {
        Map<String, FieldMappingConfigItem> getFieldMappingConfig();
        Integer getProcessingBatchSize();
        void validateLineItems(List<BulkLoadRequestLineItem__c> lineItems);
        void onUploadCompleted(Id bulkLoadRequestId);
        LineItemsProcessResult process(List<BulkLoadRequestLineItem__c> lineItems, Map<String, Object> executionContext);
        void onProcessingCompleted(Id bulkLoadRequestId, Map<String, Object> executionContext);
    }

    /**
     * Abstract class implementing IBulkUploadRequestHandler interface to provide some useful base functionality
     * that could be extended by concrete implementations.
     */
    public abstract class BulkUploadRequestHandler implements IBulkUploadRequestHandler {

        // Compiled pattern for validating email address format accepted by Salesforce Email Fields
        protected final Pattern VALID_EMAIL_PATTERN = Pattern.compile('([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})');

        protected abstract Map<String, FieldMappingConfigItem> getFieldMappingConfig();

        // base implementation that does nothing. concrete implementations extending this class can optionally provide an implementation.
        public virtual void onUploadCompleted(Id bulkLoadRequestId) {}

        // base implementation that does nothing. concrete implementations extending this class can optionally provide an implementation.
        public virtual void onProcessingCompleted(Id bulkLoadRequestId, Map<String, Object> executionContext) {}

        /**
         * Convenient base method to validate field types and mandatory fields as per the field metadata returned by
         * 'getFieldMappingConfig()' method.
         *
         * @param parsedLineItemPayload parsed line item payload
         * @return error message if any validation errors are encountered. returns blank string if no errors found.
         */
        protected String validateFieldTypesAndRequiredFields(Map<String, Object> parsedLineItemPayload) {
            List<String> requiredFieldsMissing = new List<String>();
            String errorMessage = '';

            Map<String, BulkUploadService.FieldMappingConfigItem> fieldMappingConfig = getFieldMappingConfig();
            for (String fieldNameKey: fieldMappingConfig.keySet()) {
                BulkUploadService.FieldMappingConfigItem fieldMappingConfigItem = fieldMappingConfig.get(fieldNameKey);
                String fieldValueStr = (String) parsedLineItemPayload.get(fieldNameKey);

                if (fieldMappingConfigItem.required && String.isBlank(fieldValueStr)) {
                    requiredFieldsMissing.add(fieldMappingConfigItem.fieldLabel);
                } else if (String.isNotEmpty(fieldValueStr)){
                    //value present - validate max length
                    if (fieldMappingConfigItem.maxLength != null && fieldValueStr.length() > fieldMappingConfigItem.maxLength) {
                        errorMessage += 'Maximum field length exceeded - [' + fieldMappingConfigItem.fieldLabel + ']; ';
                    }

                    // validate field type
                    if (fieldMappingConfigItem.fieldType == BulkUploadService.FIELD_TYPE_CURRENCY) {
                        try {
                            Decimal decimalValue = Decimal.valueOf(fieldValueStr.trim());
                            if (decimalValue.scale() > 2) {
                                errorMessage += 'Invalid currency - [' + fieldMappingConfigItem.fieldLabel + ' = ' + fieldValueStr + ']; ';
                            }
                        } catch (Exception ex) {
                            errorMessage += 'Invalid currency - [' + fieldMappingConfigItem.fieldLabel + ' = ' + fieldValueStr + ']; ';
                        }
                    } else if (fieldMappingConfigItem.fieldType == BulkUploadService.FIELD_TYPE_URL) {
                        try {
                            URL urlValue = new URL(fieldValueStr.trim());
                        } catch (Exception ex) {
                            errorMessage += 'Invalid URL - [' + fieldMappingConfigItem.fieldLabel + ' = ' + fieldValueStr + ']; ';
                        }
                    } else if (fieldMappingConfigItem.fieldType == BulkUploadService.FIELD_TYPE_EMAIL) {
                        if (!VALID_EMAIL_PATTERN.matcher(fieldValueStr.trim()).matches()) {
                            errorMessage += 'Invalid email address - [' + fieldMappingConfigItem.fieldLabel + ' = ' + fieldValueStr + ']; ';
                        }
                    }
                }
            }

            if (requiredFieldsMissing.size() > 0) {
                errorMessage += 'Required field(s) cannot be blank [' + String.join(requiredFieldsMissing, ',') +']; ';
            }

            return errorMessage;
        }

        /**
         * Parse line item payload JSON text. Field names are converted to lower case to make it easier for comparisons.
         * @param lineItem line item with the payload
         * @return parsed line item payload. key = JSON property name in lower case, value = JSON property value
         */
        protected Map<String, Object> parseLineItemPayloadIgnoreCaseForPropertyNames(BulkLoadRequestLineItem__c lineItem) {
            Map<String, Object> lineItemPayload = (Map<String, Object>) JSON.deserializeUntyped(lineItem.LineItemPayload__c);

            Map<String, Object> lineItemData = new Map<String, Object>();
            for (String key: lineItemPayload.keySet()) {
                lineItemData.put(key.toLowerCase(), lineItemPayload.get(key));
            }
            return lineItemData;
        }

        /**
         * Convenient method to extract field values from line item payload based on the corresponding field type.
         *
         * @param parsedLineItemPayload parsed line item payload
         * @param columnDefinition column definition returned by 'getFieldMappingConfig' method
         * @return value as a Decimal for currency fields, as a String for other supported types (String, URL, Email, Picklist)
         */
        protected Object get(Map<String, Object> parsedLineItemPayload, FieldMappingConfigItem columnDefinition) {
            if (parsedLineItemPayload.containsKey(columnDefinition.fieldLabel.toLowerCase())) {
                Object fieldValue = parsedLineItemPayload.get(columnDefinition.fieldLabel.toLowerCase());
                // check if field value is not null and not empty. return null if field value is null or empty string.
                // for non-empty values, attempt to convert to appropriate field type.
                if (fieldValue != null && String.isNotEmpty(fieldValue.toString())) {
                    if (columnDefinition.fieldType == FIELD_TYPE_CURRENCY) {
                        return Decimal.valueOf(fieldValue.toString());
                    } else {
                        return fieldValue.toString();
                    }
                }
            }
            return null;
        }
    }

    // Upload types currently supported in the system
    public enum UploadType {
        DISPUTED_CREDIT_CLAIMS
    }

    // Map of supported upload types indexed by the name. Useful for mapping to the relevant UploadType enum when
    // upload type name is passed in as a String (e.g. @AuraEnabled methods currently do not support enums).
    public static final Map<String, UploadType> UPLOAD_TYPES {
        get {
            if (UPLOAD_TYPES == null){
                Map<String, UploadType> uploadTypesMap = new Map<String, UploadType>();
                for (UploadType enumValue : UploadType.values()){
                    uploadTypesMap.put(enumValue.name(), enumValue);
                }
                UPLOAD_TYPES = uploadTypesMap;
            }
            return UPLOAD_TYPES;
        }
        private set;
    }

    public class FieldMappingConfigItem {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldType;
        @AuraEnabled public Boolean required;
        @AuraEnabled public Integer maxLength;

        public FieldMappingConfigItem(String fieldName, String fieldLabel, String fieldType, Boolean required) {
            this(fieldName, fieldLabel, fieldType, required, null);
        }

        public FieldMappingConfigItem(String fieldName, String fieldLabel, String fieldType, Boolean required, Integer maxLength) {
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.fieldType = fieldType;
            this.required = required;
            this.maxLength = maxLength;
        }
    }

    public class BulkUploadRequestSaveResult {
        @AuraEnabled public Id requestId;
        @AuraEnabled public String fileName;
        @AuraEnabled public String errorMessage;
    }

    public class LineItemsSaveResult {
        @AuraEnabled public Id requestId;
        @AuraEnabled public String fileName;
        @AuraEnabled public Integer successCount = 0;
        @AuraEnabled public Integer errorCount = 0;
        @AuraEnabled public List<BulkLoadRequestLineItem__c> invalidLineItems = new List<BulkLoadRequestLineItem__c>();
    }

    public class LineItemsProcessResult {
        @AuraEnabled public Integer successCount = 0;
        @AuraEnabled public Integer errorCount = 0;
    }

    public class BulkUploadException extends Exception {}
}