/**
 * 2020-05-25 - Nathan Franklin - Added ability to search billing accounts for selection for Merchant Portal
 * 2023-07-25 - Mahesh Parvathaneni - Added getter setter for billingAccounts to re-render the billing accounts from parent
 */
import {LightningElement, api, track} from 'lwc';
import { keyBy, debounce } from 'c/bamUtils'

export default class BamBillingAccountSelector extends LightningElement {

	// for search typing
	debouncedSearch;
	searchString;

	// used for storing the filtered billing account state
	filteredBillingAccounts;
	_billingAccounts; //private variable to store billing accounts on initial load

	@track objectifiedSelections;
	@track filteringDataset;

	@api isDisabled;

	/**
	 * for performance reasons, convert this array into an object to prevent significant lag in using .includes to find which billing accounts are selected
	 */
	@api
	set selected(value) {
		const objectifiedSelections = {};
		if(value) {
			value.forEach(item => objectifiedSelections[item] = true);
		}
		this.objectifiedSelections = objectifiedSelections;
	}
	get selected() {
		return Object.keys(this.objectifiedSelections);
	}

	@api
	set billingAccounts(value) {
		if(value) {
			this.filteredBillingAccounts = value;
			this._billingAccounts = value;
		}
	}

	get billingAccounts() {
		return this._billingAccounts;
	}

	@api applicationId;

	async connectedCallback() {
		this.filteredBillingAccounts = this.billingAccounts;
		this.debouncedSearch = debounce(this.filterBillingAccounts, 200);
	}

	get computedBillingAccounts() {
		const output = (this.filteredBillingAccounts ? this.filteredBillingAccounts.map(item => { return {...item, suburbState: (item.Suburb__c ? item.Suburb__c : '') + (item.Suburb__c && item.State__c ? ' - ' + item.State__c : (item.State__c ? item.State__c : '')), selected: !!this.objectifiedSelections[item.Id]}}) : false);
		return output;
	}

	get hasFilteredResults() {
		return (this.filteredBillingAccounts && this.filteredBillingAccounts.length > 0);
	}

	get tableWrapperStyles() {
		return 'max-height: 390px;overflow-y:auto;position:relative;';// + (this.filteredBillingAccounts ? Math.min(this.filteredBillingAccounts.length*35, 350) : 100) + 'px';
	}

	get tableClasses() {
		return 'slds-table slds-table_cell-buffer slds-table_bordered ' + (this.isDisabled ? ' slds-no-row-hover is-disabled' : '');
	}

	get trIsDisabledStyle() {
		return (this.isDisabled ? 'cursor:default;' : '');
	}

	get selectedText() {
		return (this.selected.length === 1 ? '1 account selected' : (this.selected.length > 0 ? this.selected.length + ' accounts selected' : 'No accounts selected'));
	}

	handleSearchChange(e) {
		this.searchString = e.target.value;
		this.debouncedSearch();

		// stop the change event from bubbling up
		e.stopPropagation();
	}

	handleToggleOn(e) {
		if(this.isDisabled) {
			return;
		}

		const objectifiedSelections = {...this.objectifiedSelections};
		this.filteredBillingAccounts.forEach(item => objectifiedSelections[item.Id] = true);
		this.propagateChange(Object.keys(objectifiedSelections));
	}

	/**
	 * Remove the selected billing accounts
	 */
	handleToggleOff(e) {
		if(this.isDisabled) {
			return;
		}

		const objectifiedSelections = {...this.objectifiedSelections};
		this.filteredBillingAccounts.forEach(item => {
			if(objectifiedSelections[item.Id]) {
				delete objectifiedSelections[item.Id];
			}
		});
		this.propagateChange(Object.keys(objectifiedSelections));
	}

	handleSelectionToggle(e) {
		if(this.isDisabled) {
			return;
		}

		const accId = e.currentTarget.dataset.accountid;

		if(this.objectifiedSelections[accId]) {
			delete this.objectifiedSelections[accId];
		} else {
			this.objectifiedSelections[accId] = true;
		}
		this.propagateChange(Object.keys(this.objectifiedSelections));
	}

	propagateChange(selected) {
		const changeEvent = new CustomEvent('billingaccountchange', {
			detail: {
				applicationId: this.applicationId,
				selected: selected
			}
		});
		this.dispatchEvent(changeEvent);
	}

	async filterBillingAccounts() {
		this.filteringDataset = true;
		const escapedSearchString = this.searchString.replace(/[.*+\-?^${}()|[\]\\]/g, '\\$&');
		const pattern = '\\b' + escapedSearchString;
		const cachedRegEx = new RegExp(pattern, 'i');
		if(!escapedSearchString) {
			this.filteredBillingAccounts = [...this.billingAccounts];
		} else {
			this.filteredBillingAccounts = this.billingAccounts.filter(item => cachedRegEx.test(item.Name + '|' + item.LEGACY_ID__c + '|' + item.MLID__c + '|' + item.Suburb__c + '|' + item.State__c));
		}
		this.filteringDataset = false;
	}

}