/**
 * @description Display line items of a bulk load request. Currently only line items that failed, either due to validation errors
 *              or unexpected processing errors, are displayed.
 *              Line items that fail due to validation errors are not persisted and passed into this component by
 *              the parent component (see lineItems attribute). If this is not passed in, this component attempts to
 *              retrieve the failed line items on the 'bulkUploadRequest' passed in by parent. For example, to display
 *              processing errors the parent component simply pass in the bulkLoadRequest.
 *
 * @author Ranjeewa Silva
 * @date 2021-01-22
 * @group Core
 * @changelog
 * 2021-01-22 - Ranjeewa Silva - Created.
 */

import { LightningElement, api } from 'lwc';
import { debounce } from 'c/utils';
import { CONSTANTS, sortData, getBulkUploadRequestLineItems } from 'c/bulkUploadService';
import BulkUploadBase from "c/bulkUploadBase";

export default class BulkUploadRequestLineItems extends BulkUploadBase {

    // bulk upload request instance passed in by the parent component. line items displayed by this component belongs to
    // this bulk upload.
    @api bulkUploadRequest;

    // variant that control the appearance of the card. supports "base" (takes full width) and "nested" (takes 90% of the available width).
    @api variant;

    // component title set by thew parent component.
    @api title;

    // line items retrieved from server for the bulk upload request. this contains all line items before applying filtering
    _lineItems;

    // search text to filter the line items
    searchString;

    // list of line items after filtering based on the search text
    filteredLineItems = [];

    // field to sort the line items table
    sortedBy = CONSTANTS.REQUESTLINEITEM_FIELDS.FIELD_LINE_NUMBER;

    // sort direction - could either be 'asc' or 'desc'
    sortDirection = 'asc';

    // flag indicating the line items dataset is currently being filtered.
    filteringDataset = false;

    // flag indicating the line items dataset is currently being sorted.
    sortingDataset = false;

    // flag indicating the line items dataset is currently being loaded from server.
    loadingDataset = false;

    // error message displayed to the user
    error;

    // column metadata for line items table
    columnDefinitions = [];

    // search handler
    debounceSearchHandler = debounce(this.filterLineItems, 200);

    connectedCallback() {
        const columnOutput = [];
        columnOutput.push({label: 'Line #', fieldName: CONSTANTS.REQUESTLINEITEM_FIELDS.FIELD_LINE_NUMBER, fixedWidth: false, sortedColumn: false, fieldType: 'INTEGER', cssClass : 'slds-th__action slds-text-link_reset maxWidth'});
        columnOutput.push({label: 'Line Item Payload', fieldName: CONSTANTS.REQUESTLINEITEM_FIELDS.FIELD_LINEITEM_PAYLOAD, fixedWidth: false, sortedColumn: false, fieldType: 'STRING', cssClass : 'slds-th__action slds-text-link_reset maxWidth'});
        columnOutput.push({label: 'Error Message', fieldName: CONSTANTS.REQUESTLINEITEM_FIELDS.FIELD_ERRORMESSAGE, fixedWidth: false, sortedColumn: false, fieldType: 'STRING', cssClass : 'slds-th__action slds-text-link_reset maxWidth'});
        this.columnDefinitions = columnOutput;

        if (!this._lineItems && this.bulkUploadRequest && this.bulkUploadRequest.Id) {
            // Retrieve line items from the bulk load request
            this.loadingDataset = true;

            getBulkUploadRequestLineItems(this.bulkUploadRequest.Id)
                .then((result) => {
                    this._lineItems = result;
                    this.filterLineItems();
                    this.loadingDataset = false;
                })
                .catch((error) => {
                    this.error = (error.body ? error.body.message : '');
                    this.loadingDataset = false;
                });
        }

    }

    // line items for the bulk upload request. This could be passed in by parent when displaying validation errors.
    @api
    get lineItems() { return this._lineItems; }
    set lineItems(value) {
        this._lineItems = value;
        this.filterLineItems();
    }

    get cardTitle() {
        if (this.bulkUploadRequest) {
            return `${this.title} - ${this.bulkUploadRequest.FileName__c}`;
        }
        return this.title;
    }

    /**
     * Build and return the line item data to display.
     */
    get computedLineItems() {

        if (!this.filteredLineItems || !this.columnDefinitions) {
            return [];
        }

        const lineItemsToDisplay = this.filteredLineItems.map(item => {

            const columns = [...this.columnDefinitions].map(column => {
                return {
                    ...column,
                    fieldValue: item[column.fieldName],
                    key: (item[CONSTANTS.REQUESTLINEITEM_FIELDS.FIELD_LINEITEM_ID] ? item[CONSTANTS.REQUESTLINEITEM_FIELDS.FIELD_LINEITEM_ID] : item[CONSTANTS.REQUESTLINEITEM_FIELDS.FIELD_LINE_NUMBER]) + column.fieldName
                };
            });

            return {
                ...item,
                key: (item[CONSTANTS.REQUESTLINEITEM_FIELDS.FIELD_LINEITEM_ID] ? item[CONSTANTS.REQUESTLINEITEM_FIELDS.FIELD_LINEITEM_ID] : item[CONSTANTS.REQUESTLINEITEM_FIELDS.FIELD_LINE_NUMBER]),
                _columns: columns
            };
        });

        return lineItemsToDisplay;
    }

    /**
     * Filter the line items based on the search term.
     */
    filterLineItems() {
        this.filteringDataset = true;

        if (this.searchString) {
            const escapedSearchString = this.searchString.replace(/[.*+\-?^${}()|[\]\\]/g, '\\$&');
            const pattern = '\\b' + escapedSearchString;
            const cachedRegEx = new RegExp(pattern, 'i');
            if(escapedSearchString) {
                this.filteredLineItems = this._lineItems.filter(item => {
                    return cachedRegEx.test(item.LineNumber__c + '|' + item.LineItemPayload__c + '|' + item.ErrorMessage__c);
                });
            } else {
                this.filteredLineItems = [...this._lineItems];
            }
        } else {
            this.filteredLineItems = [...this._lineItems];
        }
        if (this.sortedBy && this.sortDirection) {
            this.sortingDataset = true;

            sortData(this.sortedBy, this.sortDirection, this.columnDefinitions, this.filteredLineItems).then((result) => {
                this.filteredLineItems = result;
                this.sortingDataset = false;
            });
        }
        this.filteringDataset = false;
    }

    //Send close event to parent with event Id
    closePopup(){
        this.dispatchEvent(new CustomEvent('closepopup', {
           detail: this.bulkUploadRequest.Id
       }));
    }

    handleSearchStringChange(e) {
        this.searchString = e.target.value;
        this.debounceSearchHandler();

        // stop the change event from bubbling up
        //e.stopPropagation();
    }

    handleSort(event) {

        this.sortingDataset = true;

        const target = event.currentTarget
        const id = target.dataset.id

        //Set sort order based on field
        if (this.sortedBy === id) {
            this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortedBy = id;
            this.sortDirection = 'desc';
        }

        sortData(this.sortedBy, this.sortDirection, this.columnDefinitions, this.filteredLineItems).then((result) => {
            this.filteredLineItems = result;
            this.sortingDataset = false;
        });
    }

    handleDownloadLineItems(event) {

        const data = this._lineItems.map((lineItem, index) => {
            let payload = JSON.parse(lineItem.LineItemPayload__c);
            payload['Line Number'] = lineItem.LineNumber__c;
            payload['Error'] = lineItem.ErrorMessage__c;
            return payload;
        });

        // use Papaparse ((https://www.papaparse.com/) to generate the CSV contents.
        let csv = Papa.unparse(data);
        let fileName = (this.cardTitle ? this.cardTitle : this.bulkUploadRequest[CONSTANTS.BULKLOADREQUEST_FIELDS.FIELD_REQUEST_ID]) + '.csv';

        if (navigator && navigator.msSaveBlob) { // IE10+
            return navigator.msSaveBlob(new Blob([csv], { type: '.csv' }), fileName);
        }

        // now download the generated content as a CSV file.
        let downloadElement = document.createElement('a');
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csv);
        downloadElement.target = '_self';
        downloadElement.download = fileName;
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }

    get isAsc() {
        return (this.sortDirection === 'asc');
    }

    get isLoading() {
        return (this.filteringDataset || this.sortingDataset || this.loadingDataset);
    }

    get hasLineItems() {
        return (this.filteredLineItems && this.filteredLineItems.length > 0);
    }
}