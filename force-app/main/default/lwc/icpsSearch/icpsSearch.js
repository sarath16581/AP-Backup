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
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import NAME_FIELD from '@salesforce/schema/ICPS__c.Name';
import MAIL_CATEGORY from '@salesforce/schema/ICPS__c.MailCategory__c';
import ITEM_TYPE from '@salesforce/schema/ICPS__c.ItemType__c';
import RECEIVER_NAME from '@salesforce/schema/ICPS__c.ReceiverName__c';
import COUNTRY_OF_ORIGIN from '@salesforce/schema/ICPS__c.CountryofOrigin__c';
import NUMBER_OF_ARTICLES from '@salesforce/schema/ICPS__c.NumberofArticles__c';
import STORED_LOCATION from '@salesforce/schema/ICPS__c.StoredLocation__c';


export default class IcpsSearch extends LightningElement {
	// '012000000000000AAA' is a hardcoded global record type id for all objects
	@wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: STORED_LOCATION})
	wiredPicklistValues({error, data}) {
		if (data) {
			this.storedLocations = data.values;
		}
	}
	storedLocations;

	@track searchResults = [];
	get hasDataToDisplay() {
		return this.searchResults.length !== 0;
	}
	isLoading = false;

	columns = [
		{ label: 'Reference', fieldName: 'icpsUrl', type: 'url', typeAttributes: {label: {fieldName: NAME_FIELD.fieldApiName}, target :'_blank'}},
		{ label: 'Mail Category', fieldName: MAIL_CATEGORY.fieldApiName },
		{ label: 'Item type', fieldName: ITEM_TYPE.fieldApiName },
		{ label: 'Receiver Name', fieldName: RECEIVER_NAME.fieldApiName },
		{ label: 'Country Origin', fieldName: COUNTRY_OF_ORIGIN.fieldApiName },
		{ label: 'Number of Items', fieldName: NUMBER_OF_ARTICLES.fieldApiName },
	];

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

	validateInput(inputs) {
		if (Object.keys(inputs).length === 0) {
			this.startToast('At least one search criteria required.', 'error')
			return false;
		}
		return true;
	}

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
}