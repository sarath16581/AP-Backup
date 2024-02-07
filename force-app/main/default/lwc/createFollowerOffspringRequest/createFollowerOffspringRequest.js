/**
 * @description Wrapper component of creating TEAM follower offspring request
 * @author Harry Wang
 * @date 2023-10-27
 * @group Controller
 * @changelog
 * 2023-10-27 - Harry Wang - Created
 */
import {api, LightningElement, wire} from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import PHYSICAL_STREET from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_Street_Name__c";
import PHYSICAL_SUBURB from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_Suburb__c";
import PHYSICAL_STATE from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_State__c";
import PHYSICAL_POSTCODE from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_Street_Postcode__c";
import STATUS from "@salesforce/schema/APT_Sub_Account__c.APT_Sub_Account_Request_Status__c";
import getSubAccounts from '@salesforce/apex/FollowerOffspringRequestController.getSubAccounts';
import {refreshApex} from "@salesforce/apex";

export default class CreateFollowerOffspringRequest extends NavigationMixin(LightningElement) {
	// Can be either charge account ID or billing account ID
	@api recordId;

	// If current context is for billing account or charge account flow
	@api isBillingAccount;

	isEditLoading;
	subAccount;
	countFinalised = 0;
	isABNConfirmation = false;
	isEditView = false;
	isListView = false;
	subAccounts = [];
	_wiredSubAccounts;
	finalisedSubAccounts;
	submittedSubAccounts;

	/**
	 * Wired sub accounts passed to list view
	 * Private property _wiredSubAccounts used to support manual refresh
	 * If sub accounts is not empty open list view otherwise open edit view
	 */
	@wire(getSubAccounts, {leaderAccountId: '$recordId', isBillingAccount: '$isBillingAccount'})
	wiredData(result) {
		const {data, error} = result;
		this._wiredSubAccounts = result;
		if (data?.length > 0) {
			this.subAccounts = data.filter(item => item[STATUS.fieldApiName] === 'Error' || item[STATUS.fieldApiName] === 'Draft').map(item => {
				return {...item};
			});
			this.subAccounts.forEach(item => {
				item.PhysicalAddressStr = item[PHYSICAL_STREET.fieldApiName] + ' ' + item[PHYSICAL_SUBURB.fieldApiName]
					+ ' ' + item[PHYSICAL_STATE.fieldApiName] + ' ' + item[PHYSICAL_POSTCODE.fieldApiName];
			});

			this.finalisedSubAccounts = data.filter(item => item[STATUS.fieldApiName] === 'Pending Charge Account')
				.map(item => {
					return {...item};
			});
			this.finalisedSubAccounts.forEach(item => {
				item.PhysicalAddressStr = item[PHYSICAL_STREET.fieldApiName] + ' ' + item[PHYSICAL_SUBURB.fieldApiName]
					+ ' ' + item[PHYSICAL_STATE.fieldApiName] + ' ' + item[PHYSICAL_POSTCODE.fieldApiName];
			});

			this.submittedSubAccounts = data.filter(item => item[STATUS.fieldApiName] === 'Submitted')
				.map(item => {
					return {...item};
				});
			this.submittedSubAccounts.forEach(item => {
				item.PhysicalAddressStr = item[PHYSICAL_STREET.fieldApiName] + ' ' + item[PHYSICAL_SUBURB.fieldApiName]
					+ ' ' + item[PHYSICAL_STATE.fieldApiName] + ' ' + item[PHYSICAL_POSTCODE.fieldApiName];
			});

			this.isABNConfirmation = false;
			this.isListView = true;
		} else if (data?.length === 0) {
			this.isABNConfirmation = true;
			this.isListView = false;
		} else if (error) {
			console.error(error);
		}
	}

	/**
	 *  Show and load edit view
	 */
	handleEditSubAccount(event) {
		this.subAccount = event?.detail;
		this.isEditLoading = true;
		this.isABNConfirmation = false;
		this.isEditView = true;
		this.isListView = false;
	}

	/**
	 *  Show and load ABN confirmation view
	 */
	handleNewSubAccount() {
		this.isABNConfirmation = true;
		this.isListView = false;
	}

	/**
	 * Navigate to record view if sub accounts is not empty otherwise go back to list view
	 */
	handleCancel(event) {
		if (event?.detail) {
			if (this.subAccounts.length === 0) {
				this[NavigationMixin.Navigate]({
					type: 'standard__recordPage',
					attributes: {
						recordId: event.detail,
						actionName: 'view'
					},
				});
			} else {
				this.isABNConfirmation = false;
				this.isEditView = false;
				this.isListView = true;
			}
		}
	}

	/**
	 * Manual refresh sub accounts and show list view
	 */
	refreshListView() {
		refreshApex(this._wiredSubAccounts).then(() => {
			this.isABNConfirmation = false;
			this.isEditView = false;
			this.isListView = true;
		});
	}

	/**
	 * Handle finalise event from list view - refreshing sub accounts and updating finalised count
	 */
	handleFinalise(event) {
		this.refreshListView();
		this.countFinalised += event.detail;
	}

	/**
	 * Handle submit event from list view - refreshing sub accounts
	 */
	handleSubmit() {
		this.refreshListView();
	}
}