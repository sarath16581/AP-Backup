import { createElement } from 'lwc';
import getCaseRecordTypeInfos from "@salesforce/apex/UnifiedCaseCreationController.getCaseRecordTypeInfos";
import { getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import UnifiedCaseCreation from 'c/unifiedCaseCreation';
import {
	ARTICLES_LABEL,
	CONTACT_LABEL,
	ENQUIRY_TYPE_LABEL,
	ENQUIRY_SUBTYPE_LABEL,
	PRODUCT_CATEGORY_LABEL,
	PRODUCT_SUBCATEGORY_LABEL,
	NOTES_LABEL,
	CREATE_BUTTON_LABEL
} from 'c/unifiedCaseCreation';

// Mock picklist data
const mockGetPicklistValues = require('./data/getPicklistValuesByRecordType.json');
const mockGetCaseRecordTypeInfos = require('./data/getCaseRecordTypeInfos.json');


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
		console.log('SETH lightning-combobox: ' + element.value);
		element.dispatchEvent(
			new CustomEvent('change', { detail: { recordId: element.value } })
		);
		return;
	} else if (element?.nodeName.toLowerCase() === 'lightning-record-picker') {
		element.value = value;
		console.log('SETH lightning-record-picker: ' + element.value);
		element.dispatchEvent(
			new CustomEvent('change', { detail: { recordId: element.value } })
		);
		return;
	} else if (element?.nodeName.toLowerCase() === 'lightning-textarea') {
		element.value = value;
		console.log('SETH lightning-textarea: ' + element.value);
		element.dispatchEvent(
			new CustomEvent('change', { detail: { recordId: element.value } })
		);
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
	//console.log('SETH fieldName: ' + fieldName);
	const inputEl = element.shadowRoot.querySelector(`[data-field-name='${fieldName}']`);
	//console.log('SETH inputEl: ' + inputEl);
	if(!inputEl && throwError) {
		throw new Error(`Could not find element for '${fieldName}'`);
	}
	return inputEl;
}

function getClassElement(element, className) {
	//console.log('SETH fieldName: ' + fieldName);
	const inputEl = element.shadowRoot.querySelectorAll(className);
	//console.log('SETH inputEl: ' + inputEl);
	if(!inputEl) {
		throw new Error(`Could not find element for '${fieldName}'`);
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
		
		getPicklistValuesByRecordType.emit(
			mockGetPicklistValues
		);

		getCaseRecordTypeInfos.emit(
			mockGetCaseRecordTypeInfos
		);

		// refresh the Apex wire adapter
		await flushAllPromises();

		// Assert
		const articleHeaderDivElement = element.shadowRoot.querySelector('div[data-name="articleHeader"]');
		expect(articleHeaderDivElement.classList).toContain('slds-text-body_regular');
		expect(articleHeaderDivElement.textContent).toBe(ARTICLES_LABEL+ ' (None Linked)');

		const contactLookupReadOnlyInput = getInputFieldElement(element, 'contactLookup');
		expect(contactLookupReadOnlyInput).toBeTruthy();
		expect(contactLookupReadOnlyInput.label).toBe(CONTACT_LABEL);
		expect(contactLookupReadOnlyInput.disabled).toBe(true);

		const enquiryTypeInput = getInputFieldElement(element, 'recordTypeId');
		expect(enquiryTypeInput).toBeTruthy();
		expect(enquiryTypeInput.label).toBe(ENQUIRY_TYPE_LABEL);
		expect(enquiryTypeInput.options[0].label).toBe('Unified General Enquiry');
		expect(enquiryTypeInput.options[0].value).toBe('012Bm000006HBurIAG');
		expect(enquiryTypeInput.options[1].label).toBe('Investigation');
		expect(enquiryTypeInput.options[1].value).toBe('012Bm000005r2TpIAI');

		// TODO assert the controlling and dependencies of the picklist fields

		const enquirySubTypeInput = getInputFieldElement(element, 'enquirySubType');
		expect(enquirySubTypeInput).toBeTruthy();
		expect(enquirySubTypeInput.label).toBe(ENQUIRY_SUBTYPE_LABEL);

		const productCategoryInput = getInputFieldElement(element, 'productCategory');
		expect(productCategoryInput).toBeTruthy();
		expect(productCategoryInput.label).toBe(PRODUCT_CATEGORY_LABEL);

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


	it('test pre-populating input field values', async () => {
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
		
		getPicklistValuesByRecordType.emit(
			mockGetPicklistValues
		);

		getCaseRecordTypeInfos.emit(
			mockGetCaseRecordTypeInfos
		);

		// refresh the Apex wire adapter
		await flushAllPromises();

		// Assert
		const articleHeaderDivElement = element.shadowRoot.querySelector('div[data-name="articleHeader"]');
		expect(articleHeaderDivElement.classList).toContain('slds-text-body_regular');
		expect(articleHeaderDivElement.textContent).toBe(ARTICLES_LABEL+ ' (3)');

		const contactLookupReadOnlyInput = getInputFieldElement(element, 'contactLookup');
		expect(contactLookupReadOnlyInput).toBeTruthy();
		expect(contactLookupReadOnlyInput.label).toBe(CONTACT_LABEL);
		expect(contactLookupReadOnlyInput.disabled).toBe(true);
		expect(contactLookupReadOnlyInput.value).toBe('003000000000001AAA');

		const pillElements = getClassElement(element, '.slds-pill__label');
		expect(pillElements.length).toBe(3);
		expect(pillElements[0].textContent).toBe('111ASFDASAASDFASGFAST3532f');
		expect(pillElements[1].textContent).toBe('222ASFDASAASDFASGFAST3532f');
		expect(pillElements[2].textContent).toBe('333ASFDASAASDFASGFAST3532f');
	});
});