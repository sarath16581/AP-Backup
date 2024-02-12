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
import LABEL_FINALISE_NOTIFICATION_TITLE from "@salesforce/label/c.StarTrackFinaliseSubAccountRequestsTitle";
import LABEL_MAX_FINALISE_LIMIT_ERROR from "@salesforce/label/c.StarTrackSubAccountMaxFinalizeErrorMessage";
import LABEL_FINALISE_CONFIRMATION from "@salesforce/label/c.StarTrackSubAccountFinaliseConfirmation";
import LABEL_PARENT_NOT_SELECTED_FOR_FINALISE_ERROR from "@salesforce/label/c.StarTrackSubAccountParentNotSelectedForFinaliseError";
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
	_subAccounts = [];
	@api get subAccounts() {
		return this._subAccounts;
	}
	set subAccounts(val) {
		// state/catch of below need reset whenever subAccounts are changed from parent.
		// Those changes may because the list is triggered from different parent(leader) or
		// deletion, submission, or finalisation on the sub accounts
		this._computedSubAccounts = null;
		this._filteredSubAccounts = null;
		this._submittedSubAccountsList = null;
		this._finalisedSubAccountsList = null;
		this.searchTerm = null;

		this._subAccounts = val;
	}

	// datatable
	columns;
	readOnlyColumns;
	sortBy;
	sortDirection;
	searchTerm;
	selectedRows = [];

	// a deep clone of subAccounts with Account Type label mapped
	// this list is used to compute filtered, finalised and submitted lists
	_computedSubAccounts;

	// filtered from computedSubAccounts. Used as data source of draft/error sub account requests
	// need to be reactive whenever computedSubAccounts is updated
	_filteredSubAccounts;

	// filtered from computedSubAccounts. Used as data source of submitted sub account requests
	// need to be reactive whenever computedSubAccounts is updated
	_finalisedSubAccountsList;

	// filtered from computedSubAccounts. Used as data source of finalised sub account requests
	// need to be reactive whenever computedSubAccounts is updated
	_submittedSubAccountsList;

	isLoading = true;
	_subAccountsByIdMap;

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
	picklistMap;
	@wire(getPicklistValues, {recordTypeId: '$subAccountInfo.data.defaultRecordTypeId', fieldApiName: SUB_ACCOUNT_ACCOUNT_TYPE})
	wiredPicklistValues({data}) {
		if (data?.values) {
			this.picklistMap = new Map();
			data.values.forEach(item => {
				this.picklistMap.set(item.value, item.label);
			});
		}

		if (!this.columns) {
			//Load columns from server and add Physical Address, Account Type and row actions columns
			getDatatableColumns().then(c => {
				this.columns = c.map(item => {
					return {...item};
				});
				// insert physical address at index 2
				this.columns.splice(2, 0, {label: 'Physical Address', fieldName: 'PhysicalAddressStr', type: 'text', sortable: 'true'});
				// replace AccountType__c with AccountTypeLabel
				this.columns.splice(0, 1, {label: 'Account Type', fieldName: 'AccountTypeLabel', type: 'text', sortable: 'true'})
				this.readOnlyColumns = [...this.columns];
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

	get computedSubAccounts() {
		if (this._computedSubAccounts) {
			return this._computedSubAccounts;
		}
		if (this.picklistMap && this.subAccounts?.length > 0) {
			// map account type label
			this._computedSubAccounts = this.subAccounts.map(item => {
				return {...item, AccountTypeLabel: this.picklistMap?.get(item[SUB_ACCOUNT_ACCOUNT_TYPE.fieldApiName])};
			});
		}
		return this._computedSubAccounts;
	}

	get hasFinalisedSubAccounts() {
		return this.finalisedSubAccountsList?.length > 0;
	}

	get hasSubmittedSubAccounts() {
		return this.submittedSubAccountsList?.length > 0;
	}

	get filteredSubAccounts() {
		if (this._filteredSubAccounts) {
			return this._filteredSubAccounts;
		}

		if (!this._filteredSubAccounts && this.computedSubAccounts?.length > 0) {
			this._filteredSubAccounts = this.computedSubAccounts?.filter(item => item[SUB_ACCOUNT_STAGE.fieldApiName] === 'Error' || item[SUB_ACCOUNT_STAGE.fieldApiName] === 'Draft');
		}
		// filter records based on the search term
		if (this.searchTerm) {
			this._filteredSubAccounts = this._filteredSubAccounts.filter(item => {
				for (const field of SEARCHABLE_FIELDS) {
					const fieldValueStr = item[field].toLowerCase();
					if (fieldValueStr.includes(this.searchTerm.toLowerCase())) {
						return true;
					}
				}
				return false;
			});
		}
		if (this.sortBy) {
			this.sortData(this.sortBy, this.sortDirection);
		}

		return this._filteredSubAccounts;
	}

	get finalisedSubAccountsList() {
		if (!this._finalisedSubAccountsList && this.computedSubAccounts?.length > 0) {
			this._finalisedSubAccountsList = this.computedSubAccounts?.filter(item => item[SUB_ACCOUNT_STAGE.fieldApiName] === 'Pending Charge Account');
		}
		return this._finalisedSubAccountsList;
	}

	get submittedSubAccountsList() {
		if (!this._submittedSubAccountsList && this.computedSubAccounts?.length > 0) {
			this._submittedSubAccountsList = this.computedSubAccounts?.filter(item => item[SUB_ACCOUNT_STAGE.fieldApiName] === 'Submitted');
		}
		return this._submittedSubAccountsList;
	}

	set submittedSubAccountsList(value) {
		this._submittedSubAccountsList = value;
	}

	get subAccountsByIdMap() {
		if (!this._subAccountsByIdMap) {
			const subAccountRequestsMap = {};
			//grab the sub account requests by id so it is easier to access when iterating through the selected sub account requests
			this.errorDraftSubAccounts?.forEach(subAccount => {
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
		this.searchTerm = event.target.value;
		// invalidate the state/cache, so it can be rebuilt based on the search term
		this._filteredSubAccounts = null;
	}

	get searchCount() {
		let text = this.errorDraftSubAccounts?.length + ' account requests';
		if (this.filteredSubAccounts && this.template.querySelector('lightning-input')?.value) {
			text = this.filteredSubAccounts.length + ' of ' + text;
		}
		return text;
	}

	get selectCount() {
		return this.selectedRows.length + ' selected';
	}

	get hasErrorDraftSubAccounts() {
		return this.errorDraftSubAccounts?.length > 0;
	}

	get errorDraftSubAccounts() {
		return this.computedSubAccounts?.filter(item => item[SUB_ACCOUNT_STAGE.fieldApiName] === 'Error' || item[SUB_ACCOUNT_STAGE.fieldApiName] === 'Draft');
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
		this._filteredSubAccounts = null;
	}

	/**
	 * Dispatch edit event with updated sub account to request wrapper for updating on server side
	 */
	editRow(row) {
		this._filteredSubAccounts = null;
		this.dispatchEvent(new CustomEvent('edit', {
			detail : row
		}));
		this._filteredSubAccounts = null;
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
		this._filteredSubAccounts = parseData;
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
			label: LABEL_FINALISE_NOTIFICATION_TITLE,
		});
		if (result) {
			// validate if finalise calls reach the max finalise request
			if (this.selectedRows.length > MAX_FINALISE_REQUESTS - this.countFinalised) {
				await LightningAlert.open({
					message: LABEL_MAX_FINALISE_LIMIT_ERROR,
					theme: 'error',
					label: LABEL_FINALISE_NOTIFICATION_TITLE
				});
				return;
			}

			// validate if parent is selected for offspring follower
			if (!this.validateRelatedParentAccountRequestsSelected()) {
				await LightningAlert.open({
					message: LABEL_PARENT_NOT_SELECTED_FOR_FINALISE_ERROR,
					theme: 'error',
					label: LABEL_FINALISE_NOTIFICATION_TITLE
				});
				return;
			}

			// update charge account sub account status to Pending Charge Account
			const chargeAccountSubAccounts = this.selectedRows.map(item => {
				return {Id: item.Id, [SUB_ACCOUNT_STAGE.fieldApiName]: 'Pending Charge Account'};
			});

			// finalise charge account sub accounts
			if (chargeAccountSubAccounts.length > 0) {
				this.isLoading = true;
				finaliseSubAccounts({subAccounts: chargeAccountSubAccounts})
					.then(() => {
						LightningAlert.open({
							message: this.selectedRows?.length + ' selected sub account request(s) have been finalised.',
							theme: 'success',
							label: LABEL_FINALISE_NOTIFICATION_TITLE
						});

						this.dispatchEvent(new CustomEvent('finalise', {detail: chargeAccountSubAccounts.length}));
						this.resetSelection();

						this.countFinalised = this.countFinalised + chargeAccountSubAccounts.length;
					}).catch(error =>{
					const errorMessages = JSON.stringify(error).match(/(?<="message":")(.*?)(?=")/g).join(' ');
					if (errorMessages) {
						LightningAlert.open({
							message: errorMessages,
							theme: 'error',
							label: LABEL_FINALISE_NOTIFICATION_TITLE
						});
					}
				}).finally(() =>{
					this.isLoading = false;
				});
			}
		}
	}

	/**
	 * Handler for submitting selected sub account requests for provisioning. Validates the number of records selected is
	 * with in the limit allowed for submission at one time. Also checks if un provisioned parent account requests are
	 * selected for the selected off spring accounts.
	 */
	handleSubmitForProvisioning() {

		// check if selected requests meet the validation requirements.
		this.validateSubmitForProvisioning()
			.then(validationResult => {
				if (validationResult) {
					// extract selected request ids
					const selectedIds = this.selectedRows.map(item => item.Id);

					this.isLoading = true;
					generateSubAccountsProvisioningRequest({leaderBillingAccountId: this.leaderId, subAccountRequestIds: selectedIds})
						.then(generateRequestResult => {
							let provisioningStatus;
							submitProvisioningRequest({
								request: generateRequestResult.requestPayload,
								externalOnboardingRequestId: generateRequestResult.externalOnboardingRequestId
							}).then(resp => {
								if (resp.isSuccess) {
									provisioningStatus = {isSuccess: true, label: LABEL_SUBMIT_NOTIFICATION_TITLE, message: LABEL_SUBMIT_SUCCESSFUL_ALERT, theme: 'success'};
								} else if (resp.isRetryable) {
									provisioningStatus = {isSuccess: false, label: LABEL_SUBMIT_NOTIFICATION_TITLE, message: LABEL_SUBMIT_FAILED_TRANSIENT_ERROR_ALERT, theme: 'error'};
								} else {
									provisioningStatus = {isSuccess: false, label: LABEL_SUBMIT_NOTIFICATION_TITLE, message: LABEL_SUBMIT_FAILED_NONTRANSIENT_ERROR_ALERT, theme: 'error'};
								}
							}).catch(error => {
								provisioningStatus = {isSuccess: false, label: LABEL_SUBMIT_NOTIFICATION_TITLE,message: 'Unexpected Error : ' + error.body.message, theme: 'error'};
							}).finally(() =>{
								// show alert with appropriate messaging (success, error)
								this.isLoading = false;
								LightningAlert.open({
									message: provisioningStatus.message,
									theme: provisioningStatus.theme,
									label: provisioningStatus.label
								}).then(result => {
									// user has acknowledged the alert. if the provisioning request has been submitted successfully
									// update the table and navigate back to the leader billing account. in all other cases stay on sub account list view.
									if (provisioningStatus.isSuccess) {
										// Dispatch refresh apex event to parent
										this.dispatchEvent(new CustomEvent('submit'));
										this.resetSelection();

										this[NavigationMixin.Navigate]({
											type: 'standard__recordPage',
											attributes: {
												recordId: this.leaderId,
												objectApiName: 'Billing_Account__c',
												actionName: 'view'
											}
										});
									}
								});
							});
						}).catch(error => {
							this.isLoading = false;
							LightningAlert.open({
								message: 'Unexpected error : ' + error.body.message,
								theme: 'error',
								label: LABEL_SUBMIT_NOTIFICATION_TITLE
							});
						});
				}
			});
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