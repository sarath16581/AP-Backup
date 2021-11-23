/**
 * @description Wraps all capability exposed in Bulk Upload feature. Bulk Upload supports uploading CSV data
 *              in to Salesforce and processing each line item asynchronously. Core components are
 *              independent of specific CSV file formats and the processing logic allowing them to be re-used.
 * @author Ranjeewa Silva
 * @date 2021-01-22
 * @group Core
 * @changelog
 * 2021-01-22 - Ranjeewa Silva - Created.
 */
import { LightningElement, api } from 'lwc';
import { CONSTANTS } from 'c/bulkUploadService';

export default class BulkUpload extends LightningElement {

    // title set by parent. use to provide context of this bulk upload.
    @api title;

    // header icon to use. set by parent.
    @api iconName;

    // upload type supported by this instance
    @api type;
    // uploaded file is read in chunks to ensure Salesforce governor limits are not breached.
    // this determines the size of a chunk in bytes.
    @api chunkSize;
    // number of rows displayed as file preview. if not set by the parent, a default value of 10 rows will be used.
    @api previewRows;
    // number of days from current date to determine the starting date for displaying upload history.
    // if not set by the parent, a default value of 90 days will be used.
    @api uploadHistoryDateRange;
    // check for duplicate requests based on file name.
    @api duplicateCheck;

    connectedCallback() {

        // initialise any properties not set by parent to their default values.
        if (!this.chunkSize) {
            this.chunkSize = CONSTANTS.DEFAULT_FILE_CHUNK_SIZE;
        }
        if (!this.previewRows) {
            this.previewRows = CONSTANTS.DEFAULT_ROWS_FOR_PREVIEW;
        }
        if (!this.uploadHistoryDateRange) {
            this.uploadHistoryDateRange = CONSTANTS.DEFAULT_UPLOAD_HISTORY_DATE_RANGE;
        }
        if (!this.iconName) {
            this.iconName = CONSTANTS.DEFAULT_HEADER_ICON_NAME;
        }
    }

    /**
     * Handles the upload complete event - fired when a new file upload is completed successfully.
     */
    handleUploadComplete(event) {
        this.template.querySelector('c-bulk-upload-requests').refreshView();
    }
}