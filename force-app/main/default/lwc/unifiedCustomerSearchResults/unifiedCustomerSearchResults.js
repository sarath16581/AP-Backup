/**
 * @description an LWC search result table embedded in the unifiedCustomerSearch LWC
 * @changelog:
 * 2024-08-08 - added handleCreateContact() to fire `createcontact` event
 * 2024-08-06 - Added 'Link' Action button to results table
 */
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { transformSearchResults } from './helper';

const TABLE_COLUMNS = [
	{
		label: 'Name',
		fieldName: 'nameArr',
		type: 'customMultilineTextComplex',
		wrapText: false,
		hideDefaultActions: true,
		typeAttributes: {
			iconSrc: {
				fieldName: 'customerTypeIcon',
			},
			iconTitle: {
				fieldName: 'customerType',
			},
			iconSize: 'medium',
			iconAlternativeText: {
				fieldName: 'customerType',
			},
		},
	},
	{
		label: 'Phone',
		fieldName: 'phoneNumbersArr',
		type: 'customMultilineTextComplex',
		wrapText: false,
		hideDefaultActions: true,
	},
	{
		label: 'Email',
		fieldName: 'emailAddressesArr',
		type: 'customMultilineTextComplex',
		wrapText: false,
		hideDefaultActions: true,
	},
	{
		label: 'Address',
		fieldName: 'mailingAddressArr',
		type: 'customMultilineTextComplex',
		wrapText: false,
		hideDefaultActions: true,
	},
	{
		label: 'Cases',
		fieldName: 'numCasesArr',
		type: 'customMultilineTextComplex',
		wrapText: false,
		hideDefaultActions: true,
	},
	{
		fixedWidth: 100,
		label: 'Link',
		type: 'button',
		typeAttributes: {
			iconName: 'action:new_contact',
			label: 'Link',
			name: 'linkContact',
			title: 'Link'
		}
	}
];

/**
 * The Unified Customer Search Results component displays the search results that is passed to the component via the `searchResponse` property.
 *
 * @alias UnifiedCustomerSearchResults
 * @hideconstructor
 */
export default class UnifiedCustomerSearchResults extends NavigationMixin(
	LightningElement
) {
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
	get isDefaultState() {
		return !this.searchResponse;
	}

	/**
	 * Determines if no results were returned (e.g. no matching records)
	 * @type {boolean}
	 */
	get noResults() {
		return this.numSearchResults === 0;
	}

	columns = TABLE_COLUMNS;

	navigateToRecordPage(recordId) {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: recordId,
				actionName: 'view',
			},
		});
	}

	get data() {
		// Bind the navigateToRecordPageFn to the component instance so that when it is called by the onClick()
		const navigateToRecordPageFn = this.navigateToRecordPage.bind(this);
		return transformSearchResults(this.searchResults, navigateToRecordPageFn);
	}

	/**
	 * Navigate to customer creation form
	 *
	 * @fires UnifiedCustomerSearchResults#createcontact
	 */
	handleCreateContact(){
		this.dispatchEvent(new CustomEvent('createcontact'));
	}

	/**
	 * Handle row action events from lightning-datatable.
	 *  - 'Link' Action Button Click
	 * 
	 * @param {CustomEvent} event - The row action event.
	 * 
	 * @fires {CustomEvent} `
	 */
	handleRowAction(event) {
        const contactId = event.detail?.row?.contactId;
        const actionName = event.detail?.action?.name;
        if (actionName === 'linkContact') {
            this.dispatchEvent(new CustomEvent('linkcontact', { detail: { contactId }, bubbles:true, composed:true }));
		}
    }
}