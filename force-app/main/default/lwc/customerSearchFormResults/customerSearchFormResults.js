import { LightningElement, api } from 'lwc';

/**
 * The Customer Search Form Results component displays the search results.
 * The search response is passed to the component via the `searchResponse` property.
 *
 * @alias CustomerSearchFormResults
 * @hideconstructor
 */
export default class CustomerSearchFormResults extends LightningElement {
	/**
	 * The search response object returned from the search.
	 * @type {object}
	 */
	@api searchResponse;

	/**
	 * The search results array (records) returned from the search.
	 * @type {object[]}
	 */
	get searchResults() {
		return this.searchResponse?.searchResults || [];
	}

	/**
	 * The warning message, if applicable, returned from the search.
	 * @type {string}
	 */
	get warningMessage() {
		return this.searchResponse?.warningMessage;
	}

	/**
	 * The number of search results returned from the search.
	 * @type {number}
	 */
	get numSearchResults() {
		return this.searchResults?.length || 0;
	}

	/**
	 * Determines if in the default state (e.g. no search performed yet)
	 * @type {boolean}
	 */
	get defaultState() {
		return !this.searchResponse;
	}

	/**
	 * Determines if no results were returned (e.g. no matching records)
	 * @type {boolean}
	 */
	get noResults() {
		return this.numSearchResults === 0;
	}
}
