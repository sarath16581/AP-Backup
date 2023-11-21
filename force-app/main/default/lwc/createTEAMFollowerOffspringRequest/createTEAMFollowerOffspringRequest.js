/**
 * @description Wrapper component of creating TEAM follower offspring request
 * @author Harry Wang
 * @date 2023-10-27
 * @group Controller
 * @changelog
 * 2023-10-27 - Harry Wang - Created
 */
import {api, LightningElement, wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import PHYSICAL_STREET from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_Street_Name__c";
import PHYSICAL_SUBURB from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_Suburb__c";
import PHYSICAL_STATE from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_State__c";
import PHYSICAL_POSTCODE from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_Street_Postcode__c";
import MAILING_STREET from "@salesforce/schema/APT_Sub_Account__c.APT_Postal_Address_Street_Name__c";
import MAILING_SUBURB from "@salesforce/schema/APT_Sub_Account__c.APT_Postal_Address_Suburb__c";
import MAILING_STATE from "@salesforce/schema/APT_Sub_Account__c.APT_Postal_Address_State__c";
import MAILING_POSTCODE from "@salesforce/schema/APT_Sub_Account__c.APT_Postal_Address_Street_Postcode__c";
import getSubAccounts from '@salesforce/apex/FollowerOffspringRequestController.getSubAccounts';
import {refreshApex} from "@salesforce/apex";

export default class CreateTeamFollowerOffspringRequest extends NavigationMixin(LightningElement) {
	@api recordId;
	@api isBillingAccount;
	isEditLoading;
	subAccount;
	countFinalized = 0;
	isABNConfirmation = true;
	isEditView = false;
	isListView = false;
	subAccounts = [];
	_wiredSubAccounts;

	/**
	 * Wired sub accounts passed to list view
	 * Private property _wiredSubAccounts used to support manual refresh
	 */
	@wire(getSubAccounts, {leaderAccountId: '$recordId', isBillingAccount: '$isBillingAccount'})
	wiredData(result) {
		const {data, error} = result;
		this._wiredSubAccounts = result;
		if (data) {
			this.subAccounts = data.map(item => {
				return {...item};
			});
			// mapping physical address
			this.subAccounts.forEach(item => {
				item.PhysicalAddress = item[PHYSICAL_STREET.fieldApiName] + ' ' + item[PHYSICAL_SUBURB.fieldApiName]
					+ ' ' + item[PHYSICAL_STATE.fieldApiName] + ' ' + item[PHYSICAL_POSTCODE.fieldApiName];
				item.MailingAddress = item[MAILING_STREET.fieldApiName] + ' ' + item[MAILING_SUBURB.fieldApiName]
					+ ' ' + item[MAILING_STATE.fieldApiName] + ' ' + item[MAILING_POSTCODE.fieldApiName];
			});
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
	 * Navigate to record view using record Id in the event
	 */
	navigateToLeader(event) {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: event.detail,
				actionName: 'view'
			},
		});
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
	 * Handle finalize event from list view - refreshing sub accounts and updating finalized count
	 */
	handleFinalize(event) {
		this.refreshListView();
		this.countFinalized += event.detail;
	}
}