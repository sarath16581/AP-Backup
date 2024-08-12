/**
 * @description An LWC Interface for displaying Customer Search Form for Unified Experience
 * @changelog:
 * 2024-08-08 - added handler methods to handle `createcontact` and `backtosearch` events and pass `formInputs` params to child LWCs
 */
import { LightningElement, api } from 'lwc';
import customerSearch from '@salesforce/apex/UnifiedCustomerSearchController.search';
import { isNotBlank } from 'c/utils';
import { reduceErrors } from 'c/ldsUtils';

// Field and button labels
export const FIRST_NAME_LABEL = 'First Name';
export const LAST_NAME_LABEL = 'Last Name';
export const PHONE_NUMBER_LABEL = 'Phone';
export const EMAIL_ADDRESS_LABEL = 'Email';
export const ORGANISATION_CHECKBOX_LABEL = 'Organisation';
export const CONSUMER_CHECKBOX_LABEL = 'Consumer';
export const ORGANISATION_LOOKUP_LABEL = 'Organisation Name';
export const ABN_ACN_LABEL = 'ABN/ACN';
export const SEARCH_BUTTON_LABEL = 'Search';
export const CLEAR_BUTTON_LABEL = 'Clear';

// Customer types
export const CUSTOMER_TYPE_CONSUMER = 'CONSUMER';
export const CUSTOMER_TYPE_ORGANISATION = 'ORGANISATION';

// Field validation regular expression patterns
export const NAME_INPUT_REGEX = '^[^\\.\\!\\(\\)\\[\\]"1-9]*$'; // TODO: create pattern in utility class
export const EMAIL_INPUT_REGEX = undefined; // TODO: leverage existing utility class (currently uses OOTB lighting-input email pattern)
export const PHONE_INPUT_REGEX = '^[\\d ]+$'; // TODO: leverage existing utility class
export const ABN_ACN_INPUT_REGEX = '^(\\d{9}|\\d{11})$';

// Error messages
export const INVALID_NAME_MSG = 'Invalid name format';
export const INVALID_PHONE_NUMBER_MSG = 'Invalid phone number';
export const INVALID_EMAIL_ADDRESS_MSG = 'Invalid email address format';
export const INVALID_ABN_ACN_MSG = 'Invalid ABN/ACN';
export const MORE_INFO_REQUIRED_ERROR_MESSAGE =
	'Please enter at least First and Last Name, or Phone, or Email.';
export const INVALID_FORM_ERROR = 'Please fix and errors and try again';

// Element selectors
export const INPUT_ELEMENT_SELECTORS = [
	'lightning-input',
	'c-ame-address-validation2',
	'lightning-record-picker',
];

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

/**
 * The Customer Search Form presents a search form with inputs fields for the user define the search criteria to find
 * matching customer (Contact) records. The search is executed by calling the `UnifiedCustomerSearch` Apex Controller.
 *
 * @alias UnifiedCustomerSearchForm
 * @hideconstructor
 */
export default class UnifiedCustomerSearchForm extends LightningElement {
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
	@api get addressObj(){
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
		if (value) {
			this.organisationCheckbox = true;
			this.consumerCheckbox = false;
			this._organisationAccountId = value;
		}else{
			this.organisationCheckbox = false;
			this.consumerCheckbox = true;
		}
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

	// Private variables for input fields, used with public getters/setters
	_firstName = '';
	_lastName = '';
	_phoneNumber = '';
	_emailAddress = '';
	_addressObj = {};
	_organisationAccountId = null;
	_addressOverride = false;
	// Private variables for input fields (with no public getters/setters)
	organisationCheckbox = false;
	consumerCheckbox = false;
	abnAcn = '';
	includePhoneNumber = true;
	includeEmailAddress = true;
	showAddress = true;

	get ignorePhoneNumber() {
		return !this.includePhoneNumber;
	}

	get ignoreEmailAddress() {
		return !this.includeEmailAddress;
	}

	get customerType() {
		if (this.consumerCheckbox === true) {
			return CUSTOMER_TYPE_CONSUMER;
		}
		if (this.organisationCheckbox === true) {
			return CUSTOMER_TYPE_ORGANISATION;
		}
		return null;
	}

	get showOrganisationSection() {
		// Show unless only searching for conumers
		return this.customerType !== CUSTOMER_TYPE_CONSUMER;
	}
	get isAbnAcnDisabled() {
		return !!this.organisationAccountId;
	}

	errorMessage = undefined;
	isLoading = false;

	// Field and button labels
	firstNameLabel = FIRST_NAME_LABEL;
	lastNameLabel = LAST_NAME_LABEL;
	phoneNumberLabel = PHONE_NUMBER_LABEL;
	emailAddressLabel = EMAIL_ADDRESS_LABEL;
	organisationCheckboxLabel = ORGANISATION_CHECKBOX_LABEL;
	consumerCheckboxLabel = CONSUMER_CHECKBOX_LABEL;
	organisationLookupLabel = ORGANISATION_LOOKUP_LABEL;
	abnAcnLabel = ABN_ACN_LABEL;
	searchButtonLabel = SEARCH_BUTTON_LABEL;
	clearButtonLabel = CLEAR_BUTTON_LABEL;

	// Field validation patterns
	nameInputRegex = NAME_INPUT_REGEX;
	emailInputRegex = EMAIL_INPUT_REGEX;
	phoneInputRegex = PHONE_INPUT_REGEX;
	abnAcnInputRegex = ABN_ACN_INPUT_REGEX;

	// Field validation error messages
	invalidNameMsg = INVALID_NAME_MSG;
	invalidEmailAddressMsg = INVALID_EMAIL_ADDRESS_MSG;
	invalidPhoneNumberMsg = INVALID_PHONE_NUMBER_MSG;
	invalidAbnAcnMsg = INVALID_ABN_ACN_MSG;

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
	organisationLookupDisplayInfo = {
		primaryField: 'Name',
		additionalFields: ['ABN__c'],
	};

	/**
	 * Identifies and iterates over each input element, and checks that
	 * all inputs are valid. Use this before submitting the form.
	 *
	 * @returns {boolean}
	 */
	validateInputs() {
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

			if (!(hasFirstAndLast || hasPhoneOrEmail)) {
				isValid = false;
				this.errorMessage = MORE_INFO_REQUIRED_ERROR_MESSAGE;
			}

			return isValid;
		} catch (err) {
			this.errorMessage = reduceErrors(err).join(',');
			return false;
		}
	}

	/**
	 * Submits the form and performs the search.
	 *
	 * @fires UnifiedCustomerSearchForm#search
	 * @fires UnifiedCustomerSearchForm#result
	 * @fires UnifiedCustomerSearchForm#error
	 */
	async performSearch() {
		// Validate inputs before invoking the search method
		if (!this.validateInputs()) {
			if (this.errorMessage === undefined) {
				this.errorMessage = INVALID_FORM_ERROR;
			}
			return;
		}

		// Invoke the search method
		this.isLoading = true;
		this.dispatchEvent(new CustomEvent('search'));

		try {
			const res = await customerSearch({
				req: {
					firstName: this.firstName,
					lastName: this.lastName,
					// Ignore if include email toggle disabled
					emailAddress: this.ignoreEmailAddress ? null : this.emailAddress,
					// Ignore if include phone toggle disabled
					phoneNumber: this.ignorePhoneNumber ? null : this.phoneNumber,
					customerType: this.customerType,
					addressStreet1: this.addressObj?.addressLine1,
					addressStreet2: this.addressObj?.addressLine2,
					addressCity: this.addressObj?.city,
					addressState: this.addressObj?.state,
					addressPostalCode: this.addressObj?.postcode,
					// Ignore Account Id if the searching for consumers only
					accountId: this.consumerCheckbox ? null : this.organisationAccountId || null,
					// Ignore ABN/ACN if the searching for consumers only, or the organisationAccountId is set
					abnAcn:
							this.consumerCheckbox || this.organisationAccountId
									? null
									: this.abnAcn,
				}
			});
			// Handle search results
			this.dispatchEvent(
				new CustomEvent('result', {
					detail: JSON.parse(JSON.stringify(res)),
				})
			);
		} catch (error) {
			// Handle search errors
			this.errorMessage = reduceErrors(error).join(',');
			this.dispatchEvent(
				new CustomEvent('error', { detail: this.errorMessage })
			);
		} finally {
			this.isLoading = false;
		}
	}

	/**
	 * Resets the form inputs.
	 *
	 * @fires UnifiedCustomerSearchForm#reset
	 */
	async resetForm() {
		// Reset error message
		this.errorMessage = undefined;

		// Clear each field value
		this._firstName = '';
		this._lastName = '';
		this._emailAddress = '';
		this._phoneNumber = '';
		this.includePhoneNumber = true;
		this.includeEmailAddress = true;
		this._addressObj = undefined;
		this.organisationCheckbox = false;
		this.consumerCheckbox = false;
		this._organisationAccountId = undefined;
		this.abnAcn = undefined;

		// Ensure field values are updated before continuing
		await Promise.resolve();

		// Collect all form input elements
		const inputElements = [
			...this.template.querySelectorAll(INPUT_ELEMENT_SELECTORS.join(',')),
		];

		// Clear any field-level error messages, and call any applicable clear/reset methods
		inputElements.forEach((field) => {
			if (typeof field.setCustomValidity === 'function') {
				field.setCustomValidity(''); // Clear any custom validation message
			}
			if (typeof field.reportValidity === 'function') {
				field.reportValidity(); // Refresh the UI to clear any error styles
			}
			if (typeof field.clearSelection === 'function') {
				field.clearSelection(); // Call the clearSelection() method on lightning-record-picker
			}
		});

		// Workaround to reset address by removing the element, allow DOM update, then add element again.
		// TODO: Update address component to allow clear/reset function.
		this.showAddress = false;
		Promise.resolve().then(() => {
			this.showAddress = true;
		});

		// Notify form has been reset
		this.dispatchEvent(new CustomEvent('reset'));
	}

	/**
	 * Handles input field change events and stores the value in the
	 * corresponding variable based on the `data-field-name` attribute.
	 *
	 * @param {Event} event - The `change` event fired by the input element.
	 */
	handleInputChange(event) {
		const { fieldName } = event.target.dataset;
		const fieldValue = getInputOnChangeValue(event);

		// check the event type for AME address search if it has a manual override
		if (event.type === 'editaddress') {
			this._addressOverride = true;
		} else if (event.type === 'selectaddress') {
			this._addressOverride = false;
		}
		// store the field value based on the `name` attribute
		this[fieldName] = fieldValue;
	}

	/**
	 * Invoked on demand, to get the latest form input data from customer search ui
	 * @returns {{firstname: string, emailAddress: string, phoneNumber: string, addressObj, lastname: string}}
	 */
	@api
	getFormInputs() {
		return {
			firstName: this._firstName,
			lastName: this._lastName,
			phoneNumber: this._phoneNumber,
			emailAddress: this._emailAddress,
			addressObj: this._addressObj,
			organisationAccountId: this._organisationAccountId,
			addressOverride: this._addressOverride
		};
	}

	/**
	 * Handles any `keyup` event and checks to see if the 'enter' key is pressed.
	 * If the 'enter' key is pressed, it will invoke the search action.
	 *
	 * @param {Event} event - The `keyup` event fired by the input element.
	 */
	handleInputKeyUp(event) {
		// Check if the 'enter' key was pressed
		if (event.keyCode === 13) {
			// Trigger the `blur` event
			event.target.blur();

			// Invoke the search action
			this.handleSearchBtnClick();
		}
	}

	/**
	 * Handles when the "Clear" button is clicked.
	 */
	handleClearBtnClick() {
		// Reset the form
		this.resetForm();
	}

	/**
	 * Handles when the "Search" button is clicked.
	 */
	handleSearchBtnClick() {
		this.performSearch();
	}
}