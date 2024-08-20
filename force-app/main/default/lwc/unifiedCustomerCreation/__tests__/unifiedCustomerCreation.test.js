import { createElement } from 'lwc';
import UnifiedCustomerCreation from 'c/unifiedCustomerCreation';
import createCustomer from '@salesforce/apex/UnifiedCustomerCreationController.createNewCustomer';
import {
	FIRST_NAME_LABEL,
	LAST_NAME_LABEL,
	PREFERRED_NAME_LABEL,
	PHONE_NUMBER_LABEL,
	EMAIL_ADDRESS_LABEL,
	ORGANISATION_LOOKUP_LABEL,
	MORE_INFO_REQUIRED_ERROR_MESSAGE,
	INPUT_ELEMENT_SELECTORS,
	INVALID_FORM_ERROR,
	CUSTOMER_TYPE_CONSUMER,
	CUSTOMER_TYPE_ORGANISATION,
	CONSUMER_RADIO_LABEL,
	ORGANISATION_RADIO_LABEL,
	NEW_ORGANISATION_RADIO_LABEL,
	NEW_ORGANISATION_TEXT_LABEL,
	ORGANISATION_REQUIRED_ERROR_MESSAGE
} from 'c/unifiedCustomerCreation';

const CUSTOMER_CREATION_RES_SUCCESS = '003000000000000001';
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
	'@salesforce/apex/UnifiedCustomerCreationController.createNewCustomer',
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

describe('c-unified-customer-creation', () => {
	afterEach(() => {
		// The jsdom instance is shared across test cases in a single file so reset the DOM
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}

		// Reset all jest mocks after each test
		jest.clearAllMocks();
	});

	it('displays common creation form input and button elements excluding selection of consumer and organisation', () => {
		// Arrange
		const element = createElement('c-unified-customer-creation', {
			is: UnifiedCustomerCreation
		});
		element.customerType = null;

		// Act
		document.body.appendChild(element);

		// Assert
		const firstNameInput = getInputFieldElement(element, 'firstName');
		expect(firstNameInput).not.toBeNull();
		expect(firstNameInput.type).toBe('text');
		expect(firstNameInput.label).toBe(FIRST_NAME_LABEL);
		expect(firstNameInput.placeholder).toBe(FIRST_NAME_LABEL);
		expect(firstNameInput.maxLength).toBe('80');
		expect(firstNameInput.value).toBe('');

		const lastNameInput = getInputFieldElement(element, 'lastName');
		expect(lastNameInput).not.toBeNull();
		expect(lastNameInput.type).toBe('text');
		expect(lastNameInput.label).toBe(LAST_NAME_LABEL);
		expect(lastNameInput.placeholder).toBe(LAST_NAME_LABEL);
		expect(lastNameInput.maxLength).toBe('80');
		expect(lastNameInput.value).toBe('');

		const preferredInput = getInputFieldElement(element, 'preferredName');
		expect(preferredInput).not.toBeNull();
		expect(preferredInput.type).toBe('text');
		expect(preferredInput.label).toBe(PREFERRED_NAME_LABEL);
		expect(preferredInput.placeholder).toBe(PREFERRED_NAME_LABEL);
		expect(preferredInput.maxLength).toBe('80');
		expect(preferredInput.value).toBe('');

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
		expect(phoneNumberInput.maxLength).toBe('20');
		expect(phoneNumberInput.value).toBe('');

		const ameAddressValidationCmp = getInputFieldElement(element, 'addressObj');
		expect(ameAddressValidationCmp).not.toBeNull();

	});

	it('displays specific creation form input and button elements for when customer type is null', () => {
		// Arrange
		const element = createElement('c-unified-customer-creation', {
			is: UnifiedCustomerCreation
		});
		element.customerType = null;

		// Act
		document.body.appendChild(element);

		// Assert
		const consumerRadioGroupInput = getInputFieldElement(
			element,
			'customerTypeConsumerRadioBtnValue'
		);
		expect(consumerRadioGroupInput).not.toBeNull();
		expect(consumerRadioGroupInput.type).toBe('radio');
		expect(consumerRadioGroupInput.label).toBe('Customer Type');
		expect(consumerRadioGroupInput.options).toEqual([{ label: CONSUMER_RADIO_LABEL, value: CUSTOMER_TYPE_CONSUMER }]);
		expect(consumerRadioGroupInput.value).toBe(CUSTOMER_TYPE_CONSUMER);

		const organisationRadioGroupInput = getInputFieldElement(
			element,
			'customerTypeOrganisationRadioBtnValue'
		);
		expect(organisationRadioGroupInput).not.toBeNull();
		expect(organisationRadioGroupInput.type).toBe('radio');
		expect(organisationRadioGroupInput.label).toBe('Customer Type');
		expect(organisationRadioGroupInput.options).toEqual([{ label: ORGANISATION_RADIO_LABEL, value: CUSTOMER_TYPE_ORGANISATION }]);
		expect(organisationRadioGroupInput.value).toBe(''); // Organidation should be Blank
	});

	it('displays specific creation form input and button elements for when customer type is consumer', () => {
		// Arrange
		const element = createElement('c-unified-customer-creation', {
			is: UnifiedCustomerCreation
		});
		element.customerType = CUSTOMER_TYPE_CONSUMER;

		// Act
		document.body.appendChild(element);

		// Assert
		const consumerRadioGroupInput = getInputFieldElement(
			element,
			'customerTypeConsumerRadioBtnValue'
		);
		expect(consumerRadioGroupInput).not.toBeNull();
		expect(consumerRadioGroupInput.type).toBe('radio');
		expect(consumerRadioGroupInput.label).toBe('Customer Type');
		expect(consumerRadioGroupInput.options).toEqual([{ label: CONSUMER_RADIO_LABEL, value: CUSTOMER_TYPE_CONSUMER }]);
		expect(consumerRadioGroupInput.value).toBe(CUSTOMER_TYPE_CONSUMER);

		const organisationRadioGroupInput = getInputFieldElement(
			element,
			'customerTypeOrganisationRadioBtnValue'
		);
		expect(organisationRadioGroupInput).not.toBeNull();
		expect(organisationRadioGroupInput.type).toBe('radio');
		expect(organisationRadioGroupInput.label).toBe('Customer Type');
		expect(organisationRadioGroupInput.options).toEqual([{ label: ORGANISATION_RADIO_LABEL, value: CUSTOMER_TYPE_ORGANISATION }]);
		expect(organisationRadioGroupInput.value).toBe(''); // Organidation should be Blank
	});

	it('displays specific creation form input and button elements for when customer type is organisation', async () => {
		// Arrange
		const element = createElement('c-unified-customer-creation', {
			is: UnifiedCustomerCreation
		});
		element.customerType = CUSTOMER_TYPE_ORGANISATION;

		// Act
		document.body.appendChild(element);

		// Assert
		const consumerRadioGroupInput = getInputFieldElement(
			element,
			'customerTypeConsumerRadioBtnValue'
		);
		expect(consumerRadioGroupInput).not.toBeNull();
		expect(consumerRadioGroupInput.type).toBe('radio');
		expect(consumerRadioGroupInput.label).toBe('Customer Type');
		expect(consumerRadioGroupInput.options).toEqual([{ label: CONSUMER_RADIO_LABEL, value: CUSTOMER_TYPE_CONSUMER }]);
		expect(consumerRadioGroupInput.value).toBe(''); // Consumer should be Blank

		const organisationRadioGroupInput = getInputFieldElement(
			element,
			'customerTypeOrganisationRadioBtnValue'
		);
		expect(organisationRadioGroupInput).not.toBeNull();
		expect(organisationRadioGroupInput.type).toBe('radio');
		expect(organisationRadioGroupInput.label).toBe('Customer Type');
		expect(organisationRadioGroupInput.options).toEqual([{ label: ORGANISATION_RADIO_LABEL, value: CUSTOMER_TYPE_ORGANISATION }]);
		expect(organisationRadioGroupInput.value).toBe(CUSTOMER_TYPE_ORGANISATION);

		const organisationLookupInput = getInputFieldElement(
			element,
			'organisationAccountId'
		);
		expect(organisationLookupInput).not.toBeNull();
		expect(organisationLookupInput.label).toBe(ORGANISATION_LOOKUP_LABEL);
		expect(organisationLookupInput.value).toBe('');

		const newOrganisationToggle = getInputFieldElement(
			element,
			'newOrganisationToggle'
		);

		expect(newOrganisationToggle).not.toBeNull();
		expect(newOrganisationToggle.label).toBe(NEW_ORGANISATION_RADIO_LABEL);
		expect(newOrganisationToggle.type).toBe('toggle');
		expect(newOrganisationToggle.checked).toBeFalsy;

		changeFormInputValues(element, {
			newOrganisationToggle: true // toggle on New Organisation
		});
		await flushAllPromises(); // re-render the UI
		expect(newOrganisationToggle.checked).toBeTruthy();

		const newOrganisationNameText = getInputFieldElement(
			element,
			'newOrganisationName'
		);
		expect(newOrganisationNameText).not.toBeNull();
		expect(newOrganisationNameText.label).toBe(NEW_ORGANISATION_TEXT_LABEL);
		expect(newOrganisationNameText.type).toBe('text');
		expect(newOrganisationNameText.maxLength).toBe('40');
		expect(newOrganisationNameText.value).toBe('');

		console.log('SETH newOrganisationToggle.checked:' + newOrganisationToggle.checked);
	});

	it('displays error when one or more fields are invalid', async () => {
		// Arrange
		const element = createElement('c-unified-customer-creation', {
			is: UnifiedCustomerCreation
		});

		// Act
		document.body.appendChild(element);

		// Mock all input checkValidity() methods to return 'false'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), false);

		// Click the create button
		const createButton = getButtonByDataId(element, 'create');
		createButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).not.toBeNull();
		expect(errorDiv.textContent).toBe(INVALID_FORM_ERROR);
	});

	it('displays required fields error when submitted without filling firstname and lastname, and at least one of mobile or email', async () => {
		// Arrange
		const element = createElement('c-unified-customer-creation', {
			is: UnifiedCustomerCreation
		});
		element.customerType = CUSTOMER_TYPE_CONSUMER;

		// Act
		document.body.appendChild(element);

		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);

		// Click the search button
		const createButton = getButtonByDataId(element, 'create');
		createButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).not.toBeNull();
		expect(errorDiv.textContent).toBe(MORE_INFO_REQUIRED_ERROR_MESSAGE);
	});

	it('displays required fields error when submitted without filling organisation details when custom type is organisation', async () => {
		// Arrange
		const element = createElement('c-unified-customer-creation', {
			is: UnifiedCustomerCreation
		});
		element.customerType = CUSTOMER_TYPE_ORGANISATION;

		// Act
		document.body.appendChild(element);

		// Set field values
		changeFormInputValues(element, {
			firstName: 'Seth',
			lastName: 'The Bear',
			phoneNumber: '0400123456',
			emailAddress: 'codybear@test.com',
		});

		await flushAllPromises();

		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);

		// Click the search button
		const createButton = getButtonByDataId(element, 'create');
		createButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Assert
		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).not.toBeNull();
		expect(errorDiv.textContent).toBe(ORGANISATION_REQUIRED_ERROR_MESSAGE);
	});


	it('send request to submit customer details successfully', async () => {
		// Arrange
		const element = createElement('c-unified-customer-creation', {
			is: UnifiedCustomerCreation
		});
		element.customerType = CUSTOMER_TYPE_CONSUMER;

		// mock success
		createCustomer.mockResolvedValue(CUSTOMER_CREATION_RES_SUCCESS);

		// Act
		document.body.appendChild(element);

		// Set field values
		changeFormInputValues(element, {
			firstName: 'Seth',
			lastName: 'The Bear',
			phoneNumber: '0400123456',
			emailAddress: 'codybear@test.com',
		});

		await flushAllPromises();

		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);

		// Click the search button
		const createButton = getButtonByDataId(element, 'create');
		createButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();


	});
})