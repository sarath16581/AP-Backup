import { LightningElement, api } from 'lwc';
import customerSearch from '@salesforce/apex/CustomerSearchFormController.search';
import { isNotBlank } from 'c/utils';
import { reduceErrors } from 'c/ldsUtils';

// Field and button labels
export const FIRST_NAME_LABEL = 'First Name';
export const LAST_NAME_LABEL = 'Last Name';
export const PHONE_NUMBER_LABEL = 'Phone';
export const EMAIL_ADDRESS_LABEL = 'Email';
export const ORGANISATION_CHECKBOX_LABEL = 'Organisation';
export const CONSUMER_CHECKBOX_LABEL = 'Consumer';
export const SEARCH_BUTTON_LABEL = 'Search';
export const CLEAR_BUTTON_LABEL = 'Clear';

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
export const MORE_INFO_REQUIRED_ERROR_MESSAGE =
	'Please enter at least First and Last Name, or Phone, or Email.';
export const INVALID_FORM_ERROR = 'Please fix and errors and try again';

// Element selectors
export const INPUT_ELEMENT_SELECTORS = ['lightning-input'];

/**
 * This component displays a form with several inputs which are used to search
 * to identify the Contact record(s) which match the criteria.
 *
 * @alias CustomerSearchFormInputs
 * @hideconstructor
 */
export default class CustomerSearchFormInputs extends LightningElement {
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

	// Private variables for input fields, used with public getters/setters
	_firstName = '';
	_lastName = '';
	_phoneNumber = '';
	_emailAddress = '';
	organisationCheckbox = false;
	consumerCheckbox = false;

	errorMessage = undefined;
	isLoading = false;

	// Field and button labels
	firstNameLabel = FIRST_NAME_LABEL;
	lastNameLabel = LAST_NAME_LABEL;
	phoneNumberLabel = PHONE_NUMBER_LABEL;
	emailAddressLabel = EMAIL_ADDRESS_LABEL;
	organisationCheckboxLabel = ORGANISATION_CHECKBOX_LABEL;
	consumerCheckboxLabel = CONSUMER_CHECKBOX_LABEL;
	searchButtonLabel = SEARCH_BUTTON_LABEL;
	clearButtonLabel = CLEAR_BUTTON_LABEL;

	// Field validation patterns
	nameInputRegex = NAME_INPUT_REGEX;
	emailInputRegex = EMAIL_INPUT_REGEX;
	phoneInputRegex = PHONE_INPUT_REGEX;

	// Field validation error messages
	invalidNameMsg = INVALID_NAME_MSG;
	invalidEmailAddressMsg = INVALID_EMAIL_ADDRESS_MSG;
	invalidPhoneNumberMsg = INVALID_PHONE_NUMBER_MSG;

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
	 * @fires CustomerSearchFormInputs#search
	 * @fires CustomerSearchFormInputs#result
	 * @fires CustomerSearchFormInputs#error
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
					emailAddress: this.emailAddress,
					phoneNumber: this.phoneNumber,
					customerType: this.consumerCheckbox
						? CUSTOMER_TYPE_CONSUMER
						: this.organisationCheckbox
						? CUSTOMER_TYPE_ORGANISATION
						: null,
				},
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
	 * @fires CustomerSearchFormInputs#reset
	 */
	async resetForm() {
		// Reset error message
		this.errorMessage = undefined;

		// Clear each field value
		this._firstName = '';
		this._lastName = '';
		this._emailAddress = '';
		this._phoneNumber = '';

		// Ensure field values are updated before continuing
		await Promise.resolve();

		// Collect all form input elements
		const inputElements = [
			...this.template.querySelectorAll(INPUT_ELEMENT_SELECTORS.join(',')),
		];

		// Clear any field-level error messages
		inputElements.forEach((field) => {
			field.setCustomValidity(''); // Clear any custom validation message
			field.reportValidity(); // Refresh the UI to clear any error styles
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
		// const fieldValue = event.target.value;
		let fieldValue = event.target.value;
		// Handle different types of input fields
		if (event.target.type === 'checkbox') {
			fieldValue = event.target.checked === true;
		}

		// store the field value based on the `name` attribute
		this[fieldName] = fieldValue;
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
