/**
 * @description Edit form component for follower offspring TEAM request
 * @author Harry Wang
 * @date 2023-10-27
 * @group Controller
 * @changelog
 * 2023-10-27 - Harry Wang - Created
 */
import {api, LightningElement, wire} from 'lwc';
import {getFieldValue, getRecord} from "lightning/uiRecordApi";
import BILLING_ACCOUNT_NAME from "@salesforce/schema/Billing_Account__c.Name";
import BILLING_ACCOUNT_ORG_NAME from "@salesforce/schema/Billing_Account__c.Organisation__r.Name";
import BILLING_ACCOUNT_NUMBER from "@salesforce/schema/Billing_Account__c.LEGACY_ID__c";
import BILLING_ACCOUNT_CUSTOMER_NUMBER from "@salesforce/schema/Billing_Account__c.Customer_Number__c";
import CHARGE_ACCOUNT_OPPORTUNITY_NAME from "@salesforce/schema/APT_Charge_Account__c.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__r.Name";
import CHARGE_ACCOUNT_ORG_NAME from "@salesforce/schema/APT_Charge_Account__c.APT_Organisation__r.Name";
import CHARGE_ACCOUNT_REQUEST_NUMBER from "@salesforce/schema/APT_Charge_Account__c.Name";
import CHARGE_ACCOUNT_CUSTOMER_NUMBER from "@salesforce/schema/APT_Charge_Account__c.APT_Organisation__r.Customer_Number__c";
import CHARGE_ACCOUNT_OPPORTUNITY from "@salesforce/schema/APT_Charge_Account__c.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__c";
import CHARGE_ACCOUNT_OPPORTUNITY_KEY_CONTACT from "@salesforce/schema/APT_Charge_Account__c.APT_Quote_Proposal__r.Apttus_Proposal__Opportunity__r.KeyContact__c";
import SUB_ACCOUNT_OBJECT from "@salesforce/schema/APT_Sub_Account__c";
import SUB_ACCOUNT_NAME from "@salesforce/schema/APT_Sub_Account__c.Name";
import SUB_ACCOUNT_CONTACT from "@salesforce/schema/APT_Sub_Account__c.SubAccountContact__c";
import SUB_ACCOUNT_ACCOUNT_TYPE from "@salesforce/schema/APT_Sub_Account__c.AccountType__c";
import SUB_ACCOUNT_IS_LOGIN_REQUIRED from "@salesforce/schema/APT_Sub_Account__c.Is_Parcel_Send_Login_Required__c";
import SUB_ACCOUNT_PARENT_BILLING_ACCOUNT from "@salesforce/schema/APT_Sub_Account__c.ParentBillingAccount__c";
import SUB_ACCOUNT_LEADER_BILLING_ACCOUNT from "@salesforce/schema/APT_Sub_Account__c.APT_Billing_Account__c";
import SUB_ACCOUNT_PARENT_CHARGE_ACCOUNT from "@salesforce/schema/APT_Sub_Account__c.ParentAccountRequest__c";
import SUB_ACCOUNT_LEADER_CHARGE_ACCOUNT from "@salesforce/schema/APT_Sub_Account__c.APT_Charge_Account__c";
import SUB_ACCOUNT_CONTACT_TEL from "@salesforce/schema/APT_Sub_Account__c.APT_Sub_Account_Contact_Telephone__c";
import SUB_ACCOUNT_CONTACT_EMAIL from "@salesforce/schema/APT_Sub_Account__c.APT_Sub_Account_Contact_Email_Address__c";
import SUB_ACCOUNT_PHYSICAL_STREET from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_Street_Name__c";
import SUB_ACCOUNT_PHYSICAL_SUBURB from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_Suburb__c";
import SUB_ACCOUNT_PHYSICAL_STATE from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_State__c";
import SUB_ACCOUNT_PHYSICAL_POSTCODE from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_Street_Postcode__c";
import SUB_ACCOUNT_MAILING_STREET from "@salesforce/schema/APT_Sub_Account__c.APT_Postal_Address_Street_Name__c";
import SUB_ACCOUNT_MAILING_SUBURB from "@salesforce/schema/APT_Sub_Account__c.APT_Postal_Address_Suburb__c";
import SUB_ACCOUNT_MAILING_STATE from "@salesforce/schema/APT_Sub_Account__c.APT_Postal_Address_State__c";
import SUB_ACCOUNT_MAILING_POSTCODE from "@salesforce/schema/APT_Sub_Account__c.APT_Postal_Address_Street_Postcode__c";
import SUB_ACCOUNT_STAGE from "@salesforce/schema/APT_Sub_Account__c.APT_Sub_Account_Request_Status__c";
import {createRecord} from "lightning/uiRecordApi";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

const BILLING_ACCOUNT_FIELDS = [BILLING_ACCOUNT_NAME, BILLING_ACCOUNT_ORG_NAME, BILLING_ACCOUNT_NUMBER, BILLING_ACCOUNT_CUSTOMER_NUMBER];
const CHARGE_ACCOUNT_FIELDS = [CHARGE_ACCOUNT_OPPORTUNITY_NAME, CHARGE_ACCOUNT_ORG_NAME, CHARGE_ACCOUNT_REQUEST_NUMBER, CHARGE_ACCOUNT_CUSTOMER_NUMBER, CHARGE_ACCOUNT_OPPORTUNITY, CHARGE_ACCOUNT_OPPORTUNITY_KEY_CONTACT];
export default class FollowerOffspringRequestTeamEditForm extends LightningElement {
	@api leaderId; //Billing Account Id or Charge Account Request Id
	@api isBillingAccount;
	@api subAccountId; // blank if new TODO: for existing edit

	// Sub Account Fields
	subAccountNameField = SUB_ACCOUNT_NAME;
	subAccountContactField = SUB_ACCOUNT_CONTACT;
	subAccountAccountTypeField = SUB_ACCOUNT_ACCOUNT_TYPE;
	subAccountIsLoginRequiredField = SUB_ACCOUNT_IS_LOGIN_REQUIRED;

	physicalAddress = {};
	mailingAddress = {};
	accountType;
	isInvoicingDifferent = false;
	isCancelDisabled = false;
	selectedFollower;
	isLoading = true;
	saveDisabled = false;

	@wire(getRecord, { recordId: "$leaderId", fields: "$fields" })
	record({error, data}) {
		if (data) {
			this.recordData = data;
		}
	};
	recordData;

	get fields() {
		if (this.isBillingAccount === 'true') {
			return BILLING_ACCOUNT_FIELDS;
		}
		return CHARGE_ACCOUNT_FIELDS;
	}

	handleFormLoaded() {
		this.isLoading = false;
	}

	get billingAccountOrOpportunityName() {
		if (this.recordData) {
			if (this.isBillingAccount === 'true') {
				return {label: 'Billing Account Name', value: getFieldValue(this.recordData, BILLING_ACCOUNT_NAME)};
			} else {
				return {label: 'Opportunity Name', value: getFieldValue(this.recordData, CHARGE_ACCOUNT_OPPORTUNITY_NAME)};
			}
		}
		return {label: '', value: ''};
	}

	get legalEntityName() {
		if (this.recordData) {
			if (this.isBillingAccount === 'true') {
				return {label: 'Legal Entity Name', value: getFieldValue(this.recordData, BILLING_ACCOUNT_ORG_NAME)};
			} else {
				return {label: 'Legal Entity Name', value: getFieldValue(this.recordData, CHARGE_ACCOUNT_ORG_NAME)};
			}
		}
		return {label: '', value: ''};
	}

	get billingAccountOrChargeAccountNumber() {
		if (this.recordData) {
			if (this.isBillingAccount === 'true') {
				return {label: 'Billing Account Number', value: getFieldValue(this.recordData, BILLING_ACCOUNT_NUMBER)};
			} else {
				return {label: 'Charge Account Request Number', value: getFieldValue(this.recordData, CHARGE_ACCOUNT_REQUEST_NUMBER)
				};
			}
		}
		return {label: '', value: ''};
	}

	get customerNumber() {
		if (this.recordData) {
			if (this.isBillingAccount === 'true') {
				return {label: 'Customer Number', value: getFieldValue(this.recordData, BILLING_ACCOUNT_CUSTOMER_NUMBER)};
			} else {
				return {label: 'Customer Number', value: getFieldValue(this.recordData, CHARGE_ACCOUNT_CUSTOMER_NUMBER)};
			}
		}
		return {label: '', value: ''};
	}

	get isAccountSearchable() {
		return this.accountType === 'Offspring Follower';
	}

	handleAccountTypeChange(event) {
		this.accountType = event.target.value;
	}
	handleInvoicingToggleChange(event) {
		this.isInvoicingDifferent = !event.target.checked;
	}

	handleConfirmAddress(event) {
		if (event.detail.physicalAddress) {
			this.physicalAddress = event.detail.physicalAddress;
		}
		if (event.detail.mailingAddress) {
			this.mailingAddress = event.detail.mailingAddress;
		}
	}

	get isDSRFlow() {
		return this.isBillingAccount === 'false';
	}

	get subAccountContact() {
		if (this.isDSRFlow) {
			return getFieldValue(this.recordData, CHARGE_ACCOUNT_OPPORTUNITY_KEY_CONTACT);
		}
	}

	handleFollowerSelected(event) {
		if (event.detail) {
			this.selectedFollower = event.detail;
		}
	}

	handleCancel() {
		this.isCancelDisabled = true;
		if (this.isBillingAccount === 'true') {
			this.dispatchEvent(new CustomEvent('closed', {detail: this.leaderId}));
		} else {
			this.dispatchEvent(new CustomEvent('closed', {detail: getFieldValue(this.recordData, CHARGE_ACCOUNT_OPPORTUNITY)}));
		}
	}

	handleSave() {
		// validate address
		const allAddressValid = this.template.querySelector('c-follower-offspring-request-address').validate();

		// validate lightning-input-field
		const allInputFieldValid = [...this.template.querySelectorAll('.input-field')]
			.reduce((validSoFar, inputCmp) => {
				inputCmp.reportValidity();
				return validSoFar && inputCmp.reportValidity();
			}, true);

		// validate lightning-input
		const allInputValid = [...this.template.querySelectorAll('.input')]
			.reduce((validSoFar, inputCmp) => {
				inputCmp.reportValidity();
				return validSoFar && inputCmp.checkValidity();
			}, true);

		// validate follower offspring account type
		let followerOffspringValid = true;
		if (this.isAccountSearchable) {
			followerOffspringValid = this.template.querySelector('c-follower-offspring-request-account-search').validate();
		}
		if (allAddressValid && allInputFieldValid && allInputValid && followerOffspringValid) {
			const fields = {};// APT_Sub_Account_Request_Status__c
			fields[SUB_ACCOUNT_NAME.fieldApiName] = this.template.querySelector("[data-name='sub-account-name']").value;
			fields[SUB_ACCOUNT_CONTACT.fieldApiName] = this.template.querySelector("[data-name='sub-account-contact']").value;
			console.log('SUB_ACCOUNT_CONTACT: ' + this.template.querySelector("[data-name='sub-account-contact']").value);
			fields[SUB_ACCOUNT_ACCOUNT_TYPE.fieldApiName] = this.accountType;
			fields[SUB_ACCOUNT_IS_LOGIN_REQUIRED.fieldApiName] = this.template.querySelector("[data-name='sub-account-is-login-required']").value;
			if (this.isInvoicingDifferent) {
				fields[SUB_ACCOUNT_CONTACT_TEL.fieldApiName] = this.template.querySelector("[data-name='sub-account-tel']").value;
				fields[SUB_ACCOUNT_CONTACT_EMAIL.fieldApiName] = this.template.querySelector("[data-name='sub-account-email']").value;
			}
			fields[SUB_ACCOUNT_PHYSICAL_STREET.fieldApiName] = this.physicalAddress.street;
			fields[SUB_ACCOUNT_PHYSICAL_SUBURB.fieldApiName] = this.physicalAddress.city;
			fields[SUB_ACCOUNT_PHYSICAL_STATE.fieldApiName] = this.physicalAddress.state;
			fields[SUB_ACCOUNT_PHYSICAL_POSTCODE.fieldApiName] = this.physicalAddress.postcode;
			fields[SUB_ACCOUNT_MAILING_STREET.fieldApiName] = this.mailingAddress.street;
			fields[SUB_ACCOUNT_MAILING_SUBURB.fieldApiName] = this.mailingAddress.city;
			fields[SUB_ACCOUNT_MAILING_STATE.fieldApiName] = this.mailingAddress.state;
			fields[SUB_ACCOUNT_MAILING_POSTCODE.fieldApiName] = this.mailingAddress.postcode;
			if (this.isBillingAccount === 'true') {
				fields[SUB_ACCOUNT_LEADER_BILLING_ACCOUNT.fieldApiName] = this.leaderId;
			} else {
				fields[SUB_ACCOUNT_LEADER_CHARGE_ACCOUNT.fieldApiName] = this.leaderId;
			}
			if (this.accountType === 'Offspring Follower') {
				// if follower is existing billing account assign to parent billing account otherwise assign to parent charge account
				if ([BILLING_ACCOUNT_NUMBER.fieldApiName] in this.selectedFollower) {
					fields[SUB_ACCOUNT_PARENT_BILLING_ACCOUNT.fieldApiName] = this.selectedFollower.Id;
				} else {
					fields[SUB_ACCOUNT_PARENT_CHARGE_ACCOUNT.fieldApiName] = this.selectedFollower.Id;
				}
			}
			fields[SUB_ACCOUNT_STAGE.fieldApiName] = 'Draft';
			const recordInput = {apiName: SUB_ACCOUNT_OBJECT.objectApiName, fields};
			this.saveDisabled = true;
			createRecord(recordInput)
				.then((record) => {
					this.dispatchEvent(
						new ShowToastEvent({
							title: 'Success',
							message: 'New follower/offspring account request saved',
							variant: 'success',
						}),
					);
					this.saveDisabled = false;
					console.log('Sub account created: ' + record.id);
				})
				.catch((error) => {
					const errorMessages = JSON.stringify(error).match(/(?<="message":")(.*?)(?=")/g).join(' ');
					if (errorMessages) {
						this.dispatchEvent(
							new ShowToastEvent({
								title: "Error creating record",
								message: errorMessages,
								variant: "error",
							}),
						);
					}
					this.saveDisabled = false;
				});
		}
	}

}