/**
 * @description Bulk Upload Request history
 * @author Ranjeewa Silva
 * @date 2021-01-22
 * @group Core
 * @changelog
 * 2021-01-22 - Ranjeewa Silva - Created.
 */
import { LightningElement, track, wire, api } from 'lwc';
import LOCALE from '@salesforce/i18n/locale';
import { refreshApex } from '@salesforce/apex';
import { debounce, get } from 'c/utils';
import { CONSTANTS, sortData } from 'c/bulkUploadService';
import getBulkLoadRequestsByTypeAndCreatedDate from '@salesforce/apex/BulkUploadController.getBulkLoadRequestsByTypeAndCreatedDate';

export default class BulkUploadRequests extends LightningElement {

    // number of days from current date to determine the starting date for displaying upload history.
    // passed in by parent.
    @api uploadHistoryDateRange;

    // upload type supported by this instance
    @api type;

    // upload history table column definitions.
    uploadHistoryTableColumns;

    // upload history data received via wire adapter. No filetring/sorting is applied on this data set.
    bulkUploadRequestList;

    // filtered data set after applying filters.
    filteredBulkUploadRequestList;

    // search term entered by user for filtering the dataset.
    searchString;

    // Default sort column
    sortedBy = CONSTANTS.BULKLOADREQUEST_FIELDS.FIELD_UPLOADTIMESTAMP;
    // Default sort direction
    sortDirection = 'desc';

    // Bulk load request Id selected for viewing it's line items.
    showLineItemsRequestId;

    // if set to true, indicates the dataset is currently being filtered.
    filteringDataset = false;
    // if set to true, indicates the dataset is currently being sorted.
    sortingDataset = false;
    // if set to true, indicates the dataset is currently being loaded.
    loadingDataset = true;

    // search handler
    debounceSearchHandler = debounce(this.filterBulkLoadRequests, 200);

    connectedCallback() {
        const columnOutput = [];
        columnOutput.push({label: 'File Name', fieldName: CONSTANTS.BULKLOADREQUEST_FIELDS.FIELD_FILENAME, fixedWidth: false, sortedColumn: false, fieldType: 'STRING', cssClass : 'slds-th__action slds-text-link_reset maxWidth'});
        columnOutput.push({label: 'Total Line Items', fieldName: CONSTANTS.BULKLOADREQUEST_FIELDS.FIELD_TOTALLINEITEMS, fixedWidth: false, sortedColumn: false, fieldType: 'INTEGER', cssClass : 'slds-th__action slds-text-link_reset maxWidth'});
        columnOutput.push({label: 'Status', fieldName: CONSTANTS.BULKLOADREQUEST_FIELDS.FIELD_STATUS, fixedWidth: false, sortedColumn: false, fieldType: 'STRING', cssClass : 'slds-th__action slds-text-link_reset maxWidth'});
        columnOutput.push({label: '# Successful', fieldName: CONSTANTS.BULKLOADREQUEST_FIELDS.FIELD_TOTALSUCCESSFUL, fixedWidth: false, sortedColumn: false, fieldType: 'INTEGER', cssClass : 'slds-th__action slds-text-link_reset maxWidth'});
        columnOutput.push({label: '# Failures', fieldName: CONSTANTS.BULKLOADREQUEST_FIELDS.FIELD_TOTALFAILED, fixedWidth: false, sortedColumn: false, fieldType: 'INTEGER', cssClass : 'slds-th__action slds-text-link_reset maxWidth'});
        columnOutput.push({label: 'Uploaded Date', fieldName: CONSTANTS.BULKLOADREQUEST_FIELDS.FIELD_UPLOADTIMESTAMP, fixedWidth: false, sortedColumn: false, fieldType: 'DATETIME', cssClass : 'slds-th__action slds-text-link_reset maxWidth'});
        columnOutput.push({label: 'Processed Date', fieldName: CONSTANTS.BULKLOADREQUEST_FIELDS.FIELD_PROCESSEDTIMESTAMP, fixedWidth: false, sortedColumn: false, fieldType: 'DATETIME', cssClass : 'slds-th__action slds-text-link_reset maxWidth'});
        columnOutput.push({label: 'Uploaded By', fieldName: 'Owner.Name', fixedWidth: false, sortedColumn: false, fieldType: 'STRING', cssClass : 'slds-th__action slds-text-link_reset maxWidth'});
        this.uploadHistoryTableColumns = columnOutput;
    }

    // results returned by wire service. Required for refreshing the results via Apex.
    wiredBulkUploadRequestList;
    @wire(getBulkLoadRequestsByTypeAndCreatedDate, { numberOfDays: '$uploadHistoryDateRange', uploadType: '$type' })
    wiredGetBulkLoadRequests(value) {
        this.wiredBulkUploadRequestList = value;
        const { data, error} = value;
        if (data) {
            this.bulkUploadRequestList = data;
            // filter the data set (if search term is populated)
            this.debounceSearchHandler();
            this.loadingDataset = false;
        }
    }

    /**
     * Build and return the bulk load request history to display.
     */
    get computedBulkUploadRequestList() {

        if (!this.filteredBulkUploadRequestList || !this.uploadHistoryTableColumns) {
            return [];
        }

        const computedDataset = this.filteredBulkUploadRequestList.map(item => {
            const columns = [...this.uploadHistoryTableColumns].map(column => {
                const col = {
                    ...column,
                    fieldValue: get(item, column.fieldName, null),
                    key: item['Id'] + column.fieldName
                };
                col['fieldNameIs_' + column.fieldName] = true;
                return col;
            });

            const isLineItemsVisible = (this.showLineItemsRequestId === item.Id);
            const isVisible = (this.showLineItemsRequestId ? this.showLineItemsRequestId === item.Id : true);
            return {
                ...item,
                hasFailedLineItems: (item.TotalFailed__c > 0),
                isVisible: isVisible,
                showLineItems: isLineItemsVisible,
                _columns: columns
            };
        });
        return computedDataset;
    }

    get isAsc() {
        return (this.sortDirection === 'asc');
    }

    get isLoading() {
        return (this.filteringDataset || this.sortingDataset || this.loadingDataset);
    }

    get hasBulkUploadRequests() {
        return this.filteredBulkUploadRequestList && this.filteredBulkUploadRequestList.length > 0;
    }

    /**
     * Show line items for a Bulk Load Request in history table.
     */
    handleShowLineItemsPanel(event) {
        const target = event.currentTarget;
        // set the request id currently expanded to show line items.
        this.showLineItemsRequestId = target.dataset.id;
    }

    /**
     * Close line items panel.
     */
    handleCloseLineItemsPanel(event) {
        const requestId = event.detail;
        if (this.showLineItemsRequestId === requestId) {
            this.showLineItemsRequestId = null;
        }
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

        sortData(this.sortedBy, this.sortDirection, this.uploadHistoryTableColumns, this.filteredBulkUploadRequestList).then((result) => {
            this.filteredBulkUploadRequestList = result;
            this.sortingDataset = false;
        });
    }

    /**
     * Filter the bulk load requests returned by wire service based on the search term.
     */
    filterBulkLoadRequests() {
        this.filteringDataset = true;

        if (this.searchString) {
            // we have a search term. filter records based on the search term.
            const escapedSearchString = this.searchString.replace(/[.*+\-?^${}()|[\]\\]/g, '\\$&');
            const pattern = '\\b' + escapedSearchString;
            const cachedRegEx = new RegExp(pattern, 'i');
            if(escapedSearchString) {
                this.filteredBulkUploadRequestList = this.bulkUploadRequestList.filter(item => {
                    let value = item.FileName__c + '|' + item.Status__c;
                    if (item.UploadTimestamp__c) {
                        const uploadTimeStampStr = new Intl.DateTimeFormat(LOCALE, {year:"numeric", month:"2-digit", day:"2-digit", hour:"2-digit",minute:"2-digit"}).format(new Date(item.UploadTimestamp__c));
                        value += ('|' + uploadTimeStampStr);
                    }
                    if (item.ProcessedTimestamp__c) {
                        const processedTimeStampStr = new Intl.DateTimeFormat(LOCALE, {year:"numeric", month:"2-digit", day:"2-digit", hour:"2-digit",minute:"2-digit"}).format(new Date(item.ProcessedTimestamp__c));
                        value += ('|' + processedTimeStampStr);
                    }
                    if (item.Owner && item.Owner.Name) {
                        const ownerName = item.Owner.Name;
                        value += ('|' + ownerName);
                    }
                    return cachedRegEx.test(value);
                });
            } else {
                this.filteredBulkUploadRequestList = [...this.bulkUploadRequestList];
            }
        } else {
            this.filteredBulkUploadRequestList = [...this.bulkUploadRequestList];
        }

        //apply sorting
        if (this.sortedBy && this.sortDirection) {
            this.sortingDataset = true;

            sortData(this.sortedBy, this.sortDirection, this.uploadHistoryTableColumns, this.filteredBulkUploadRequestList).then((result) => {
                this.filteredBulkUploadRequestList = result;
                this.sortingDataset = false;
            });
        }
        this.filteringDataset = false;
    }

    /**
     * Called by parent to refresh the history view. For example, when a new bulk upload is performed the
     * history is refreshed to include the newly uploaded request.
     */
    @api refreshView() {
        //refreshApex(this.wiredBulkUploadRequestList);
        this.reloadData();

        // poll every 20 seconds for another 4 minutes.
        this.poll(this.reloadData, 20000, 240000);
    }

    reloadData = () => {
         refreshApex(this.wiredBulkUploadRequestList);
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    // Polling function that excutes the function passed into it after every interval until a timeout it reached
    // the first execution of the polled function is done after an initial delay of the interval
    // the function the executes will not return a value.
    // By default we call the function passed into the poll function every 20 seconds for an hour
    async poll(fn, interval = 20000, timeout = 3600000) {
        let timer
        const endTime = Number(new Date()) + timeout;
        const polledFunction = (resolve, reject) => {
            if (timer) {
                clearTimeout(timer);
            }
            if (Number(new Date()) < endTime) {
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(polledFunction, interval, resolve, reject);
            }
            fn();
        }
        await this.delay(interval)
        return new Promise(polledFunction)
    }
}