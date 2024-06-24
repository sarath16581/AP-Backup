import { createElement } from 'lwc';
import CustomerSearchForm from 'c/customerSearchForm';

const SEARCH_FORM_INPUT_CMP = 'c-customer-search-form-inputs';

describe('c-customer-search-form', () => {
	afterEach(() => {
		// The jsdom instance is shared across test cases in a single file so reset the DOM
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
	});

	it('displays the customer search form inputs component', () => {
		// Arrange
		const element = createElement('c-customer-search-form', {
			is: CustomerSearchForm,
		});

		// Act
		document.body.appendChild(element);

		// Assert
		const inputComponent = element.shadowRoot.querySelector(
			SEARCH_FORM_INPUT_CMP
		);
		expect(inputComponent).not.toBeNull();
	});
});
