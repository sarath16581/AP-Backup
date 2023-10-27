/**
 * @description Address child component for follower offspring TEAM request
 * Physical and mailing addresses are required to be confirmed before saving.
 * 'Is mailing address same as physical address' can be toggled by user
 * @author Harry Wang
 * @date 2023-10-27
 * @group Controller
 * @changelog
 * 2023-10-27 - Harry Wang - Created
 */import {api, LightningElement} from 'lwc';

export default class FollowerOffspringRequestAddress extends LightningElement {
	confirmedPhysicalAddress = {};
	confirmedMailingAddress = {};
	showMailingAddress = true;

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

	handleConfirmedPhysicalAddress(event) {
		if (event.detail) {
			const physicalAddressVar = event.detail;
			if(physicalAddressVar.addressLine1 !== undefined && physicalAddressVar.addressLine2 !== undefined){
				this.confirmedPhysicalAddress.street = physicalAddressVar.addressLine1+' '+physicalAddressVar.addressLine2;
			}else{
				this.confirmedPhysicalAddress.street = physicalAddressVar.addressLine1;
			}
			if(physicalAddressVar.city  !== null){
				this.confirmedPhysicalAddress.city = physicalAddressVar.city;
			}
			if(physicalAddressVar.state  !== null){
				this.confirmedPhysicalAddress.state = physicalAddressVar.state;
			}
			if(physicalAddressVar.postcode  !== null){
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

	handleConfirmedMailingAddress(event) {
		if (event.detail) {
			this.mailingAddressVar = event.detail;
			if(this.mailingAddressVar.addressLine1 !== undefined && this.mailingAddressVar.addressLine2 !== undefined){
				this.confirmedMailingAddress.street = this.mailingAddressVar.addressLine1+' '+this.mailingAddressVar.addressLine2;
			}else{
				this.confirmedMailingAddress.street = this.mailingAddressVar.addressLine1;
			}
			if(this.mailingAddressVar.city  !== null){
				this.confirmedMailingAddress.city = this.mailingAddressVar.city;
			}
			if(this.mailingAddressVar.state  !== null){
				this.confirmedMailingAddress.state = this.mailingAddressVar.state;
			}
			if(this.mailingAddressVar.postcode  !== null){
				this.confirmedMailingAddress.postcode = this.mailingAddressVar.postcode;
			}
			this.dispatchEvent(new CustomEvent('confirmaddress', {
				detail : {
					mailingAddress: this.confirmedMailingAddress
				}
			}));
		}
	}

	@api validate() {
		const allValid = [...this.template.querySelectorAll('c-ame-address-validation2')]
			.reduce((validSoFar, ameAddressCmp) => {
				ameAddressCmp.reportValidity();
				return validSoFar && ameAddressCmp.checkValidity();
			}, true);
		return allValid;
	}
}