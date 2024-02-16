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
import getSubAccounts from '@salesforce/apex/FollowerOffspringRequestController.getSubAccounts';
import {refreshApex} from "@salesforce/apex";

export default class CreateFollowerOffspringRequest extends NavigationMixin(LightningElement) {
	// can be either charge account ID or billing account ID
	@api recordId;

	// if current context is for billing account or charge account flow
	@api isBillingAccount;

	isEditLoading;
	subAccount;
	countFinalised = 0;
	isABNConfirmation = false;
	isEditView = false;
	isListView = false;
	subAccounts = [];
	_wiredSubAccounts;

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
			this.subAccounts = data.map(item => {
				return {...item, PhysicalAddressStr: item[PHYSICAL_STREET.fieldApiName] + ' ' + item[PHYSICAL_SUBURB.fieldApiName]
						+ ' ' + item[PHYSICAL_STATE.fieldApiName] + ' ' + item[PHYSICAL_POSTCODE.fieldApiName]};
			});

			this.isABNConfirmation = false;
			this.isEditView = false;
			this.isListView = true;
		} else if (data?.length === 0) {
			this.subAccounts = [];
			this.isABNConfirmation = true;
			this.isEditView = false;
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
				// User cancel the request, ABN to be reconfirmed
				this.isABNConfirmation = true;
				this.isEditView = false;
				this.isListView = false;
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