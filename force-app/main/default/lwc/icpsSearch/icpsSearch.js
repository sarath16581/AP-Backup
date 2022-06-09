/**
 * @author Harry Wang
 * @date 2022-03-21
 * @group Controller
 * @tag Controller
 * @domain ICPS
 * @description Javascript controller for ICPS Search.
 * @changelog
 * 2022-03-21 - Harry Wang - Created
 */
import {LightningElement, track, wire} from 'lwc';
import getICPSCases from '@salesforce/apex/ICPSServiceController.getICPSCases';
import { getPicklistValuesByRecordType, getObjectInfo } from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import ICPS_OBJECT from '@salesforce/schema/ICPS__c';
import NAME_FIELD from '@salesforce/schema/ICPS__c.Name';
import MAIL_CATEGORY from '@salesforce/schema/ICPS__c.MailCategory__c';
import ITEM_TYPE from '@salesforce/schema/ICPS__c.ItemType__c';
import RECEIVER_NAME from '@salesforce/schema/ICPS__c.ReceiverName__c';
import COUNTRY_OF_ORIGIN from '@salesforce/schema/ICPS__c.CountryofOrigin__c';
import NUMBER_OF_ARTICLES from '@salesforce/schema/ICPS__c.NumberofArticles__c';
import STORED_LOCATION from '@salesforce/schema/ICPS__c.StoredLocation__c';
import STATUS from '@salesforce/schema/ICPS__c.Status__c';

export default class IcpsSearch extends LightningElement {
	// get ICPS object info
	@wire (getObjectInfo, {objectApiName: ICPS_OBJECT})
	icpsObjectInfo;

	// get picklist values for default record type
	@wire(getPicklistValuesByRecordType, { objectApiName: ICPS_OBJECT, recordTypeId: '$icpsObjectInfo.data.defaultRecordTypeId'})
	wiredPicklistValues({data}) {
		if (data) {
			this.storedLocations = data.picklistFieldValues[STORED_LOCATION.fieldApiName].values;
			this.status = data.picklistFieldValues[STATUS.fieldApiName].values;
		}
	}
	storedLocations;
	status;

	// collection of ICPS search results
	@track searchResults = [];
	get noDataToDisplay() {
		return this.searchResults.length === 0;
	}
	isLoading = false;

	columns = [
		{ label: 'Reference', fieldName: 'icpsUrl', type: 'url', sortable: true, typeAttributes: {label: {fieldName: NAME_FIELD.fieldApiName}, target :'_blank'}},
		{ label: 'Mail Category', fieldName: MAIL_CATEGORY.fieldApiName, sortable: true },
		{ label: 'Item type', fieldName: ITEM_TYPE.fieldApiName, sortable: true },
		{ label: 'Receiver Name', fieldName: RECEIVER_NAME.fieldApiName, sortable: true },
		{ label: 'Country Origin', fieldName: COUNTRY_OF_ORIGIN.fieldApiName, sortable: true },
		{ label: 'Status', fieldName: STATUS.fieldApiName, sortable: true },
		{ label: 'Number of Items', fieldName: NUMBER_OF_ARTICLES.fieldApiName, sortable: true },
	];

	sortDirection = 'asc';
	sortedBy;

	/**
	 * Search ICPS based on the search params from user inputs
	 */
	handleSearch() {
		let searchParams = new Map();
		this.template.querySelectorAll(".search-input").forEach(function (input) {
			if (input.value) {
				searchParams[input.getAttribute('data-id')] = input.value;
			}
		});
		if (this.validateInput(searchParams)) {
			this.isLoading = true;
			this.searchResults = [];
			getICPSCases({
				searchParams: searchParams,
				matchAll: true
			}).then((result) => {
				let tempResults = [];
				result.forEach((item) => {
					let tempItem = Object.assign({}, item);
					tempItem.icpsUrl = '/lightning/r/ICPS__c/' + item.Id + '/view';
					tempResults.push(tempItem);
				});
				this.searchResults = tempResults;
			}).catch((error) => {
				console.error(error);
				this.startToast('Search failed: ' + error.body.message, 'error');
			}).finally(() => {
				this.isLoading = false;
			})
		}
	}

	/**
	 * Validate user inputs on search
	 */
	validateInput(inputs) {
		if (Object.keys(inputs).length === 0) {
			this.startToast('At least one search criteria required.', 'error')
			return false;
		}
		return true;
	}

	/**
	 * Reset user inputs and search results
	 */
	handleReset() {
		this.template.querySelectorAll(".search-input").forEach(function (input) {
			input.value = null;
		});
		this.searchResults = [];
	}

	startToast(msg, variant) {
		let event = new ShowToastEvent({
			message: msg,
			variant: variant
		});
		this.dispatchEvent(event);
	}

	/**
	 * Sort by specific fieldName in the data table
	 */
	sortBy(field, reverse, primer) {
		const key = primer
			? function (x) {
				return primer(x[field]);
			}
			: function (x) {
				return x[field];
			};

		return function (a, b) {
			a = key(a);
			b = key(b);
			return reverse * ((a > b) - (b > a));
		};
	}

	/**
	 * Used to handle sorting
	 */
	onHandleSort(event) {
		const { fieldName: sortedBy, sortDirection } = event.detail;
		const cloneSearchResults = [...this.searchResults];

		cloneSearchResults.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
		this.searchResults = cloneSearchResults;
		this.sortDirection = sortDirection;
		this.sortedBy = sortedBy;
	}
}