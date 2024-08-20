/**
 * @description an LWC Customer Search Interface for Unified Experience
 * @changelog:
 * 2024-08-08 - added handler methods to handle `createcontact` and `backtosearch` events and pass `formInputs` params to child LWCs
 */
import { LightningElement, api } from 'lwc';

// Lightning card title
export const SEARCH_FORM_TITLE = 'Customer Search';

/**
 * The Unified Customer Search component allows users to specify criteria and search for customer records. This component wraps
 * the search form and search results components and is exposed for use in Lightning App Builder.
 *
 * @alias UnifiedCustomerSearch
 * @hideconstructor
 */
export default class UnifiedCustomerSearch extends LightningElement {
	/**
	 * The Id of the record to provide context to this component.
	 * @type {string|undefined}
	 */
	@api recordId;

	searchFormTitle = SEARCH_FORM_TITLE;
	isSearching = false;
	searchResponse;
	showCustomerSearchForm = true;
	showCustomerCreationForm = false;
	formInputs;

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

	/**
	 * Handles the `createcontact` event.
	 */
	handleCreateContact(){
		this.showCustomerCreationForm = true;
		this.showCustomerSearchForm = false;
		// invoke a method to retrieve form inputs from customer search ui on demand
		const customerSearchFormInputs = this.template.querySelector('c-unified-customer-search-form');
		if (customerSearchFormInputs) {
			const searchFormInputs = customerSearchFormInputs.getFormInputs();
			this.formInputs = {
				firstName: searchFormInputs.firstName,
				lastName: searchFormInputs.lastName,
				phoneNumber: searchFormInputs.phoneNumber,
				emailAddress: searchFormInputs.emailAddress,
				addressObj: searchFormInputs.addressObj,
				organisationAccountId: searchFormInputs.organisationAccountId,
				addressOverride: searchFormInputs.addressOverride,
				customerType: searchFormInputs.customerType
			}
		}
	}

	/**
	 * Handles the `backtosearch` event.
	 */
	handleBackToSearch(){
		this.showCustomerCreationForm = false;
		this.showCustomerSearchForm = true;
		// invoke a method to retrieve form inputs from customer creation ui on demand
		const customerCreationFormInputs = this.template.querySelector('c-unified-customer-creation');
		if (customerCreationFormInputs) {
			const creationFormInputs = customerCreationFormInputs.getFormInputs();
			this.formInputs = {
				firstName: creationFormInputs.firstName,
				lastName: creationFormInputs.lastName,
				phoneNumber: creationFormInputs.phoneNumber,
				emailAddress: creationFormInputs.emailAddress,
				addressObj: creationFormInputs.addressObj,
				organisationAccountId: creationFormInputs.organisationAccountId,
				addressOverride: creationFormInputs.addressOverride,
				customerType: creationFormInputs.customerType
			}
		}
	}

}