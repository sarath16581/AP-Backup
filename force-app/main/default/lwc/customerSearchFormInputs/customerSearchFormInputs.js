import { LightningElement, api } from "lwc";
import customerSearch from "@salesforce/apex/CustomerSearchFormController.search";
import { isBlank, isNotBlank } from "c/utils";
import { reduceErrors } from "c/ldsUtils";

// Lightning card title
export const SEARCH_FORM_TITLE = "Customer Search";

// Field and button labels
export const FIRST_NAME_LABEL = "First Name";
export const LAST_NAME_LABEL = "Last Name";
export const PHONE_NUMBER_LABEL = "Phone";
export const EMAIL_ADDRESS_LABEL = "Email";
export const SEARCH_BUTTON_LABEL = "Search";
export const CLEAR_BUTTON_LABEL = "Clear";

// Field validation regular expression patterns
export const NAME_INPUT_REGEX = '^[^\\.\\!\\(\\)\\[\\]"1-9]*$'; // TODO: create pattern in utility class
export const EMAIL_INPUT_REGEX = undefined; // TODO: leverage existing utility class (currently uses OOTB lighting-input email pattern)
export const PHONE_INPUT_REGEX = "^[\\d ]+$"; // TODO: leverage existing utility class

// Error messages
export const INVALID_NAME_MSG = "Invalid name format";
export const INVALID_PHONE_NUMBER_MSG = "Invalid phone number";
export const INVALID_EMAIL_ADDRESS_MSG = "Invalid email address format";
export const MORE_INFO_REQUIRED_ERROR_MESSAGE =
	"Please enter at least First and Last Name, or Phone, or Email.";
export const FIRST_AND_LAST_NAME_REQUIRED_ERROR_MESSAGE =
	"Please enter both First and Last name (or leave both blank).";
export const INVALID_FORM_ERROR = "Please fix and errors and try again";

// Element selectors
export const INPUT_ELEMENT_SELECTORS = ["lightning-input"];

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
	_firstName = "";
	_lastName = "";
	_phoneNumber = "";
	_emailAddress = "";

	errorMessage = undefined;
	isLoading = false;

	// Lightning card title
	searchFormTitle = SEARCH_FORM_TITLE;

	// Field and button labels
	firstNameLabel = FIRST_NAME_LABEL;
	lastNameLabel = LAST_NAME_LABEL;
	phoneNumberLabel = PHONE_NUMBER_LABEL;
	emailAddressLabel = EMAIL_ADDRESS_LABEL;
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
				...this.template.querySelectorAll(INPUT_ELEMENT_SELECTORS.join(",")),
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

			// Cannot include first name, but not last name
			if (isNotBlank(this.firstName) && isBlank(this.lastName)) {
				isValid = false;
				this.errorMessage = FIRST_AND_LAST_NAME_REQUIRED_ERROR_MESSAGE;
			}

			// Cannot include last name, but not first name
			if (isBlank(this.firstName) && isNotBlank(this.lastName)) {
				isValid = false;
				this.errorMessage = FIRST_AND_LAST_NAME_REQUIRED_ERROR_MESSAGE;
			}

			// At least one of the following fields is required to be included in the
			// search query. If they're all bank, display an error.
			if (
				isBlank(this.firstName) &&
				isBlank(this.lastName) &&
				isBlank(this.phoneNumber) &&
				isBlank(this.emailAddress)
			) {
				isValid = false;
				this.errorMessage = MORE_INFO_REQUIRED_ERROR_MESSAGE;
			}

			return isValid;
		} catch (err) {
			this.errorMessage = reduceErrors(err).join(",");
			return false;
		}
	}

	/**
	 * Submits the form and performs the search.
	 *
	 * @fires InputChangeEvent#searchstart
	 * @fires InputChangeEvent#searchresult
	 * @fires InputChangeEvent#searcherror
	 */
	performSearch() {
		// Validate inputs before invoking the search method
		if (!this.validateInputs()) {
			if (this.errorMessage === undefined) {
				this.errorMessage = INVALID_FORM_ERROR;
			}
			return;
		}

		// Invoke the search method
		this.isLoading = true;
		this.dispatchEvent(new CustomEvent("searchstart"));
		customerSearch({
			req: {
				firstName: this.firstName,
				lastName: this.lastName,
				emailAddress: this.emailAddress,
				phoneNumber: this.phoneNumber,
			},
		})
			.then((res) => {
				// Handle search results
				this.dispatchEvent(
					new CustomEvent("searchresult", {
						detail: JSON.parse(JSON.stringify(res)),
					})
				);
				this.isLoading = false;
			})
			.catch((error) => {
				// Handle search errors
				this.errorMessage = reduceErrors(error).join(",");
				this.dispatchEvent(
					new CustomEvent("searcherror", { detail: this.errorMessage })
				);
				this.isLoading = false;
			});
	}

	/**
	 * Handle `blur` events from input components and trim any leading
	 * or training whitespaces from string values.
	 *
	 * @param {Event} event - The `blur` event fired by the input element.
	 * @fires InputChangeEvent#inputchange
	 */
	handleInputBlur(event) {
		if (typeof event.target.value === "string") {
			// Trim any leading or trailing spaces for text inputs from `string` inputs
			const oldValue = event.target.value;
			const newValue = oldValue.trim();
			if (oldValue !== newValue) {
				event.target.value = newValue;
				event.target.dispatchEvent(
					new CustomEvent("change", {
						detail: {
							value: event.target.value,
						},
					})
				);
			}
		}
	}

	/**
	 * Handles input field change events and stores the value in the
	 * corresponding variable based on the `data-field-name` attribute.
	 *
	 * Fires a new event (`inputchange`) with the `fieldName` and `value` details.
	 *
	 * @param {Event} event - The `change` event fired by the input element.
	 * @fires CustomEvent#inputchange
	 */
	handleInputChange(event) {
		const { fieldName } = event.target.dataset;
		const fieldValue = event.target.value;

		// store the field value based on the `name` attribute
		this[fieldName] = fieldValue;

		this.dispatchEvent(
			new CustomEvent("inputchange", {
				detail: {
					fieldName: fieldName,
					value: fieldValue,
				},
			})
		);
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
		// TODO: implement
	}

	/**
	 * Handles when the "Search" button is clicked.
	 */
	handleSearchBtnClick() {
		this.performSearch();
	}
}
