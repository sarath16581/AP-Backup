/**
 * @author Hasantha Liyanage
 * @date 2023-09-19
 * @group child component
 * @domain BSP
 * @description Type ahead component for BSP
 * @changelog
 * 2023-09-19 - Hasantha Liyanage  - Created
 */

import {api, LightningElement} from 'lwc';
import {NavigationMixin} from "lightning/navigation";
import {checkAllValidity} from 'c/bspCommonJS';

export default class BspTypeAhead extends NavigationMixin(LightningElement) {

	@api picklistOptions = []; // options object list for picklist
	@api inputLabel= '';
	@api inputSubLabel= '';
	@api inputPlaceholder= '';
	@api inputMessageWhenValueMissing = 'Complete this field.';
	@api inputRequired = false;
	@api searchTerm = ''; // search text
	@api defaultValue = {}; // is there a default value needs to be selected
	@api otherOptions = []; // other custom options to appear at the bottom of the drop

	picklistOrdered = []; // ordered picklist values
	searchResults; // searched values
	showSearchResults = false; // show hide the drop
	selected = {}; // object of the selected value from the drop
	isLoaded = false;
	isDefaultLoadedOnce = false; // if the picklistOptions[] has only one element, this is set to true

	/**
	 * Check custom validity of the component in the parent components when required
	 * @returns {*}
	 */
	@api
	checkValidity(){
		const inputComponents = this.template.querySelectorAll('lightning-input');
		const searchInput = this.template.querySelector('[data-id="searchbox"]');
		if(this.inputRequired) {
			const isExists = this.picklistOrdered.some((picklistOption) => picklistOption.label === searchInput.value);
			if (!isExists) {
				searchInput.setCustomValidity(this.inputMessageWhenValueMissing);
			}
		}
		return checkAllValidity(inputComponents,false);
	}

	/**
	 * Handle the selected value from the drop
	 * @param event
	 */
	handleSearchResultSelect(event) {
		this.showSearchResults = false;
		// if there is no value in the field set the search term empty will remove highlighting functionality in row's
		if (!event.target.value) {
			this.searchTerm = null;
		}

		const searchInput = this.template.querySelector('[data-id="searchbox"]');
		searchInput.value = event.detail.label;
		if (event.detail.value !== this.selected.value) {
			this.selected.value = event.detail.value;
			this.selected.label = event.detail.label;

			// letting the parent know when a value is selected
			const changeEvent = new CustomEvent('selection', {
				detail: {
					selected: this.selected
				}
			});
			this.dispatchEvent(changeEvent);
		}
		searchInput.setCustomValidity('');
		searchInput.reportValidity();
	}

	connectedCallback() {
		this.initialise();
		this.isLoaded = true;
	}

	renderedCallback() {
		this.setDefaultValues();
	}

	/**
	 * setting the default values when render
	 */
	setDefaultValues() {
		const searchInput = this.template.querySelector('[data-id="searchbox"]');
		// if the default is loaded on load and there is no value already set default value if available
		if (!this.isDefaultLoadedOnce && this.defaultValue && !searchInput.value) {
			this.isDefaultLoadedOnce = true;
			searchInput.value = this.defaultValue.label;
		}
	}

	/**
	 * execute initial preparations
	 */
	initialise() {
		// assign other options if available
		if (this.otherOptions) {
			this.picklistOrdered = [...this.picklistOptions, ...this.otherOptions];
		}
		// order option alphabetically
		this.picklistOrdered = this.picklistOrdered.sort((a, b) => {
			if (a.label < b.label) {
				return -1
			}
		});
	}

	/**
	 * Searching the list based on the keyed in value in the input field
	 * @param event
	 */
	searchList(event) {
		const input = event.target.value.toLowerCase();
		this.searchTerm = input; // assign the search term while typing in progress
		// get selected value
		const result = this.picklistOrdered.filter((picklistOption) =>
			picklistOption.label.toLowerCase().includes(input)
		);

		// deep copy is required to trigger bindings, this will help the text highlight
		this.searchResults = JSON.parse(JSON.stringify(result));
	}

	/**
	 * on focus out handler
	 * this function will check for validations after curser moved out from component
	 * @param event
	 */
	handleOnFocusOut(event) {
		if(this.inputRequired) {
			const isExists = this.picklistOrdered.some((picklistOption) => picklistOption.label === event.target.value);
			if (!isExists) {
				const searchInput = this.template.querySelector('[data-id="searchbox"]');
				searchInput.setCustomValidity(this.inputMessageWhenValueMissing);
			}
		}
		// focus out happens after the blur
		event.target.reportValidity();

		//let the parent component know there is a reset happened
		this.selected.value = event.target.value;
		const changeEvent = new CustomEvent('inputfocusout', {
			detail: {
				selected: this.selected
			}
		});
		this.dispatchEvent(changeEvent);
	}

	/**
	 * on blur handler
	 * @param event
	 */
	handleOnBlur(event) {
		// hide the dropdown when user click outside the component
		this.showSearchResults = false;

	}

	/**
	 * most of the initialisation work happens here
	 * @param event
	 */
	handleOnFocus(event) {
		this.showSearchResults = true;
		// nothing previously typed or clear button is clicked: initialising the dropdown list again
		if (!this.searchResults || !event.target.value) {
			// re-initialising the list
			this.searchResults = this.picklistOrdered;
		} else {
			// show the dropdown list
			this.showSearchResults = true;
		}

		// assign current value in the input field will highlight the matching text in list
		this.searchTerm = event.target.value;
	}
}