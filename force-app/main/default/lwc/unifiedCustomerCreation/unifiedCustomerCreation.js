/**
 * @description An LWC Interface for displaying Customer Creation form for unified experience.
 * @author: Seth Heang
 * @changelog:
 * 2024-08-06 - Seth Heang - Created
 */
import {LightningElement, api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createNewCustomer from '@salesforce/apex/UnifiedCustomerCreationController.createNewCustomer';
import { reduceErrors } from 'c/ldsUtils';
import {isBlank, isNotBlank} from 'c/utils';

// Element selectors
export const INPUT_ELEMENT_SELECTORS = [
	'lightning-input',
	'c-ame-address-validation2',
	'lightning-record-picker',
];

// Field and button labels
export const FIRST_NAME_LABEL = 'First Name';
export const LAST_NAME_LABEL = 'Last Name';
export const PREFERRED_NAME_LABEL = 'Preferred Name';
export const PHONE_NUMBER_LABEL = 'Phone';
export const EMAIL_ADDRESS_LABEL = 'Email';
export const ORGANISATION_RADIO_LABEL = 'Organisation';
export const CONSUMER_RADIO_LABEL = 'Consumer';
export const ORGANISATION_LOOKUP_LABEL = 'Organisation Name';
export const NEW_ORGANISATION_TEXT_LABEL = 'New Organisation Name';
export const NEW_ORGANISATION_RADIO_LABEL = 'New Organisation';
export const BACK_BUTTON_LABEL = 'Back';
export const CREATE_BUTTON_LABEL = 'Create';

// Customer types
export const CUSTOMER_TYPE_CONSUMER = 'CONSUMER';
export const CUSTOMER_TYPE_ORGANISATION = 'ORGANISATION';

// Field validation regular expression patterns
export const NAME_INPUT_REGEX = '^[^\\.\\!\\(\\)\\[\\]"1-9]*$'; // TODO: create pattern in utility class
export const EMAIL_INPUT_REGEX = undefined; // TODO: leverage existing utility class (currently uses OOTB lighting-input email pattern)
export const PHONE_INPUT_REGEX = '^[\\d ]+$'; // TODO: leverage existing utility class

// Error messages
export const INVALID_NAME_MSG = 'Invalid name format';
export const INVALID_PHONE_NUMBER_MSG = 'Invalid phone number';
export const INVALID_EMAIL_ADDRESS_MSG = 'Invalid email address format';
export const MORE_INFO_REQUIRED_ERROR_MESSAGE = 'Please enter First and Last Name and at least one of Phone or Email.';
export const CUSTOMER_TYPE_REQUIRED_ERROR_MESSAGE = 'Please select a customer type.';
export const ORGANISATION_REQUIRED_ERROR_MESSAGE = 'Please enter Organisation.';
export const INVALID_FORM_ERROR = 'Please fix errors and try again';

/**
 * Helper method to get the value of the onchange event from an input component
 * based on the input type.
 *
 * @param {CustomEvent} event - The onchange event from the input
 * @returns {any} The value of the changed input component.
 */
export function getInputOnChangeValue(event) {
	if (!event?.detail) {
		return undefined;
	}

	const elementName = event.target.nodeName.toLowerCase();

	if (elementName === 'c-ame-address-validation2') {
		const address = event.detail;
		return {
			address: address.address,
			addressLine1: address.addressLine1,
			addressLine2: address.addressLine2,
			city: address.city,
			state: address.state,
			postcode: address.postcode,
			dpid: event.detail.dpid,
			latitude: event.detail.latitude,
			longitude: event.detail.longitude,
		};
	}

	if (elementName === 'lightning-record-picker') {
		return event.detail.recordId;
	}

	if (event.target.type === 'checkbox' || event.target.type === 'toggle') {
		return event.target.checked === true;
	}
	return event.detail.value;
}

export default class UnifiedCustomerCreation extends LightningElement {


	/**
	 * The value of the 'First Name' field on the form
	 * @type {string}
	 */
	@api get firstName() {
		return this._firstName;
	}
	set firstName(value) {
		this._firstName = value;
	}

	/**
	 * The value of the 'Last Name' field on the form
	 * @type {string}
	 */
	@api get lastName() {
		return this._lastName;
	}
	set lastName(value) {
		this._lastName = value;
	}

	/**
	 * The value of the 'Phone Number' field on the form
	 * @type {string}
	 */
	@api get phoneNumber() {
		return this._phoneNumber;
	}
	set phoneNumber(value) {
		this._phoneNumber = value;
	}

	/**
	 * The value of the 'Email Address' field on the form
	 * @type {string}
	 */
	@api get emailAddress() {
		return this._emailAddress;
	}
	set emailAddress(value) {
		this._emailAddress = value;
	}

	/**
	 * The value of the 'Address Obj' field on the form
	 * @type {object}
	 */
	@api get addressObj() {
		return this._addressObj;
	}
	set addressObj(value) {
		this._addressObj = value;
	}

	/**
	 * The value of the 'Organisation Account Id' field on the form
	 * @type {string}
	 */
	@api get organisationAccountId() {
		return this._organisationAccountId;
	}
	set organisationAccountId(value) {
		this._organisationAccountId = value;
	}

	/**
	 * The value of the 'Address Override' field on the form
	 * @type {boolean}
	 */
	@api get addressOverride() {
		return this._addressOverride;
	}
	set addressOverride(value){
		this._addressOverride = value;
	}

	/**
	 * The value of the 'Customer Type' field on the form
	 * @type {string|null}
	 */
	@api get customerType() {
		return this._customerType;
	}
	set customerType(value){
		this._customerType = value;
		if (this._customerType === CUSTOMER_TYPE_CONSUMER || this._customerType === null) {
			this.customerTypeConsumerRadioBtnValue = CUSTOMER_TYPE_CONSUMER;
			this.customerTypeOrganisationRadioBtnValue = '';
			this._customerType = CUSTOMER_TYPE_CONSUMER;
		} else if (this._customerType === CUSTOMER_TYPE_ORGANISATION) {
			this.customerTypeConsumerRadioBtnValue = '';
			this.customerTypeOrganisationRadioBtnValue = CUSTOMER_TYPE_ORGANISATION;
		}
	}

	// Field and button labels
	firstNameLabel = FIRST_NAME_LABEL;
	lastNameLabel = LAST_NAME_LABEL;
	preferredNameLabel = PREFERRED_NAME_LABEL;
	phoneNumberLabel = PHONE_NUMBER_LABEL;
	emailAddressLabel = EMAIL_ADDRESS_LABEL;
	organisationLookupLabel = ORGANISATION_LOOKUP_LABEL;
	newOrganisationTextLabel = NEW_ORGANISATION_TEXT_LABEL;
	newOrganisationRadioLabel = NEW_ORGANISATION_RADIO_LABEL;
	backButtonLabel = BACK_BUTTON_LABEL;
	createContactLabel = CREATE_BUTTON_LABEL;

	// Field validation patterns
	nameInputRegex = NAME_INPUT_REGEX;
	emailInputRegex = EMAIL_INPUT_REGEX;
	phoneInputRegex = PHONE_INPUT_REGEX;

	// Field validation error messages
	invalidNameMsg = INVALID_NAME_MSG;
	invalidEmailAddressMsg = INVALID_EMAIL_ADDRESS_MSG;
	invalidPhoneNumberMsg = INVALID_PHONE_NUMBER_MSG;

	// Organisation Account Lookup Configuration
	organisationLookupFilter = {
		criteria: [
			{
				fieldPath: 'IsPersonAccount',
				operator: 'eq',
				value: false,
			},
		],
		filterLogic: '1',
	};

	// Private variables for input fields, used with public getters/setters
	_firstName = '';
	_lastName = '';
	_phoneNumber = '';
	_emailAddress = '';
	_addressObj = {};
	_organisationAccountId = '';
	_addressOverride = false;
	_customerType = null;
	// Private variables for input fields (with no public getters/setters)
	preferredName = '';
	customerTypeConsumerRadioBtnValue = ''; // default to blank
	customerTypeOrganisationRadioBtnValue = ''; // default to blank
	newOrganisationName = '';
	newOrganisationToggle = false;
	_errorMessage = undefined;
	isLoading = false;
	disableCreateBtn = false;

	get errorMessage(){
		return this._errorMessage;
	}
	set errorMessage(value){
		this._errorMessage = value;
		this.disableCreateBtn = true;
	}


	get showOrganisationSection() {
		// Show unless only searching for consumers
		return this.customerTypeOrganisationRadioBtnValue === CUSTOMER_TYPE_ORGANISATION;
	}

	get customerTypeConsumerOption() {
		return [{ label: CONSUMER_RADIO_LABEL, value: CUSTOMER_TYPE_CONSUMER }];
	}

	get customerTypeOrganisationOption() {
		return [{ label: ORGANISATION_RADIO_LABEL, value: CUSTOMER_TYPE_ORGANISATION }];
	}

	/**
	 * Dispatch an event to navigate back to search ui
	 *
	 * @fires UnifiedCustomerCreation#backtosearch
	 */
	handleBackBtnClick() {
		this.dispatchEvent(new CustomEvent('backtosearch'));
	}

	/**
	 * Handles input field change events and stores the value in the
	 * corresponding variable based on the `data-field-name` attribute.
	 *
	 * @param {Event} event - The `change` event fired by the input element.
	 */
	handleInputChange(event) {
		this.disableCreateBtn = false;
		const { fieldName } = event.target.dataset;
		const fieldValue = getInputOnChangeValue(event);

		// check the event type for AME address search if it has a manual override
		this.handleAMEAddressSearchForAddressOverride(event);

		// check the event for customer type radio button and update the state appropriately for pre-population value from Customer Search UI
		this.handleCustomerTypeRadioBtn(event);

		// store the field value based on the `name` attribute
		this[fieldName] = fieldValue;

		this.handleNewOrganisationToggleBtn();
	}

	/**
	 * Manage the addressOverride flag based on `editaddress` or `selectaddress` event from AMEAddressValidation2 lwc component
	 * @param event
	 */
	handleAMEAddressSearchForAddressOverride(event) {
		if (event.type === 'editaddress') {
			this._addressOverride = true;
		} else if (event.type === 'selectaddress') {
			this._addressOverride = false;
		}
	}

	/**
	 * Manage the customerType and update appropriate flags
	 * @param event
	 */
	handleCustomerTypeRadioBtn(event) {
		if (event.target.type === 'radio') {
			const radioValue = event.detail.value;
			if (radioValue === CUSTOMER_TYPE_CONSUMER) {
				this._organisationAccountId = undefined;
				this.customerTypeOrganisationRadioBtnValue = '';
				this.customerTypeConsumerRadioBtnValue = CUSTOMER_TYPE_CONSUMER;
			} else if (radioValue === CUSTOMER_TYPE_ORGANISATION) {
				this.customerTypeConsumerRadioBtnValue = '';
				this.customerTypeOrganisationRadioBtnValue = CUSTOMER_TYPE_ORGANISATION;
			}
			this._customerType = radioValue;
		}
	}

	/**
	 * Manage the New Organisation Toggle and update appropriate flags
	 */
	handleNewOrganisationToggleBtn() {
		if (this.newOrganisationToggle === true) {
			this._organisationAccountId = undefined;
		}
	}

	/**
	 * Invoked on demand, to get the latest form input data from customer creation ui
	 * @returns {{firstName: string, lastName: string, emailAddress: string, phoneNumber: string, addressObj: {}, organisationAccountId: string}}
	 */
	@api getFormInputs(){
		return {
			firstName: this.firstName,
			lastName: this.lastName,
			phoneNumber: this.phoneNumber,
			emailAddress: this.emailAddress,
			addressObj: this.addressObj,
			organisationAccountId: this.organisationAccountId,
			addressOverride: this.addressOverride,
			customerType: this.customerType
		}
	}

	get ameDefaultAddress(){
		return this.addressOverride === true ? this.addressObj : undefined;
	}

	get ameSearchTerm(){
		return this.addressOverride === false ? this.addressObj?.address : undefined;
	}

	get ameSupportAutoSearchOnLoad() {
		return this.addressOverride === false;
	}

	/**
	 * Identifies and iterates over each input element, and checks that
	 * all inputs are valid. Use this before submitting the form.
	 *
	 * @returns {boolean}
	 */
	validateInputs(){
		try {
			// Reset any previous error message
			this.errorMessage = undefined;

			// Collect all form input elements
			const inputElements = [
				...this.template.querySelectorAll(INPUT_ELEMENT_SELECTORS.join(',')),
			];

			// Check each individual field is valid
			let isValid = inputElements.reduce((validSoFar, el) => {
				el.reportValidity();
				return validSoFar && el.checkValidity();
			}, true);

			// If one or more fields is invalid, stop validating (field will display error message)
			if (!isValid) {
				return false;
			}

			// Check at least First AND Last Name, or Phone, or Email is entered
			const hasFirstAndLast =
					isNotBlank(this.firstName) && isNotBlank(this.lastName);
			const hasPhoneOrEmail =
					isNotBlank(this.phoneNumber) || isNotBlank(this.emailAddress);
			if (!(hasFirstAndLast && hasPhoneOrEmail)) {
				isValid = false;
				this.errorMessage = MORE_INFO_REQUIRED_ERROR_MESSAGE;
			}

			const hasCustomerType = isNotBlank(this.customerType);
			if (!hasCustomerType) {
				isValid = false;
				this.errorMessage = CUSTOMER_TYPE_REQUIRED_ERROR_MESSAGE;
			}

			const hasOrganisation = this.showOrganisationSection && (isBlank(this.organisationAccountId) && isBlank(this.newOrganisationName));
			if (hasOrganisation) {
				isValid = false;
				this.errorMessage = ORGANISATION_REQUIRED_ERROR_MESSAGE;
			}
			return isValid;
		} catch (err) {
			this.errorMessage = reduceErrors(err).join(',');
			return false;
		}
	}

	/**
	 * Handle the creation of a new Consumer/Business contact, and optionally a new Organisation including all appropriate fields mapped from the UI form
	 * @fires UnifiedCustomerCreation#customercreated
	 */
	async handleSubmitContactCreation(){
		// Validate inputs before invoking the search method
		if (!this.validateInputs()) {
			if (this.errorMessage === undefined) {
				this.errorMessage = INVALID_FORM_ERROR;
			}
			return;
		}

		this.isLoading = true;
		try {
			const contactId = await createNewCustomer({
				request: {
					firstName: this.firstName,
					lastName: this.lastName,
					preferredName: this.preferredName,
					emailAddress: this.emailAddress,
					mobileNumber: this.phoneNumber,
					customerType: this.customerType,
					addressStreet: this.addressObj?.address,
					addressCity: this.addressObj?.city,
					addressState: this.addressObj?.state,
					addressPostalCode: this.addressObj?.postcode,
					addressDPID: this.addressObj?.dpid,
					addressLatitude: this.addressObj?.latitude,
					addressLongitude: this.addressObj?.longitude,
					accountId: this.organisationAccountId, // link existing org
					accountName: this.newOrganisationName // create new org
				}
			});
			// Dispatch the ShowToastEvent
			this.dispatchEvent(new ShowToastEvent({
				title: 'Success!',
				message: 'Contact is created successfully.',
				variant: 'success',
			}));

			// Dispatch the `customercreated` event with customerId and propagate up to parent component
			this.dispatchEvent(new CustomEvent('customercreated', {
				detail: {
					customerId: contactId
				},
				bubbles: true,
				composed: true
			}));
		} catch (error) {
			// Handle search errors
			this.errorMessage = reduceErrors(error).join(',');
		} finally {
			this.isLoading = false;
		}
	}

}