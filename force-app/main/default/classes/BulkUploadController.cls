/**
 * @author Ranjeewa Silva
 * @date 2020-01-22
 * @group Core
 * @tag BulkUpload
 * @description Controller for bulk uploading csv data into Salesforce and processing line items asynchronously. Invokes
 *              BulkUploadService to service requests.
 * @changelog
 * 2020-01-22 - Ranjeewa Silva - Created
 */

public with sharing class BulkUploadController {

    /**
     * Returns the bulk upload configuration specific to the upload type.
     *
     * @param uploadType type of the upload (e.g. DISPUTED_CREDIT_CLAIMS)
     * @return configuration specific to the upload type.
     */
    @AuraEnabled (Cacheable = true)
    public static Map<String, Object> loadConfig(String uploadType) {
        try {
            BulkUploadService.UploadType upType = BulkUploadService.UPLOAD_TYPES.get(uploadType);
            return new Map<String, Object>{
                    'fieldMapping' => BulkUploadService.getInstance().getFieldMapping(upType)
            };
        } catch (Exception ex) {
            AuraHandledException auraEx = new AuraHandledException(ex.getMessage());
            auraEx.initCause(ex);
            throw auraEx;
        }
    }

    /**
     * Creates a new Bulk upload request (BulkLoadRequest__c). This is the first step in bulk upload and the bulk upload
     * request record created here will become the parent for line items included in bulk upload.
     *
     * @param request instance of BulkLoadRequest__c to be inserted
     * @param duplicateFileCheck if true check for duplicate requests by file name.
     * @return Bulk upload save results
     */
    @AuraEnabled
    public static BulkUploadService.BulkUploadRequestSaveResult createRequest(BulkLoadRequest__c request, Boolean duplicateFileCheck) {
        try {
            return BulkUploadService.getInstance().createRequest(request,duplicateFileCheck);
        } catch (Exception ex) {
            AuraHandledException auraEx = new AuraHandledException(ex.getMessage());
            auraEx.initCause(ex);
            throw auraEx;
        }
    }

    /**
     * Upload a batch of line items for a Bulk Load Request previously created. This method can be called repeatedly to
     * insert multiple batches of line items.
     *
     * @param request parent bulk load request the line items belong to
     * @param lineItems batch of line items to be inserted
     *
     * @return Line Items save results.
     */
    @AuraEnabled
    public static BulkUploadService.LineItemsSaveResult uploadLineItems(BulkLoadRequest__c request, List<BulkLoadRequestLineItem__c> lineItems) {
        try {
            return BulkUploadService.getInstance().createLineItems(request.Id, lineItems);
        } catch (Exception ex) {
            AuraHandledException auraEx = new AuraHandledException(ex.getMessage());
            auraEx.initCause(ex);
            throw auraEx;
        }
    }

    /**
     * Finalise the Bulk Load Request. This method must be called when all line items in this Bulk Load Request has
     * been uploaded.
     *
     * Finalising the request closes the bulk load request and no new line items can be added after finalising the request.
     *
     * @param request the bulk load request to finalise.
     * @param allLineItemsValid indicates if all line items for this request has been uploaded successfully.
     *
     */
    @AuraEnabled
    public static void finaliseRequest(BulkLoadRequest__c request, Boolean allLineItemsValid) {
        try {
            BulkUploadService.getInstance().finaliseUploading(request, allLineItemsValid);
        } catch (Exception ex) {
            AuraHandledException auraEx = new AuraHandledException(ex.getMessage());
            auraEx.initCause(ex);
            throw auraEx;
        }
    }

    /**
     * Retrieves all historical Bulk Load Requests uploaded in the last 'numberOdDays' (e.g. last 60 days).
     *
     * @param numberOfDays date filter applied
     * @param uploadType only return requests for this upload type.
     *
     * @return list of bulk upload requests
     */
    @AuraEnabled(Cacheable=true)
    public static List<BulkLoadRequest__c> getBulkLoadRequestsByTypeAndCreatedDate(Integer numberOfDays, String uploadType) {
        try {
            return BulkLoadRequestSelector.newInstance().selectByTypeAndUploadDate(numberOfDays, new Set<String>{uploadType}, new Set<Object>{BulkLoadRequestSelector.Options.WITH_OWNER}).values();
        } catch (Exception ex) {
            AuraHandledException auraEx = new AuraHandledException(ex.getMessage());
            auraEx.initCause(ex);
            throw auraEx;
        }
    }

    /**
     * Return line items for the bulk load request
     * @param bulkLoadRequestId Id of the parent bulk load request
     *
     * @return list of line items
     */
    @AuraEnabled(Cacheable=true)
    public static List<BulkLoadRequestLineItem__c> getLineItems(Id bulkLoadRequestId) {
        try {
            return BulkLoadRequestLineItemsSelector.newInstance().selectByBulkLoadRequestAndStatus(bulkLoadRequestId, new Set<String>{BulkUploadService.LINEITEM_STATUS_ERROR}).values();
        } catch (Exception ex) {
            AuraHandledException auraEx = new AuraHandledException(ex.getMessage());
            auraEx.initCause(ex);
            throw auraEx;
        }
    }
}