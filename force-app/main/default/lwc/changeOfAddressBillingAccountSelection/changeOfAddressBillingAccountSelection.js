import {api, LightningElement, wire} from 'lwc';
import getBillingAccounts from '@salesforce/apex/ChangeOfAddressController.getActiveBillingAccounts';
import getColumns from '@salesforce/apex/ChangeOfAddressController.getColumns';
import LABEL_DSR_NOT_REQUIRED_FOR_AP from "@salesforce/label/c.Change_Of_Address_DSR_Not_Required_For_AP";

// Searchable fields
const SEARCHABLE_AP_FIELDS = ['Name', 'LEGACY_ID__c', 'billingAddress', 'PAYER_ACCOUNT_ID__c'];
const SEARCHABLE_ST_FIELDS = ['Name', 'LEGACY_ID__c', 'billingAddress', 'physicalAddress', 'PAYER_ACCOUNT_ID__c', 'LeaderAccount__c'];
const ROW_LIMIT = 10; // TODO change back to 50 after testing

export default class ChangeOfAddressBillingAccountSelection extends LightningElement {
	@api accountId;
	@api newBillingAddress;
	@api newPhysicalAddress;
	@api currentBillingAddress;
	@api currentPhysicalAddress;
	apBillingAccounts;
	stBillingAccounts;
	apBillingAccountsColumns;
	stBillingAccountsColumns;
	selectedAPBAs = [];
	selectedSTBAs = [];
	selectedAPBAIds = [];
	selectedSTBAIds = [];
	_filteredAPBillingAccounts;
	_filteredSTBillingAccounts;
	apSearchTerm;
	stSearchTerm;
	productSelection = [{label: 'AP', value: 'AP'}, {label: 'ST', value: 'ST'}];
	productSelected = [];
	apRowOffset = ROW_LIMIT;
	stRowOffset = ROW_LIMIT;
	billingAccountError;

	@wire(getBillingAccounts, {orgId: '$accountId'})
	wiredData(result) {
		const {data} = result;
		if (data) {
			let nameUrl;
			let billingAddress;
			let physicalAddress;
			let PAYER_ACCOUNT_ID__c;
			let LeaderAccount__c;
			this.apBillingAccounts = data.filter(e => e.Source_System__c === 'SAP ERP').map(row => {
				nameUrl = `/${row.Id}`;
				billingAddress = row.Street__c + ' ' + row.Suburb__c + ' ' + row.State__c + ' ' + row.Postal_Code__c;
				PAYER_ACCOUNT_ID__c = row.PAYER_ACCOUNT_ID__r?.Name;
				return {...row , nameUrl, billingAddress, PAYER_ACCOUNT_ID__c}
			});
			this.stBillingAccounts = data.filter(e => e.Source_System__c === 'TEAM').map(row => {
				nameUrl = `/${row.Id}`;
				billingAddress = row.Street__c + ' ' + row.Suburb__c + ' ' + row.State__c + ' ' + row.Postal_Code__c;
				physicalAddress = row.PhysicalStreet__c + ' ' + row.PhysicalSuburb__c + ' ' + row.PhysicalState__c + ' ' + row.PhysicalPostalCode__c;
				PAYER_ACCOUNT_ID__c = row.PAYER_ACCOUNT_ID__r?.Name;
				LeaderAccount__c = row.LeaderAccount__r?.Name;
				return {...row , nameUrl, billingAddress, physicalAddress, PAYER_ACCOUNT_ID__c, LeaderAccount__c}
			});

			let noApOrSt = [];
			if (this.apBillingAccounts.length === 0) {
				noApOrSt.push('AP');
			}
			if (this.apBillingAccounts.length === 0) {
				noApOrSt.push('ST');
			}

			if (noApOrSt.length > 0) {
				this.billingAccountError = `No active ${noApOrSt.join(' or ')} Billing Accounts exist under this Organisation. Please click Next to proceed with address update on Organisation and selected contacts.`;

			}

			getColumns({objectName:'Billing_Account__c', fieldSetName: 'ChangeOfAddressAPBillingAccountColumn'}).then(c => {
				this.apBillingAccountsColumns = c.map(item => {
					return {...item};
				});
				this.apBillingAccountsColumns.splice(0, 0, { label: 'Name', fieldName: 'nameUrl', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}});
				this.apBillingAccountsColumns.splice(3, 0, { label: 'Billing Address', fieldName: 'billingAddress' });
			});
			getColumns({objectName:'Billing_Account__c', fieldSetName: 'ChangeOfAddressSTBillingAccountColumn'}).then(c => {
				this.stBillingAccountsColumns = c.map(item => {
					return {...item};
				});
				this.stBillingAccountsColumns.splice(0, 0, { label: 'Name', fieldName: 'nameUrl', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}});
				this.stBillingAccountsColumns.splice(3, 0, { label: 'Billing Address', fieldName: 'billingAddress' });
				this.stBillingAccountsColumns.splice(4, 0, { label: 'Physical Address', fieldName: 'physicalAddress' });
			});
		}
	}

	get infoMessage() {
		if (this.newPhysicalAddress && this.apBillingAccounts?.length > 0 && this.stBillingAccounts?.length === 0) {
			return LABEL_DSR_NOT_REQUIRED_FOR_AP;
		}
	}

	get showAPBillingAccounts() {
		return this.newBillingAddress && this.apBillingAccounts?.length > 0 && (this.showProductOptions ? this.productSelected.includes('AP') : true);
	}

	get showSTBillingAccounts() {
		return this.stBillingAccounts?.length > 0 && (this.showProductOptions ? this.productSelected.includes('ST') : true);
	}

	get showSelectedAPBillingAccounts() {
		return this.selectedAPBAs?.length > 0;
	}

	get showSelectedSTBillingAccounts() {
		return this.selectedSTBAs?.length > 0;
	}

	get filteredAPBillingAccounts() {
		if (this._filteredAPBillingAccounts) {
			return this._filteredAPBillingAccounts;
		}

		if (!this._filteredAPBillingAccounts && this.apBillingAccounts?.length > 0) {
			this._filteredAPBillingAccounts = this.apBillingAccounts;
		}

		// filter records based on the search term
		if (this.apSearchTerm) {
			this._filteredAPBillingAccounts = this._filteredAPBillingAccounts.filter(item => {
				for (const field of SEARCHABLE_AP_FIELDS) {
					if (item[field]) {
						const fieldValueStr = item[field].toLowerCase();
						if (fieldValueStr.includes(this.apSearchTerm.toLowerCase())) {
							return true;
						}
					}
				}
				return false;
			});
		}

		// filter records based on the row offset
		if (this._filteredAPBillingAccounts) {
			this._filteredAPBillingAccounts = this._filteredAPBillingAccounts.slice(0, this.apRowOffset);
		}

		this.selectedAPBAIds = this.selectedAPBAs.map(c => c.Id);

		return this._filteredAPBillingAccounts;
	}

	get filteredSTBillingAccounts() {
		if (this._filteredSTBillingAccounts) {
			return this._filteredSTBillingAccounts;
		}

		if (!this._filteredSTBillingAccounts && this.stBillingAccounts?.length > 0) {
			this._filteredSTBillingAccounts = this.stBillingAccounts;
		}

		// filter records based on the search term
		if (this.stSearchTerm) {
			this._filteredSTBillingAccounts = this._filteredSTBillingAccounts.filter(item => {
				for (const field of SEARCHABLE_ST_FIELDS) {
					const fieldValueStr = item[field].toLowerCase();
					if (fieldValueStr.includes(this.stSearchTerm.toLowerCase())) {
						return true;
					}
				}
				return false;
			});
		}

		// filter records based on the row offset
		if (this._filteredSTBillingAccounts) {
			this._filteredSTBillingAccounts = this._filteredSTBillingAccounts.slice(0, this.stRowOffset);
		}

		this.selectedSTBAIds = this.selectedSTBAs.map(c => c.Id);

		return this._filteredSTBillingAccounts;
	}

	/**
	 *  Triggered when user select billing accounts
	 */
	handleSelectedRows(event) {
		if (event.target.dataset.id === 'apBA') {
			this.selectedAPBAs = event.detail.selectedRows;
		}
		if (event.target.dataset.id === 'stBA') {
			this.selectedSTBAs = event.detail.selectedRows;
		}
	}

	/**
	 * Increment row offset when user scroll to the bottom of the table for infinite loading
	 */
	handleLoadData(event) {
		if (event.target.dataset.id === 'apBA') {
			// disable infinite loading if table is fully loaded
			if (this.filteredAPBillingAccounts.length < this.apRowOffset) {
				event.target.enableInfiniteLoading = false;
			} else {
				this.apRowOffset = this.apRowOffset + ROW_LIMIT;
				this._filteredAPBillingAccounts = null;
			}
		}
		if (event.target.dataset.id === 'stBA') {
			// disable infinite loading if table is fully loaded
			if (this.filteredSTBillingAccounts.length < this.stRowOffset) {
				event.target.enableInfiniteLoading = false;
			} else {
				this.stRowOffset = this.stRowOffset + ROW_LIMIT;
				this._filteredSTBillingAccounts = null;
			}
		}
	}

	/**
	 * Update filtered billing accounts based on search term
	 */
	handleSearchChange(event) {
		if (event.target.dataset.id === 'apBASearch') {
			this.apSearchTerm = event.target.value;
			// invalidate the state/cache, so it can be rebuilt based on the search term
			this._filteredAPBillingAccounts = null;
			// Reset rowOffset
			this.apRowOffset = ROW_LIMIT;
			const datatable = this.template.querySelector(`[data-id="apBA"]`);
			datatable.enableInfiniteLoading = true;
			datatable.scrollToTop();
		}
		if (event.target.dataset.id === 'stBASearch') {
			this.stSearchTerm = event.target.value;
			// invalidate the state/cache, so it can be rebuilt based on the search term
			this._filteredSTBillingAccounts = null;
			// Reset rowOffset
			this.stRowOffset = ROW_LIMIT;
			const datatable = this.template.querySelector(`[data-id="stBA"]`);
			datatable.enableInfiniteLoading = true;
			datatable.scrollToTop();
		}
	}

	get isLoading() {
		return this.apBillingAccounts == null || this.stBillingAccounts == null;
	}

	/**
	 * Only show AP ST selection if both AP and ST billing accounts are viewable
	 */
	get showProductOptions() {
		return this.apBillingAccounts?.length > 0 && this.stBillingAccounts?.length > 0 && this.newBillingAddress;
	}

	get showPhysicalAddressChange() {
		return this.newPhysicalAddress && (!this.infoMessage || this.stBillingAccounts?.length > 0);
	}

	handleProductSelected(event) {
		this.productSelected = event.detail.value;
	}
	@api
    async getUserSelectedData() {
		return {selectedAP: this.selectedAPBAs, selectedST: this.selectedSTBAs};
	}
	@api
	async restoreState(data) {
		this.selectedAPBAs = data.selectedAP;
		this.selectedSTBAs = data.selectedST;
    }
	
	//TODO: handleRowSelection not work when user input search term
}