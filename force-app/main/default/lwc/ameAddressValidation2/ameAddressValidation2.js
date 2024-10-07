/**
 * @description Integrates with AME address validation API and provides address lookup and validation behaviour. Also allows
 *              capturing the address manually.
 *              This component supports automatically searching AME for an initial search term if supportsAutoSearchOnLoad = true.
 *              Also supports getting the user to confirm the address after selecting from AME or manual entry.
 *
 *              Component publish following events
 *              * selectaddress  - Fired when an address is selected from AME.
 *              * editaddress    - Fired when the address is updated manually.
 *              * confirmaddress - Fired when the address is confirmed.
 *              All three events above include the address as event detail.
 *
 *              NOTE: New component is introduced instead of updating the existing ameAddressValidation1 component so
 *              that there is no impact to the public api exposed by the existing component. This is important to ensure
 *              components that use ameAddressValidation1 continue to function without any change.
 *
 * @author Ranjeewa Silva
 * @date 2020-10-27
 * @changelog
 * 2020-10-27 - Ranjeewa Silva - Created
 * 2020-11-06 - Ranjeewa Silva - Updated to support confirmation of blank address details (when address is unknown).
 * 2021-09-28 - Ranjeewa Silva - Added support for additinal address fields and also introduced a new variant - "show-detail-onsearch"
 * 2024-07-31 - Marcel HK - Added generic error to UI when an error is caught in a try/catch block.
 */

import { LightningElement, track, api } from 'lwc';
import searchAddress from '@salesforce/apex/AMEAddressValidationController1.searchAddress';
import getAddressDetails from '@salesforce/apex/AMEAddressValidationController1.getAddressDetails';
import { debounce } from 'c/utils';

const GENERIC_ERROR_MESSAGE = 'Something went wrong';

export default class AmeAddressValidation2 extends LightningElement {
	// address search input placeholder text
	@api addressSearchPlaceholder = 'Search for address';

	// address label (e.g. Sender Address, Addressee Address) displayed over search input
	@api label = 'Address';

	// indicates the address input is mandatory
	@api required = false;

	// search term to populate into address search input. If supportsAutoSearchOnLoad = true, use this search term to
	// search AME for a valid address.
	@api searchTerm = '';

	// help text displayed next to the address label
	@api helpText = 'If address not found, please override and enter address.';

	// label of the toggle for enabling manual address input
	@api overrideLabel = 'Override Address';

	// default address set by the parent. This is used to populate address details on load if supportsAutoSearchOnLoad = false.
	// If supportsAutoSearchOnLoad = true, this value is ignored.
	// Following properties are supported:
	//  - addressLine1
	//  - addressLine2
	//  - city
	//  - state
	//  - postcode
	//  - countryName
	@api defaultAddress;

	// variant of the component. Supports:
	//   standard (default) - Always show address detail section. Note that the detail may show blank address values.
	//   detail-hidden - Details section is always hidden. Use this to select address directly from AME and it is not necessary to manually override address.
	//   show-detail-onselect - Address details section is hidden on load. Details section is shown when an address is selected from AME.
	//   show-detail-onsearch - Address details section is hidden on load. Details section is shown when an address search is triggered from AME.
	//                          This variant allows an address to be entered manually without having to select one from AME search results.
	@api variant = 'standard';

	// If set, search AME for the address search term passed in on load and automatically select the returned address
	// having a 'HIGH' confidence rating. If none of the returned addresses have a 'HIGH' confidence rating, do not
	// populate address details and let the user search and select the correct address or manually enter the address.
	@api supportsAutoSearchOnLoad = false;

	// If set, force the user to confirm the address selected. Address may have been selected automatically (on load),
	// selected by user following a search or manually entered by the user. Confirmation will be required in all three scenarios.
	// Confirmed address is dispatched in "confirmaddress" event.
	@api confirmationRequired = false;

	// represents the address used internally by the component. Gets updated based on user actions.
	@track address = {};

	// set when an address has been selected from AME results. used to determine if address details section should be
	// shown / hidden when variant = 'show-detail-onselect'.
	isAddressDetailsAvailable = false;

	// set when an address search has been performed in AME. use to determine if address details section should be
	// shown / hidden when variant = 'show-detail-onsearch'.
	isAddressSearchPerformed = false;

	// results returned by AME for the address search term
	searchResults = [];

	// shows address search results drop down
	showSearchResults = false;

	// manual address override is enabled
	overrideAddress = false;

	// searching address in AME
	isLoadingSearchResults = false;
	// retrieving details of the selected address from AME
	isLoadingAddressDetails = false;

	// Error message to be displayed to the user
	errorMessage;

	// Has the user explicitly confirmed the selected address. This takes effect only if confirmationRequired is set by the parent.
	isConfirmed = false;

	connectedCallback() {
		// If supportsAutoSearchOnLoad = true, search AME and attempt to select an address from returned results.
		if (this.supportsAutoSearchOnLoad && this.searchTerm && this.searchTerm.length > 0) {
			this.doInitialAddressSearch();
		} else if (!this.supportsAutoSearchOnLoad && this.defaultAddress) {
			// parent has passed in a default address. Use that to initialise internal address data. Also set manual override to
			// true to indicate it's not validated.
			this.address = {
				...this.defaultAddress,
				manualOverride: true
			};
			this.overrideAddress = true;
		}
	}

	/**
	 * Search AME for the search term supplied by the parent and attempt to automatically select an address
	 * from the returned results.
	 */
	async doInitialAddressSearch() {
		try {
			this.errorMessage = undefined;
			// trigger an auto search
			const response = await searchAddress({ searchTerm: this.searchTerm });
			this.isAddressSearchPerformed = true;
			const results = JSON.parse(response);

			// Check if we have received an address result with 'HIGH' confidence rating.
			if (results && results.length > 0 && results[0].confidence === 'HIGH') {
				// High confidence address match found. Retrieve details from AME and populate address.
				const addressDetailsResponse = await getAddressDetails({ address: results[0].dpid });
				if (addressDetailsResponse && addressDetailsResponse.length > 0) {
					this.setAddressFromAmeAddressResponse(addressDetailsResponse, false);
				}
			}
		} catch (error) {
			console.error(error);
			this.errorMessage = GENERIC_ERROR_MESSAGE;
		}
	}

	/**
	 * search address in AME based on the search term
	 */
	handleSearchAddress(event) {
		this.searchTerm = event.target.value;
		if (this.searchTerm.length >= 2) {
			this.debouncedSearchHandler(this.searchTerm);
		}
	}

	debouncedSearchHandler = debounce(this.handleSearchAME, 200);

	/**
	 * search ame for the search term
	 */
	async handleSearchAME(searchAddressTerm) {
		try {
			this.openSearchResultsList();
			this.isLoadingSearchResults = true;
			this.errorMessage = undefined;
			const response = await searchAddress({ searchTerm: searchAddressTerm });
			this.isAddressSearchPerformed = true;
			if (response && response.length > 0) {
				const result = JSON.parse(response);
				// translate to the form required to be displayed on UI.
				this.searchResults = result.map((record, index) => ({
					...record,
					title: record.singleLine,
					subtitle: ''
				}));
			}
		} catch (error) {
			console.error(JSON.parse(JSON.stringify(error)));
			this.errorMessage = GENERIC_ERROR_MESSAGE;
		} finally {
			this.isLoadingSearchResults = false;
		}
	}

	/**
	 * user has selected one address from search results. Get the details from AME and populate internal
	 * address data.
	 */
	async handleSearchResultSelect(event) {
		try {
			const record = event.detail;
			this.isLoadingAddressDetails = true;
			this.errorMessage = undefined;
			const addressResponse = await getAddressDetails({ address: record.dpid });
			if (addressResponse && addressResponse.length > 0) {
				this.setAddressFromAmeAddressResponse(addressResponse, true);
			}
		} catch (error) {
			console.error(JSON.parse(JSON.stringify(error)));
			this.errorMessage = GENERIC_ERROR_MESSAGE;
		} finally {
			this.isLoadingAddressDetails = false;
			this.closeSearchResultsList();
		}
	}

	/**
	 * handles manual address input (when overrideAddress = true).
	 */
	handleAddressChange(event) {
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

		const value = target.type === 'checkbox' ? target.checked : target.value;
		const key = target.name;
		this.address = {
			...this.address,
			[key]: value,
			manualOverride: true
		};
		this.address.address = `${this.address.addressLine1 ? `${this.address.addressLine1},` : ''}${this.address.addressLine2 ? ` ${this.address.addressLine2},` : ''}${
			this.address.city ? ` ${this.address.city}` : ''
		}${this.address.state ? ` ${this.address.state}` : ''}${this.address.postcode ? ` ${this.address.postcode}` : ''}${
			this.address.countryName ? ` ${this.address.countryName}` : ''
		}`.trim();

		if (!this.confirmationRequired) {
			// Do this only if confirmationRequired is not set to true. No need to fire address change event
			// if confirmationRequired=true, as this will be done when the user confirms the selected
			// address.

			// address overridden manually - only include relevant fields in the event payload.
			const updatedAddress = {
				address: this.address.address,
				addressLine1: this.address.addressLine1,
				addressLine2: this.address.addressLine2,
				city: this.address.city,
				state: this.address.state,
				postcode: this.address.postcode,
				countryName: this.address.countryName
			};

			// Creates the event with the data.
			const manualChangeEvent = new CustomEvent('editaddress', {
				detail: updatedAddress
			});
			// Dispatches the event.
			this.dispatchEvent(manualChangeEvent);
		}
	}

	handleOverrideCheckboxChange(event) {
		this.overrideAddress = event.target.checked;
	}

	/**
	 * Populate internal address data (internal state) from the address details received from AME.
	 * Also dispatch 'selectaddress' event.
	 */
	setAddressFromAmeAddressResponse(value, updateSearchTerm) {
		const [parsedAddress] = JSON.parse(value);
		const [geoData] = parsedAddress.geoDataList;
		this.address = {
			address: parsedAddress.singleLine,
			addressLine1: parsedAddress.semiStructured.addressLines[0],
			addressLine2: parsedAddress.semiStructured.addressLines[1],
			addressLines: parsedAddress.semiStructured.addressLines,
			city: parsedAddress.semiStructured.locality,
			state: parsedAddress.semiStructured.state,
			postcode: parsedAddress.semiStructured.postcode,
			countryName: parsedAddress.semiStructured.countryName,
			countryCode: parsedAddress.semiStructured.countryCode,
			dpid: parsedAddress.dpid,
			latitude: geoData ? geoData.latitude : null,
			longitude: geoData ? geoData.longitude : null,
			geoDataList: parsedAddress.geoDataList,
			deliveryData: parsedAddress.deliveryData
		};

		if (updateSearchTerm) {
			this.searchTerm = this.address.address;
		}

		this.isAddressDetailsAvailable = true;

		//Dispatch select address event
		const selectedEvent = new CustomEvent('selectaddress', {
			detail: this.address
		});
		this.dispatchEvent(selectedEvent);
	}

	openSearchResultsList() {
		if (this.searchResults.length > 0 || this.isLoadingSearchResults) {
			this.showSearchResults = true;
		}
	}

	closeSearchResultsList() {
		this.showSearchResults = false;
	}

	handleConfirmSelectedAddress(event) {
		this.isConfirmed = !this.isConfirmed;

		// Check if the address is valid and show any errors on screen.
		const isValid = this.checkValidityOnConfirmation();

		if (this.isConfirmed && isValid) {
			// address is valid and confirmed. dispatch "confirmaddress" event with relevant payload.
			this.dispatchAddressConfirmedEvent(this.overrideAddress);
		} else if (this.isConfirmed && !isValid) {
			// attempting to confirm - but address input validation has failed.
			this.isConfirmed = false;
		}
	}

	/**
	 * Validate address input on confirmation and show validation errors on screen.
	 */
	checkValidityOnConfirmation() {
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

		// Validation has passed. Clear any error messages.
		this.errorMessage = null;
		return true;
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
		this.dispatchEvent(new CustomEvent('confirmaddress', { detail: confirmedAddress }));
	}

	/**
	 * Validate input components and report validity on UI.
	 * If confirmationRequired = true, also validates if the address is confirmed.
	 */
	@api reportValidity() {
		const inputComponents = this.template.querySelectorAll('.address-input');
		const inputsArray = inputComponents ? [...inputComponents] : [];
		inputsArray.forEach(inputCmp => inputCmp.reportValidity());

		if (this.confirmationRequired && !this.isConfirmed) {
			this.errorMessage = 'Please confirm address.';
		}
	}

	/**
	 * Validate input components, report validity on UI and returns true if valid.
	 * If confirmationRequired = true, also validates if the address is confirmed.
	 */
	@api checkValidity() {
		const inputComponents = this.template.querySelectorAll('.address-input');
		const inputsArray = inputComponents ? [...inputComponents] : [];
		return inputsArray.reduce(
			(acc, inputCmp) => {
				inputCmp.reportValidity();
				return acc && inputCmp.checkValidity();
			},
			this.confirmationRequired ? this.isConfirmed : true
		);
	}

	/**
	 * Disable address search input if set to manually override or the selected address is already confirmed.
	 * Disabling address search input on confirmation is done only if confirmationRequired = true.
	 */
	get isAddressSearchDisabled() {
		if (this.confirmationRequired && this.isConfirmed) {
			return true;
		}
		return this.overrideAddress;
	}

	/**
	 * Disable address input fields if manual override is turned off or the selected address is already confirmed.
	 * Disabling input fields on confirmation is done only if confirmationRequired = true.
	 */
	get isAddressInputDisabled() {
		if (this.confirmationRequired && this.isConfirmed) {
			return true;
		}
		return !this.overrideAddress;
	}

	get showDetails() {
		if (this.variant === 'detail-hidden') {
			//details always hidden
			return false;
		} else if (this.variant === 'show-detail-onselect') {
			// show details if an address has been selected
			return this.isAddressDetailsAvailable;
		} else if (this.variant === 'show-detail-onsearch') {
			return this.isAddressSearchPerformed;
		}

		//details always visible (standard behaviour)
		return true;
	}
}