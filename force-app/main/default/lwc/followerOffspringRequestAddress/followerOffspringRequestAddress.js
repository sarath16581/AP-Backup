/**
 * @description Address child component for follower offspring TEAM request
 * Physical and mailing addresses are required to be confirmed before saving.
 * 'Is mailing address same as physical address' can be toggled by user
 * @author Harry Wang
 * @date 2023-10-27
 * @group Controller
 * @changelog
 * 2023-10-27 - Harry Wang - Created
 */
import {api, LightningElement} from 'lwc';
import SUB_ACCOUNT_PHYSICAL_STREET from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_Street_Name__c";
import SUB_ACCOUNT_PHYSICAL_SUBURB from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_Suburb__c";
import SUB_ACCOUNT_PHYSICAL_STATE from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_State__c";
import SUB_ACCOUNT_PHYSICAL_POSTCODE from "@salesforce/schema/APT_Sub_Account__c.APT_Street_Address_Street_Postcode__c";
import SUB_ACCOUNT_MAILING_STREET from "@salesforce/schema/APT_Sub_Account__c.APT_Postal_Address_Street_Name__c";
import SUB_ACCOUNT_MAILING_SUBURB from "@salesforce/schema/APT_Sub_Account__c.APT_Postal_Address_Suburb__c";
import SUB_ACCOUNT_MAILING_STATE from "@salesforce/schema/APT_Sub_Account__c.APT_Postal_Address_State__c";
import SUB_ACCOUNT_MAILING_POSTCODE from "@salesforce/schema/APT_Sub_Account__c.APT_Postal_Address_Street_Postcode__c";

export default class FollowerOffspringRequestAddress extends LightningElement {
	physicalAddress;
	mailingAddress;
	confirmedPhysicalAddress;
	confirmedMailingAddress;
	toggleChecked;
	showMailingAddress = true;

	_subAccount;

	@api set subAccount(value) {
		if (value) {
			this.confirmedMailingAddress = {
				addressLine1: value[SUB_ACCOUNT_MAILING_STREET.fieldApiName],
				city: value[SUB_ACCOUNT_MAILING_SUBURB.fieldApiName],
				state: value[SUB_ACCOUNT_MAILING_STATE.fieldApiName],
				postcode: value[SUB_ACCOUNT_MAILING_POSTCODE.fieldApiName]
			};
			this.confirmedPhysicalAddress = {
				addressLine1: value[SUB_ACCOUNT_PHYSICAL_STREET.fieldApiName],
				city: value[SUB_ACCOUNT_PHYSICAL_SUBURB.fieldApiName],
				state: value[SUB_ACCOUNT_PHYSICAL_STATE.fieldApiName],
				postcode: value[SUB_ACCOUNT_PHYSICAL_POSTCODE.fieldApiName]
			};
			this.toggleChecked = JSON.stringify(this.confirmedMailingAddress) === JSON.stringify(this.confirmedPhysicalAddress);
			this.showMailingAddress = !this.toggleChecked;
		}
		this._subAccount = value;
	}

	get subAccount() {
		return this._subAccount;
	}

	handleAddressToggleChange(event) {
		this.showMailingAddress = !(event.detail.checked);
		if (event.detail.checked && this.confirmedPhysicalAddress) {
			this.confirmedMailingAddress = this.confirmedPhysicalAddress;
			this.dispatchEvent(new CustomEvent('confirmaddress', {
				detail : {
					mailingAddress: this.confirmedMailingAddress
				}
			}));
		}
	}

	/**
	 * Triggered when user confirm physical address then dispatch confirm address event to request wrapper
	 */
	handleConfirmedPhysicalAddress(event) {
		if (event.detail) {
			const physicalAddressVar = event.detail;
			this.confirmedPhysicalAddress = {};
			if (physicalAddressVar.addressLine1 != null) {
				this.confirmedPhysicalAddress.addressLine1 = physicalAddressVar.addressLine1;
			}
			if (physicalAddressVar.addressLine2 != null) {
				this.confirmedPhysicalAddress.addressLine2 = physicalAddressVar.addressLine2;
			}
			if(physicalAddressVar.city != null){
				this.confirmedPhysicalAddress.city = physicalAddressVar.city;
			}
			if(physicalAddressVar.state != null){
				this.confirmedPhysicalAddress.state = physicalAddressVar.state;
			}
			if(physicalAddressVar.postcode != null){
				this.confirmedPhysicalAddress.postcode = physicalAddressVar.postcode;
			}

			if (!this.showMailingAddress) { // physical same as mailing
				this.confirmedMailingAddress = this.confirmedPhysicalAddress;
				this.dispatchEvent(new CustomEvent('confirmaddress', {
					detail : {
						physicalAddress: this.confirmedPhysicalAddress,
						mailingAddress: this.confirmedMailingAddress
					}
				}));
			} else {
				this.dispatchEvent(new CustomEvent('confirmaddress', {
					detail : {
						physicalAddress: this.confirmedPhysicalAddress,
					}
				}));
			}
		}
	}

	/**
	 * Triggered when user confirm physical address then dispatch confirm address event to request wrapper
	 */
	handleConfirmedMailingAddress(event) {
		if (event.detail) {
			this.confirmedMailingAddress = {};
			this.mailingAddressVar = event.detail;
			if(this.mailingAddressVar.addressLine1 != null){
				this.confirmedMailingAddress.addressLine1 = this.mailingAddressVar.addressLine1;
			}
			if(this.mailingAddressVar.addressLine2 != null){
				this.confirmedMailingAddress.addressLine2 = this.mailingAddressVar.addressLine2;
			}
			if(this.mailingAddressVar.city != null){
				this.confirmedMailingAddress.city = this.mailingAddressVar.city;
			}
			if(this.mailingAddressVar.state != null){
				this.confirmedMailingAddress.state = this.mailingAddressVar.state;
			}
			if(this.mailingAddressVar.postcode != null){
				this.confirmedMailingAddress.postcode = this.mailingAddressVar.postcode;
			}
			this.dispatchEvent(new CustomEvent('confirmaddress', {
				detail : {
					mailingAddress: this.confirmedMailingAddress
				}
			}));
		}
	}

	/**
	 * Validate address input. If defaultAddress exists return true
	 */
	@api validate() {
		const ameValid = [...this.template.querySelectorAll('c-ame-sub-account-address')]
			.reduce((validSoFar, ameAddressCmp) => {
				ameAddressCmp.reportValidity();
				return validSoFar && ameAddressCmp.checkValidity();
			}, true);
		return ameValid;
	}
}