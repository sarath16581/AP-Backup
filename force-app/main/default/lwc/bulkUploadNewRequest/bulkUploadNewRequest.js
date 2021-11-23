/**
 * @description Create new bulk upload request and upload the contents of the selected CSV file as line items.
 * @author Ranjeewa Silva
 * @date 2021-01-22
 * @group Core
 * @changelog
 * 2021-01-22 - Ranjeewa Silva - Created.
 */

import { LightningElement, api, track } from 'lwc';
import { get } from 'c/utils';
import BulkUploadBase from "c/bulkUploadBase";
import { CONSTANTS, getConfig, createBulkUploadRequest, uploadBulkUploadLineItems, finaliseBulkUploadRequest } from 'c/bulkUploadService';

export default class BulkUploadNewRequest extends BulkUploadBase {

    // title set by parent.
    @api title;
    // upload type. this determines the format of the csv file and processing logic to use.
    @api type;
    // maximum data(in bytes) to read from CSV file in one chunk. Set by parent to match the upload type.
    @api chunkSize;
    // number of rows to show in file preview.
    @api previewRows;
    // check for duplicate requests based on file name.
    @api duplicateCheck;

    // field mapping definitions. used to validate the csv file (not individual line items) to ensure all mandatory
    // fields are present in the input file.
    _fieldMappingDefinitions;

    // file selected for upload.
    selectedFile = null;

    // line items in the current file that failed validation checks.
    invalidLineItems = [];

    // if set to true, displays the screen to review current file upload (includes file preview and mapping information).
    reviewInputFile;

    // indicates if current file is successfully uploaded and available to be processed asynchronously.
    isUploadSuccessful;

    // status of the current upload.
    uploadStatusMessage;

    // if set to true, displays line items that failed validations.
    showValidationErrors = false;

    // indicates the current upload is in progress.
    uploadingFile = false;

    connectedCallback() {

        this.loadScripts();

        getConfig(this.type).then(result => {
            this._fieldMappingDefinitions = get(result, 'fieldMapping', {});
        });
    }

    handleUploadFile(event) {
        this.selectedFile = event.target.files[0];
        const inputCmp = this.template.querySelector(".file-input");

        const fileType =  this.getFileType(this.selectedFile);

        // check file type explicitly. Setting lightning-input's 'accept' attribute does not prevent drag and drop of other
        // non csv files.
        if (fileType === 'csv') {
            this.reviewInputFile = true;
            this.uploadStatusMessage = null;
            this.invalidLineItems = [];
            this.showValidationErrors = false;
            inputCmp.setCustomValidity("");
        } else {
            inputCmp.setCustomValidity('File type [' + fileType + '] not supported.');
        }
        inputCmp.reportValidity();
    }

    /**
     * Show individual line items that failed validation checks with the error details.
     */
    handleShowValidationErrors(event) {
        this.showValidationErrors = true;
    }

    /**
     * Close validation errors panel.
     */
    handleHideValidationErrors(event) {
        this.showValidationErrors = false;
    }

    handleCancelUpload() {
        this.reviewInputFile = false;
    }

    /**
     * Current file upload details have been reviewed by the user and confirmed.
     * Upload is performed in three steps.
     * 1. Create the Bulk Load Request (BulkLoadRequest__c) record. The status is set to 'New' at this stage as line items
     *    are not yet inserted.
     * 2. Read the file in chunks and insert line items for each chunk. Line items are validated before inserting them and
     *    upload statistics are gathered across multiple chunks. Note that chunk size is controlled by the parent component.
     * 3. When all line items have been inserted, finalise the upload.
     *      - If no validation errors, set the status of parent Bulk Load Request to 'Pending' allowing it to be processed
     *      - If validation errors are encountered, abort the current upload and delete the parent Bulk Load Request. Show
     *        validation errors to user.
     */
    handleConfirmUpload() {
        this.reviewInputFile = false;
        this.uploadingFile = true;

        const bulkUploadRequest = {
            Id: null,
            FileName__c : this.selectedFile.name,
            Type__c: this.type,
            sobjectType: CONSTANTS.BULKLOADREQUEST_OBJECT
        };

        //Gather upload statistics
        const uploadStatistics = {
            totalLineItems: 0,
            successCount: 0,
            errorCount: 0,
            lineItemErrors: []
        };

        const chunkUploadResultPromises = [];

        // Insert the parent Bulk Load Request first
        createBulkUploadRequest(bulkUploadRequest, this.duplicateCheck)
            .then(result => {

                if (!result.requestId) {
                    // parent request has failed to insert (e.g. failed duplicate check) - display the error message received in results.
                    this.uploadStatusMessage = result.errorMessage;
                    this.isUploadSuccessful = false;
                    this.uploadingFile = false;
                } else {
                    // request is created successfully.
                    bulkUploadRequest.Id = result.requestId;

                    // now read and parse the csv file contents in chunks using Papaparse (https://www.papaparse.com/). If selected
                    // file is smaller than the chunk size, the whole file is read and uploaded in one chunk.
                    // 'chunk' callback receives the data read by Papaparse for each chunk. 'complete' callback function is
                    // called by Papaparse when it has read the file in chunks.
                    let chunkStart = 0;
                    Papa.parse(this.selectedFile, {
                        chunk: function(results, parser) {
                            // Papaparse has read and parsed a chunk from the file. If the file is smaller than the configured
                            // chunk size whole file is read in one chunk.
                            const lineItems = results.data.map((item, index) => {
                                return {
                                    BulkLoadRequest__c: bulkUploadRequest.Id,
                                    LineItemPayload__c: JSON.stringify(item),
                                    LineNumber__c: chunkStart + index + 1, // Papaparse currently does not pass the line number. Set the line number based on the index of the array of data passed in.
                                    sobjectType: CONSTANTS.BULKLOADREQUESTLINEITEM_OBJECT
                                }
                            });

                            // update the start index of the next chunk. used for deriving the line number.
                            chunkStart += results.data.length;

                            uploadStatistics.totalLineItems = uploadStatistics.totalLineItems + lineItems.length;

                            // upload line items for current chunk. keep a reference to the Promise returned so that
                            // we can check if it has been resolved at the end when all the chunks have been read ( see 'complete' below).
                            let uploadResultPromise = uploadBulkUploadLineItems(bulkUploadRequest, lineItems);
                            uploadResultPromise
                                .then(result => {
                                    uploadStatistics.successCount = uploadStatistics.successCount + result.successCount;
                                    uploadStatistics.errorCount = uploadStatistics.errorCount + result.errorCount;
                                    if (result.errorCount && result.errorCount > 0) {
                                        uploadStatistics.lineItemErrors.push(...result.invalidLineItems);
                                        console.log(uploadStatistics);
                                    }
                                })
                                .catch(error => {
                                    console.log('Error uploading line items : ', JSON.stringify(error));
                                    uploadStatistics.errorCount += lineItems.length;
                                });
                            chunkUploadResultPromises.push(uploadResultPromise);
                        },
                        complete: (results) => {

                            // all the chunks have been read and parsed by Papaparse. however it is possible that some of the chunks are
                            // still being uploaded.

                            let allLineItemsValid = false;
                            let isException = false;

                            // wait until all chunks are uploaded - use the collection of Promises collected when line items are uploaded
                            // for this purpose.
                            // once all chunks are uploaded, finalise the bulk load request.
                            Promise.all(chunkUploadResultPromises)
                                .then(() => {
                                    allLineItemsValid = (uploadStatistics.errorCount > 0 ? false: true);
                                    bulkUploadRequest.TotalLineItems__c = uploadStatistics.totalLineItems;
                                    bulkUploadRequest.TotalSuccessful__c = uploadStatistics.successCount;
                                    bulkUploadRequest.TotalFailed__c = uploadStatistics.errorCount;
                                    if (!allLineItemsValid) {
                                        this.uploadStatusMessage = 'Selected file - ' + this.selectedFile.name + ' has failed validation checks. '+ uploadStatistics.errorCount + ' out of ' + uploadStatistics.totalLineItems +' line items failed validation.';
                                        this.isUploadSuccessful = false;
                                        this.invalidLineItems = uploadStatistics.lineItemErrors;
                                    }
                                    this.finaliseUpload(bulkUploadRequest, allLineItemsValid);
                                })
                                .catch(error => {
                                    this.uploadStatusMessage = 'Unexpected server error - ' + (error.body ? error.body.message : '') + '. Please try again.';
                                    this.isUploadSuccessful = false;
                                    isException = true;
                                    this.finaliseUpload(bulkUploadRequest, false);
                                });
                        },
                        header: true,
                        chunkSize: this.chunkSize
                    });
                }
            })
            .catch(error => {
                this.uploadStatusMessage = 'Unexpected server error - ' + (error.body ? error.body.message : '') + '. Please try again.';
                this.isUploadSuccessful = false;
                this.uploadingFile = false;
            });
    }

    get bulkUploadRequest() {
        const bulkRequest = {
            FileName__c : this.fileName
        };
        return bulkRequest;
    }

    get fileName() {
        if (this.selectedFile) {
            return this.selectedFile.name;
        }
        return '';
    }

    get hasErrors() {
        return (this.uploadStatusMessage && !this.isUploadSuccessful);
    }

    get hasLineItemErrorDetails() {
        return this.hasErrors && this.invalidLineItems && this.invalidLineItems.length > 0;
    }

    get hasMessages() {
        return (!!this.uploadStatusMessage);
    }

    get isLoading() {
        return (!this.hasExternalLibrariesLoaded || this.uploadingFile);
    }

    finaliseUpload(bulkUploadRequest, allLineItemsValid) {
        // all the chunks have been read and uploaded.
        // finalise the Bulk Load Request, indicating all line items have been uploaded, so that the server
        // can start processing line items asynchronously.
        finaliseBulkUploadRequest(bulkUploadRequest, allLineItemsValid)
            .then(() => {
                if (allLineItemsValid) {
                    this.uploadStatusMessage = 'File - ' + this.selectedFile.name + ' uploaded successfully.';
                    this.isUploadSuccessful = true;

                    // reset the message after 3 seconds.
                    setTimeout(() => {
                        this.uploadStatusMessage = null;
                    }, 3000);
                    this.dispatchEvent(new CustomEvent('complete'));
                }
                this.uploadingFile = false;
            }).catch(error => {
                if (allLineItemsValid) {
                   this.uploadStatusMessage = 'Unexpected server error - ' + (error.body ? error.body.message : '') + '. Please try again.';
                }
                this.uploadingFile = false;
            });
    }

    getFileType(file) {
        if (!file) {
            return '';
        }

        // cannot rely on File.type as it may be platform dependent.
        // for the purpose of initial validation check use file name extension - if user attempts to upload a non csv file
        // the parser will catch the error.

        if (file.name) {
            const fileNameParts = file.name.split('.');
            if (fileNameParts.length > 1) {
                return fileNameParts.pop();
            }
        }
        return (file.type ? file.type : '');
    }
}