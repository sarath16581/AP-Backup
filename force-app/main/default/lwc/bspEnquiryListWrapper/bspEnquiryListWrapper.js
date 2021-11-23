import { LightningElement, wire, track } from 'lwc';
import getIndOrgPicklist from '@salesforce/apex/bspEnquiryUplift.getIndOrgPicklist';
import getConstants from '@salesforce/apex/bspEnquiryUplift.getAllConstants';
import getBillingAccounts from '@salesforce/apex/bspEnquiryUplift.getAllBillingAccounts';
import getDynamicPageSizes from '@salesforce/apex/bspEnquiryUplift.getDynamicPageSizePicklist';
import getStatusList from '@salesforce/apex/bspEnquiryUplift.getStatusList';
import getEnquiryTypeOptions from '@salesforce/apex/bspEnquiryUplift.getRelatedToList';
import getUserBillingAccountScope from '@salesforce/apex/bspEnquiryUplift.getUserBillingAccountScope'

export default class BspEnquiryListWrapper extends LightningElement {

    defaultOrg;
    defaultPageSize;
    userBillingAccountScope;
    
    @wire(getBillingAccounts) allBilingAccOptions;
    @wire(getIndOrgPicklist) allOrgOptions;
    @wire(getDynamicPageSizes) dynamicPageSizes;
    @wire(getStatusList) statusList;
    @wire(getEnquiryTypeOptions) allEnquiryTypeOptions;
    @wire(getUserBillingAccountScope) billingAccountScope;

    @track searchText = '';
    @track orgFilterOption = '';
    @track billingAccFilterOption = '';
    @track statusFilterOption = '';
    @track enquiryTypeFilterOption = '';
    @track pageSizeFilterOption = '';
    @track fromdataFilterOption = null;
    @track toDateFilterOption = null;

    //Get the billing account scope for the user
    @wire(getUserBillingAccountScope)
    billingAccountScope({
        error,
        data
    }) {
        if (data) {
            this.userBillingAccountScope = data;
            this.enquiryTypeFilterOption = data;
        } /*else {
            console.log(error);
        }*/
    }

    //Get the default org options and default pagination options from custom settings
    @wire(getConstants)
    allConstants({
        error,
        data
    }) {
        if (data) {
            this.defaultOrg = data.DEFAULT_ORG_OPTION_VALUE;
            this.defaultPageSize = data.DEFAULT_PAGE_OPTION_VALUE;
            this.pageSizeFilterOption = data.DEFAULT_PAGE_OPTION_VALUE;
        }/* else {
            console.log(error);
        }*/
    }

    get orgPicklistOptions() {
        return this.allOrgOptions.data;
    }

    get billingAccPicklistOptions() {
        return this.allBilingAccOptions.data;
    }

    get pageSizeOptions() {
        return this.dynamicPageSizes.data;
    }

    get getStatusOptions() {
        return this.statusList.data;
    }

    get enquiryTypeOptions() {
        return this.allEnquiryTypeOptions.data;
    }

    get showEnquiryTypesFilter() {
        return this.userBillingAccountScope == 'ALL' ? true : false;
    }

    handleSearchKeyUp() {

    }

    handleChange(event) {
        this.template.querySelector("c-bsp-enquiries-list").handleResetPagination();
        const field = event.target.dataset.id;
        if (field === 'search') {
            this.searchText = event.target.value;
        } else if (field === 'pageSelection') {
            this.pageSizeFilterOption = event.target.value;
        } else if (field === 'organisation') {
            this.orgFilterOption = event.target.value;
        } else if (field === 'billingAccount') {
            this.billingAccFilterOption = event.target.value;
        } else if (field === 'fromdate') {
            this.fromdataFilterOption = event.target.value;
        } else if (field === 'todate') {
            this.toDateFilterOption = event.target.value;
        } else if (field === 'status') {
            this.statusFilterOption = event.target.value;
        } else if (field === 'enquiryType') {
            this.enquiryTypeFilterOption = event.target.value;
        }
    }
}