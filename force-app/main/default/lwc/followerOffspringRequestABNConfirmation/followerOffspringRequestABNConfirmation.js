/**
 * @description ABN Confirmation component for follower offspring request
 * @author Harry Wang
 * @date 2023-10-27
 * @group Controller
 * @changelog
 * 2023-10-27 - Harry Wang - Created
 */
import {api, LightningElement, wire} from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import BILLING_ACCOUNT_ABN from "@salesforce/schema/Billing_Account__c.ABN__c";
import BILLING_ACCOUNT_ORG_NAME from "@salesforce/schema/Billing_Account__c.Organisation__r.Name";
import CHARGE_ACCOUNT_ABN from "@salesforce/schema/APT_Charge_Account__c.APT_ABN__c";
import CHARGE_ACCOUNT_ORG_NAME from "@salesforce/schema/APT_Charge_Account__c.APT_Organisation__r.Name";
import CHARGE_ACCOUNT_OPPORTUNITY from "@salesforce/schema/APT_Charge_Account__c.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__c";
import abnConfirmationError from "@salesforce/label/c.StarTrackSubAccountABNConfirmationErrorMessage";
import LightningAlert from "lightning/alert";

const BILLING_ACCOUNT_FIELDS = [BILLING_ACCOUNT_ABN, BILLING_ACCOUNT_ORG_NAME];
const CHARGE_ACCOUNT_FIELDS = [CHARGE_ACCOUNT_ABN, CHARGE_ACCOUNT_ORG_NAME, CHARGE_ACCOUNT_OPPORTUNITY];

export default class FollowerOffspringRequestAbnConfirmation extends LightningElement {
	@api leaderId;
	@api isBillingAccount;
	isABNSame = false;

	/**
	 * Load leader account details
	 */
	@wire(getRecord, { recordId: "$leaderId", fields: "$fields" })
	record({error, data}) {
		if (data) {
			this.recordData = data;
		}
		if (error) {
			console.log(JSON.stringify(error));
		}
	}
	recordData;

	/**
	 * Get fields based on leader account type - used to wire leader account details
	 */
	get fields() {
		console.log(this.leaderId);
		// if else check on $leaderId
		if (this.isBillingAccount === 'true') {
			return BILLING_ACCOUNT_FIELDS;
		}
		return CHARGE_ACCOUNT_FIELDS;
	}

	get accountABN() {
		if (this.recordData) {
			if (this.isBillingAccount === 'true') {
				return {label: 'Leader ABN', value: getFieldValue(this.recordData, BILLING_ACCOUNT_ABN)};
			}
			return {label: 'Leader ABN', value: getFieldValue(this.recordData, CHARGE_ACCOUNT_ABN)};
		}
		return {label: '', value: ''};
	}

	get accountORGName() {
		if (this.recordData) {
			if (this.isBillingAccount === 'true') {
				return  {label: 'Leader Entity Name', value: getFieldValue(this.recordData, BILLING_ACCOUNT_ORG_NAME)};
			}
			return  {label: 'Leader Entity Name', value: getFieldValue(this.recordData, CHARGE_ACCOUNT_ORG_NAME)};
		}
		return {label: '', value: ''};
	}

	get options() {
		return [
			{ label: 'Yes', value: 'yes' },
			{ label: 'No', value: 'no' },
		];
	}

	/**
	 * Enabled next button when selection is made. Update isABNSame attribute
	 */
	handleChange(event) {
		this.template.querySelector('[data-id="next"]').disabled = false;
		const value = event.detail.value;
		if (value === 'yes') {
			this.isABNSame = true;
		} else {
			this.isABNSame = false;
		}
	}

	/**
	 * Notify request wrapper to close current page
	 */
	handleClose() {
		if (this.isBillingAccount === 'true') {
			this.dispatchEvent(new CustomEvent('closed', {detail: this.leaderId}));
		} else {
			this.dispatchEvent(new CustomEvent('closed', {detail: getFieldValue(this.recordData, CHARGE_ACCOUNT_OPPORTUNITY)}));
		}

	}

	/**
	 * Dispatch confirmed event to request wrapper - showing error if ABN is different
	 */
	handleNext() {
		if (this.isABNSame) {
			this.dispatchEvent(new CustomEvent('confirmed'));
		} else {
			const errorMessage = abnConfirmationError;
			LightningAlert.open({
				message: errorMessage,
				theme: 'error',
				variant: 'headerless'
			});
		}
	}
}