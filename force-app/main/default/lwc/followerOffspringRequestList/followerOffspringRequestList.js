/**
 * @description List view component to show list of sub accounts for provided leader account
 * Supported feature: searching on account name and address, editing individual account, mass deleting accounts, sorting
 * @author Harry Wang
 * @date 2023-11-01
 * @group Controller
 * @changelog
 * 2023-11-01 - Harry Wang - Created
 * 2023-12-07 - Ranjeewa Silva - Implemented handler for submit action.
 */
import {api, LightningElement, wire} from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import {getFieldValue, getRecord, deleteRecord} from "lightning/uiRecordApi";
import LightningAlert from 'lightning/alert';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import LightningConfirm from "lightning/confirm";
import {getObjectInfo, getPicklistValues} from "lightning/uiObjectInfoApi";

// field mappings
import BILLING_ACCOUNT_NAME from "@salesforce/schema/Billing_Account__c.Name";
import BILLING_ACCOUNT_NUMBER from "@salesforce/schema/Billing_Account__c.LEGACY_ID__c";
import CHARGE_ACCOUNT_OPPORTUNITY_ID from "@salesforce/schema/APT_Charge_Account__c.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__c";
import CHARGE_ACCOUNT_OPPORTUNITY_NAME from "@salesforce/schema/APT_Charge_Account__c.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__r.Name";
import SUB_ACCOUNT_OBJECT from "@salesforce/schema/APT_Sub_Account__c";
import SUB_ACCOUNT_STAGE from "@salesforce/schema/APT_Sub_Account__c.APT_Sub_Account_Request_Status__c";
import SUB_ACCOUNT_ACCOUNT_TYPE from "@salesforce/schema/APT_Sub_Account__c.AccountType__c";
import SUB_ACCOUNT_PARENT_ACCOUNT_REQUEST from '@salesforce/schema/APT_Sub_Account__c.ParentAccountRequest__c';

// custom labels
import maxFinaliseError from "@salesforce/label/c.StarTrackSubAccountMaxFinalizeErrorMessage";
import LABEL_FINALISE_CONFIRMATION from "@salesforce/label/c.StarTrackSubAccountFinaliseConfirmation";
import LABEL_MAX_SUBMIT_LIMIT_REACHED_ERRORMESSAGE from '@salesforce/label/c.StarTrackSubAccountMaxSubmitLimitReachedErrorMessage';
import LABEL_SUBMIT_FOR_PROVISIONING_CONFIRMATION_MESSAGE from '@salesforce/label/c.StarTrackSubAccountsSubmitConfirmationMessage';
import LABEL_PARENT_NOT_SELECTED_FOR_SUBMIT_ERRORMESSAGE from '@salesforce/label/c.StarTrackSubAccountParentNotSelectedForSubmitErrorMessage';
import LABEL_SUBMIT_NOTIFICATION_TITLE from '@salesforce/label/c.StarTrackSubmitSubAccountRequestsTitle';
import LABEL_SUBMIT_SUCCESSFUL_ALERT from '@salesforce/label/c.StarTrackSubAccountRequestSubmittedSuccessfullyAlert';
import LABEL_SUBMIT_FAILED_TRANSIENT_ERROR_ALERT from '@salesforce/label/c.StarTrackSubAccountRequestFailedTransientErrorAlert';
import LABEL_SUBMIT_FAILED_NONTRANSIENT_ERROR_ALERT from '@salesforce/label/c.StarTrackSubAccountRequestFailedNonTransientErrorAlert';

// custom permission granting ability to submit provisioning requests
import PERMISSION_SUBMIT_PROVISIONREQUESTS from '@salesforce/customPermission/Submit_Billing_Account_Provisioning_Request';
import PERMISSION_SUBMIT_SUBACCOUNT_PROVISIONREQUESTS from '@salesforce/customPermission/Submit_Sub_Account_Provisioning_Request';

// apex controller method calls
import getDatatableColumns from '@salesforce/apex/FollowerOffspringRequestController.retrieveListViewColumns';
import finaliseSubAccounts from '@salesforce/apex/FollowerOffspringRequestController.finaliseSubAccounts';
import generateSubAccountsProvisioningRequest from '@salesforce/apex/ProvisionSTBillingAccountsController.generateSubAccountsProvisioningRequest';
import submitProvisioningRequest from '@salesforce/apexContinuation/ProvisionSTBillingAccountsController.submitProvisioningRequest';

// Row actions
const actions = [
	{label: 'Edit', name: 'edit'},
	{label: 'Delete', name: 'delete'}
];

// Searchable fields
const SEARCHABLE_FIELDS = ['Name', 'PhysicalAddressStr'];

// Max number of requests can be finalised
const MAX_FINALISE_REQUESTS = 10;
const MAX_SUBMIT_REQUESTS = 10;
export default class FollowerOffspringRequestList extends NavigationMixin(LightningElement) {
	// Can be either charge account ID or billing account ID
	@api leaderId;

	// If current context is for billing account or charge account flow
	@api isBillingAccount;

	// Count of requests finalised. Required to trigger max request error
	@api countFinalised;

	// Sub Accounts passed from request wrapper
	@api subAccounts = [];

	// Finalised sub Accounts passed from request wrapper
	@api finalisedSubAccounts;

	columns;
	finalisedColumns;

	// Default sorting is on CreatedDate DESC
	sortBy = 'CreatedDate';
	sortDirection = 'desc';

	picklistMap;
	_filteredSubAccounts;
	searchTerm;
	selectedRows = [];
	isLoading = true;
	_subAccountsByIdMap;

	// navigation bar & submit button
	listViewUrl;
	recordViewUrl;
	listViewLabel;
	recordViewLabel;
	submitLabel;
	backLabel;

	/**
	 *  Load leader account details for navigation bar
	 */
	@wire(getRecord, { recordId: "$leaderId", fields: "$fields" })
	record({error, data}) {
		if (data) {
			if (this.isBillingAccount === 'true') {
				this.listViewLabel = 'Billing Accounts';
				this.listViewUrl = '/lightning/o/Billing_Account__c/list?filterName=Recent';
				const billingAccountNameLabel = getFieldValue(data, BILLING_ACCOUNT_NUMBER) ? ' (' + getFieldValue(data, BILLING_ACCOUNT_NUMBER) + ')' : '';
				this.recordViewLabel = getFieldValue(data, BILLING_ACCOUNT_NAME) + billingAccountNameLabel;
				this.recordViewUrl = '/lightning/r/Billing_Account__c/'+ this.leaderId + '/view';
				this.submitLabel = 'Submit';
				this.backLabel = 'Back to Billing Account';
			} else {
				this.listViewLabel = 'Opportunities';
				this.listViewUrl = '/lightning/o/Opportunity/list?filterName=Recent';
				this.recordViewLabel = getFieldValue(data, CHARGE_ACCOUNT_OPPORTUNITY_NAME);
				this.recordViewUrl = '/lightning/r/Opportunity/'+ getFieldValue(data, CHARGE_ACCOUNT_OPPORTUNITY_ID) + '/view';
				this.submitLabel = 'Finalise Request(s)';
				this.backLabel = 'Back to Opportunity';
			}
		}
		if (error) {
			console.log('Error when loading leader: ' + error);
		}
	}

	/**
	 *  Get sub account object info to wire picklist value
	 */
	@wire(getObjectInfo, {objectApiName: SUB_ACCOUNT_OBJECT})
	subAccountInfo;

	/**
	 *  Get account type picklist API name and label map - required to render the datatable
	 *  Upon receiving load datatable columns
	 */
	@wire(getPicklistValues, {recordTypeId: '$subAccountInfo.data.defaultRecordTypeId', fieldApiName: SUB_ACCOUNT_ACCOUNT_TYPE})
	wiredPicklistValues({data}) {
		this.picklistMap = new Map();
		if (data?.values) {
			data.values.forEach(item => {
				this.picklistMap.set(item.value, item.label);
			});
		}
		if (this.filteredSubAccounts != null) {
			this.filteredSubAccounts.forEach(acc => {
				acc.AccountTypeLabel = this.picklistMap.get(acc[SUB_ACCOUNT_ACCOUNT_TYPE.fieldApiName]);
			});
			//Load columns from server and add Physical Address, Account Type and row actions columns
			getDatatableColumns().then(c => {
				this.columns = c.map(item => {
					return {...item};
				});
				// insert physical address at index 2
				this.columns.splice(2, 0, {label: 'Physical Address', fieldName: 'PhysicalAddressStr', type: 'text', sortable: 'true'});
				// replace AccountType__c with AccountTypeLabel
				this.columns.splice(0, 1, {label: 'Account Type', fieldName: 'AccountTypeLabel', type: 'text', sortable: 'true'})
				this.finalisedColumns = [...this.columns];
				this.columns.push({type: 'action', typeAttributes: {rowActions: actions}});
			}).catch(error => {
				console.error(error);
			});
			this.isLoading = false;
		}
	}

	/**
	 * Get fields based on leader account type - used to wire leader account details
	 */
	get fields() {
		if (this.isBillingAccount === 'true') {
			return [BILLING_ACCOUNT_NAME, BILLING_ACCOUNT_NUMBER];
		}
		return [CHARGE_ACCOUNT_OPPORTUNITY_ID, CHARGE_ACCOUNT_OPPORTUNITY_NAME];
	}

	get hasFinalisedSubAccounts() {
		return this.finalisedSubAccounts != null && this.finalisedSubAccounts?.length > 0;
	}

	get filteredSubAccounts() {
		if (this._filteredSubAccounts == null && this.subAccounts.length > 0) {
			this._filteredSubAccounts = JSON.parse(JSON.stringify(this.subAccounts));
		}
		return this._filteredSubAccounts;
	}

	set filteredSubAccounts(value) {
		this._filteredSubAccounts = value;
	}

	get subAccountsByIdMap() {
		if (!this._subAccountsByIdMap) {
			const subAccountRequestsMap = {};
			 //grab the sub account requests by id so it is easier to access when iterating through the selected sub account requests
			 this.subAccounts.forEach(subAccount => {
				subAccountRequestsMap[subAccount.Id] = subAccount;
			 });
			 this._subAccountsByIdMap = subAccountRequestsMap;
		}
		return this._subAccountsByIdMap;
	}

	get canSubmitForProvisioning() {
		return (this.isBillingAccount === 'true' && this.hasPermissionsToSubmitSubAccountProvisioningRequests);
	}

	get canFinaliseSubAccountRequests() {
		return (this.isBillingAccount !== 'true');
	}

	get hasPermissionsToSubmitSubAccountProvisioningRequests() {
		return (PERMISSION_SUBMIT_PROVISIONREQUESTS || PERMISSION_SUBMIT_SUBACCOUNT_PROVISIONREQUESTS);
	}

	/**
	 * Update filteredSubAccounts based on search term
	 */
	handleSearchChange(event) {
		const searchKey = event.target.value.toLowerCase();
		const subAccountsCopy = JSON.parse(JSON.stringify(this.subAccounts));
		subAccountsCopy.forEach(acc => {
			acc.AccountTypeLabel = this.picklistMap.get(acc[SUB_ACCOUNT_ACCOUNT_TYPE.fieldApiName]);
		});
		if (searchKey) {
			const searchRecords = [];
			subAccountsCopy.forEach(item => {
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
			this.filteredSubAccounts = subAccountsCopy;
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
			case 'delete':
				this.deleteRow(row);
				break;
		}
	}

	handleRowSelection(event) {
		this.selectedRows = event.detail.selectedRows;
	}

	/**
	 * Delete selected sub accounts from datatable and reset selection. Show error if deletion failed.
	 * Dispatch delete event to request wrapper for deletion on server side
	 */
	async deleteRow(row) {
		const result = await LightningConfirm.open({
			message: 'Selected sub account request will be deleted.',
			variant: 'headerless',
			label: 'Sub Account Delete',
		});
		if (result) {
			this.isLoading = true;
			deleteRecord(row.Id).then(() => {
				this.dispatchEvent(new CustomEvent('delete'));
				// delete rows from filteredSubAccounts
				this.filteredSubAccounts = [...this.filteredSubAccounts].filter(item => row.Id !== item.Id);
				this.subAccounts = [...this.subAccounts].filter(item => row.Id !== item.Id);
				this.resetSelection();
				this.dispatchEvent(
					new ShowToastEvent({
						title: "Success",
						message: 'Selected sub account has been deleted.',
						variant: "success",
					})
				);
			}).catch(error =>{
				const errorMessages = JSON.stringify(error).match(/(?<="message":")(.*?)(?=")/g).join(' ');
				if (errorMessages) {
					this.dispatchEvent(
						new ShowToastEvent({
							title: "An error occurred while deleting the selected record.",
							message: errorMessages,
							label: "Deleting Sub Account Request Error",
						})
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
	 * Update selected sub accounts status to 'Pending Charge Account' and dispatch finalise event to request wrapper
	 * User can select up to MAX_FINALISE_REQUESTS records in one go
	 * Show errors if any failures
	 */
	async handleSubmit() {
		const text = this.isBillingAccount === 'true' ? 'submitted' : 'finalised';
		const result = await LightningConfirm.open({
			message: this.selectedRows?.length + ' selected sub account request(s) will be ' + text,
			variant: 'headerless',
			label: 'Sub Accounts Submit/Finalise',
		});
		if (result) {
			if (this.isBillingAccount === 'true') {
				// TODO: Submit
			} else {
				// validate if finalise calls reach the max finalise request
				if (this.selectedRows.length > MAX_FINALISE_REQUESTS - this.countFinalised) {
					await LightningAlert.open({
						message: maxFinaliseError,
						theme: 'error',
						label: 'Finalising Request(s) Error'
					});
					return;
				}
				// update charge account sub account status to Pending Charge Account
				const chargeAccountSubAccounts = this.selectedRows.map(item => {
					return {Id: item.Id, [SUB_ACCOUNT_STAGE.fieldApiName]: 'Pending Charge Account'};
				});
				// extract IDs to refresh list view
				const ids = chargeAccountSubAccounts.map(item => item.Id);

				// finalise charge account sub accounts
				if (chargeAccountSubAccounts.length > 0) {
					this.isLoading = true;
					finaliseSubAccounts({subAccounts: chargeAccountSubAccounts})
						.then(() => {
							this.dispatchEvent(
								new ShowToastEvent({
									title: "Success",
									message: this.selectedRows?.length + ' selected sub account(s) have been finalised.',
									variant: "success",
								})
							);
							this.dispatchEvent(new CustomEvent('finalise', {detail: chargeAccountSubAccounts.length}));
							// delete rows from filteredSubAccounts and subAccounts
							this.filteredSubAccounts = [...this.filteredSubAccounts].filter(item => !ids.includes(item.Id));
							this.subAccounts = [...this.subAccounts].filter(item => !ids.includes(item.Id));
							this.resetSelection();
							this.countFinalised = this.countFinalised + chargeAccountSubAccounts.length;
						}).catch(error =>{
						const errorMessages = JSON.stringify(error).match(/(?<="message":")(.*?)(?=")/g).join(' ');
						if (errorMessages) {
							this.dispatchEvent(
								new ShowToastEvent({
									title: "An error occurred while finalizing record(s).",
									message: errorMessages,
									variant: "error",
								})
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

	/**
	 * Validates selection before submitting for provisioning. Any validation errors are presented back to the user as alerts.
	 * @return true if no validation errors and user has acknowledged the submit action, false otherwise.
	 */
	async validateSubmitForProvisioning() {
		if (this.selectedRows.length > MAX_SUBMIT_REQUESTS) {
			await LightningAlert.open({
				message: LABEL_MAX_SUBMIT_LIMIT_REACHED_ERRORMESSAGE,
				theme: 'error',
				label: LABEL_SUBMIT_NOTIFICATION_TITLE
			});
			return false;
		}

		if (!this.validateRelatedParentAccountRequestsSelected()) {
			await LightningAlert.open({
				message: LABEL_PARENT_NOT_SELECTED_FOR_SUBMIT_ERRORMESSAGE,
				theme: 'error',
				label: LABEL_SUBMIT_NOTIFICATION_TITLE
			});
			return false;
		}

		const result = await LightningConfirm.open({
			message: (this.selectedRows.length + ' ' + LABEL_SUBMIT_FOR_PROVISIONING_CONFIRMATION_MESSAGE),
			theme: 'inverse',
			label: LABEL_SUBMIT_NOTIFICATION_TITLE
		});
		return result;
	}

	/**
	 * Checks of all parent account requests referenced in offspring sub accounts are also being submitted for provisioning.
	 * @return true if all parent account requests are also submitted. false otherwise.
	 */
	validateRelatedParentAccountRequestsSelected() {
		const selectedIds = this.selectedRows.map(item => item.Id);

		const allParentsSelected = this.selectedRows.reduce((validSoFar, subAccountRequest) => {
			const parentAccountRequestId = subAccountRequest[SUB_ACCOUNT_PARENT_ACCOUNT_REQUEST.fieldApiName];
			return !(parentAccountRequestId && this.subAccountsByIdMap[parentAccountRequestId] && !selectedIds.includes(parentAccountRequestId));
		}, true);

		return allParentsSelected;
	}
}