import { createElement } from 'lwc';
import getCaseRecordTypeInfos from "@salesforce/apex/UnifiedCaseCreationController.getCaseRecordTypeInfos";
import { getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import UnifiedCaseCreation from 'c/unifiedCaseCreation';
import createNewCase from '@salesforce/apex/UnifiedCaseCreationController.createNewCase';
import {
	ARTICLES_LABEL,
	CONTACT_LABEL,
	ENQUIRY_TYPE_LABEL,
	ENQUIRY_SUBTYPE_LABEL,
	PRODUCT_CATEGORY_LABEL,
	PRODUCT_SUBCATEGORY_LABEL,
	NOTES_LABEL,
	CREATE_BUTTON_LABEL,
	ENQUIRY_TYPE_OPTIONS,
	INPUT_ELEMENT_SELECTORS,
	CONTACTID_MISSING_ERROR,
	IMPACTED_ARTICLE_MISSING_ERROR,
	INVALID_FORM_ERROR
} from 'c/unifiedCaseCreation';

// Mock picklist data
const mockGetPicklistValuesForInvestigationRecType = require('./data/getPicklistValuesByInvestigationRecType.json');
const mockGetPicklistValuesForGeneralEnquiryRecType = require('./data/getPicklistValuesByGeneralEnquiryRecType.json');
const mockGetCaseRecordTypeInfos = require('./data/getCaseRecordTypeInfos.json');

// Mock Apex Response
const CASE_CREATION_RES_SUCCESS = '500000000000000001';
const CASE_CREATION_RES_ERROR = {
	body: { message: 'An internal server error has occurred' },
	ok: false,
	status: 500,
	statusText: 'Internal server error',
};

// Mock imperative Apex method call
jest.mock(
	'@salesforce/apex/UnifiedCaseCreationController.createNewCase',
	() => {
		return {
			default: jest.fn(),
		};
	},
	{ virtual: true }
);

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

/**
 * Sets the value of the a form input element and fires the 'change' event.
 * Does not currently support all components or input types. These should be added as needed.
 *
 * @param {Element} element
 * @param {any} value - Set the input element's value to this.
 */
function changeInputFieldValue(element, value) {
	if (element?.nodeName.toLowerCase() === 'lightning-combobox') {
		element.value = value;
		element.dispatchEvent(
			new CustomEvent('change', { detail: { recordId: element.value } })
		);
		return;
	} else if (element?.nodeName.toLowerCase() === 'lightning-record-picker') {
		element.value = value;
		element.dispatchEvent(
			new CustomEvent('change', { detail: { recordId: element.value } })
		);
		return;
	} else if (element?.nodeName.toLowerCase() === 'lightning-textarea') {
		element.value = value;
		element.dispatchEvent(
			new CustomEvent('change', { detail: { recordId: element.value } })
		);
		return;
	}

	throw new Error(`Unhandled element: '${element?.nodeName}'`);
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
 * Finds and returns input field based on the `data-field-name` attribute.
 *
 * @param {Element} element - The element to run `querySelector` on
 * @param {string} fieldName - The dataFieldName attribute to query
 * @param {boolean} throwError - If the element cannot be found, throw an error. Default = false.
 * @returns {HTMLElement} - The HTMLElement that was found
 */
function getInputFieldElement(element, fieldName, throwError = false) {
	const inputEl = element.shadowRoot.querySelector(`[data-field-name='${fieldName}']`);
	if(!inputEl && throwError) {
		throw new Error(`Could not find element for '${fieldName}'`);
	}
	return inputEl;
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

function getClassElement(element, className) {
	const inputEl = element.shadowRoot.querySelectorAll(className);
	if(!inputEl) {
		throw new Error(`Could not find element for '${className}'`);
	}
	return inputEl;
}

// Mock imperative Apex method call
jest.mock(
	'@salesforce/apex/UnifiedCaseCreationController.getCaseRecordTypeInfos',
	() => {
		const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
		return {
			default: createApexTestWireAdapter(jest.fn()),
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

describe('c-unified-case-creation', () => {
	afterEach(() => {
		// The jsdom instance is shared across test cases in a single file so reset the DOM
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
		
		// Reset all jest mocks after each test
		jest.clearAllMocks();
	});

	it('displays input elements on the Case Creation form UI', async () => {
		// Arrange
		const element = createElement('c-unified-case-creation', {
			is: UnifiedCaseCreation
		});

		// Act
		document.body.appendChild(element);

		getCaseRecordTypeInfos.emit(
			mockGetCaseRecordTypeInfos
		);

		getPicklistValuesByRecordType.emit(
			mockGetPicklistValuesForInvestigationRecType
		);

		// refresh the Apex wire adapter
		await flushAllPromises();

		// Assert
		const articleHeaderDivElement = element.shadowRoot.querySelector('div[data-name="articleHeader"]');
		expect(articleHeaderDivElement.classList).toContain('slds-text-body_regular');
		expect(articleHeaderDivElement.textContent).toBe(ARTICLES_LABEL+ ' (None Linked)');

		const contactLookupReadOnlyInput = getInputFieldElement(element, 'contactId');
		expect(contactLookupReadOnlyInput).toBeTruthy();
		expect(contactLookupReadOnlyInput.label).toBe(CONTACT_LABEL);
		expect(contactLookupReadOnlyInput.disabled).toBe(true);

		const enquiryTypeInput = getInputFieldElement(element, 'enquiryType');
		expect(enquiryTypeInput).toBeTruthy();
		expect(enquiryTypeInput.label).toBe(ENQUIRY_TYPE_LABEL);
		expect(enquiryTypeInput.options.length).toBe(2); // Investigation, General Enquiry
		expect(enquiryTypeInput.options[0].label).toBe(ENQUIRY_TYPE_OPTIONS[0].label);
		expect(enquiryTypeInput.options[0].value).toBe(ENQUIRY_TYPE_OPTIONS[0].value);
		expect(enquiryTypeInput.options[1].label).toBe(ENQUIRY_TYPE_OPTIONS[1].label);
		expect(enquiryTypeInput.options[1].value).toBe(ENQUIRY_TYPE_OPTIONS[1].value);
		

		const enquirySubTypeInput = getInputFieldElement(element, 'enquirySubType');
		expect(enquirySubTypeInput).toBeTruthy();
		expect(enquirySubTypeInput.label).toBe(ENQUIRY_SUBTYPE_LABEL);

		const productCategoryInput = getInputFieldElement(element, 'productCategory');
		expect(productCategoryInput).toBeTruthy();
		expect(productCategoryInput.label).toBe(PRODUCT_CATEGORY_LABEL);
		expect(productCategoryInput.options.length).toBe(1); // Late item
		expect(productCategoryInput.options[0].value).toBe('Domestic');

		const productSubCategoryInput = getInputFieldElement(element, 'productSubCategory');
		expect(productSubCategoryInput).toBeTruthy();
		expect(productSubCategoryInput.label).toBe(PRODUCT_SUBCATEGORY_LABEL);

		const notesInput = getInputFieldElement(element, 'notes');
		expect(notesInput).toBeTruthy();
		expect(notesInput.label).toBe(NOTES_LABEL);

		const createButton = getButtonByDataId(element, 'create');
		expect(createButton).toBeTruthy();
		expect(createButton.label).toBe(CREATE_BUTTON_LABEL);
	});


	it('test pre-populating input field values where enquiryType is not passed over from parent component', async () => {
		// Arrange
		const element = createElement('c-unified-case-creation', {
			is: UnifiedCaseCreation
		});
		element.contactId = '003000000000001AAA';
		element.impactedArticles = [
			'111ASFDASAASDFASGFAST3532f',
			'222ASFDASAASDFASGFAST3532f',
			'333ASFDASAASDFASGFAST3532f'
		];

		// Act
		document.body.appendChild(element);

		getCaseRecordTypeInfos.emit(
			mockGetCaseRecordTypeInfos
		);
		
		getPicklistValuesByRecordType.emit(
			mockGetPicklistValuesForInvestigationRecType
		);

		// refresh the Apex wire adapter
		await flushAllPromises();

		// Assert
		const articleHeaderDivElement = element.shadowRoot.querySelector('div[data-name="articleHeader"]');
		expect(articleHeaderDivElement.classList).toContain('slds-text-body_regular');
		expect(articleHeaderDivElement.textContent).toBe(ARTICLES_LABEL+ ' (3)');

		const contactLookupReadOnlyInput = getInputFieldElement(element, 'contactId');
		expect(contactLookupReadOnlyInput).toBeTruthy();
		expect(contactLookupReadOnlyInput.label).toBe(CONTACT_LABEL);
		expect(contactLookupReadOnlyInput.disabled).toBe(true);
		expect(contactLookupReadOnlyInput.value).toBe('003000000000001AAA');

		const pillElements = getClassElement(element, '.slds-pill__label');
		expect(pillElements.length).toBe(3);
		expect(pillElements[0].textContent).toBe('111ASFDASAASDFASGFAST3532f');
		expect(pillElements[1].textContent).toBe('222ASFDASAASDFASGFAST3532f');
		expect(pillElements[2].textContent).toBe('333ASFDASAASDFASGFAST3532f');

		const enquiryTypeInput = getInputFieldElement(element, 'enquiryType');
		expect(enquiryTypeInput).toBeTruthy();
		expect(enquiryTypeInput.label).toBe(ENQUIRY_TYPE_LABEL);
		expect(enquiryTypeInput.value).toBe('Investigation');

		const enquirySubTypeInput = getInputFieldElement(element, 'enquirySubType');
		expect(enquirySubTypeInput).toBeTruthy();
		expect(enquirySubTypeInput.label).toBe(ENQUIRY_SUBTYPE_LABEL);
		expect(enquirySubTypeInput.value).toBe('Late item');

		const productCategoryInput = getInputFieldElement(element, 'productCategory');
		expect(productCategoryInput).toBeTruthy();
		expect(productCategoryInput.label).toBe(PRODUCT_CATEGORY_LABEL);
		expect(productCategoryInput.value).toBe('Domestic');

		const productSubCategoryInput = getInputFieldElement(element, 'productSubCategory');
		expect(productSubCategoryInput).toBeTruthy();
		expect(productSubCategoryInput.label).toBe(PRODUCT_SUBCATEGORY_LABEL);
		expect(productSubCategoryInput.value).toBe(''); // no default due to many available options
	});

	it('test pre-populating input field values where Investigation enquiryType is passed over from parent component', async () => {
		// Arrange
		const element = createElement('c-unified-case-creation', {
			is: UnifiedCaseCreation
		});
		element.enquiryType = 'Investigation';

		// Act
		document.body.appendChild(element);

		getCaseRecordTypeInfos.emit(
			mockGetCaseRecordTypeInfos
		);
		
		getPicklistValuesByRecordType.emit(
			mockGetPicklistValuesForInvestigationRecType
		);

		// refresh the Apex wire adapter
		await flushAllPromises();

		// Assert
		const enquiryTypeInput = getInputFieldElement(element, 'enquiryType');
		expect(enquiryTypeInput).toBeTruthy();
		expect(enquiryTypeInput.label).toBe(ENQUIRY_TYPE_LABEL);
		expect(enquiryTypeInput.value).toBe('Investigation');

		const enquirySubTypeInput = getInputFieldElement(element, 'enquirySubType');
		expect(enquirySubTypeInput).toBeTruthy();
		expect(enquirySubTypeInput.label).toBe(ENQUIRY_SUBTYPE_LABEL);
		expect(enquirySubTypeInput.value).toBe('Late item');

		const productCategoryInput = getInputFieldElement(element, 'productCategory');
		expect(productCategoryInput).toBeTruthy();
		expect(productCategoryInput.label).toBe(PRODUCT_CATEGORY_LABEL);
		expect(productCategoryInput.value).toBe('Domestic');

		const productSubCategoryInput = getInputFieldElement(element, 'productSubCategory');
		expect(productSubCategoryInput).toBeTruthy();
		expect(productSubCategoryInput.label).toBe(PRODUCT_SUBCATEGORY_LABEL);
		expect(productSubCategoryInput.value).toBe(''); // no default due to many available options
	});

	it('test pre-populating input field values where General Enquiry enquiryType is passed over from parent component', async () => {
		// Arrange
		const element = createElement('c-unified-case-creation', {
			is: UnifiedCaseCreation
		});
		element.enquiryType = 'General Enquiry';

		// Act
		document.body.appendChild(element);

		getCaseRecordTypeInfos.emit(
			mockGetCaseRecordTypeInfos
		);
		
		getPicklistValuesByRecordType.emit(
			mockGetPicklistValuesForGeneralEnquiryRecType
		);

		// refresh the Apex wire adapter
		await flushAllPromises();

		// Assert
		const enquiryTypeInput = getInputFieldElement(element, 'enquiryType');
		expect(enquiryTypeInput).toBeTruthy();
		expect(enquiryTypeInput.label).toBe(ENQUIRY_TYPE_LABEL);
		expect(enquiryTypeInput.value).toBe('General Enquiry');

		const enquirySubTypeInput = getInputFieldElement(element, 'enquirySubType');
		expect(enquirySubTypeInput).toBeTruthy();
		expect(enquirySubTypeInput.label).toBe(ENQUIRY_SUBTYPE_LABEL);
		expect(enquirySubTypeInput.value).toBe('Tracking');

		const productCategoryInput = getInputFieldElement(element, 'productCategory');
		expect(productCategoryInput).toBeTruthy();
		expect(productCategoryInput.label).toBe(PRODUCT_CATEGORY_LABEL);
		expect(productCategoryInput.value).toBe('Domestic');

		const productSubCategoryInput = getInputFieldElement(element, 'productSubCategory');
		expect(productSubCategoryInput).toBeTruthy();
		expect(productSubCategoryInput.label).toBe(PRODUCT_SUBCATEGORY_LABEL);
		expect(productSubCategoryInput.value).toBe(''); // no default due to many available options
	});

	it('displays error when one or more fields are invalid', async () => {
		// Arrange
		const element = createElement('c-unified-case-creation', {
			is: UnifiedCaseCreation
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
		expect(createButton.disabled).toBe(true);

		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).not.toBeNull();
		expect(errorDiv.textContent).toBe(INVALID_FORM_ERROR);
	});

	it('test input validations on case creation form where impacted articles are empty', async () => {
		// Arrange
		const element = createElement('c-unified-case-creation', {
			is: UnifiedCaseCreation
		});
		element.contactId = '003000000000001AAA';

		// Act
		document.body.appendChild(element);

		getCaseRecordTypeInfos.emit(
			mockGetCaseRecordTypeInfos
		);
		
		getPicklistValuesByRecordType.emit(
			mockGetPicklistValuesForGeneralEnquiryRecType
		);

		const caseCreatedEvent = jest.fn();
		element.addEventListener('casecreated', caseCreatedEvent);

		// Set field values
		changeFormInputValues(element, {
			enquiryType: 'Investigation',
			enquirySubType: 'Late item',
			productCategory: 'Domestic',
			productSubCategory: 'Metro',
			notes: 'Case Test Notes'
		});

		// refresh the Apex wire adapter
		await flushAllPromises();
		
		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);
		
		// Click the search button
		const createButton = getButtonByDataId(element, 'create');
		createButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();
		
		expect(caseCreatedEvent).not.toHaveBeenCalled();
		expect(createButton.disabled).toBe(true);
		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).not.toBeNull();
		expect(errorDiv.textContent).toBe(IMPACTED_ARTICLE_MISSING_ERROR);
	});

	it('test input validations on case creation form where contactId is empty', async () => {
		// Arrange
		const element = createElement('c-unified-case-creation', {
			is: UnifiedCaseCreation
		});
		element.impactedArticles = [
			'111ASFDASAASDFASGFAST3532f',
			'222ASFDASAASDFASGFAST3532f',
			'333ASFDASAASDFASGFAST3532f'
		];

		// Act
		document.body.appendChild(element);

		getCaseRecordTypeInfos.emit(
			mockGetCaseRecordTypeInfos
		);
		
		getPicklistValuesByRecordType.emit(
			mockGetPicklistValuesForGeneralEnquiryRecType
		);

		const caseCreatedEvent = jest.fn();
		element.addEventListener('casecreated', caseCreatedEvent);

		// Set field values
		changeFormInputValues(element, {
			enquiryType: 'Investigation',
			enquirySubType: 'Late item',
			productCategory: 'Domestic',
			productSubCategory: 'Metro',
			notes: 'Case Test Notes'
		});

		// refresh the Apex wire adapter
		await flushAllPromises();
		
		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);
		
		// Click the search button
		const createButton = getButtonByDataId(element, 'create');
		createButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();
		
		expect(caseCreatedEvent).not.toHaveBeenCalled();
		expect(createButton.disabled).toBe(true);
		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).not.toBeNull();
		expect(errorDiv.textContent).toBe(CONTACTID_MISSING_ERROR);
	});

	it('send request to submit unified investigation case creation successfully', async () => {
		// Arrange
		const element = createElement('c-unified-case-creation', {
			is: UnifiedCaseCreation
		});
		element.contactId = '003000000000001AAA';
		element.impactedArticles = [
			'111ASFDASAASDFASGFAST3532f',
			'222ASFDASAASDFASGFAST3532f',
			'333ASFDASAASDFASGFAST3532f'
		];
		element.consignmentId = 'a1h000000000000001';

		
		// mock success
		createNewCase.mockResolvedValue(CASE_CREATION_RES_SUCCESS);

		// Act
		document.body.appendChild(element);

		const caseCreatedEvent = jest.fn();
		element.addEventListener('casecreated', caseCreatedEvent);

		getCaseRecordTypeInfos.emit(
			mockGetCaseRecordTypeInfos
		);
		
		getPicklistValuesByRecordType.emit(
			mockGetPicklistValuesForInvestigationRecType
		);

		// Set field values
		changeFormInputValues(element, {
			enquiryType: 'Investigation',
			enquirySubType: 'Late item',
			productCategory: 'Domestic',
			productSubCategory: 'Metro',
			notes: 'Case Test Notes'
		});

		// refresh the Apex wire adapter
		await flushAllPromises();
		
		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);
		
		// Click the search button
		const createButton = getButtonByDataId(element, 'create');
		createButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		const { request } = createNewCase.mock.calls[0][0];
		expect(Object.keys(request).length).toBe(9);
		expect(request.impactedArticles).toEqual([
			'111ASFDASAASDFASGFAST3532f',
			'222ASFDASAASDFASGFAST3532f',
			'333ASFDASAASDFASGFAST3532f'
		]);
		expect(request.contactId).toBe('003000000000001AAA');
		expect(request.enquiryType).toBe('Investigation');
		expect(request.enquirySubType).toBe('Late item');
		expect(request.productCategory).toBe('Domestic');
		expect(request.productSubCategory).toBe('Metro');
		expect(request.notes).toBe('Case Test Notes');
		expect(request.recordTypeId).toBe('012Bm000005r2TpIAI'); // unified investigation
		expect(request.consignmentId).toBe('a1h000000000000001');

		expect(caseCreatedEvent).toHaveBeenCalledWith(
			expect.objectContaining({
				detail: {
					caseId: CASE_CREATION_RES_SUCCESS
				},
				bubbles: true,
				composed: true
			})
		);
	});

	it('displays spinner while creating new case', async () => {
		// Arrange
		const element = createElement('c-unified-case-creation', {
			is: UnifiedCaseCreation,
		});
		element.contactId = '003000000000001AAA';
		element.impactedArticles = [
			'111ASFDASAASDFASGFAST3532f',
			'222ASFDASAASDFASGFAST3532f',
			'333ASFDASAASDFASGFAST3532f'
		];
		element.consignmentId = 'a1h000000000000001';

		// Assign mock value for resolved Apex promise
		createNewCase.mockResolvedValue(CASE_CREATION_RES_SUCCESS);

		// Act
		document.body.appendChild(element);

		getCaseRecordTypeInfos.emit(
			mockGetCaseRecordTypeInfos
		);
		
		getPicklistValuesByRecordType.emit(
			mockGetPicklistValuesForGeneralEnquiryRecType
		);

		// Set field values
		changeFormInputValues(element, {
			enquiryType: 'General Enquiry',
			enquirySubType: 'Tracking',
			productCategory: 'Domestic',
			productSubCategory: 'Express Post',
			notes: 'Case Test Notes'
		});


		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);

		// Click the search button
		const createButton = getButtonByDataId(element, 'create');
		createButton.click();

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

	it('send request to submit unified general enquiry case creation successfully', async () => {
		// Arrange
		const element = createElement('c-unified-case-creation', {
			is: UnifiedCaseCreation
		});
		element.contactId = '003000000000001AAA';
		element.impactedArticles = [
			'111ASFDASAASDFASGFAST3532f',
			'222ASFDASAASDFASGFAST3532f',
			'333ASFDASAASDFASGFAST3532f'
		];
		element.consignmentId = 'a1h000000000000001';

		
		// mock success
		createNewCase.mockResolvedValue(CASE_CREATION_RES_SUCCESS);

		// Act
		document.body.appendChild(element);

		const caseCreatedEvent = jest.fn();
		element.addEventListener('casecreated', caseCreatedEvent);

		getCaseRecordTypeInfos.emit(
			mockGetCaseRecordTypeInfos
		);
		
		getPicklistValuesByRecordType.emit(
			mockGetPicklistValuesForGeneralEnquiryRecType
		);

		// Set field values
		changeFormInputValues(element, {
			enquiryType: 'General Enquiry',
			enquirySubType: 'Tracking',
			productCategory: 'Domestic',
			productSubCategory: 'Express Post',
			notes: 'Case Test Notes'
		});

		// refresh the Apex wire adapter
		await flushAllPromises();
		
		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);
		
		// Click the search button
		const createButton = getButtonByDataId(element, 'create');
		createButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		const { request } = createNewCase.mock.calls[0][0];
		expect(Object.keys(request).length).toBe(9);
		expect(request.impactedArticles).toEqual([
			'111ASFDASAASDFASGFAST3532f',
			'222ASFDASAASDFASGFAST3532f',
			'333ASFDASAASDFASGFAST3532f'
		]);
		expect(request.contactId).toBe('003000000000001AAA');
		expect(request.enquiryType).toBe('General Enquiry');
		expect(request.enquirySubType).toBe('Tracking');
		expect(request.productCategory).toBe('Domestic');
		expect(request.productSubCategory).toBe('Express Post');
		expect(request.notes).toBe('Case Test Notes');
		expect(request.recordTypeId).toBe('012Bm000006HBurIAG'); // unified general enquiry
		expect(request.consignmentId).toBe('a1h000000000000001');

		expect(caseCreatedEvent).toHaveBeenCalledWith(
			expect.objectContaining({
				detail: {
					caseId: CASE_CREATION_RES_SUCCESS
				},
				bubbles: true,
				composed: true
			})
		);
	});

	it('send request to submit unified investigation case creation with failure', async () => {
		// Arrange
		const element = createElement('c-unified-case-creation', {
			is: UnifiedCaseCreation
		});
		element.contactId = '003000000000001AAA';
		element.impactedArticles = [
			'111ASFDASAASDFASGFAST3532f',
			'222ASFDASAASDFASGFAST3532f',
			'333ASFDASAASDFASGFAST3532f'
		];
		element.consignmentId = 'a1h000000000000001';

		
		// mock success
		createNewCase.mockRejectedValue(CASE_CREATION_RES_ERROR);

		// Act
		document.body.appendChild(element);

		const caseCreatedEvent = jest.fn();
		element.addEventListener('casecreated', caseCreatedEvent);

		getCaseRecordTypeInfos.emit(
			mockGetCaseRecordTypeInfos
		);
		
		getPicklistValuesByRecordType.emit(
			mockGetPicklistValuesForGeneralEnquiryRecType
		);

		// Set field values
		changeFormInputValues(element, {
			enquiryType: 'Investigation',
			enquirySubType: 'Late item',
			productCategory: 'Domestic',
			productSubCategory: 'Metro',
			notes: 'Case Test Notes'
		});

		// refresh the Apex wire adapter
		await flushAllPromises();
		
		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);
		
		// Click the search button
		const createButton = getButtonByDataId(element, 'create');
		createButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		expect(caseCreatedEvent).not.toHaveBeenCalled();
		expect(createButton.disabled).toBe(true);
		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).not.toBeNull();
	});

	
	it('send request to submit unified general enquiry case creation with failure', async () => {
		// Arrange
		const element = createElement('c-unified-case-creation', {
			is: UnifiedCaseCreation
		});
		element.contactId = '003000000000001AAA';
		element.impactedArticles = [
			'111ASFDASAASDFASGFAST3532f',
			'222ASFDASAASDFASGFAST3532f',
			'333ASFDASAASDFASGFAST3532f'
		];
		element.consignmentId = 'a1h000000000000001';

		
		// mock success
		createNewCase.mockRejectedValue(CASE_CREATION_RES_ERROR);

		// Act
		document.body.appendChild(element);

		const caseCreatedEvent = jest.fn();
		element.addEventListener('casecreated', caseCreatedEvent);

		getCaseRecordTypeInfos.emit(
			mockGetCaseRecordTypeInfos
		);
		
		getPicklistValuesByRecordType.emit(
			mockGetPicklistValuesForGeneralEnquiryRecType
		);

		// Set field values
		changeFormInputValues(element, {
			enquiryType: 'General Enquiry',
			enquirySubType: 'Tracking',
			productCategory: 'Domestic',
			productSubCategory: 'Express Post',
			notes: 'Case Test Notes'
		});

		// refresh the Apex wire adapter
		await flushAllPromises();
		
		// Mock all input checkValidity() methods to return 'true'
		mockCheckValidity(element, INPUT_ELEMENT_SELECTORS.join(','), true);
		
		// Click the search button
		const createButton = getButtonByDataId(element, 'create');
		createButton.click();

		// Wait for any asynchronous code to complete
		await flushAllPromises();
		
		expect(caseCreatedEvent).not.toHaveBeenCalled();
		expect(createButton.disabled).toBe(true);
		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).not.toBeNull();
	});
});