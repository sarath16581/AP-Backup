/**
 * @description Service class or utility functions and server communication
 * @author Ranjeewa Silva
 * @date 2021-01-22
 * @changelog
 * 2021-01-22 - Ranjeewa Silva - Created
 */

//Server calls
import createRequest from '@salesforce/apex/BulkUploadController.createRequest';
import finaliseRequest from '@salesforce/apex/BulkUploadController.finaliseRequest';
import getLineItems from '@salesforce/apex/BulkUploadController.getLineItems';
import loadConfig from '@salesforce/apex/BulkUploadController.loadConfig';
import uploadLineItems from '@salesforce/apex/BulkUploadController.uploadLineItems';

// Object API names
import BULKLOADREQUEST_OBJECT from '@salesforce/schema/BulkLoadRequest__c';
import BULKLOADREQUESTLINEITEM_OBJECT from '@salesforce/schema/BulkLoadRequestLineItem__c';

// Bulk Load Request field mappings
import FIELD_FILENAME from '@salesforce/schema/BulkLoadRequest__c.FileName__c';
import FIELD_PROCESSEDTIMESTAMP from '@salesforce/schema/BulkLoadRequest__c.ProcessedTimestamp__c'
import FIELD_REQUEST_ID from '@salesforce/schema/BulkLoadRequest__c.Id';
import FIELD_STATUS from '@salesforce/schema/BulkLoadRequest__c.Status__c';
import FIELD_TOTALFAILED from '@salesforce/schema/BulkLoadRequest__c.TotalFailed__c';
import FIELD_TOTALLINEITEMS from '@salesforce/schema/BulkLoadRequest__c.TotalLineItems__c';
import FIELD_TOTALSUCCESSFUL from '@salesforce/schema/BulkLoadRequest__c.TotalSuccessful__c';
import FIELD_UPLOADTIMESTAMP from '@salesforce/schema/BulkLoadRequest__c.UploadTimestamp__c'

// Line item field mappings
import FIELD_ERRORMESSAGE from '@salesforce/schema/BulkLoadRequestLineItem__c.ErrorMessage__c'
import FIELD_LINEITEM_ID from '@salesforce/schema/BulkLoadRequestLineItem__c.Id';
import FIELD_LINE_NUMBER from '@salesforce/schema/BulkLoadRequestLineItem__c.LineNumber__c';
import FIELD_LINEITEM_PAYLOAD from '@salesforce/schema/BulkLoadRequestLineItem__c.LineItemPayload__c'

let _config;

export const CONSTANTS = {
    DEFAULT_FILE_CHUNK_SIZE: 2 * 1024 * 1024, // Default chunk size of 2 MBs
    DEFAULT_ROWS_FOR_PREVIEW: 10,
    DEFAULT_UPLOAD_HISTORY_DATE_RANGE: 90,
    DEFAULT_HEADER_ICON_NAME: 'standard:entity',


    BULKLOADREQUEST_OBJECT : BULKLOADREQUEST_OBJECT.objectApiName,
    BULKLOADREQUESTLINEITEM_OBJECT : BULKLOADREQUESTLINEITEM_OBJECT.objectApiName,

    BULKLOADREQUEST_FIELDS : {
        FIELD_REQUEST_ID: FIELD_REQUEST_ID.fieldApiName,
        FIELD_FILENAME: FIELD_FILENAME.fieldApiName,
        FIELD_TOTALLINEITEMS: FIELD_TOTALLINEITEMS.fieldApiName,
        FIELD_STATUS: FIELD_STATUS.fieldApiName,
        FIELD_TOTALSUCCESSFUL: FIELD_TOTALSUCCESSFUL.fieldApiName,
        FIELD_TOTALFAILED: FIELD_TOTALFAILED.fieldApiName,
        FIELD_UPLOADTIMESTAMP: FIELD_UPLOADTIMESTAMP.fieldApiName,
        FIELD_PROCESSEDTIMESTAMP: FIELD_PROCESSEDTIMESTAMP.fieldApiName
    },

    REQUESTLINEITEM_FIELDS : {
            FIELD_LINEITEM_ID: FIELD_LINEITEM_ID.fieldApiName,
            FIELD_LINE_NUMBER: FIELD_LINE_NUMBER.fieldApiName,
            FIELD_LINEITEM_PAYLOAD: FIELD_LINEITEM_PAYLOAD.fieldApiName,
            FIELD_ERRORMESSAGE: FIELD_ERRORMESSAGE.fieldApiName
    }
}

/**
 * Retrieve configuration
 */
export const getConfig = async (type) => {
	if(!_config) {
		_config = await loadConfig({
		    uploadType: type
        });
		return Promise.resolve(_config);
	} else {
		return Promise.resolve(_config);
	}
}

/**
 * Create new Bulk Load Request
 */
export const createBulkUploadRequest = async (request, duplicateFileCheck) => {

    let result = await createRequest({
		request: request,
		duplicateFileCheck: duplicateFileCheck
	});

	console.log('createRequest', result);
	return result;
}

/**
 * Upload line items for the bulk load request.
 */
export const uploadBulkUploadLineItems = async (request, lineItems) => {

    let result = await uploadLineItems({
		request: request,
		lineItems: lineItems
	});

	console.log('uploadLineItems', result);
	return result;
}

/**
 * Finalise newly created bulk load request. All line items on the request must be inserted before calling this
 * method.
 */
export const finaliseBulkUploadRequest = async (request, allLineItemsValid) => {

    let result = await finaliseRequest({
		request: request,
		allLineItemsValid: allLineItemsValid
	});

	console.log('finaliseRequest', result);
	return result;
}

/**
 * Retrieve bulk load request line items.
 */
export const getBulkUploadRequestLineItems = async (bulkLoadRequestId) => {

    let result = await getLineItems({
		bulkLoadRequestId: bulkLoadRequestId
	});

	console.log('getLineItems', result);
	return result;
}

/**
 * Sort the dataset passed in based on the sort direction.
 */
export const sortData = async (sortedBy, sortDirection, columnDefinitions, dataSet) => {
    const cloneData = [...dataSet];

    // grab the definition of the sort column
    const fieldType = columnDefinitions.filter((field) => field.fieldName === sortedBy);
    const fieldSort = columnDefinitions.filter((field) => field.sortedColumn === true);

    // sort the data factoring in if it's a date field then we reference the timestamp instead of the actual date
    const primer = (val, row) => {
        if(!fieldType || fieldType.length === 0) {
            return val;
        } else {
            if(fieldType[0].type === 'date' && !isNaN((new Date(val)).getTime())) {
                return (new Date(val)).getTime()
            } else {
                return val;
            }
        }
    };

    //Set sorted column
    if(fieldType[0] !== undefined && !fieldType[0].sortedColumn){
        fieldType[0].sortedColumn = true;
    }
    if(fieldSort[0] !== undefined && fieldType[0].fieldName !== fieldSort[0].fieldName){
        fieldSort[0].sortedColumn = false;
    }

    // sort data set
    await cloneData.sort(sortBy(sortedBy, (sortDirection === 'asc' ? 1 : -1), primer));
    return cloneData;
}

// Sort the data columns
export const sortBy = (field, reverse, primer) => {
    const key = primer
        ? function(x) {
            return primer(x[field], x);
        }
        : function(x) {
            return x[field];
        };

    return function(a, b) {
        a = key(a);
        b = key(b);

        if(a === undefined) {
            // accounts for empty values to make sure they are all grouped together either at the top or at the bottom
            return reverse * 1;
        } else if(b === undefined) {
            // accounts for empty values to make sure they are all grouped together either at the top or at the bottom
            return reverse * -1;
        } else {
            return reverse * ((a > b) - (b > a));
        }
    };
}