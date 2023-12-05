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

// custom labels
import LABEL_MAX_FINALISE_LIMIT_ERROR from "@salesforce/label/c.StarTrackSubAccountMaxFinalizeErrorMessage";
import LABEL_FINALISE_CONFIRMATION from "@salesforce/label/c.StarTrackSubAccountFinaliseConfirmation";

// apex controller method calls
import getDatatableColumns from '@salesforce/apex/FollowerOffspringRequestController.retrieveListViewColumns';
import finaliseSubAccounts from '@salesforce/apex/FollowerOffspringRequestController.finaliseSubAccounts';

// Row actions
const actions = [
	{label: 'Edit', name: 'edit'},
	{label: 'Delete', name: 'delete'}
];

// Searchable fields
const SEARCHABLE_FIELDS = ['Name', 'PhysicalAddressStr'];

// Max number of requests can be finalised
const MAX_FINALISE_REQUESTS = 10;
export default class FollowerOffspringRequestList extends LightningElement {
	// Can be either charge account ID or billing account ID
	@api leaderId;

	// If current context is for billing account or charge account flow
	@api isBillingAccount;

	// Count of requests finalised. Required to trigger max request error
	@api countFinalised;

	// Sub Accounts passed from request wrapper
	@api subAccounts = [];

	// Finalised sub Accounts passed from request wrapper
	@api finalisedSubAccounts = [];

	columns;
	finalisedColumns;

	// Default sorting is on CreatedDate DESC
	sortBy = 'CreatedDate';
	sortDirection = 'desc';

	picklistMap;
	_filteredSubAccounts;
	_finalisedSubAccountsList;
	searchTerm;
	selectedRows = [];
	isLoading = true;

	// navigation bar & submit button
	listViewUrl;
	recordViewUrl;
	listViewLabel;
	recordViewLabel;
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
				this.backLabel = 'Back to Billing Account';
			} else {
				this.listViewLabel = 'Opportunities';
				this.listViewUrl = '/lightning/o/Opportunity/list?filterName=Recent';
				this.recordViewLabel = getFieldValue(data, CHARGE_ACCOUNT_OPPORTUNITY_NAME);
				this.recordViewUrl = '/lightning/r/Opportunity/'+ getFieldValue(data, CHARGE_ACCOUNT_OPPORTUNITY_ID) + '/view';
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

		if (this.hasFinalisedSubAccounts) {
			this.finalisedSubAccountsList.forEach(acc => {
				acc.AccountTypeLabel = this.picklistMap.get(acc[SUB_ACCOUNT_ACCOUNT_TYPE.fieldApiName]);
			});
		}

		if (this.hasFilteredSubAccounts) {
			this.filteredSubAccounts.forEach(acc => {
				acc.AccountTypeLabel = this.picklistMap.get(acc[SUB_ACCOUNT_ACCOUNT_TYPE.fieldApiName]);
			});
		}

		if (this.hasFinalisedSubAccounts || this.hasFilteredSubAccounts) {
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
			window.scroll(0, 0);
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
		return this.finalisedSubAccountsList?.length > 0;
	}

	get hasFilteredSubAccounts() {
		return this.filteredSubAccounts?.length > 0;
	}

	get filteredSubAccounts() {
		if (this._filteredSubAccounts == null && this.subAccounts?.length > 0) {
			this._filteredSubAccounts = JSON.parse(JSON.stringify(this.subAccounts));
		}
		return this._filteredSubAccounts;
	}

	set filteredSubAccounts(value) {
		this._filteredSubAccounts = value;
	}

	get finalisedSubAccountsList() {
		if (this._finalisedSubAccountsList == null && this.finalisedSubAccounts?.length > 0) {
			this._finalisedSubAccountsList = JSON.parse(JSON.stringify(this.finalisedSubAccounts));
		}
		return this._finalisedSubAccountsList;
	}

	set finalisedSubAccountsList(value) {
		this._finalisedSubAccountsList = value;
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
			label: 'Delete Sub Account Request',
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
	async handleFinalise() {
		const result = await LightningConfirm.open({
			message: 'Do you want to Finalise ' + this.selectedRows?.length + ' sub account requests? ' + LABEL_FINALISE_CONFIRMATION,
			theme: 'inverse',
			label: 'Finalise Sub Account Request(s)',
		});
		if (result) {
			// validate if finalise calls reach the max finalise request
			if (this.selectedRows.length > MAX_FINALISE_REQUESTS - this.countFinalised) {
				await LightningAlert.open({
					message: LABEL_MAX_FINALISE_LIMIT_ERROR,
					theme: 'error',
					label: 'Finalise Sub Account Request(s)'
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
						LightningAlert.open({
							message: this.selectedRows?.length + ' selected sub account request(s) have been finalised.',
							theme: 'success',
							label: 'Finalise Sub Account Request(s)'
						});

						this.dispatchEvent(new CustomEvent('finalise', {detail: chargeAccountSubAccounts.length}));
						// delete selected rows from filteredSubAccounts and subAccounts
						this.filteredSubAccounts = [...this.filteredSubAccounts].filter(item => !ids.includes(item.Id));
						this.subAccounts = [...this.subAccounts].filter(item => !ids.includes(item.Id));

						// add selected rows to finalised sub accounts
						const updatedFinalisedSubAccounts = [...this.selectedRows].map(i => {
							i[SUB_ACCOUNT_STAGE.fieldApiName] = 'Pending Charge Account';
							return i;
						});
						this.finalisedSubAccountsList = this.hasFinalisedSubAccounts ? updatedFinalisedSubAccounts.concat([...this.finalisedSubAccountsList]) : [...updatedFinalisedSubAccounts];

						// reset selection
						this.resetSelection();
						this.countFinalised = this.countFinalised + chargeAccountSubAccounts.length;
					}).catch(error =>{
					const errorMessages = JSON.stringify(error).match(/(?<="message":")(.*?)(?=")/g).join(' ');
					if (errorMessages) {
						LightningAlert.open({
							message: errorMessages,
							theme: 'error',
							label: 'Finalise Sub Account Request(s)'
						});
					}
				}).finally(() =>{
					this.isLoading = false;
				});
			}
		}
	}

	handleSubmitForProvisioning() {

	    this.validateSubmitForProvisioning().then(result => {
	        if (result) {
		        // extract selected request ids
                const selectedIds = this.selectedRows.map(item => item.Id);

                //let provisioningStatus = {isSuccess: true, label: LABEL_SUBMITTED_SUCCESSFULLY_MESSAGE, message: LABEL_SUBMITTED_SUCCESSFULLY_INSTRUCTIONS, theme: 'success'};
                //let provisioningStatus = {isSuccess: false, label: LABEL_SUBMIT_TRANSIENT_ERROR_ERRORMESSAGE, message: LABEL_SUBMIT_TRANSIENT_ERROR_INSTRUCTIONS, theme: 'error'};
                //let provisioningStatus = {isSuccess: false, label: LABEL_SUBMIT_NON_TRANSIENT_ERROR_ERRORMESSAGE, message: LABEL_SUBMIT_NONTRANSIENT_ERROR_INSTRUCTIONS, theme: 'error'};
                //let provisioningStatus = {isSuccess: false, label: 'Sub Account Request(s) Submit Error', theme: 'error'};
                /*LightningAlert.open({
                    message: provisioningStatus.message,
                    theme: provisioningStatus.theme,
                    label: provisioningStatus.label
                }).then(result => {
                    //TODO handle navigation
                    console.log(result);
                });*/

                this.isLoading = true;
                generateSubAccountsProvisioningRequest({leaderBillingAccountId: this.leaderId, subAccountRequestIds: selectedIds})
	                .then(result => {
	                    let provisioningStatus;
	                    submitProvisioningRequest({
	                        request: result.requestPayload,
	                        externalOnboardingRequestId: result.externalOnboardingRequestId
	                    }).then(resp => {
	                        if (resp.isSuccess) {
	                            provisioningStatus = {isSuccess: true, label: LABEL_SUBMITTED_SUCCESSFULLY_MESSAGE, message: LABEL_SUBMITTED_SUCCESSFULLY_INSTRUCTIONS, theme: 'success'};
	                        } else if (resp.isRetryable) {
	                            provisioningStatus = {isSuccess: false, label: LABEL_SUBMIT_TRANSIENT_ERROR_ERRORMESSAGE, message: LABEL_SUBMIT_TRANSIENT_ERROR_INSTRUCTIONS, theme: 'error'};
	                        } else {
	                            provisioningStatus = {isSuccess: false, label: LABEL_SUBMIT_NON_TRANSIENT_ERROR_ERRORMESSAGE, message: LABEL_SUBMIT_NONTRANSIENT_ERROR_INSTRUCTIONS, theme: 'error'};

                            }
	                    }).catch(error => {
							provisioningStatus = {isSuccess: false, label: 'Sub Account Request(s) Submit Error',message: 'Unexpected Error : ' + error.body.message, theme: 'error'};
	                    }).finally(() =>{
	                        this.isLoading = false;
	                        if (provisioningStatus) {
	                            LightningAlert.open({
                                    message: provisioningStatus.message,
                                    theme: provisioningStatus.theme,
                                    label: provisioningStatus.label
                                }).then(result => {
                                    //TODO handle navigation
                                    console.log(result);
                                });
                            }
                        });
	                }).catch(error => {
	                    this.isLoading = false;
	                    LightningAlert.open({
                            message: 'Unexpected error : ' + error.body.message,
                            theme: 'error',
                            label: 'Sub Account Request(s) Submit Error'
                        }).then(result => {
                            //TODO handle navigation
                            console.log(result);
                        });
	                });

            }
		});
    }

	resetSelection() {
		this.template.querySelector('lightning-datatable').selectedRows = [];
		this.selectedRows = [];
	}
}