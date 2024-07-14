import { createElement } from 'lwc';
import EmptyState from 'c/emptyState';

describe.each([['desert'], ['fishingDeals'], ['noAccess'], ['noAccess2'], ['openRoad'], ['paragraph']])(
	"c-empty-state (illustration='%s')",
	(illustration) => {
		afterEach(() => {
			// The jsdom instance is shared across test cases in a single file so reset the DOM
			while (document.body.firstChild) {
				document.body.removeChild(document.body.firstChild);
			}
		});

		it(`displays large svg (default)`, () => {
			// Arrange
			const element = createElement('c-empty-state', {
				is: EmptyState,
			});
			element.illustration = illustration;

			// Act
			document.body.appendChild(element);

			// Assert
			const div = element.shadowRoot.querySelector(
				'div.slds-illustration_large'
			);
			expect(div).not.toBeNull();

			const svg = div.querySelector('svg.slds-illustration__svg');
			expect(svg).not.toBeNull();
		});

		it(`displays large svg (set 'size' property)`, () => {
			// Arrange
			const element = createElement('c-empty-state', {
				is: EmptyState,
			});
			element.illustration = illustration;
			element.size = 'large';

			// Act
			document.body.appendChild(element);

			// Assert
			const div = element.shadowRoot.querySelector(
				'div.slds-illustration_large'
			);
			expect(div).not.toBeNull();

			const svg = div.querySelector('svg.slds-illustration__svg');
			expect(svg).not.toBeNull();
		});

		it(`displays small svg (set 'size' property)`, () => {
			// Arrange
			const element = createElement('c-empty-state', {
				is: EmptyState,
			});
			element.illustration = illustration;
			element.size = 'small';

			// Act
			document.body.appendChild(element);

			// Assert
			const div = element.shadowRoot.querySelector(
				'div.slds-illustration_small'
			);
			expect(div).not.toBeNull();

			const svg = div.querySelector('svg.slds-illustration__svg');
			expect(svg).not.toBeNull();
		});

		it(`displays title and body text below (default)`, () => {
			// Arrange
			const element = createElement('c-empty-state', {
				is: EmptyState,
			});
			element.illustration = illustration;
			element.titleText = 'This is a test';
			element.bodyText = 'Example of some text goes here.';

			// Act
			document.body.appendChild(element);

			// Assert
			const gridEl = element.shadowRoot.querySelector('div.slds-grid_vertical');
			expect(gridEl).not.toBeNull();

			// First element should be the SVG image
			const svgEl = gridEl.querySelector('svg.slds-illustration__svg');
			expect(svgEl).not.toBeNull();

			// Second element should be the title text (below the image)
			const titleTextEl = gridEl.querySelector('h3');
			expect(titleTextEl).not.toBeNull();
			expect(titleTextEl.textContent).toBe('This is a test');

			// Third element should be the body text (below the image)
			const bodyTextEl = gridEl.querySelector('p');
			expect(bodyTextEl).not.toBeNull();
			expect(bodyTextEl.tagName.toLowerCase()).toEqual('p');
			expect(bodyTextEl.textContent).toBe('Example of some text goes here.');
		});

		it(`displays title and body text below (set 'textPosition' property)`, () => {
			// Arrange
			const element = createElement('c-empty-state', {
				is: EmptyState,
			});
			element.illustration = illustration;
			element.textPosition = 'below';
			element.titleText = 'This is a test';
			element.bodyText = 'Example of some text goes here.';

			// Act
			document.body.appendChild(element);

			// Assert
			const gridEl = element.shadowRoot.querySelector('div.slds-grid_vertical');
			expect(gridEl).not.toBeNull();

			// First element should be the SVG image
			const svgEl = gridEl.querySelector('svg.slds-illustration__svg');
			expect(svgEl).not.toBeNull();

			// Second element should be the title text (below the image)
			const titleTextEl = gridEl.querySelector('h3');
			expect(titleTextEl).not.toBeNull();
			expect(titleTextEl.textContent).toBe('This is a test');

			// Third element should be the body text (below the image)
			const bodyTextEl = gridEl.querySelector('p');
			expect(bodyTextEl).not.toBeNull();
			expect(bodyTextEl.tagName.toLowerCase()).toEqual('p');
			expect(bodyTextEl.textContent).toBe('Example of some text goes here.');
		});

		it(`displays title and body text above (set 'textPosition' property)`, () => {
			// Arrange
			const element = createElement('c-empty-state', {
				is: EmptyState,
			});
			element.illustration = illustration;
			element.textPosition = 'above';
			element.titleText = 'This is a test';
			element.bodyText = 'Example of some text goes here.';

			// Act
			document.body.appendChild(element);

			// Assert
			const gridEl = element.shadowRoot.querySelector(
				'div.slds-grid_vertical-reverse'
			);
			expect(gridEl).not.toBeNull();

			// First element should be the SVG image
			const svgEl = gridEl.querySelector('svg.slds-illustration__svg');
			expect(svgEl).not.toBeNull();

			// Second element should be the title text (below the image)
			const titleTextEl = gridEl.querySelector('h3');
			expect(titleTextEl).not.toBeNull();
			expect(titleTextEl.textContent).toBe('This is a test');

			// Third element should be the body text (below the image)
			const bodyTextEl = gridEl.querySelector('p');
			expect(bodyTextEl).not.toBeNull();
			expect(bodyTextEl.tagName.toLowerCase()).toEqual('p');
			expect(bodyTextEl.textContent).toBe('Example of some text goes here.');
		});
	}
);
