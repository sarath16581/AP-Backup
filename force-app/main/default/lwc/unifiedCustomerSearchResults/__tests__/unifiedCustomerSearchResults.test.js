import { createElement } from 'lwc';
import UnifiedCustomerSearchResults from 'c/unifiedCustomerSearchResults';

describe('c-unified-customer-search-results', () => {
	afterEach(() => {
		// The jsdom instance is shared across test cases in a single file so reset the DOM
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
	});

	it('displays empty state - default state (paragraph image)', () => {
		// Arrange
		const element = createElement('c-unified-customer-search-results', {
			is: UnifiedCustomerSearchResults,
		});

		// Act
		document.body.appendChild(element);

		// Assert
		const emptyStatesArr = element.shadowRoot.querySelectorAll('c-empty-state');
		expect(emptyStatesArr.length).toBe(1);

		const emptyStateEl = emptyStatesArr[0];
		expect(emptyStateEl.illustration).toBe('paragraph');
		expect(emptyStateEl.textPosition).toBe('above');
		expect(emptyStateEl.titleText).toBe("Click 'Search' to begin");
		expect(emptyStateEl.bodyText).toBeUndefined();

		const resultsDiv = element.shadowRoot.querySelector(
			'div[data-id="search-results"]'
		);
		expect(resultsDiv).toBeNull();
	});

	it('displays empty state - no results (desert image)', () => {
		// Arrange
		const element = createElement('c-unified-customer-search-results', {
			is: UnifiedCustomerSearchResults,
		});
		element.searchResponse = { searchResults: [] };

		// Act
		document.body.appendChild(element);

		// Assert
		const emptyStatesArr = element.shadowRoot.querySelectorAll('c-empty-state');
		expect(emptyStatesArr.length).toBe(1);

		const emptyStateEl = emptyStatesArr[0];
		expect(emptyStateEl.illustration).toBe('desert');
		expect(emptyStateEl.textPosition).toBe('above');
		expect(emptyStateEl.titleText).toBe('No results found');
		expect(emptyStateEl.bodyText).toBe('Search results not relevant?');

		const createContactBtn = element.shadowRoot.querySelector('lightning-button');
		expect(createContactBtn).not.toBe(null);
		expect(createContactBtn.label).toBe('Create Contact');
		expect(createContactBtn.variant).toBe('neutral');
		expect(createContactBtn.iconName).toBe('utility:contact');

		const resultsDiv = element.shadowRoot.querySelector(
			'div[data-id="search-results"]'
		);
		expect(resultsDiv).toBeNull();
	});

	it('displays search results', () => {
		// Arrange
		const element = createElement('c-unified-customer-search-results', {
			is: UnifiedCustomerSearchResults,
		});
		element.searchResponse = {
			searchResults: [{ id: '001000000000001' }, { id: '001000000000002' }],
		};

		// Act
		document.body.appendChild(element);

		// Assert
		const emptyStatesArr = element.shadowRoot.querySelectorAll('c-empty-state');
		expect(emptyStatesArr.length).toBe(0);

		const resultsDiv = element.shadowRoot.querySelector(
			'div[data-id="search-results"]'
		);
		expect(resultsDiv).not.toBeNull();

		const numContactsEl = resultsDiv.querySelector('p[data-id="num-results"]');
		expect(numContactsEl).not.toBeNull();
		expect(numContactsEl.textContent).toBe('2 Contacts Found');

		const warningMsgEl = resultsDiv.querySelector(
			'p[data-id="warning-message"]'
		);
		expect(warningMsgEl).toBeNull();
	});

	it('displays search results with warning message', () => {
		// Arrange
		const element = createElement('c-unified-customer-search-results', {
			is: UnifiedCustomerSearchResults,
		});
		element.searchResponse = {
			searchResults: [{ id: '001000000000001' }, { id: '001000000000002' }],
			warningMessage: 'This is a test message',
		};

		// Act
		document.body.appendChild(element);

		// Assert
		const emptyStatesArr = element.shadowRoot.querySelectorAll('c-empty-state');
		expect(emptyStatesArr.length).toBe(0);

		const resultsDiv = element.shadowRoot.querySelector(
			'div[data-id="search-results"]'
		);
		expect(resultsDiv).not.toBeNull();

		const numContactsEl = resultsDiv.querySelector('p[data-id="num-results"]');
		expect(numContactsEl).not.toBeNull();
		expect(numContactsEl.textContent).toBe('2 Contacts Found');

		const warningMsgEl = resultsDiv.querySelector(
			'p[data-id="warning-message"]'
		);
		expect(warningMsgEl).not.toBeNull();
		expect(warningMsgEl.textContent).toBe('This is a test message');
	});
});
