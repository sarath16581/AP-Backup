import { LightningElement, api } from 'lwc';

// Lightning card title
export const SEARCH_FORM_TITLE = 'Customer Search';

/**
 * The Customer Search form allows users to specify criteria and search for
 * customer records. This component wraps the search form inputs and search
 * results components and is exposed for use in Lightning App Builder.
 *
 * @alias CustomerSearchForm
 * @hideconstructor
 */
export default class CustomerSearchForm extends LightningElement {
	/**
	 * The Id of the record to provide context to this component.
	 * @type {string|undefined}
	 */
	@api recordId;

	searchFormTitle = SEARCH_FORM_TITLE;
	isSearching = false;
	searchResponse;

	/**
	 * Handles the `onstart` event.
	 */
	handleSearchStart() {
		this.isSearching = true;
	}

	/**
	 * Handles the `onerror` event.
	 * Note: The error message is displayed by the form component, so there is no
	 * need to take any additional action here.
	 */
	handleSearchError() {
		this.isSearching = false;
	}

	/**
	 * Handles the `onresult` event.
	 * @param {CustomEvent} event - The event object which contains the searchResponse data.
	 */
	handleSearchResults(event) {
		this.searchResponse = event.detail;
		this.isSearching = false;
	}

	/**
	 * Handles the `onreset` event.
	 */
	handleSearchReset() {
		// Clear any previous results
		this.searchResponse = undefined;
	}
}
