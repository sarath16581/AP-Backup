import { createElement } from 'lwc';
import getLatestCaseFeedsResults from '@salesforce/apex/UnifiedCaseFeedsUpdateController.getLatestCaseFeedsResults';
import { refreshApex } from '@salesforce/apex';
import UnifiedCaseFeeds from 'c/unifiedCaseFeeds';
import { getNavigateCalledWith } from 'lightning/navigation';

// Mock Apex Response data
const MOCK_CASE_FEED_MORE_THAN_THREE_RESULTS = require('./data/getCaseFeedsMoreThanThreeResults.json');
const MOCK_CASE_FEED_EXACT_THREE_RESULTS = require('./data/getCaseFeedsExactlyThreeResults.json');
const MOCK_CASE_FEED_BLANK_RESULTS = [];
const MOCK_GET_CASE_FEEDS_FAILURE = {
	body: { message: 'An internal server error has occurred' },
	ok: false,
	status: 500,
	statusText: 'Bad Request',
};

// Mock imperative wire call
jest.mock(
	'@salesforce/apex/UnifiedCaseFeedsUpdateController.getLatestCaseFeedsResults',
	() => {
		const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
		return {
			default: createApexTestWireAdapter(jest.fn()),
		};
	},
	{ virtual: true }
);

jest.mock(
	"@salesforce/apex",
	() => {
		return {
			refreshApex: jest.fn(() => Promise.resolve()),
		};
	},
	{ virtual: true }
);

/**
 * Finds and returns input field based on the `data-field-name` attribute.
 *
 * @param {Element} element - The element to run `querySelector` on
 * @param {string} lightningElement - The lightning element to run query on
 * @param {string} name - The data name attribute to query
 * @param {boolean} throwError - If the element cannot be found, throw an error. Default = false.
 * @returns {HTMLElement} - The HTMLElement that was found
 */
function getElementsByName(element, lightningElement, name, throwError = false) {
	lightningElement = lightningElement || '';
	const inputEl = Array.from(element.shadowRoot.querySelectorAll(`${lightningElement}[data-name='${name}']`));
	if(!inputEl && throwError) {
		throw new Error(`Could not find element for '${name}'`);
	}
	return inputEl;
}


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

describe('c-unified-case-feeds', () => {
	afterEach(() => {
		// The jsdom instance is shared across test cases in a single file so reset the DOM
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
		
		// Reset all jest mocks after each test
		jest.clearAllMocks();
	});

	it('displays case feed component with three feed results', async () => {
		// Arrange
		const element = createElement('c-unified-case-feeds', {
			is: UnifiedCaseFeeds
		});

		// Act
		document.body.appendChild(element);

		getLatestCaseFeedsResults.emit(
			MOCK_CASE_FEED_EXACT_THREE_RESULTS
		);
		// refresh the Apex wire adapter
		await flushAllPromises();

		const feedRefreshButtonIconElement = getElementsByName(element, 'lightning-button-icon', 'refreshFeed');
		expect(feedRefreshButtonIconElement).not.toBeNull();
		expect(feedRefreshButtonIconElement.length).toBe(1);
		expect(feedRefreshButtonIconElement[0].iconName).toBe('utility:refresh');
		expect(feedRefreshButtonIconElement[0].size).toBe('large');
		expect(feedRefreshButtonIconElement[0].variant).toBe('bare');

		const feedHeaderElements = getElementsByName(element, null, 'feedHeader');
		expect(feedHeaderElements.length).toBe(3);
		expect(feedHeaderElements[0].textContent).toBe('Scan Event Update 1');
		expect(feedHeaderElements[1].textContent).toBe('Email Received 2');
		expect(feedHeaderElements[2].textContent).toBe('Scheduled Contact Request 3');

		const feedBodyElements = getElementsByName(element, null, 'feedBody');
		expect(feedBodyElements.length).toBe(3);
		expect(feedBodyElements[0].textContent).toBe('Processing Package');
		expect(feedBodyElements[1].textContent).toBe('smith.john@auspost.com.au');
		expect(feedBodyElements[2].textContent).toBe('Phone');

		const feedIconElements = getElementsByName(element, 'lightning-icon', 'feedCustomIcon');
		expect(feedIconElements.length).toBe(3);
		expect(feedIconElements[0].iconName).toBe('custom:custom26');
		expect(feedIconElements[1].iconName).toBe('standard:email');
		expect(feedIconElements[2].iconName).toBe('standard:contact_request');

		const feedNavigationButtonIconElement = getElementsByName(element, 'lightning-button-icon', 'feedRecordId');
		expect(feedNavigationButtonIconElement).not.toBeNull();
		expect(feedNavigationButtonIconElement.length).toBe(1);
		expect(feedNavigationButtonIconElement[0].iconName).toBe('utility:new_window');
		expect(feedNavigationButtonIconElement[0].getAttribute('data-value')).toBe('001000000000AAAAAA');
		expect(feedNavigationButtonIconElement[0].size).toBe('large');
		expect(feedNavigationButtonIconElement[0].variant).toBe('bare');

		const feedDateTimeElements = getElementsByName(element, null, 'feedFormattedDateTime');
		expect(feedDateTimeElements.length).toBe(3);
		expect(feedDateTimeElements[0].textContent).toBe('24/09/2024 12:07 pm');
		expect(feedDateTimeElements[1].textContent).toBe('24/09/2024 12:03 pm');
		expect(feedDateTimeElements[2].textContent).toBe('22/09/2024 12:07 pm');

		const linkDiv = element.shadowRoot.querySelector('.slds-text-link');
		expect(linkDiv).toBeNull();
	});

	it('displays case feed component with more than three feed results', async () => {
		// Arrange
		const element = createElement('c-unified-case-feeds', {
			is: UnifiedCaseFeeds
		});

		// Act
		document.body.appendChild(element);

		getLatestCaseFeedsResults.emit(
			MOCK_CASE_FEED_MORE_THAN_THREE_RESULTS
		);
		// refresh the Apex wire adapter
		await flushAllPromises();

		let linkDiv = element.shadowRoot.querySelector('.slds-text-link');
		expect(linkDiv).not.toBeNull();
		expect(linkDiv.textContent).toBe('View 2 More');

		linkDiv.click();
		// refresh the layout after button click
		await flushAllPromises();

		const feedRefreshButtonIconElement = getElementsByName(element, 'lightning-button-icon', 'refreshFeed');
		expect(feedRefreshButtonIconElement).not.toBeNull();
		expect(feedRefreshButtonIconElement.length).toBe(1);
		expect(feedRefreshButtonIconElement[0].iconName).toBe('utility:refresh');
		expect(feedRefreshButtonIconElement[0].size).toBe('large');
		expect(feedRefreshButtonIconElement[0].variant).toBe('bare');

		const feedHeaderElements = getElementsByName(element, null, 'feedHeader');
		expect(feedHeaderElements.length).toBe(5);
		expect(feedHeaderElements[0].textContent).toBe('Scan Event Update 1');
		expect(feedHeaderElements[1].textContent).toBe('Email Received 2');
		expect(feedHeaderElements[2].textContent).toBe('Scheduled Contact Request 3');
		expect(feedHeaderElements[3].textContent).toBe('Scan Event Update 4');
		expect(feedHeaderElements[4].textContent).toBe('Scan Event Update 5');

		const feedBodyElements = getElementsByName(element, null, 'feedBody');
		expect(feedBodyElements.length).toBe(5);
		expect(feedBodyElements[0].textContent).toBe('Processing Package');
		expect(feedBodyElements[1].textContent).toBe('smith.john@auspost.com.au');
		expect(feedBodyElements[2].textContent).toBe('Email');
		expect(feedBodyElements[3].textContent).toBe('Onboard for Delivery');
		expect(feedBodyElements[4].textContent).toBe('Delivery Successful');

		const feedIconElements = getElementsByName(element, 'lightning-icon', 'feedCustomIcon');
		expect(feedIconElements.length).toBe(5);
		expect(feedIconElements[0].iconName).toBe('custom:custom26');
		expect(feedIconElements[1].iconName).toBe('standard:email');
		expect(feedIconElements[2].iconName).toBe('standard:contact_request');
		expect(feedIconElements[3].iconName).toBe('custom:custom26');
		expect(feedIconElements[4].iconName).toBe('custom:custom26');

		const feedNavigationButtonIconElement = getElementsByName(element, 'lightning-button-icon', 'feedRecordId');
		expect(feedNavigationButtonIconElement).not.toBeNull();
		expect(feedNavigationButtonIconElement.length).toBe(1);
		expect(feedNavigationButtonIconElement[0].iconName).toBe('utility:new_window');
		expect(feedNavigationButtonIconElement[0].getAttribute('data-value')).toBe('001000000000AAAAAA');
		expect(feedNavigationButtonIconElement[0].size).toBe('large');
		expect(feedNavigationButtonIconElement[0].variant).toBe('bare');

		const feedDateTimeElements = getElementsByName(element, null, 'feedFormattedDateTime');
		expect(feedDateTimeElements.length).toBe(5);
		expect(feedDateTimeElements[0].textContent).toBe('24/09/2024 12:07 pm');
		expect(feedDateTimeElements[1].textContent).toBe('24/09/2024 12:03 pm');
		expect(feedDateTimeElements[2].textContent).toBe('22/09/2024 12:07 pm');
		expect(feedDateTimeElements[3].textContent).toBe('20/09/2024 12:07 pm');
		expect(feedDateTimeElements[4].textContent).toBe('01/09/2024 01:07 pm');
	});

	it('displays case feed component with more than three feed results and toggle view more button', async () => {
		// Arrange
		const element = createElement('c-unified-case-feeds', {
			is: UnifiedCaseFeeds
		});

		// Act
		document.body.appendChild(element);

		getLatestCaseFeedsResults.emit(
			MOCK_CASE_FEED_MORE_THAN_THREE_RESULTS
		);
		// refresh the Apex wire adapter
		await flushAllPromises();

		let feedHeaderElements = getElementsByName(element, null, 'feedHeader');
		let feedBodyElements = getElementsByName(element, null, 'feedBody');
		let feedIconElements = getElementsByName(element, 'lightning-icon', 'feedCustomIcon');
		let feedNavigationButtonIconElement = getElementsByName(element, 'lightning-button-icon', 'feedRecordId');
		let feedDateTimeElements = getElementsByName(element, null, 'feedFormattedDateTime');

		expect(feedHeaderElements.length).toBe(3);
		expect(feedBodyElements.length).toBe(3);
		expect(feedIconElements.length).toBe(3);
		expect(feedNavigationButtonIconElement.length).toBe(1);
		expect(feedDateTimeElements.length).toBe(3);

		let linkDiv = element.shadowRoot.querySelector('.slds-text-link');
		expect(linkDiv).not.toBeNull();
		expect(linkDiv.textContent).toBe('View 2 More');

		linkDiv.click();
		// refresh the layout after button click
		await flushAllPromises();

		feedHeaderElements = getElementsByName(element, null, 'feedHeader');
		feedBodyElements = getElementsByName(element, null, 'feedBody');
		feedIconElements = getElementsByName(element, 'lightning-icon', 'feedCustomIcon');
		feedNavigationButtonIconElement = getElementsByName(element, 'lightning-button-icon', 'feedRecordId');
		feedDateTimeElements = getElementsByName(element, null, 'feedFormattedDateTime');

		expect(feedHeaderElements.length).toBe(5);
		expect(feedBodyElements.length).toBe(5);
		expect(feedIconElements.length).toBe(5);
		expect(feedNavigationButtonIconElement.length).toBe(1);
		expect(feedDateTimeElements.length).toBe(5);

		linkDiv = element.shadowRoot.querySelector('.slds-text-link');
		expect(linkDiv).not.toBeNull();
		expect(linkDiv.textContent).toBe('Hide Updates');

		linkDiv.click();
		// refresh the layout after button click
		await flushAllPromises();

		feedHeaderElements = getElementsByName(element, null, 'feedHeader');
		feedBodyElements = getElementsByName(element, null, 'feedBody');
		feedIconElements = getElementsByName(element, 'lightning-icon', 'feedCustomIcon');
		feedNavigationButtonIconElement = getElementsByName(element, 'lightning-button-icon', 'feedRecordId');
		feedDateTimeElements = getElementsByName(element, null, 'feedFormattedDateTime');

		expect(feedHeaderElements.length).toBe(3);
		expect(feedBodyElements.length).toBe(3);
		expect(feedIconElements.length).toBe(3);
		expect(feedNavigationButtonIconElement.length).toBe(1);
		expect(feedDateTimeElements.length).toBe(3);
	});

	it('displays case feed component with no feed results', async () => {
		// Arrange
		const element = createElement('c-unified-case-feeds', {
			is: UnifiedCaseFeeds
		});

		// Act
		document.body.appendChild(element);

		getLatestCaseFeedsResults.emit(
			MOCK_CASE_FEED_BLANK_RESULTS
		);
		// refresh the Apex wire adapter
		await flushAllPromises();

		const emptyStateCmp = element.shadowRoot.querySelector('c-empty-state');
		expect(emptyStateCmp).not.toBeNull();
		expect(emptyStateCmp.illustration).toBe('fishingDeals');
		expect(emptyStateCmp.titleText).toBe('No Update');
		expect(emptyStateCmp.textPosition).toBe('above');
		expect(emptyStateCmp.size).toBe('small');
	});

	it('displays case feed component to refresh and verify refreshApex is called once', async () => {
		// Arrange
		const element = createElement('c-unified-case-feeds', {
			is: UnifiedCaseFeeds
		});

		refreshApex.mockResolvedValue(MOCK_CASE_FEED_MORE_THAN_THREE_RESULTS);

		// Act
		document.body.appendChild(element);

		getLatestCaseFeedsResults.emit(
			MOCK_CASE_FEED_EXACT_THREE_RESULTS
		);
		// refresh the Apex wire adapter
		await flushAllPromises();

		const feedHeaderElements = getElementsByName(element, null, 'feedHeader');
		const feedBodyElements = getElementsByName(element, null, 'feedBody');
		const feedIconElements = getElementsByName(element, 'lightning-icon', 'feedCustomIcon');
		const feedNavigationButtonIconElement = getElementsByName(element, 'lightning-button-icon', 'feedRecordId');
		const feedDateTimeElements = getElementsByName(element, null, 'feedFormattedDateTime');
		expect(feedHeaderElements.length).toBe(3);
		expect(feedBodyElements.length).toBe(3);
		expect(feedIconElements.length).toBe(3);
		expect(feedNavigationButtonIconElement.length).toBe(1);
		expect(feedDateTimeElements.length).toBe(3);

		const feedRefreshButtonIconElement = getElementsByName(element, 'lightning-button-icon', 'refreshFeed');
		expect(feedRefreshButtonIconElement).not.toBeNull();

		// click on refresh button
		feedRefreshButtonIconElement[0].click();

		// Wait for DOM to update for lightning spinner (but not for Apex method to resolve)
		await Promise.resolve();

		// Expect lightning-spinner to be displayed
		expect(element.shadowRoot.querySelector('lightning-spinner')).toBeTruthy();

		// Wait for any asynchronous code to complete
		await flushAllPromises();

		// Expect lightning-spinner to be hidden after search completed
		expect(element.shadowRoot.querySelector('lightning-spinner')).toBeFalsy();

		// expect refresh apex to be called and new results are populated 
		expect(refreshApex).toHaveBeenCalledTimes(1);
	});

	it('displays case feed component with unexpected failure in @wire adaptor', async () => {
		// Arrange
		const element = createElement('c-unified-case-feeds', {
			is: UnifiedCaseFeeds
		});

		// Act
		document.body.appendChild(element);

		getLatestCaseFeedsResults.error(
			MOCK_GET_CASE_FEEDS_FAILURE
		);
		// refresh the Apex wire adapter
		await flushAllPromises();
		
		const errorDiv = element.shadowRoot.querySelector("div[data-id='error']");
		expect(errorDiv).not.toBeNull();
		expect(errorDiv.textContent).toBe('Error: Bad Request');
	});

	it('allows record navigation when icon button is clicked on SCR', async () => {
		// Arrange
		const element = createElement('c-unified-case-feeds', {
			is: UnifiedCaseFeeds
		});

		// Act
		document.body.appendChild(element);

		getLatestCaseFeedsResults.emit(
			MOCK_CASE_FEED_EXACT_THREE_RESULTS
		);
		// refresh the Apex wire adapter
		await flushAllPromises();

		const feedHeaderElements = getElementsByName(element, null, 'feedHeader');
		const feedBodyElements = getElementsByName(element, null, 'feedBody');
		const feedDateTimeElements = getElementsByName(element, null, 'feedFormattedDateTime');
		expect(feedHeaderElements.length).toBe(3);
		expect(feedBodyElements.length).toBe(3);
		expect(feedDateTimeElements.length).toBe(3);

		const feedNavigationButtonIconElement = getElementsByName(element, 'lightning-button-icon', 'feedRecordId');
		expect(feedNavigationButtonIconElement).not.toBeNull();
		expect(feedNavigationButtonIconElement.length).toBe(1);
		expect(feedNavigationButtonIconElement[0].iconName).toBe('utility:new_window');
		expect(feedNavigationButtonIconElement[0].getAttribute('data-value')).toBe('001000000000AAAAAA');
		expect(feedNavigationButtonIconElement[0].size).toBe('large');
		expect(feedNavigationButtonIconElement[0].variant).toBe('bare');

		// click on record navigation button
		feedNavigationButtonIconElement[0].click();

		const { pageReference } = getNavigateCalledWith();
		// Verify the component under test called the correct navigate event
		expect(pageReference.type).toBe("standard__recordPage");
		expect(pageReference.attributes.actionName).toBe("view");
		expect(pageReference.attributes.recordId).toBe("001000000000AAAAAA");
	});
});