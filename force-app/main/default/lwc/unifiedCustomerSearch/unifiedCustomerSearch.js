/**
 * @description an LWC Customer Search Interface for Unified Experience
 * @changelog:
 * 2024-08-08 - added handler methods to handle `createcontact` and `backtosearch` events and pass `formInputs` params to child LWCs
 * 2024-08-28 - Added public properties `autoSearchOnLoad` and `autoLinkContact`, added public method `setFormInput`
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
	 * If enabled, then a search will be invoked when the search form is loaded.
	 * @type {boolean}
	 */
	@api autoSearchOnLoad = false;

	/**
	 * If enabled, then a search will automatically link the Contact if only one is found.
	 * @type {boolean}
	 */
	@api autoLinkContact = false;

	/**
	 * Sets the form fields for the firstName, lastName, emailAddress, and phoneNumber.
	 * This is used to pre-fill the form fields.
	 *
	 * @param {object} data Form fields to set
	 */
	@api setFormInputs({ firstName, lastName, emailAddress, phoneNumber }) {
		this.formInputs = {
			...this.formInputs,
			firstName,
			lastName,
			emailAddress,
			phoneNumber
		};
	}

	/**
	 * The `connectedCallback` lifecycle hook is called after the component is inserted into the DOM.
	 *
	 * This is used to notify the wrapper component which will call the `setFormInputs` method.
	 */
	connectedCallback() {
		this.dispatchEvent(new CustomEvent('connected'));
	}

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