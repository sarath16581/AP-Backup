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
import {api, LightningElement, track} from 'lwc';

export default class FollowerOffspringRequestAddress extends LightningElement {
	physicalAddressStr;
	mailingAddressStr;
	confirmedPhysicalAddress = {};
	confirmedMailingAddress = {};
	toggleChecked;
	showMailingAddress = true;

	_defaultAddress;

	/**
	 * Load default address when updating existing sub account
	 */
	@api set defaultAddress(value) {
		if (value) {
			this.mailingAddressStr = value.mailingAddress;
			this.physicalAddressStr = value.physicalAddress;
			this.toggleChecked = value.mailingSameAsPhysical;
			this.showMailingAddress = !this.toggleChecked;
		}
		this._defaultAddress = value;
	}

	get defaultAddress() {
		return this._defaultAddress;
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
	 * Triggered when user confirm physical address
	 * Map physical address fields then dispatch confirm address event to request wrapper
	 */
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
			this.physicalAddressStr = Object.values(this.confirmedPhysicalAddress).join(' ');
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
	 * Triggered when user confirm physical address
	 * Map mailing address fields then dispatch confirm address event to request wrapper
	 */
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
			this.mailingAddressStr = Object.values(this.confirmedMailingAddress).join(' ');
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
		if (this.defaultAddress != null) {
			return true;
		}
		const ameValid = [...this.template.querySelectorAll('c-ame-address-validation2')]
			.reduce((validSoFar, ameAddressCmp) => {
				ameAddressCmp.reportValidity();
				return validSoFar && ameAddressCmp.checkValidity();
			}, true);
		return ameValid;
	}
}