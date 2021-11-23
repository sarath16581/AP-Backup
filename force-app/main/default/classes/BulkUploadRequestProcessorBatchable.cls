/**
* @author Ranjeewa Silva
* @date 2021-02-04
* @description Batch class for processing line items in a bulk load request. Line items are processed asynchronously in
*              batches for scalability without breaching platform governor limits.
*              Intended for processing line items of a single bulk upload request in a single invocation of the batch job.
* @changelog
* 2021-02-04 - Ranjeewa Silva - Created.
*/

public with sharing class BulkUploadRequestProcessorBatchable implements Database.Batchable<SObject>, Database.Stateful {

    // id of the parent bulk load request, of which the line items are to be processed.
    Id bulkLoadRequestId;

    // type of the bulk upload. this determines how line item payload is processed.
    BulkUploadService.UploadType uploadType;

    // contextual information (collection of name - value pairs) relevant for the current batch run. execution context
    // is retained across all batches that belong to the current run.
    Map<String, Object> executionContext = new Map<String, Object>();

    // number of records successfully processed by current run
    Integer successCount = 0;

    // number of records failed to process during current run
    Integer errorCount = 0;

    public BulkUploadRequestProcessorBatchable(Id requestId, BulkUploadService.UploadType uploadType) {
        this.bulkLoadRequestId = requestId;
        this.uploadType = uploadType;
    }

    public Database.QueryLocator start(Database.BatchableContext ctx){
        return BulkLoadRequestLineItemsSelector.newInstance().selectByBulkLoadRequestAndStatusQueryLocator(this.bulkLoadRequestId, new Set<String>{BulkUploadService.LINEITEM_STATUS_NEW}, new Set<Object>{BulkLoadRequestLineItemsSelector.Options.WITH_BULKLOADREQUEST});
    }

    public void execute(Database.BatchableContext ctx, List<SObject> scope) {
        try {
            List<BulkLoadRequestLineItem__c> lineItems = (List<BulkLoadRequestLineItem__c>) scope;

            // call service class to process line items
            BulkUploadService.LineItemsProcessResult processResults = BulkUploadService.getInstance().processLineItems(this.uploadType, lineItems, executionContext);

            // update success / error count with the results of processing current batch of line items
            this.successCount += processResults.successCount;
            this.errorCount += processResults.errorCount;
        } catch (Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Bulk Upload', BulkUploadRequestProcessorBatchable.class.getName(), 'execute', null, LoggingLevel.ERROR);
        }
    }

    public void finish(Database.BatchableContext ctx) {
        try {

            BulkUploadService.LineItemsProcessResult requestProcessingResults = new BulkUploadService.LineItemsProcessResult();
            requestProcessingResults.successCount = this.successCount;
            requestProcessingResults.errorCount = this.errorCount;

            // all line items of the bulk load request has been processed. call service class to complete processing of the bulk load request and invoke any post - processing actions.
            BulkUploadService.getInstance().finaliseProcessing(this.uploadType, this.bulkLoadRequestId, requestProcessingResults, this.executionContext);
        } catch (Exception ex) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 'Bulk Upload', BulkUploadRequestProcessorBatchable.class.getName(), 'finish', null, LoggingLevel.ERROR);
        }
    }
}