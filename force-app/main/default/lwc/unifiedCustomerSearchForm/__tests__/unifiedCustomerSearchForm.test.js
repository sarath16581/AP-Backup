import { createElement } from 'lwc';
import UnifiedCustomerSearchForm from 'c/unifiedCustomerSearchForm';
import customerSearch from '@salesforce/apex/UnifiedCustomerSearchController.search';
import {
	FIRST_NAME_LABEL,
	LAST_NAME_LABEL,
	PHONE_NUMBER_LABEL,
	EMAIL_ADDRESS_LABEL,
	ORGANISATION_CHECKBOX_LABEL,
	CONSUMER_CHECKBOX_LABEL,
	ORGANISATION_LOOKUP_LABEL,
	ABN_ACN_LABEL,
	SEARCH_BUTTON_LABEL,
	CLEAR_BUTTON_LABEL,
	MORE_INFO_REQUIRED_ERROR_MESSAGE,
	INPUT_ELEMENT_SELECTORS,
	GENERIC_SEARCH_ERROR_MSG,
	INVALID_FORM_ERROR
} from 'c/unifiedCustomerSearchForm';

const CUSTOMER_SEARCH_RES_SUCCESS = {
	searchResults: [],
	warningMessage: undefined,
};
const CUSTOMER_SEARCH_RES_ERROR = {
	body: { message: 'An internal server error has occurred' },
	ok: false,
	status: 500,
	statusText: 'Internal server error',
};

/**
 * Sets the value of the a form input element and fires the 'change' event.
 * Does not currently support all components or input types. These should be added as needed.
 *
 * @param {Element} element
 * @param {any} value - Set the input element's value to this.
 */
function changeInputFieldValue(element, value) {
	if (element?.nodeName.toLowerCase() === 'lightning-input') {
		// Handle checkbox/toggle elements
		if (element.type === 'checkbox' || element.type === 'toggle') {
			element.checked = value === true;
			element.dispatchEvent(
				new CustomEvent('change', { detail: { checked: element.checked } })
			);
		}

		// Handle other input types
		element.value = value;
		element.dispatchEvent(
			new CustomEvent('change', { detail: { value: element.value } })
		);
		return;
	} else if (element?.nodeName.toLowerCase() === 'lightning-record-picker') {
		element.value = value;
		element.dispatchEvent(
			new CustomEvent('change', { detail: { recordId: element.value } })
		);
		return;
	} else if (element?.nodeName.toLowerCase() === 'c-ame-address-validation2') {
		element.dispatchEvent(new CustomEvent('selectaddress', {detail: value}));
		return;
	}

	throw new Error(`Unhandled element: '${element?.nodeName}'`);
}

/**
 * Bulk set the value of the a form input element and fires the 'change' events.
 * 
 * @param {Element} element 
 * @param {object} data - e.g. { dataFieldId: "newValue" }
 */
function changeFormInputValues(element, data) {
	for(const field of Object.keys(data)) {
		const inputEl = getInputFieldElement(element, field, true);
		changeInputFieldValue(inputEl, data[field]);
	}
}

/**
 * Finds and returns input field based on the `data-field-name` attribute.
 *
 * @param {Element} element - The element to run `querySelector` on
 * @param {string} fieldName - The dataFieldName attribute to query
 * @param {boolean} throwError - If the element cannot be found, throw an error. Default = false.
 * @returns {HTMLElement} - The HTMLElement that was found
 */
function getInputFieldElement(element, fieldName, throwError=false) {
	const inputEl = element.shadowRoot.querySelector(`[data-field-name='${fieldName}']`);
	if(!inputEl && throwError) {
		throw new Error(`Could not find element for '${fieldName}'`);
	}
	return inputEl;
}

/**
 * Finds and returns lightning-button based on the `data-id` attribute.
 *
 * @param {Element} element - The element to run `querySelector` on
 * @param {string} dataId - The dataId attribute to query
 * @returns {HTMLElement} - The HTMLElement that was found
 */
function getButtonByDataId(element, dataId) {
	return element.shadowRoot.querySelector(
		`lightning-button[data-id='${dataId}']`
	);
}

/**
 * Mock the checkValidity() methods to return specified value.
 * Useful when testing for valid inputs as the default stub returns 'undefined'.
 *
 * @param {Element} element - The element to run `querySelectorAll` on
 * @param {string} selector - The querySelector to use e.g. "lightning-input"
 * @param {boolean} result - The boolean value which should be returned by the method
 */
function mockCheckValidity(element, selector, result) {
	[...element.shadowRoot.querySelectorAll(selector)].forEach((el) => {
		el.checkValidity = jest.fn().mockReturnValue(result);
	});
}

// Mock imperative Apex method call
jest.mock(
	'@salesforce/apex/UnifiedCustomerSearchController.search',
	() => {
		return {
			default: jest.fn(),
		};
	},
	{ virtual: true }
);

/**
 * Helper function to flush all pending promises in the event loop.
 * Useful for ensuring all asynchronous operations are complete before
 * proceeding with test assertions.
 * @returns {Promise<void>} A promise that resolves after all pending promises are flushed.
 */
function flushAllPromises() {
	// eslint-disable-next-line @lwc/lwc/no-async-operation
	return new Promise((resolve) => setTimeout(resolve, 0));
}

describe('c-unified-customer-search-form', () => {
	afterEach(() => {
		// The jsdom instance is shared across test cases in a single file so reset the DOM
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}

		// Reset all jest mocks after each test
		jest.clearAllMocks();
	});

	it('displays search form input and button elements', () => {
		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		// Assert
		const firstNameInput = getInputFieldElement(element, 'firstName');
		expect(firstNameInput).not.toBeNull();
		expect(firstNameInput.type).toBe('text');
		expect(firstNameInput.label).toBe(FIRST_NAME_LABEL);
		expect(firstNameInput.placeholder).toBe(FIRST_NAME_LABEL);
		expect(firstNameInput.maxLength).toBe('40');
		expect(firstNameInput.value).toBe('');

		const lastNameInput = getInputFieldElement(element, 'lastName');
		expect(lastNameInput).not.toBeNull();
		expect(lastNameInput.type).toBe('text');
		expect(lastNameInput.label).toBe(LAST_NAME_LABEL);
		expect(lastNameInput.placeholder).toBe(LAST_NAME_LABEL);
		expect(lastNameInput.maxLength).toBe('80');
		expect(lastNameInput.value).toBe('');

		const emailAddressInput = getInputFieldElement(element, 'emailAddress');
		expect(emailAddressInput).not.toBeNull();
		expect(emailAddressInput.type).toBe('email');
		expect(emailAddressInput.label).toBe(EMAIL_ADDRESS_LABEL);
		expect(emailAddressInput.placeholder).toBe(EMAIL_ADDRESS_LABEL);
		expect(emailAddressInput.maxLength).toBe('80');
		expect(emailAddressInput.value).toBe('');

		const phoneNumberInput = getInputFieldElement(element, 'phoneNumber');
		expect(phoneNumberInput).not.toBeNull();
		expect(phoneNumberInput.type).toBe('tel');
		expect(phoneNumberInput.label).toBe(PHONE_NUMBER_LABEL);
		expect(phoneNumberInput.placeholder).toBe(PHONE_NUMBER_LABEL);
		expect(phoneNumberInput.maxLength).toBe('40');
		expect(phoneNumberInput.value).toBe('');

		const organisationCheckboxInput = getInputFieldElement(
			element,
			'organisationCheckbox'
		);
		expect(organisationCheckboxInput).not.toBeNull();
		expect(organisationCheckboxInput.type).toBe('checkbox');
		expect(organisationCheckboxInput.label).toBe(ORGANISATION_CHECKBOX_LABEL);
		expect(organisationCheckboxInput.checked).toBe(false);

		const consumerCheckboxInput = getInputFieldElement(
			element,
			'consumerCheckbox'
		);
		expect(consumerCheckboxInput).not.toBeNull();
		expect(consumerCheckboxInput.type).toBe('checkbox');
		expect(consumerCheckboxInput.label).toBe(CONSUMER_CHECKBOX_LABEL);
		expect(consumerCheckboxInput.checked).toBe(false);

		const organisationLookupInput = getInputFieldElement(
			element,
			'organisationAccountId'
		);
		expect(organisationLookupInput).not.toBeNull();
		expect(organisationLookupInput.label).toBe(ORGANISATION_LOOKUP_LABEL);

		const abnAcnInput = getInputFieldElement(element, 'abnAcn');
		expect(abnAcnInput).not.toBeNull();
		expect(abnAcnInput.type).toBe('text');
		expect(abnAcnInput.label).toBe(ABN_ACN_LABEL);
		expect(abnAcnInput.maxLength).toBe('11');
		expect(abnAcnInput.value).toBe('');

		const buttons = [
			...element.shadowRoot.querySelectorAll('lightning-button'),
		];
		expect(buttons.length).toBe(2);

		const searchButton = buttons[0];
		expect(searchButton).not.toBeNull();
		expect(searchButton.label).toBe(SEARCH_BUTTON_LABEL);

		const clearButton = buttons[1];
		expect(clearButton).not.toBeNull();
		expect(clearButton.label).toBe(CLEAR_BUTTON_LABEL);
	});

	it('allows pre-populating input field values', () => {
		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});
		element.firstName = 'Joan';
		element.lastName = 'Watson';
		element.emailAddress = 'jwatson@example.com';
		element.phoneNumber = '0401234567';

		// Act
		document.body.appendChild(element);

		// Assert
		const firstNameInput = getInputFieldElement(element, 'firstName');
		expect(firstNameInput).not.toBeNull();
		expect(firstNameInput.value).toBe('Joan');

		const lastNameInput = getInputFieldElement(element, 'lastName');
		expect(lastNameInput).not.toBeNull();
		expect(lastNameInput.value).toBe('Watson');

		const emailAddressInput = getInputFieldElement(element, 'emailAddress');
		expect(emailAddressInput).not.toBeNull();
		expect(emailAddressInput.value).toBe('jwatson@example.com');

		const phoneNumberInput = getInputFieldElement(element, 'phoneNumber');
		expect(phoneNumberInput).not.toBeNull();
		expect(phoneNumberInput.value).toBe('0401234567');
	});

	it('displays error when one or more fields are invalid', async () => {
		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		// Mock all input checkValidity() methods to return 'false'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), false);

		// Click the search button
		const searchButton = getButtonByDataId(element, 'search');
		searchButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).not.toBeNull();
		expect(errorDiv.textContent).toBe(INVALID_FORM_ERROR);
	});

	it('displays error when submitted without any values', async () => {
		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		const searchEvent = jest.fn();
		element.addEventListener('search', searchEvent);

		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);

		// Click the search button
		const searchButton = getButtonByDataId(element, 'search');
		searchButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).not.toBeNull();
		expect(errorDiv.textContent).toBe(MORE_INFO_REQUIRED_ERROR_MESSAGE);
		expect(searchEvent).not.toHaveBeenCalled();
	});

	it('displays error when submitted with first name, but no last name', async () => {
		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		const searchEvent = jest.fn();
		element.addEventListener('search', searchEvent);

		const firstNameInput = getInputFieldElement(element, 'firstName');
		changeInputFieldValue(firstNameInput, 'Sherlock');

		// Mock all lightning-input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);

		// Click the search button
		const searchButton = getButtonByDataId(element, 'search');
		searchButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).not.toBeNull();
		expect(errorDiv.textContent).toBe(MORE_INFO_REQUIRED_ERROR_MESSAGE);
		expect(searchEvent).not.toHaveBeenCalled();
	});

	it('displays error when submitted with last name, but no first name', async () => {
		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		const searchEvent = jest.fn();
		element.addEventListener('search', searchEvent);

		const lastNameInput = getInputFieldElement(element, 'lastName');
		changeInputFieldValue(lastNameInput, 'Holmes');

		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);

		// Click the search button
		const searchButton = getButtonByDataId(element, 'search');
		searchButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).not.toBeNull();
		expect(errorDiv.textContent).toBe(MORE_INFO_REQUIRED_ERROR_MESSAGE);
		expect(searchEvent).not.toHaveBeenCalled();
	});

	it('allows last name withtout first name if mobile is provided', async () => {
		// Assign mock value for resolved Apex promise
		customerSearch.mockResolvedValue(CUSTOMER_SEARCH_RES_SUCCESS);

		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		const searchEvent = jest.fn();
		element.addEventListener('search', searchEvent);

		const lastNameInput = getInputFieldElement(element, 'lastName');
		changeInputFieldValue(lastNameInput, 'Holmes');

		const phoneNumberInput = getInputFieldElement(element, 'phoneNumber');
		changeInputFieldValue(phoneNumberInput, 'Holmes');

		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);

		// Click the search button
		const searchButton = getButtonByDataId(element, 'search');
		searchButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).toBeNull();
		expect(searchEvent).toHaveBeenCalled();
	});

	it('allows phone number as the only input', async () => {
		// Assign mock value for resolved Apex promise
		customerSearch.mockResolvedValue(CUSTOMER_SEARCH_RES_SUCCESS);

		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		const searchEvent = jest.fn();
		element.addEventListener('search', searchEvent);

		const phoneNumberInput = getInputFieldElement(element, 'phoneNumber');
		changeInputFieldValue(phoneNumberInput, '0400000000');

		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);

		// Click the search button
		const searchButton = getButtonByDataId(element, 'search');
		searchButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).toBeNull();
		expect(searchEvent).toHaveBeenCalled();
	});

	it('disables consumer checkbox when organisation checkbox is selected', async () => {
		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		const organisationCheckboxInput = getInputFieldElement(
			element,
			'organisationCheckbox'
		);
		changeInputFieldValue(organisationCheckboxInput, true);

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		expect(organisationCheckboxInput.checked).toBe(true);
		expect(organisationCheckboxInput.disabled).toBe(false);

		const consumerCheckboxInput = getInputFieldElement(
			element,
			'consumerCheckbox'
		);
		expect(consumerCheckboxInput.disabled).toBe(true);
	});

	it('disables organisation checkbox when consumer checkbox is selected', async () => {
		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		const consumerCheckboxInput = getInputFieldElement(
			element,
			'consumerCheckbox'
		);
		changeInputFieldValue(consumerCheckboxInput, true);

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		expect(consumerCheckboxInput.checked).toBe(true);
		expect(consumerCheckboxInput.disabled).toBe(false);

		const organisationCheckboxInput = getInputFieldElement(
			element,
			'organisationCheckbox'
		);
		expect(organisationCheckboxInput.disabled).toBe(true);
	});

	it('hides organisation input fields when consumer checkbox is selected', async () => {
		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		const consumerCheckboxInput = getInputFieldElement(
			element,
			'consumerCheckbox'
		);
		changeInputFieldValue(consumerCheckboxInput, true);

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		const organisationLookupInput = getInputFieldElement(
			element,
			'organisationAccountId'
		);
		expect(organisationLookupInput).toBeNull();

		const abnAcnInput = getInputFieldElement(element, 'abnAcn');
		expect(abnAcnInput).toBeFalsy();
	});

	it('disables ABN/ACN input when Organisation is selected', async () => {
		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		// Assert
		const organisationLookupInput = getInputFieldElement(
			element,
			'organisationAccountId'
		);
		changeInputFieldValue(organisationLookupInput, '001000000000000000');

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		const abnAcnInput = getInputFieldElement(element, 'abnAcn');
		expect(abnAcnInput.disabled).toBe(true);
	});

	it('disables phone field when include phone toggle disabled', async () => {
		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		// Assert
		const includePhoneToggle =getInputFieldElement(element, 'includePhoneNumber');
		expect(includePhoneToggle.checked).toBe(true);

		const phoneNumberInput = getInputFieldElement(element,'phoneNumber');
		expect(phoneNumberInput.disabled).toBeFalsy();

		changeInputFieldValue(includePhoneToggle, false);

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		expect(phoneNumberInput.disabled).toBe(true);
	});

	it('disables email field when include email toggle disabled', async () => {
		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		// Assert
		const includeEmailToggle =getInputFieldElement(element, 'includeEmailAddress');
		expect(includeEmailToggle.checked).toBe(true);

		const emailAddressInput = getInputFieldElement(element,'emailAddress');
		expect(emailAddressInput.disabled).toBeFalsy();

		changeInputFieldValue(includeEmailToggle, false);

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		expect(emailAddressInput.disabled).toBe(true);
	});

	it('displays spinner while searching', async () => {
		// Assign mock value for resolved Apex promise
		customerSearch.mockResolvedValue(CUSTOMER_SEARCH_RES_SUCCESS);

		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		// Expect lightning-spinner to be hidden by default
		expect(element.shadowRoot.querySelector('lightning-spinner')).toBeFalsy();

		// Prepare valid test data
		const emailAddressInput = getInputFieldElement(element, 'emailAddress');
		changeInputFieldValue(emailAddressInput, 'sherlock@example.com');

		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);

		// Click the search button
		const searchButton = getButtonByDataId(element, 'search');
		searchButton.click();

		// Wait for DOM to update (but not for Apex method to resolve)
		await Promise.resolve();

		// Assert
		// Expect lightning-spinner to be displayed
		expect(element.shadowRoot.querySelector('lightning-spinner')).toBeTruthy();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Expect lightning-spinner to be hidden after search completed
		expect(element.shadowRoot.querySelector('lightning-spinner')).toBeFalsy();
	});

	it('fires "result" event on search callout success', async () => {
		// Assign mock value for resolved Apex promise
		customerSearch.mockResolvedValue(CUSTOMER_SEARCH_RES_SUCCESS);

		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		const searchEvent = jest.fn();
		element.addEventListener('search', searchEvent);

		const resultEvent = jest.fn();
		element.addEventListener('result', resultEvent);

		// Prepare valid test data
		const emailAddressInput = getInputFieldElement(element, 'emailAddress');
		changeInputFieldValue(emailAddressInput, 'sherlock@example.com');

		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);

		// Click the search button
		const searchButton = getButtonByDataId(element, 'search');
		searchButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		expect(searchEvent).toHaveBeenCalled();
		expect(resultEvent).toHaveBeenCalledWith(
			expect.objectContaining({ detail: CUSTOMER_SEARCH_RES_SUCCESS })
		);
	});

	it('fires "error" on search callout error', async () => {
		// Assign mock value for resolved Apex promise
		customerSearch.mockRejectedValue(CUSTOMER_SEARCH_RES_ERROR);

		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		const searchEvent = jest.fn();
		element.addEventListener('search', searchEvent);

		const errorEvent = jest.fn();
		element.addEventListener('error', errorEvent);

		// Prepare valid test data
		const emailAddressInput = getInputFieldElement(element, 'emailAddress');
		changeInputFieldValue(emailAddressInput, 'sherlock@example.com');

		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);

		// Click the search button
		const searchButton = getButtonByDataId(element, 'search');
		searchButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		expect(searchEvent).toHaveBeenCalled();
		expect(errorEvent).toHaveBeenCalledWith(
			expect.objectContaining({
				detail: GENERIC_SEARCH_ERROR_MSG,
			})
		);
	});

	it('displays error message on search callout error', async () => {
		// Assign mock value for resolved Apex promise
		customerSearch.mockRejectedValue(CUSTOMER_SEARCH_RES_ERROR);

		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		// Prepare valid test data
		const emailAddressInput = getInputFieldElement(element, 'emailAddress');
		changeInputFieldValue(emailAddressInput, 'sherlock@example.com');

		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);

		// Click the search button
		const searchButton = getButtonByDataId(element, 'search');
		searchButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).not.toBeNull();
		expect(errorDiv.textContent).toBe(GENERIC_SEARCH_ERROR_MSG);
	});

	it('clears form on "Clear" button click', async () => {
		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		// Prepare valid test data
		const firstNameInput = getInputFieldElement(element, 'firstName');
		changeInputFieldValue(firstNameInput, 'Sherlock');

		const lastNameInput = getInputFieldElement(element, 'lastName');
		changeInputFieldValue(lastNameInput, 'Holmes');

		const phoneNumberInput = getInputFieldElement(element, 'phoneNumber');
		changeInputFieldValue(phoneNumberInput, '0400 000 000');

		const emailAddressInput = getInputFieldElement(element, 'emailAddress');
		changeInputFieldValue(emailAddressInput, 'sherlock@');
		emailAddressInput.setCustomValidity('bad email');

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Click the search button
		const clearButton = getButtonByDataId(element, 'clear');
		clearButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		expect(firstNameInput.value).toBe('');
		expect(lastNameInput.value).toBe('');
		expect(phoneNumberInput.value).toBe('');
		expect(emailAddressInput.value).toBe('');
	});

	it('sends request with all fields populated, except customer type', async () => {
		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Assign mock value for resolved Apex promise
		customerSearch.mockResolvedValue(CUSTOMER_SEARCH_RES_SUCCESS);

		// Act
		document.body.appendChild(element);
		
		// Set field values
		changeFormInputValues(element, {
				firstName: 'Codey',
				lastName: 'The Bear',
				phoneNumber: '0400 000 000',
				emailAddress: 'sherlock@example.com',
				consumerCheckbox: false,
				organisationCheckbox: false,
				includePhoneNumber: true,
				includeEmailAddress: true,
				organisationAccountId: '001000000000000000',
				abnAcn: '98765432100',
				addressObj: {
					addressLine1: 'U 404',
					addressLine2: '42 Coder DR',
					city: 'Developer Park',
					state: 'WWW',
					postcode: '1337'
				}
		});

		await flushAllPromises();
		
		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);
		
		// Click the search button
		const searchButton = getButtonByDataId(element, 'search');
		searchButton.click();

		await flushAllPromises();

		// Assert
		expect(customerSearch.mock.calls).toHaveLength(1);
		const { req } = customerSearch.mock.calls[0][0];
		expect(Object.keys(req).length).toBe(12);
		expect(req.firstName).toBe('Codey');
		expect(req.lastName).toBe('The Bear');
		expect(req.phoneNumber).toBe('0400 000 000');
		expect(req.emailAddress).toBe('sherlock@example.com');
		expect(req.customerType).toBe(null);
		expect(req.addressStreet1).toBe('U 404');
		expect(req.addressStreet2).toBe('42 Coder DR');
		expect(req.addressCity).toBe('Developer Park');
		expect(req.addressState).toBe('WWW');
		expect(req.addressPostalCode).toBe('1337');
		expect(req.accountId).toBe('001000000000000000');
		expect(req.abnAcn).toBe(null);
	});

	it('send request for consumer, ensuring that organisation details are null', async () => {
		// Arrange
		const element = createElement('c-unified-customer-search-form', {
			is: UnifiedCustomerSearchForm,
		});

		// Assign mock value for resolved Apex promise
		customerSearch.mockResolvedValue(CUSTOMER_SEARCH_RES_SUCCESS);

		// Act
		document.body.appendChild(element);
		
		// Set field values
		changeFormInputValues(element, {
				firstName: 'Codey',
				lastName: 'The Bear',
				consumerCheckbox: true,
				organisationAccountId: '001000000000000000',
				abnAcn: '98765432100',
		});

		await flushAllPromises();
		
		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);
		
		// Click the search button
		const searchButton = getButtonByDataId(element, 'search');
		searchButton.click();

		await flushAllPromises();

		// Assert
		expect(customerSearch.mock.calls).toHaveLength(1);
		const { req } = customerSearch.mock.calls[0][0];
		expect(Object.keys(req).length).toBe(12);
		expect(req.firstName).toBe('Codey');
		expect(req.lastName).toBe('The Bear');
		expect(req.customerType).toBe('CONSUMER');
		expect(req.accountId).toBe(null);
		expect(req.abnAcn).toBe(null);
	});
});
