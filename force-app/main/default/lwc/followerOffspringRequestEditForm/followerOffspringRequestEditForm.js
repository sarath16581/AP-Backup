/**
 * @description Edit form component for follower offspring TEAM request
 * @author Harry Wang
 * @date 2023-10-27
 * @group Controller
 * @changelog
 * 2023-10-27 - Harry Wang - Created
 */
import {api, LightningElement, wire} from 'lwc';
import {getFieldValue, getRecord, updateRecord, createRecord} from "lightning/uiRecordApi";
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
import SUB_ACCOUNT_Id from "@salesforce/schema/APT_Sub_Account__c.Id";
import SUB_ACCOUNT_NAME from "@salesforce/schema/APT_Sub_Account__c.Name";
import SUB_ACCOUNT_CONTACT from "@salesforce/schema/APT_Sub_Account__c.SubAccountContact__c";
import SUB_ACCOUNT_ACCOUNT_TYPE from "@salesforce/schema/APT_Sub_Account__c.AccountType__c";
import SUB_ACCOUNT_IS_LOGIN_REQUIRED from "@salesforce/schema/APT_Sub_Account__c.Is_Parcel_Send_Login_Required__c";
import SUB_ACCOUNT_PARENT_BILLING_ACCOUNT from "@salesforce/schema/APT_Sub_Account__c.ParentBillingAccount__c";
import SUB_ACCOUNT_LEADER_BILLING_ACCOUNT from "@salesforce/schema/APT_Sub_Account__c.APT_Billing_Account__c";
import SUB_ACCOUNT_PARENT_SUB_ACCOUNT from "@salesforce/schema/APT_Sub_Account__c.ParentAccountRequest__c";
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
import {ShowToastEvent} from "lightning/platformShowToastEvent";

const BILLING_ACCOUNT_FIELDS = [BILLING_ACCOUNT_NAME, BILLING_ACCOUNT_ORG_NAME, BILLING_ACCOUNT_NUMBER, BILLING_ACCOUNT_CUSTOMER_NUMBER];
const CHARGE_ACCOUNT_FIELDS = [CHARGE_ACCOUNT_OPPORTUNITY_NAME, CHARGE_ACCOUNT_ORG_NAME, CHARGE_ACCOUNT_REQUEST_NUMBER, CHARGE_ACCOUNT_CUSTOMER_NUMBER, CHARGE_ACCOUNT_OPPORTUNITY, CHARGE_ACCOUNT_OPPORTUNITY_KEY_CONTACT];
export default class FollowerOffspringRequestEditForm extends LightningElement {
	// Can be either charge account ID or billing account ID
	@api leaderId;

	// If current context is for billing account or charge account flow
	@api isBillingAccount;

	// Private property required to have custom logic in setter
	_subAccount;

	// leader fields
	billingAccountOrOpportunityName = {label: '', value: ''};
	billingAccountOrChargeAccountNumber = {label: '', value: ''};
	legalEntityName = {label: '', value: ''};
	customerNumber = {label: '', value: ''};

	// lightning input field names
	subAccountNameField = SUB_ACCOUNT_NAME;
	subAccountContactField = SUB_ACCOUNT_CONTACT;
	subAccountAccountTypeField = SUB_ACCOUNT_ACCOUNT_TYPE;
	subAccountIsLoginRequiredField = SUB_ACCOUNT_IS_LOGIN_REQUIRED;

	// lightning inputs
	subAccountName;
	subAccountContact;
	accountType;
	subAccountLoginRequired;
	contactDetailsSame;
	subAccountContactTel;
	subAccountContactEmail;

	physicalAddress = {};
	mailingAddress = {};
	isInvoicingDifferent;
	selectedFollower;
	@api isLoading;

	/**
	 * Load leader account details
	 */
	@wire(getRecord, { recordId: "$leaderId", fields: "$fields" })
	record({error, data}) {
		if (data) {
			this.recordData = data;
			// load leader details
			if (this.isBillingAccount === 'true') {
				this.billingAccountOrOpportunityName = {label: 'Billing Account Name', value: getFieldValue(this.recordData, BILLING_ACCOUNT_NAME)};
				this.billingAccountOrChargeAccountNumber = {label: 'Billing Account Number', value: getFieldValue(this.recordData, BILLING_ACCOUNT_NUMBER)};
				this.legalEntityName = {label: 'Legal Entity Name', value: getFieldValue(this.recordData, BILLING_ACCOUNT_ORG_NAME)};
				this.customerNumber = {label: 'Customer Number', value: getFieldValue(this.recordData, BILLING_ACCOUNT_CUSTOMER_NUMBER)};
			} else {
				this.billingAccountOrOpportunityName = {label: 'Opportunity Name', value: getFieldValue(this.recordData, CHARGE_ACCOUNT_OPPORTUNITY_NAME)};
				this.billingAccountOrChargeAccountNumber = {label: 'Charge Account Request Number', value: getFieldValue(this.recordData, CHARGE_ACCOUNT_REQUEST_NUMBER)};
				this.legalEntityName = {label: 'Legal Entity Name', value: getFieldValue(this.recordData, CHARGE_ACCOUNT_ORG_NAME)};
				this.customerNumber = {label: 'Customer Number', value: getFieldValue(this.recordData, CHARGE_ACCOUNT_CUSTOMER_NUMBER)};
				this.subAccountContact = getFieldValue(this.recordData, CHARGE_ACCOUNT_OPPORTUNITY_KEY_CONTACT);
			}
		}
		if (error) {
			console.log('Error when loading leader: ' + error);
		}
	}
	recordData;

	/**
	 * Get fields based on leader account type - used to wire leader account details
	 */
	get fields() {
		if (this.isBillingAccount === 'true') {
			return BILLING_ACCOUNT_FIELDS;
		}
		return CHARGE_ACCOUNT_FIELDS;
	}

	get subAccount() {
		return this._subAccount;
	}

	/**
	 * Pre-populate form inputs if editing existing subAccount
	 */
	@api set subAccount(value) {
		if (value) {
			this._subAccount = value;
			this.subAccountName = this._subAccount[SUB_ACCOUNT_NAME.fieldApiName];
			this.subAccountContact = this._subAccount[SUB_ACCOUNT_CONTACT.fieldApiName];
			this.subAccountLoginRequired = this._subAccount[SUB_ACCOUNT_IS_LOGIN_REQUIRED.fieldApiName];
			this.subAccountContactTel = this._subAccount[SUB_ACCOUNT_CONTACT_TEL.fieldApiName];
			this.subAccountContactEmail = this._subAccount[SUB_ACCOUNT_CONTACT_EMAIL.fieldApiName];
			this.physicalAddress = {
				street: this._subAccount[SUB_ACCOUNT_PHYSICAL_STREET.fieldApiName],
				city: this._subAccount[SUB_ACCOUNT_PHYSICAL_SUBURB.fieldApiName],
				state: this._subAccount[SUB_ACCOUNT_PHYSICAL_STATE.fieldApiName],
				postcode: this._subAccount[SUB_ACCOUNT_PHYSICAL_POSTCODE.fieldApiName],
			};
			this.mailingAddress = {
				street: this._subAccount[SUB_ACCOUNT_MAILING_STREET.fieldApiName],
				city: this._subAccount[SUB_ACCOUNT_MAILING_SUBURB.fieldApiName],
				state: this._subAccount[SUB_ACCOUNT_MAILING_STATE.fieldApiName],
				postcode: this._subAccount[SUB_ACCOUNT_MAILING_POSTCODE.fieldApiName],
			};
			this.accountType = this._subAccount[SUB_ACCOUNT_ACCOUNT_TYPE.fieldApiName];
			if (this.isAccountSearchable) {
				this.selectedFollower = this._subAccount[SUB_ACCOUNT_PARENT_BILLING_ACCOUNT.fieldApiName]
					? {Id: this._subAccount[SUB_ACCOUNT_PARENT_BILLING_ACCOUNT.fieldApiName]} : {Id: this._subAccount[SUB_ACCOUNT_PARENT_SUB_ACCOUNT.fieldApiName]};
			}
		}
		this.contactDetailsSame = !(this.subAccountContactTel || this.subAccountContactEmail);
		this.isInvoicingDifferent = !this.contactDetailsSame;
	}

	/**
	 *  Disable loading spinner when input form is loaded
	 */
	handleFormLoaded() {
		this.isLoading = false;
	}

	get isAccountSearchable() {
		return this.accountType === 'Offspring Follower';
	}

	/**
	 *  If Follower or Offspring account type selected, reset selector follower
	 */
	handleAccountTypeChange(event) {
		const accountType = event.target.value;
		if (accountType !== 'Offspring Follower') {
			// Reset selected follower
			this.selectedFollower = null;
		}
		this.accountType = accountType;
	}

	/**
	 *  Handler when address confirmed from AME. Map AME address to sub account address
	 */
	handleConfirmAddress(event) {
		if (event.detail.physicalAddress) {
			const physicalAddressVar = event.detail.physicalAddress; // unmapped physical address from AME
			if(physicalAddressVar.addressLine1 != null && physicalAddressVar.addressLine2 != null){
				this.physicalAddress.street = physicalAddressVar.addressLine1+' '+physicalAddressVar.addressLine2;
			} else if(physicalAddressVar.addressLine1 != null){
				this.physicalAddress.street = physicalAddressVar.addressLine1;
			}
			if(physicalAddressVar.city != null){
				this.physicalAddress.city = physicalAddressVar.city;
			}
			if(physicalAddressVar.state != null){
				this.physicalAddress.state = physicalAddressVar.state;
			}
			if(physicalAddressVar.postcode != null){
				this.physicalAddress.postcode = physicalAddressVar.postcode;
			}
		}
		if (event.detail.mailingAddress) {
			const mailingAddressVar = event.detail.mailingAddress; // unmapped mailing address from AME
			if(mailingAddressVar.addressLine1 != null && mailingAddressVar.addressLine2 != null){
				this.mailingAddress.street = mailingAddressVar.addressLine1+' '+mailingAddressVar.addressLine2;
			} else if(mailingAddressVar.addressLine1 != null){
				this.mailingAddress.street = mailingAddressVar.addressLine1;
			}
			if(mailingAddressVar.city != null){
				this.mailingAddress.city = mailingAddressVar.city;
			}
			if(mailingAddressVar.state != null){
				this.mailingAddress.state = mailingAddressVar.state;
			}
			if(mailingAddressVar.postcode != null){
				this.mailingAddress.postcode = mailingAddressVar.postcode;
			}
		}
	}

	get isDSRFlow() {
		return this.isBillingAccount === 'false';
	}

	/**
	 *  Handler whe user toggle if Invoicing Contact Same As Sub Account Contact
	 */
	handleInvoicingToggleChange(event) {
		this.isInvoicingDifferent = !event.target.checked;
	}

	/**
	 *  Handler when user selected a follower
	 */
	handleFollowerSelected(event) {
		if (event.detail) {
			this.selectedFollower = event.detail;
		}
	}

	/**
	 *  Dispatch event closed to request wrapper including leader ID if billing account flow, otherwise charge account opportunity ID
	 *  Those IDs are required for navigation
	 */
	handleCancel() {
		if (this.isBillingAccount === 'true') {
			this.dispatchEvent(new CustomEvent('cancel', {detail: this.leaderId}));
		} else {
			this.dispatchEvent(new CustomEvent('cancel', {detail: getFieldValue(this.recordData, CHARGE_ACCOUNT_OPPORTUNITY)}));
		}
	}

	/**
	 *  Validate form inputs before saving.
	 *  This method support both update (if this.subAccount exists) and creation.
	 *  Dispatch upsert event to request wrapper if succeeds otherwise show errors
	 */
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
			const fields = {};
			if (this.subAccount?.Id) {
				fields[SUB_ACCOUNT_Id.fieldApiName] = this.subAccount.Id;
			}
			if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_NAME.fieldApiName] !== this.template.querySelector("[data-name='sub-account-name']").value)) {
				fields[SUB_ACCOUNT_NAME.fieldApiName] = this.template.querySelector("[data-name='sub-account-name']").value;
			}
			if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_CONTACT.fieldApiName] !== this.template.querySelector("[data-name='sub-account-contact']").value)) {
				fields[SUB_ACCOUNT_CONTACT.fieldApiName] = this.template.querySelector("[data-name='sub-account-contact']").value;
			}
			if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_ACCOUNT_TYPE.fieldApiName] !== this.accountType)) {
				fields[SUB_ACCOUNT_ACCOUNT_TYPE.fieldApiName] = this.accountType;
			}
			if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_IS_LOGIN_REQUIRED.fieldApiName] !== this.template.querySelector("[data-name='sub-account-is-login-required']").value)) {
				fields[SUB_ACCOUNT_IS_LOGIN_REQUIRED.fieldApiName] = this.template.querySelector("[data-name='sub-account-is-login-required']").value;
			}

			if (this.isInvoicingDifferent) {
				if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_CONTACT_TEL.fieldApiName] !== this.template.querySelector("[data-name='sub-account-tel']").value)) {
					fields[SUB_ACCOUNT_CONTACT_TEL.fieldApiName] = this.template.querySelector("[data-name='sub-account-tel']").value;
				}
				if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_CONTACT_EMAIL.fieldApiName] !== this.template.querySelector("[data-name='sub-account-email']").value)) {
					fields[SUB_ACCOUNT_CONTACT_EMAIL.fieldApiName] = this.template.querySelector("[data-name='sub-account-email']").value;
				}
			} else {
				if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_CONTACT_TEL.fieldApiName] != null)) {
					fields[SUB_ACCOUNT_CONTACT_TEL.fieldApiName] = null;
				}
				if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_CONTACT_EMAIL.fieldApiName] != null)) {
					fields[SUB_ACCOUNT_CONTACT_EMAIL.fieldApiName] = null;
				}
			}
			if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_PHYSICAL_STREET.fieldApiName] !== this.physicalAddress.street)) {
				fields[SUB_ACCOUNT_PHYSICAL_STREET.fieldApiName] = this.physicalAddress.street;
			}
			if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_PHYSICAL_SUBURB.fieldApiName] !== this.physicalAddress.city)) {
				fields[SUB_ACCOUNT_PHYSICAL_SUBURB.fieldApiName] = this.physicalAddress.city;
			}
			if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_PHYSICAL_STATE.fieldApiName] !== this.physicalAddress.state)) {
				fields[SUB_ACCOUNT_PHYSICAL_STATE.fieldApiName] = this.physicalAddress.state;
			}
			if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_PHYSICAL_POSTCODE.fieldApiName] !== this.physicalAddress.postcode)) {
				fields[SUB_ACCOUNT_PHYSICAL_POSTCODE.fieldApiName] = this.physicalAddress.postcode;
			}
			if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_MAILING_STREET.fieldApiName] !== this.mailingAddress.street)) {
				fields[SUB_ACCOUNT_MAILING_STREET.fieldApiName] = this.mailingAddress.street;
			}
			if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_MAILING_SUBURB.fieldApiName] !== this.mailingAddress.city)) {
				fields[SUB_ACCOUNT_MAILING_SUBURB.fieldApiName] = this.mailingAddress.city;
			}
			if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_MAILING_STATE.fieldApiName] !== this.mailingAddress.state)) {
				fields[SUB_ACCOUNT_MAILING_STATE.fieldApiName] = this.mailingAddress.state;
			}
			if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_MAILING_POSTCODE.fieldApiName] !== this.mailingAddress.postcode)) {
				fields[SUB_ACCOUNT_MAILING_POSTCODE.fieldApiName] = this.mailingAddress.postcode;
			}
			if (!this.subAccount) {
				if (this.isBillingAccount === 'true') {
					fields[SUB_ACCOUNT_LEADER_BILLING_ACCOUNT.fieldApiName] = this.leaderId;
				} else {
					fields[SUB_ACCOUNT_LEADER_CHARGE_ACCOUNT.fieldApiName] = this.leaderId;
				}
			}
			if (this.accountType === 'Offspring Follower') {
				// if follower is existing billing account assign to parent billing account otherwise assign to parent sub account
				if (!this.subAccount || (this.subAccount && (this.selectedFollower.Id !== this.subAccount[SUB_ACCOUNT_PARENT_BILLING_ACCOUNT.fieldApiName]
						&& this.selectedFollower.Id !== this.subAccount[SUB_ACCOUNT_PARENT_SUB_ACCOUNT.fieldApiName]))) {
					if (this.selectedFollower[BILLING_ACCOUNT_NUMBER.fieldApiName]) {
						fields[SUB_ACCOUNT_PARENT_BILLING_ACCOUNT.fieldApiName] = this.selectedFollower.Id;
						fields[SUB_ACCOUNT_PARENT_SUB_ACCOUNT.fieldApiName] = null;
					} else {
						fields[SUB_ACCOUNT_PARENT_BILLING_ACCOUNT.fieldApiName] = null;
						fields[SUB_ACCOUNT_PARENT_SUB_ACCOUNT.fieldApiName] = this.selectedFollower.Id;
					}
				}
			} else {
				if (this.subAccount && this.subAccount[SUB_ACCOUNT_ACCOUNT_TYPE] === 'Offspring Follower' || this.selectedFollower == null) {
					fields[SUB_ACCOUNT_PARENT_BILLING_ACCOUNT.fieldApiName] = null;
					fields[SUB_ACCOUNT_PARENT_SUB_ACCOUNT.fieldApiName] = null;
				}
			}
			if (!this.subAccount || (this.subAccount && this.subAccount[SUB_ACCOUNT_STAGE.fieldApiName] !== 'Draft')) {
				fields[SUB_ACCOUNT_STAGE.fieldApiName] = 'Draft';
			}

			// create record if subAccount exists otherwise update record
			const apiName = SUB_ACCOUNT_OBJECT.objectApiName;
			this.isLoading = true;
			if (this.subAccount) {
				updateRecord({fields})
					.then((record) => {
						this.dispatchEvent(
							new ShowToastEvent({
								title: 'Success',
								message: 'Existing follower/offspring account request updated',
								variant: 'success',
							}),
						);
						console.log('Sub account updated: ' + record.id);
						this.dispatchEvent(new CustomEvent('upsert'));
					})
					.catch((error) => {
						this.dispatchFormattedError(error);
					})
					.finally(() => {
						this.isLoading = false;
					});
			} else {
				createRecord({apiName, fields})
					.then((record) => {
						this.dispatchEvent(
							new ShowToastEvent({
								title: 'Success',
								message: 'follower/offspring account request created',
								variant: 'success',
							}),
						);
						console.log('Sub account created: ' + record.id);
						this.dispatchEvent(new CustomEvent('upsert'));
					})
					.catch((error) => {
						this.dispatchFormattedError(error);
					})
					.finally(() => {
						this.isLoading = false;
					});
			}
		}
	}

	/**
	 *  Show errors when saving/deleting sub account(s)
	 */
	dispatchFormattedError(error) {
		const errorMessages = JSON.stringify(error).match(/(?<="message":")(.*?)(?=")/g).join(' ');
		if (errorMessages) {
			this.dispatchEvent(
				new ShowToastEvent({
					title: "An error occurred while saving/deleting record(s)",
					message: errorMessages,
					variant: "error",
				}),
			);
		}
	}

	/**
	 *  Send default selected parent account ID to account search component if this.subAccount exists
	 */
	get defaultSelection() {
		if (this.subAccount) {
			if (this.subAccount[SUB_ACCOUNT_PARENT_BILLING_ACCOUNT.fieldApiName]) {
				return this.subAccount[SUB_ACCOUNT_PARENT_BILLING_ACCOUNT.fieldApiName];
			}
			if (this.subAccount[SUB_ACCOUNT_PARENT_SUB_ACCOUNT.fieldApiName]) {
				return this.subAccount[SUB_ACCOUNT_PARENT_SUB_ACCOUNT.fieldApiName];
			}
		}
		return null;
	}
}