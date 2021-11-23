import {LightningElement, track,wire} from 'lwc';
import getFiles from '@salesforce/apex/bspAccountReporting.getFiles';
import DOCUMENT_INTERVAL_FIELD from '@salesforce/schema/ContentVersion.Document_Interval__c';
import getCVReportRecordType from '@salesforce/apex/bspAccountReporting.getCVReportRecordType';
import {getPicklistValues} from 'lightning/uiObjectInfoApi';
import getBillingAccounts from '@salesforce/apex/bspEnquiryUplift.getAllBillingAccountsForReports';

export default class BspAccountReporting extends LightningElement {

    pageSizeFilterOption = '5';                    // default page size
    selectedReportType = 'Report';                 // default report type
    selectedDocumentType = 'DIFOT';                // defaultdocument type
    selectedDocumentInterval = 'All';              // default doc interval
    sortByColumnApiName = 'Document_Date__c';      // default column for sorting
    sortByOrder = 'Desc';                          // default sort order
    selectedBillingAccount = 'all';

    isLoading = true;
    pageNumber = 1;
    isLastPage = false;
    resultsSize = 0
    showPrevButton = false;
    showNextButton = false;
    recordStart = 0;
    recordEnd = 0;
    isShowNoResultsFoundMsg = false;
    isAsc = true;
    isDsc = false;
    isTitleSort = false;
    isDocTypeSort = false;
    isDocDateSort = true;
    isDocIntervalSort = false;
    isDocVersionSort = false;
    isDocModifiedDateSort = false;
    isLinkedEntitySort = false;

    errorMessage;
    selectedFromDate= null;
    selectedToDate= null;
    recordTypeId;
    //errorMsg;
    //wiredData;

    @track searchReultsWrapper;
    @track contentDocIdNLinkedEntityNameMap;

    @track documentIntervalOptions = [
        { label: 'All', value: 'All' }
    ];

    @track pageSizeOptions = [
        { label: '5 Files',  value: '5' },
        { label: '10 Files', value: '10' },
        { label: '15 Files', value: '15' },
        { label: '20 Files', value: '20' },
    ];

    @wire(getBillingAccounts) allBilingAccOptions;

    get billingAccPicklistOptions() {
        return this.allBilingAccOptions.data;    //--[TO DO : Change first option label to 'All billing account reports']
    }
 
    get defaultPageSize() {
        return this.pageSizeFilterOption ? this.pageSizeFilterOption : '';
    }

    /**
     * get recordType
     */
    @wire(getCVReportRecordType) getCVReportRecordTypeWired ({error,data}) {
        if (data)
            this.recordTypeId = data;
    }

    /**
     * Get picklist values
     */
    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: DOCUMENT_INTERVAL_FIELD
    }) wiredPicklistVals({error, data }) {
        if (data)
            this.documentIntervalOptions = this.documentIntervalOptions.concat(data.values);
    }


    /**
     * get recordType Options
     */
    get reportTypeOptions() {
        return [
            {label: 'Report',value: 'Report'}
        ];
    }

    /**
     * get document type Options
     */
    get documentTypeOptions() { //To Check : do we get  from CV Document Type picklist value field??
        return [{
            label: 'DIFOT',
            value: 'DIFOT'
        }];
    }

    /**
     * change handler
     */
    handleChange(event) {
        const field = event.target.dataset.id;
        if (field === 'repotType')
            this.selectedReportType = event.target.value;
        else if (field === 'documentType')
            this.selectedDocumentType = event.target.value;
        else if (field === 'documentInterval')
            this.selectedDocumentInterval = event.target.value;
        else if (field === 'fromDate')
            this.selectedFromDate = event.target.value;
        else if (field === 'toDate')
            this.selectedToDate = event.target.value;
        else if (field === 'pageSelection')
            this.pageSizeFilterOption = event.target.value;
        else if (field === 'billingAccount')
            this.selectedBillingAccount = event.target.value;
        this.pageNumber = 1;
        this.isLoading = true;
    }


   @wire(getFiles, {
           reportType: '$selectedReportType',
            documentType: '$selectedDocumentType',
            documentInterval:'$selectedDocumentInterval',
            fromDate:'$selectedFromDate',
            toDate: '$selectedToDate',
            pageNumber: '$pageNumber',
            pageSize: '$pageSizeFilterOption',
            sortByColumn: '$sortByColumnApiName',
            sortByOrder: '$sortByOrder',
            selectedBillingAccount:'$selectedBillingAccount'
    }) searchFilesTemp({error,data}) {
  
        this.errorMessage = null;
        if (data) {
            this.searchReultsWrapper = data.paginatedSearchResults;
            this.contentDocIdNLinkedEntityNameMap = data.contentDocIdNLinkedEntityNameMap;
            if (data.paginatedSearchResults.length > 0)
                this.isShowNoResultsFoundMsg = false;
            else
                this.isShowNoResultsFoundMsg = true;

            if (data.paginatedSearchResults.length <
                (data.totalSearchCount - ((this.pageNumber - 1) * this.pageSizeFilterOption))) {
                this.isLastPage = false;
            } else {
                this.isLastPage = true;
            }
            this.resultsSize = data.totalSearchCount;
            this.enableDisableNextPrevButtons();
            this.isLoading = false;
            //this.contentVersions = result;
        } else if (error) {
            this.isLoading = false;
            if (Array.isArray(error.body)) {
                this.errorMessage = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.errorMessage = error.body.message;
            }
        }

    }

    /**
     * search files
     */
    /*searchFiles() {
        this.isLoading = true;
        this.errorMessage = null;
        getFiles({
            reportType: this.selectedReportType,
            documentType: this.selectedDocumentType,
            documentInterval: this.selectedDocumentInterval,
            fromDate: this.selectedFromDate,
            toDate: this.selectedToDate,
            pageNumber: this.pageNumber,
            pageSize: this.pageSizeFilterOption,
            sortByColumn: this.sortByColumnApiName,
            sortByOrder: this.sortByOrder,
            selectedBillingAccount:this.selectedBillingAccount
        }).then(data => {
            this.searchReultsWrapper = data.paginatedSearchResults;
            if (data.paginatedSearchResults.length > 0)
                this.isShowNoResultsFoundMsg = false;
            else
                this.isShowNoResultsFoundMsg = true;

            if (data.paginatedSearchResults.length <
                (data.totalSearchCount - ((this.pageNumber - 1) * this.pageSizeFilterOption))) {
                this.isLastPage = false;
            } else {
                this.isLastPage = true;
            }
            this.resultsSize = data.totalSearchCount;
            this.enableDisableNextPrevButtons();
            this.isLoading = false;
            //this.contentVersions = result;

        }).catch(error => {
            this.isLoading = false;
            if (Array.isArray(error.body)) {
                this.errorMessage = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.errorMessage = error.body.message;
            }
            //this.errorMessage = error.body.message;
        });

    } */

    get isShowResults() {
        return this.searchReultsWrapper ? true : false;
    }


    /*
     *updating page status and enabling/disabling the navigation buttons
     */
    enableDisableNextPrevButtons() {
        if (this.isLastPage)
            this.showNextButton = false;
        else
            this.showNextButton = true;

        if (this.pageNumber == 1)
            this.showPrevButton = false;
        else
            this.showPrevButton = true;

        if (this.pageNumber == 1)
            this.recordStart = 1;
        else
            this.recordStart = (this.pageNumber - 1) * parseInt(this.pageSizeFilterOption) + 1;

        if (this.pageNumber == 1)
            this.recordEnd = this.searchReultsWrapper.length; // this.data.length;
        else
            this.recordEnd = (parseInt(this.pageSizeFilterOption) * (this.pageNumber - 1)) + parseInt(this.searchReultsWrapper.length); //this.data.length);
    }

    /*
     *clicking on previous button this method will be called
     */
    previousHandler() {
        this.pageNumber = this.pageNumber - 1;
        //this.searchFiles();
        // this.isLoading = true;
    }

    /*
     *clicking on next button this method will be called
     */
    nextHandler() {
        this.pageNumber = this.pageNumber + 1;
        //this.searchFiles();
        // this.isLoading = true;
    }

   /* connectedCallback() {
        this.searchFiles();
    }*/

    sortTitle(event) {
        this.isTitleSort = true;
        this.isDocTypeSort = false;
        this.isDocDateSort = false;
        this.isDocIntervalSort = false;
        this.isDocVersionSort = false;
        this.isDocModifiedDateSort = false;
        this.isLinkedEntitySort = false;
        this.sortData(event.currentTarget.dataset.id);
    }

    sortDocumentType(event) {
        this.isTitleSort = false;
        this.isDocTypeSort = true;
        this.isDocDateSort = false;
        this.isDocIntervalSort = false;
        this.isDocVersionSort = false;
        this.isDocModifiedDateSort = false;
        this.isLinkedEntitySort = false;
        this.sortData(event.currentTarget.dataset.id);
    }

    sortDocDate(event) {
        this.isTitleSort = false;
        this.isDocTypeSort = false;
        this.isDocDateSort = true;
        this.isDocIntervalSort = false;
        this.isDocVersionSort = false;
        this.isDocModifiedDateSort = false;
        this.isLinkedEntitySort = false;
        this.sortData(event.currentTarget.dataset.id);
    }
    sortDocInterval(event) {
        this.isTitleSort = false;
        this.isDocTypeSort = false;
        this.isDocDateSort = false;
        this.isDocIntervalSort = true;
        this.isDocVersionSort = false;
        this.isDocModifiedDateSort = false;
        this.isLinkedEntitySort = false;
        this.sortData(event.currentTarget.dataset.id);
    }

    sortVersionNumber(event) {
        this.isTitleSort = false;
        this.isDocTypeSort = false;
        this.isDocDateSort = false;
        this.isDocIntervalSort = false;
        this.isDocVersionSort = true;
        this.isDocModifiedDateSort = false;
        this.isLinkedEntitySort = false;
        this.sortData(event.currentTarget.dataset.id);

    }

    sortDocModifiedDate(event) {
        this.isTitleSort = false;
        this.isDocTypeSort = false;
        this.isDocDateSort = false;
        this.isDocIntervalSort = false;
        this.isDocVersionSort = false;
        this.isDocModifiedDateSort = true;
        this.isLinkedEntitySort = false;
        this.sortData(event.currentTarget.dataset.id);
    }

    sortLinkedEntityId(event){
        this.isTitleSort = false;
        this.isDocTypeSort = false;
        this.isDocDateSort = false;
        this.isDocIntervalSort = false;
        this.isDocVersionSort = false;
        this.isDocModifiedDateSort = false; 
        this.isLinkedEntitySort = true;
        this.sortData('ContentVersion.ContentDocument.ParentId');
    }

    /*
     *Update the sort column and sort order
     */
    sortData(sortColumnName) {

        this.handleResetPagination();
        //this.setLoadingStatus(true);
        // check previous column and direction
        if (this.sortByColumnApiName === sortColumnName) {
            this.sortByOrder = this.sortByOrder === 'asc' ? 'desc NULLS LAST' : 'asc';
        } else {
            this.sortByOrder = 'asc';
        }

        // check arrow direction
        if (this.sortByOrder === 'asc') {
            this.isAsc = true;
            this.isDsc = false;
        } else {
            this.isAsc = false;
            this.isDsc = true;
        }
        this.sortByColumnApiName = sortColumnName;
        //this.searchFiles();
    }

    handleResetPagination() {
        this.pageNumber = 1;
        this.isLastPage = false;
        this.resultsSize = 0
        this.showPrevButton = false;
        this.showNextButton = false;
        this.recordStart = 0;
        this.recordEnd = 0;
        this.errorMessage = null;
    }
}