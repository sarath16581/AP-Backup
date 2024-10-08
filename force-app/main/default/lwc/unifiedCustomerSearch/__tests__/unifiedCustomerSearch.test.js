import { createElement } from 'lwc';
import UnifiedCustomerSearch, { SEARCH_FORM_TITLE } from 'c/unifiedCustomerSearch';

const SEARCH_FORM_CMP = 'c-unified-customer-search-form';

describe('c-unified-customer-search', () => {
	afterEach(() => {
		// The jsdom instance is shared across test cases in a single file so reset the DOM
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
	});

	it('displays component title', () => {
		// Arrange
		const element = createElement('c-unified-customer-search', {
			is: UnifiedCustomerSearch,
		});

		// Act
		document.body.appendChild(element);

		// Assert
		const cardCmp = element.shadowRoot.querySelector('lightning-card');
		expect(cardCmp).not.toBeNull();
		expect(cardCmp.title).toBe(SEARCH_FORM_TITLE);
	});

	it('displays the customer search form inputs component', () => {
		// Arrange
		const element = createElement('c-unified-customer-search', {
			is: UnifiedCustomerSearch,
		});

		// Act
		document.body.appendChild(element);

		// Assert
		const inputComponent = element.shadowRoot.querySelector(
			SEARCH_FORM_CMP
		);
		expect(inputComponent).not.toBeNull();
	});
});
