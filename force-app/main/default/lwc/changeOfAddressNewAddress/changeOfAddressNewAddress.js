import {api, LightningElement} from 'lwc';
import LightningAlert from "lightning/alert";

export default class ChangeOfAddressNewAddress extends LightningElement {
	@api currentBillingAddress;
	@api currentPhysicalAddress;

	newBillingAddress;
	newPhysicalAddress;

	addressError;

	handleAddressUpdated(event) {
		if (event.target.dataset.id === 'billing-address') {
			this.newBillingAddress = event.detail.address;
		} else if (event.target.dataset.id === 'physical-address') {
			this.newPhysicalAddress = event.detail.address;
		}
		
	}
	@api
    async getReturnData() {
		let detail = {};
        this.validateAddresses().then(result => {
			if (result) {
				if (this.newBillingAddress != null) {
					detail['billingAddress'] = this.newBillingAddress;
				}
				if (this.newPhysicalAddress != null) {
					detail['physicalAddress'] = this.newPhysicalAddress;
				}	
			}
		});
		return detail;
    }
	@api
	restoreState(data) {
        if(data.billingAddress){
			const billindAddrComp = this.template.querySelector('[data-id="billing-address"]');
			billindAddrComp.defaultAddress=data.billingAddress;
		}
		if(data.physicalAddress){
			const billindAddrComp = this.template.querySelector('[data-id="physical-address"]');
			billindAddrComp.defaultAddress=data.physicalAddress;
		}
    }
	async validateAddresses() {
		if (this.newBillingAddress == null && this.newPhysicalAddress == null) {
			this.addressError = 'Please update at least one address to proceed to the next screen.';
			return false;
		}
		let sameAddressFound = [];
		const concatBillingAddress = [this.newBillingAddress?.addressLine1, this.newBillingAddress?.addressLine2, this.newBillingAddress?.city, this.newBillingAddress?.state, this.newBillingAddress?.postcode].join(' ');
		const concatPhysicalAddress = [this.newPhysicalAddress?.addressLine1, this.newPhysicalAddress?.addressLine2, this.newPhysicalAddress?.city, this.newPhysicalAddress?.state, this.newPhysicalAddress?.postcode].join(' ');
		if (this.currentBillingAddress != null && concatBillingAddress?.replace(/ /g, '').toLowerCase() === this.currentBillingAddress.replace(/ /g, '').toLowerCase()) {
			sameAddressFound.push('Billing');
		}
		if (this.currentPhysicalAddress != null && concatPhysicalAddress?.replace(/ /g, '').toLowerCase() === this.currentPhysicalAddress.replace(/ /g, '').toLowerCase()) {
			sameAddressFound.push('Physical');
		}
		if (sameAddressFound.length > 0) {
			const message = `You have selected same ${sameAddressFound.join(' and ')} address(es) as the new address. The address(es) will not be updated on the Organisation. Please click OK to proceed to contact selection`;
			await LightningAlert.open({
				message: message,
				theme: 'warning',
				label: 'Change of Address'
			});
		}
		return true;
	}
}