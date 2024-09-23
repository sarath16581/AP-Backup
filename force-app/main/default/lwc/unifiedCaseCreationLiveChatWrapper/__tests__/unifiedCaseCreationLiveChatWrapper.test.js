import { createElement } from 'lwc';
import UnifiedCaseCreationLiveChatWrapper from 'c/unifiedCaseCreationLiveChatWrapper';
import GENERIC_LMS_CHANNEL from '@salesforce/messageChannel/genericMessageChannel__c';
import { subscribe, MessageContext, publish } from 'lightning/messageService';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import getExistingCasesCount from '@salesforce/apex/UnifiedCaseHistoryController.getCountForDuplicatedCasesRelatedToArticle';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';

const mockGetRecordForLiveChatTranscript = require('./data/getRecordForLiveChatTranscript.json');
// Mock imperative Apex method call
jest.mock(
	'@salesforce/apex/UnifiedCaseHistoryController.getCountForDuplicatedCasesRelatedToArticle',
	() => {
		return {
			default: jest.fn(),
		};
	},
	{ virtual: true }
);

const EXISTING_CASE_RES_SUCCESS = 5;
const EXISTING_CASE_RES_ERROR = {
	body: { message: 'An internal server error has occurred' },
	ok: false,
	status: 500,
	statusText: 'Internal server error',
};

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

describe('c-unified-case-creation-live-chat-wrapper', () => {
	afterEach(() => {
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
		// Reset all jest mocks after each test
		jest.clearAllMocks();

		jest.resetModules();

		// Flush any pending promises to avoid asynchronous interference
		return flushAllPromises();
	});

	it('registers the LMS subscriber during the component lifecycle', () => {
		// Create component
		const element = createElement('c-unified-case-creation-live-chat-wrapper', {
			is: UnifiedCaseCreationLiveChatWrapper
		});
		document.body.appendChild(element);

		// Validate if pubsub got registered after connected to the DOM
		expect(subscribe).toHaveBeenCalled();
		expect(subscribe.mock.calls[0][1]).toBe(GENERIC_LMS_CHANNEL);
	});
	
	it('invokes getRecord for LiveChatTranscript and pass properties to case creation component', async () => {
		// Create component
		const element = createElement('c-unified-case-creation-live-chat-wrapper', {
			is: UnifiedCaseCreationLiveChatWrapper
		});
		
		getRecord.emit(
			mockGetRecordForLiveChatTranscript
		);
	
		document.body.appendChild(element);
		
		const messagePayload = {
			source: 'unifiedTrackingChatWrapper',
			type: 'articleSelected',
			body: {
				consignmentId: '000ASFDASAASDFASGFAST3532f',
				selectedArticleIds: [
					'111ASFDASAASDFASGFAST3532f',
					'222ASFDASAASDFASGFAST3532f',
					'333ASFDASAASDFASGFAST3532f'
				]
			}
		}
		publish(MessageContext, GENERIC_LMS_CHANNEL, messagePayload);

		// Wait for any asynchronous DOM updates
		await flushAllPromises();
		
		const caseCreationCmp = element.shadowRoot.querySelector('c-unified-case-creation');
		expect(caseCreationCmp.impactedArticles).toEqual([
			'111ASFDASAASDFASGFAST3532f',
			'222ASFDASAASDFASGFAST3532f',
			'333ASFDASAASDFASGFAST3532f'
		]);
		expect(caseCreationCmp).not.toBeNull();
		expect(caseCreationCmp.contactId).toBe('003000000000001AAA');
		expect(caseCreationCmp.consignmentId).toBe('a1h000000000000001');
		expect(caseCreationCmp.enquiryType).toBe('Investigation');
		expect(caseCreationCmp.enquirySubType).toBe('Late item');
		expect(caseCreationCmp.productCategory).toBe('Domestic');
		expect(caseCreationCmp.productSubCategory).toBe('Express Post');
	});
	
	it('validates existing case count and display warning message', async () => {
		// Create component
		const element = createElement('c-unified-case-creation-live-chat-wrapper', {
			is: UnifiedCaseCreationLiveChatWrapper
		});
		
		getExistingCasesCount.mockResolvedValue(
			EXISTING_CASE_RES_SUCCESS
		);
	
		document.body.appendChild(element);

		// Wait for any asynchronous DOM updates
		await flushAllPromises();
		
		const warningMsg = element.shadowRoot.querySelector("p");
		expect(warningMsg.textContent).toContain('5 Existing Cases');
	});
	
	it('calls updateRecord and handles success', async () => {
		// Arrange: Create element and set properties
		const element = createElement('c-unified-case-creation-live-chat-wrapper', {
			is: UnifiedCaseCreationLiveChatWrapper
		});

		// Mock the resolved value for updateRecord
		updateRecord.mockResolvedValue({ id: '500000000012312ABC' });

		getRecord.emit(
			mockGetRecordForLiveChatTranscript
		);

		document.body.appendChild(element);
		
		// Mock handler for toast event
		const toastHandler = jest.fn();
		element.addEventListener(ShowToastEventName, toastHandler);
		
		const caseCreationCmp = element.shadowRoot.querySelector('c-unified-case-creation');
		expect(caseCreationCmp).not.toBeNull();
		// Dispatch the 'casecreated' event from the child component
		const eventDetail = { caseId: '500000000012312ABC' }; // Example event detail
		const customEvent = new CustomEvent('casecreated', { detail: eventDetail });
		caseCreationCmp.dispatchEvent(customEvent);

		// Wait for any asynchronous updates
		await flushAllPromises();
		expect(updateRecord).toHaveBeenCalled();
		expect(toastHandler).toHaveBeenCalled();
		expect(toastHandler.mock.calls[0][0].detail.variant).toBe('success');
	});

	it('calls updateRecord with failure', async () => {
		// Arrange: Create element and set properties
		const element = createElement('c-unified-case-creation-live-chat-wrapper', {
			is: UnifiedCaseCreationLiveChatWrapper
		});

		// Mock the resolved value for updateRecord
		updateRecord.mockRejectedValue(EXISTING_CASE_RES_ERROR);

		getRecord.emit(
			mockGetRecordForLiveChatTranscript
		);

		document.body.appendChild(element);
		
		const caseCreationCmp = element.shadowRoot.querySelector('c-unified-case-creation');
		expect(caseCreationCmp).not.toBeNull();
		// Dispatch the 'casecreated' event from the child component
		caseCreationCmp.dispatchEvent(
			new CustomEvent('casecreated',
				{ detail: { caseId: '500000000012312ABC' } }
			)
		);

		// Mock handler for toast event
		const toastHandler = jest.fn();
		element.addEventListener(ShowToastEventName, toastHandler);

		// Wait for any asynchronous updates
		await flushAllPromises();
		expect(updateRecord).toHaveBeenCalled();
		expect(toastHandler).toHaveBeenCalled();
		expect(toastHandler.mock.calls[0][0].detail.variant).toBe('error');
	});
});