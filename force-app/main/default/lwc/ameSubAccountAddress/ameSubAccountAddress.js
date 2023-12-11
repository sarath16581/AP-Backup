/**
 * @description Support capturing the address manually when lookup address from AME.
 * Address need to be validated before confirmation
 * @author Harry Wang
 * @date 2023-11-22
 * @changelog
 * 2023-11-22 - Harry Wang - Created
 */
import {api, LightningElement, track} from 'lwc';
import LightningConfirm from "lightning/confirm";

export default class AmeSubAccountAddress extends LightningElement {
	@track address = {};

	// Default address set by the parent. This is used to populate address details on load
	// Following properties are supported:
	//  - addressLine1
	//  - addressLine2
	//  - city
	//  - state
	//  - postcode
	//  - countryName
	@api defaultAddress;

	@api streetMaxLength;

	// Address label
	@api label;

	// If address inputs are required
	@api required;

	// manual address override is enabled
	overrideAddress = false;

	// Has the user explicitly confirmed the selected address. This takes effect only if confirmationRequired is set by the parent.
	isConfirmed = false;

	// Error message to be displayed to the user
	errorMessage;

	connectedCallback() {
		if (this.defaultAddress) {
			// parent has passed in a default address. Use that to initialise internal address data. Also set manual override to
			// true to indicate it's not validated.
			this.address = {
				...this.defaultAddress,
				manualOverride: true
			};
			this.overrideAddress = true;
			this.isConfirmed = true;
		}
	}

	/**
	 * Disable address input fields if manual override is turned off or the selected address is already confirmed.
	 */
	get isAddressInputDisabled() {
		if (this.isConfirmed) {
			return true;
		}
		return !this.overrideAddress;
	}

	/**
	 * Enable AME search if manual override is turned off and the selected address is not confirmed.
	 */
	get isSearchEnabled() {
		if (this.isConfirmed) {
			return false;
		}
		return !this.overrideAddress;
	}

	// Concatenated address length from addressLine1 and addressLine2
	get concatenatedAddressLength() {
		const addressLine1 = this.address?.addressLine1;
		const addressLine2 = this.address?.addressLine2;
		const addressLine1Length = addressLine1 != null ? addressLine1.length : 0;
		const addressLine2Length = addressLine2 != null ? addressLine2.length : 0;
		return addressLine2 ? addressLine1Length + addressLine2Length + 1 : addressLine1Length;
	}

	/**
	 * User has selected one address from search results. Get the details from AME and populate internal
	 * address data.
	 */
	handleSelectAddress(event) {
		this.address = event.detail;
		this.errorMessage = '';
		// Show error if address is more than this.streetMaxLength characters
		if (this.streetMaxLength && this.concatenatedAddressLength > this.streetMaxLength) {
			this.errorMessage = 'The address line 1 and 2 entered are more than ' + this.streetMaxLength + ' characters';
		}
	}

	/**
	 * User has changed the address. Map address fields
	 */
	handleAddressChange(event) {
		this.errorMessage = '';
		const target = event.target;

		// user has updated the address. new address has to be confirmed again.
		this.isConfirmed = false;

		if (this.address && !this.address.manualOverride) {
			//Clear the address details previously returned by AME if present
			this.address.dpid = null;
			this.address.address = null;
			this.address.addressLines = [];
			this.address.latitude = null;
			this.address.longitude = null;
			this.address.geoDataList = [];
			this.address.deliveryData = null;
		}

		const value = target.type === "checkbox" ? target.checked : target.value;
		const key = target.name;
		this.address = {
			...this.address,
			[key]: value,
			manualOverride: true
		}
		this.address.address = `${this.address.addressLine1 ? `${this.address.addressLine1},` : ''}${this.address.addressLine2 ? ` ${this.address.addressLine2},` : ''}${this.address.city ? ` ${this.address.city}` : ''}${this.address.state ? ` ${this.address.state}` : ''}${this.address.postcode ? ` ${this.address.postcode}` : ''}${this.address.countryName ? ` ${this.address.countryName}` : ''}`.trim();

		// Show error if address is more than this.streetMaxLength characters
		if (this.streetMaxLength && this.concatenatedAddressLength > this.streetMaxLength) {
			this.errorMessage = 'The address line 1 and 2 entered are more than ' + this.streetMaxLength + ' characters';
		}
	}

	/**
	 * User has confirmed the address. Validate and dispatch confirm event
	 */
	async handleConfirmSelectedAddress() {

		this.isConfirmed = !this.isConfirmed;

		// Check if the address is valid and show any errors on screen.
		const isValid = await this.checkValidityOnConfirmation();
		if (this.isConfirmed && isValid) {
			// address is valid and confirmed. dispatch "confirmaddress" event with relevant payload.
			this.dispatchAddressConfirmedEvent(this.overrideAddress);
		} else if (this.isConfirmed && !isValid) {

			// attempting to confirm - but address input validation has failed.
			this.isConfirmed = false;
		}

	}

	handleOverrideCheckboxChange(event) {
		this.overrideAddress = event.target.checked;
	}

	/**
	 * Dispatch 'confirmaddress' event with relevant address payload.
	 * If address captured manually, then ensure any address details returned from AME such as 'dpid' is not included.
	 */
	dispatchAddressConfirmedEvent() {
		let confirmedAddress = this.address;
		if (confirmedAddress && confirmedAddress.manualOverride) {
			// address is overridden manually. include only the relevant fields in the event payload.
			confirmedAddress = {
				address: this.address.address,
				addressLine1: this.address.addressLine1,
				addressLine2: this.address.addressLine2,
				city: this.address.city,
				state: this.address.state,
				postcode: this.address.postcode,
				countryName: this.address.countryName
			};
		}
		// Dispatches the event.
		this.dispatchEvent(new CustomEvent("confirmaddress", { detail : confirmedAddress}));
	}

	/**
	 * Validate address input on confirmation and show validation errors on screen.
	 */
	async checkValidityOnConfirmation() {
		if (!this.isConfirmed) {
			// Clearing the "confirmed" status here. re-set any error messages.
			this.errorMessage = null;
			return true;
		}

		if (this.overrideAddress && !this.checkValidity()) {
			// Manual Override is enabled and address validation has failed.
			this.errorMessage = 'Please enter address details before confirming.';
			return false;
		} else if (!this.overrideAddress && (!this.checkValidity() || !(this.address && this.address.dpid))) {
			// Manual Override is disabled and address validation has failed.
			this.errorMessage = 'Please search and select address before confirming.';
			return false;
		}

		// Check if address should be truncated
		if (this.streetMaxLength && this.concatenatedAddressLength > this.streetMaxLength) {
			let truncatedAddress = (this.address?.addressLine1 + ' ' + this.address?.addressLine2).substring(0, this.streetMaxLength);
			const confirmMessage = "The address line 1 and 2 entered are more than " + this.streetMaxLength + " characters. This will be truncated to '" + truncatedAddress
				+ "' Click ‘OK’ to continue or ‘Cancel’ to re-enter the address";
			const result = await LightningConfirm.open({
				message: confirmMessage,
				label: 'Confirm Address Warning',
				theme: 'warning'
			});
			if (result) {
				this.address.addressLine1 = truncatedAddress;
				this.address.addressLine2 = '';
				this.errorMessage = null;
				return true;
			} else {
				this.errorMessage = 'The address line 1 and 2 entered are more than ' + this.streetMaxLength + ' characters';
				return false;
			}
		}

		// Validation has passed. Clear any error messages.
		this.errorMessage = null;
		return true;
	}

	/**
	 * Validate input components and report validity on UI.
	 * If confirmationRequired = true, also validates if the address is confirmed.
	 */
	@api reportValidity(){
		const inputComponents = this.template.querySelectorAll(".address-input");
		const inputsArray = inputComponents ? [...inputComponents] : [];
		inputsArray.forEach(inputCmp => inputCmp.reportValidity());
		if (!this.isConfirmed) {
			this.errorMessage = 'Please confirm address.';
		}
	}

	/**
	 * Validate input components, report validity on UI and returns true if valid
	 */
	@api checkValidity(){
		const inputComponents = this.template.querySelectorAll(".address-input");
		const inputsArray = inputComponents ? [...inputComponents] : [];
		return inputsArray.reduce((acc, inputCmp) => {
			inputCmp.reportValidity();
			return acc && inputCmp.checkValidity();
		}, this.isConfirmed);
	}
}