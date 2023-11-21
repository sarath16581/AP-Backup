/**
 * @description List view component to show list of sub accounts for provided leader account
 * Supported feature: searching on account name and address, editing individual account, mass deleting accounts, sorting
 * @author Harry Wang
 * @date 2023-11-01
 * @group Controller
 * @changelog
 * 2023-11-01 - Harry Wang - Created
 */
import {api, LightningElement, wire} from 'lwc';
import getDatatableColumns from '@salesforce/apex/FollowerOffspringRequestController.retrieveListViewColumns';
import deleteSubAccounts from '@salesforce/apex/FollowerOffspringRequestController.deleteSubAccounts';
import finalizeSubAccounts from '@salesforce/apex/FollowerOffspringRequestController.finalizeSubAccounts';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import LightningConfirm from "lightning/confirm";
import BILLING_ACCOUNT_NAME from "@salesforce/schema/Billing_Account__c.Name";
import CHARGE_ACCOUNT_OPPORTUNITY_ID from "@salesforce/schema/APT_Charge_Account__c.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__c";
import CHARGE_ACCOUNT_OPPORTUNITY_NAME from "@salesforce/schema/APT_Charge_Account__c.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__r.Name";
import SUB_ACCOUNT_STAGE from "@salesforce/schema/APT_Sub_Account__c.APT_Sub_Account_Request_Status__c";
import maxFinalizeError from "@salesforce/label/c.StarTrackSubAccountMaxFinalizeErrorMessage";
import {getFieldValue, getRecord} from "lightning/uiRecordApi";
import LightningAlert from 'lightning/alert';

// Row actions
const actions = [
	{label: 'Edit', name: 'edit'}
];

// Searchable fields
const SEARCHABLE_FIELDS = ['Name', 'PhysicalAddress'];

// Max number of requests can be finalized
const MAX_FINALIZE_REQUESTS = 10;
export default class FollowerOffspringRequestTeamList extends LightningElement {
	@api leaderId;
	@api isBillingAccount;
	@api countFinalized;
	columns;

	// Default sorting is on CreatedDate DESC
	sortBy = 'CreatedDate';
	sortDirection = 'desc';

	@api subAccounts = [];
	_filteredSubAccounts;
	searchTerm
	selectedRows = [];
	isLoading = true;

	// navigation bar & submit button
	listViewUrl;
	recordViewUrl;
	listViewLabel;
	recordViewLabel;
	submitLabel;

	/**
	 *  Load leader account details for navigation bar
	 */
	@wire(getRecord, { recordId: "$leaderId", fields: "$fields" })
	record({error, data}) {
		if (data) {
			if (this.isBillingAccount === 'true') {
				this.listViewLabel = 'Billing Accounts';
				this.listViewUrl = '/lightning/o/Billing_Account__c/list?filterName=Recent';
				this.recordViewLabel = getFieldValue(data, BILLING_ACCOUNT_NAME);
				this.recordViewUrl = '/lightning/r/Billing_Account__c/'+ this.leaderId + '/view';
				this.submitLabel = 'Submit'
			} else {
				this.listViewLabel = 'Opportunities';
				this.listViewUrl = '/lightning/o/Opportunity/list?filterName=Recent';
				this.recordViewLabel = getFieldValue(data, CHARGE_ACCOUNT_OPPORTUNITY_NAME);
				this.recordViewUrl = '/lightning/r/Opportunity/'+ getFieldValue(data, CHARGE_ACCOUNT_OPPORTUNITY_ID) + '/view';
				this.submitLabel = 'Finalize Request(s)'
			}
		}
		if (error) {
			console.log('Error when loading leader: ' + error);
		}
	}

	/**
	 * Get fields based on leader account type - used to wire leader account details
	 */
	get fields() {
		if (this.isBillingAccount === 'true') {
			return [BILLING_ACCOUNT_NAME];
		}
		return [CHARGE_ACCOUNT_OPPORTUNITY_ID, CHARGE_ACCOUNT_OPPORTUNITY_NAME];
	}

	/**
	 * Load columns from server and add additional Physical Address and row actions columns
	 */
	@wire(getDatatableColumns)
	wiredColumns({error, data}) {
		if (data) {
			this.columns = data.map(item => {
				return {...item};
			});
			// insert physical address at index 2
			this.columns.splice(2, 0, {label: 'Physical Address', fieldName: 'PhysicalAddress', type: 'text', sortable: 'true'});
			this.columns.push({type: 'action', typeAttributes: {rowActions: actions}});
		} else if (error) {
			console.error(error);
		}
		this.isLoading = false;
	}

	get filteredSubAccounts() {
		if (this._filteredSubAccounts == null && this.subAccounts.length > 0) {
			this._filteredSubAccounts = this.subAccounts;
		}
		return this._filteredSubAccounts;
	}

	set filteredSubAccounts(value) {
		this._filteredSubAccounts = value;
	}

	/**
	 * Filter out sub accounts based on search term
	 */
	handleSearchChange(event) {
		const searchKey = event.target.value.toLowerCase();
		const searchRecords = [];
		if (searchKey) {
			this.subAccounts.forEach(item => {
				for (const field of SEARCHABLE_FIELDS) {
					const fieldValueStr = item[field].toLowerCase();
					if (fieldValueStr.includes(searchKey)) {
						searchRecords.push(item);
						break;
					}
				}
			});
			this.filteredSubAccounts = searchRecords;
		} else {
			this.filteredSubAccounts = this.subAccounts;
		}

	}

	get searchCount() {
		let text = this.subAccounts.length + ' account requests';
		if (this.filteredSubAccounts && this.template.querySelector('lightning-input')?.value) {
			text = this.filteredSubAccounts.length + ' of ' + text;
		}
		return text;
	}

	get selectCount() {
		return this.selectedRows.length + ' selected';
	}

	get hasSubAccounts() {
		return this.subAccounts.length > 0;
	}

	get isActionDisabled() {
		return this.selectedRows.length === 0;
	}

	handleRowAction(event) {
		const actionName = event.detail.action.name;
		const row = event.detail.row;
		switch (actionName) {
			case 'edit':
				this.editRow(row);
				break;
			default:
		}
	}

	handleRowSelection(event) {
		this.selectedRows = event.detail.selectedRows;
	}

	/**
	 * Delete selected sub accounts from datatable and reset selection. Show error if deletion failed.
	 * Dispatch delete event to request wrapper for deletion on server side
	 */
	async handleDeleteRows() {
		const result = await LightningConfirm.open({
			message: this.selectedRows?.length + ' selected sub account request(s) will be deleted.',
			variant: 'headerless',
			label: 'Sub Accounts Delete',
		});
		if (result) {
			this.isLoading = true;
			const ids = this.selectedRows.map(item => item.Id);
			deleteSubAccounts({subAccounts: this.selectedRows})
				.then(() => {
					this.dispatchEvent(new CustomEvent('delete'));
					// delete rows from filteredSubAccounts
					this.filteredSubAccounts = [...this.filteredSubAccounts].filter(item => !ids.includes(item.Id));
					this.subAccounts = [...this.subAccounts].filter(item => !ids.includes(item.Id));
					this.resetSelection();
				}).catch(error =>{
					const errorMessages = JSON.stringify(error).match(/(?<="message":")(.*?)(?=")/g).join(' ');
					if (errorMessages) {
						this.dispatchEvent(
							new ShowToastEvent({
								title: "An error occurred while saving/deleting record(s).",
								message: errorMessages,
								variant: "error",
							}),
						);
					}
				}).finally(() =>{
					this.isLoading = false;
			});
		}
	}

	/**
	 * Dispatch edit event to request wrapper for creation on server side
	 */
	handleNew() {
		this.dispatchEvent(new CustomEvent('new'));
		this.filteredSubAccounts = null;
	}

	/**
	 * Dispatch edit event with updated sub account to request wrapper for updating on server side
	 */
	editRow(row) {
		this.filteredSubAccounts = null;
		this.dispatchEvent(new CustomEvent('edit', {
			detail : row
		}));
		this.filteredSubAccounts = null;
	}

	/**
	 * Sort datatable when user click any column
	 */
	handleSort(event) {
		this.sortBy = event.detail.fieldName;
		this.sortDirection = event.detail.sortDirection;
		this.sortData(this.sortBy, this.sortDirection);
	}

	/**
	 * Sort datatable based on sort direction and field name passed from handleSort
	 */
	sortData(fieldName, direction) {
		let parseData = JSON.parse(JSON.stringify(this.filteredSubAccounts));
		let keyValue = (a) => {
			return a[fieldName].toLowerCase();
		};
		let isReverse = direction === 'asc' ? 1: -1;
		parseData.sort((x, y) => {
			x = keyValue(x) ? keyValue(x) : '';
			y = keyValue(y) ? keyValue(y) : '';
			return isReverse * ((x > y) - (y > x));
		});
		this.filteredSubAccounts = parseData;
	}

	/**
	 * Update selected sub accounts status to 'Pending Charge Account' and dispatch finalize event to request wrapper
	 * User can select up to MAX_FINALIZE_REQUESTS records in one go
	 * Show errors if any failures
	 */
	async handleSubmit() {
		const result = await LightningConfirm.open({
			message: this.selectedRows?.length + ' selected sub account request(s) will be submitted/finalized.',
			variant: 'headerless',
			label: 'Sub Accounts Submit/Finalize',
		});
		if (result) {
			if (this.isBillingAccount === 'true') {
				// TODO: Submit
			} else {
				if (this.selectedRows.length > MAX_FINALIZE_REQUESTS - this.countFinalized) {
					await LightningAlert.open({
						message: maxFinalizeError,
						theme: 'error',
						variant: 'headerless'
					});
					return;
				}
				// update charge account sub account status to Pending Charge Account
				const chargeAccountSubAccounts = this.selectedRows.map(item => {
					return {Id: item.Id, [SUB_ACCOUNT_STAGE.fieldApiName]: 'Pending Charge Account'};
				});
				// extract IDs to refresh list view
				const ids = chargeAccountSubAccounts.map(item => item.Id);

				// finalize charge account sub accounts
				if (chargeAccountSubAccounts.length > 0) {
					this.isLoading = true;
					finalizeSubAccounts({subAccounts: chargeAccountSubAccounts})
						.then(() => {
							this.dispatchEvent(new CustomEvent('finalize', {detail: chargeAccountSubAccounts.length}));
							// delete rows from filteredSubAccounts and subAccounts
							this.filteredSubAccounts = [...this.filteredSubAccounts].filter(item => !ids.includes(item.Id));
							this.subAccounts = [...this.subAccounts].filter(item => !ids.includes(item.Id));
							this.resetSelection();
							this.countFinalized = this.countFinalized + chargeAccountSubAccounts.length;
						}).catch(error =>{
						const errorMessages = JSON.stringify(error).match(/(?<="message":")(.*?)(?=")/g).join(' ');
						if (errorMessages) {
							this.dispatchEvent(
								new ShowToastEvent({
									title: "An error occurred while submitting/finalizing record(s).",
									message: errorMessages,
									variant: "error",
								}),
							);
						}
					}).finally(() =>{
						this.isLoading = false;
					});
				}
			}
		}
	}

	resetSelection() {
		this.template.querySelector('lightning-datatable').selectedRows = [];
		this.selectedRows = [];
	}
}