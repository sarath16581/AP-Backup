/**
 * @date         : 19/05/2020
 * @description  : Component that integrates with AME address validation API and provides
 *                 autocomplete and validation behaviour
 --------------------------------------- History --------------------------------------------------
 11.09.2019    Hara Sahoo          Created
 13.05.2021    Snigdha Sahu        INC1774375 : Incomplete address capture from H&S forms
 18.06.2021    Naveen Rajanna      REQ2529715 - Removed the INC1774375 fix and is now handelled in the parse method of AMEFinalResponse class
 **/
import { LightningElement, track, api } from 'lwc'
import searchAddress from '@salesforce/apex/AMEAddressValidationController1.searchAddress'
import getAddressDetails from '@salesforce/apex/AMEAddressValidationController1.getAddressDetails'

import { debounce } from 'c/utils'

const ATTRIB_ACTIVE_DESC = 'aria-activedescendant';
const NODE_INPUT = 'LIGHTNING-INPUT';
const NODE_SERARCH_RESULT = 'C-SEARCH-RESULT';
const SCROLL_OPTIONS = { behaviour: "smooth", block: "nearest" };
const SELECTOR_COMBOBOX = 'DIV[data-name="cmpCombobox"]';
const SELECTOR_INPUT = `${NODE_INPUT}[data-name="cmpSearchInput"]`;
const SELECTOR_OPTIONS = 'UL[data-name="option-container"] > LI[role="option"]';

export default class chasMissingItemAddressLookup extends LightningElement {
	@api inputError = false;
	@api inputFieldError = false;
	@api errorMessage = '';
	@api placeholder = 'Type your address';
	@api label = 'Address';
	@api addressChangeHandler;
	@api addressSearchTermChangeHandler;
	@api formUpdateCallback;
	@api required = false;
	@api searchAddressTerm = '';
	@api fieldLevelHelp = 'If address not found, please expand and manually override the address';

	/* the address attribute must be of the shape
	{
		addressLine1
		addressLine2
		city
		state
		postcode
		countrycode
		dpid
	}
	*/
	@api address = {};

	@track showAddressDetails = false;
	@track selectedRecord;
	isLoading;

	@track isSearchingAddressDetails = false;
	@track searchResults = [];
	@track isShowDropDown = false;
	@track enterAddressDetails = true;

	@api setAddress(address) {
		this.address = { ...address }
	}

	@api setAddressSearchTerm(searchAddressTerm, updateUI) {
		this.searchAddressTerm = searchAddressTerm;

		if (updateUI) {
			// Return whether UI is in sync
			return this.updateUserSearchInput();
		}
	}
	/* checks for form validity errors and sets the error class*/
	get searchboxClass() {
		//return `slds-input slds-combobox__input slds-has-focus ${this.inputError ? 'searchbox-err' : 'searchbox'}`;
		return `${this.inputError ? 'searchbox-err' : 'searchbox'}`;
	}
	/* checks for form validity errors and sets the error class, like blank fields etc*/
	get checkValidityClass() {
		let fieldInputClass = 'slds-m-right_x-small';
		if (this.inputFieldError) {
			const allValid = [...this.template.querySelectorAll('lightning-input')]
				.reduce((validSoFar, inputCmp) => {
					inputCmp.reportValidity();
					return validSoFar && inputCmp.checkValidity();
				}, true);
			if (allValid) {
				this.inputFieldError = false;
				return fieldInputClass;
			} else {
				this.inputFieldError = true;
				return fieldInputClass;
			}
		}
		else {
			return fieldInputClass;
		}

	}

	/***
	 * Added a connectedCallback method to set the initial value as a one-off action within renderedCallback.
	 * This prevents a feedback loop (where onchange event causes it so set the value resulting in missing key-strokes)
	 */
	connectedCallback() {
		this.activeIndex = -1;

		// Set initial value for search input
		if (this.searchAddressTerm) {
			this.setInitValue = true;
		}
	}

	/***
	 * Set initial value for address search 
	 */
	renderedCallback() {
		if (this.setInitValue) {
			// One-off initialisation, skip whenever applied
			if (this.updateUserSearchInput()) {
				delete this.setInitValue;
			}
		}
	}

	updateUserSearchInput() {
		const elem = this.template.querySelector(SELECTOR_INPUT);

		if (elem) {
			elem.value = this.searchAddressTerm;			
		}

		// Return whether this operation succeeded
		return !!elem;
	}

	/**
	 * Event handler for on change event (any type of input)
	 * @param {*} event 
	 * @returns void
	 */
	handleChange(event) {
		if (event.target.nodeName === NODE_INPUT) {
			this.showAddressDetails = false;
			this.inputError = false;

			const showError = new CustomEvent("showError", {
				detail: this.inputError
			});

			// Fire the custom event to inform the parent component, that the field has an error
			this.dispatchEvent(showError);

			const searchAddressTerm = event.target.value;

			if (this.searchAddressTerm != searchAddressTerm) {
				return new Promise(() => {
					this.setAddressSearchTerm(searchAddressTerm);

					if (searchAddressTerm.length >= 2) {
						this.debouncedSearchHandler(searchAddressTerm);
					}

					const addressTyped = new CustomEvent("addressTyped", {
						detail: { searchAddressTerm }
					});

					// Fire the custom event to inform the parent component with the address typed
					this.dispatchEvent(addressTyped);
				});
			}
		}
	}

	/**
	 * Existing method that enables end user to capture address manually
	 */
	selectManually() {
		this.activeIndex = -1;
		this.setDropDownVisibility(false);
		
		this.showAddressDetails = true;
		this.required = true;
		this.CheckBox = true;

		const addressOverride = new CustomEvent("addressOverride", {
			detail: { selected: this.CheckBox, }
		});

		// Fire the custom event to inform the parent component with the manually entered address
		this.dispatchEvent(addressOverride);
		if (this.CheckBox === true) {
			this.enterAddressDetails = false
		}
	}
	
	async selectSearchOption(event) {
		const record = event.detail;
		this.isSearchingAddressDetails = true;

		try {
			const addressResponse = await getAddressDetails({ address: record.dpid });
			const parsedAddress = JSON.parse(addressResponse);

			const formattedAddress = this.formatParsedAddress(parsedAddress);
			this.address = {
				...formattedAddress,
				addressLine : formattedAddress.addressLine1,
				addressLine3 : formattedAddress.addressLine2,
				city : formattedAddress.locality,
				dpid : formattedAddress.delpointId
			};
			
			this.setAddressSearchTerm(formattedAddress.address, true);

			const selectedEvent = new CustomEvent("searchtermchange", {
				detail: {
					address: this.address,
				}

			});
			// Dispatches the event to inform the parent component with the selected address
			this.dispatchEvent(selectedEvent);

			this.fireChangeHandlers()
		} catch (error) {
			//  eslint-disable-next-line no-console
		} finally {
			this.isSearchingAddressDetails = false;
			this.setDropDownVisibility(false);
		}
	}

	formatParsedAddress([parsedAddress]) {
		const [geoData] = parsedAddress.geoDataList;
		
		return {
			address : parsedAddress.singleLine,
			delpointId : parsedAddress.dpid,
			...parsedAddress.semiStructured,
			...geoData,
			addressLine1 : parsedAddress.semiStructured.addressLines[0],
			addressLine2 : parsedAddress.semiStructured.addressLines[1]
		};
	}

	focusOnSearchInput() {
		const searchInput = this.template.querySelector('input[data-name="cmpSearchInput"]')
		if (searchInput) {
			searchInput.focus();
		}
	}

	debouncedSearchHandler = debounce(this.handleSearch, 200);
	// eslint-disable-next-line @lwc/lwc/no-async-operation
	timeoutDelay = (wait = 100) => new Promise(res => setTimeout(res, wait));
	delayedLostFocus = () => this.timeoutDelay().then(() =>{
		if (!this.gotFocus) {
			this.setDropDownVisibility(false);
		}
	});

	async handleSearch(searchAddressTerm) {
		this.setDropDownVisibility(true);		
		this.isLoading = true;
		try {
			const response = await searchAddress({ searchTerm: searchAddressTerm });
			const result = JSON.parse(response);
			this.searchResults = this.formatSearchRecordsForDisplay(result);
		} catch (error) {
			//  eslint-disable-next-line no-console
		} finally {
			this.isLoading = false
		}
	}

	// takes the records returned from the search and concatanates the data contained
	// in the queried fields (except 'Id', 'Name', 'FirstName' and 'LastName') joins it with a '|' for diplay
	// and puts in in a new field called 'additionalFieldData'
	defaultSearchResultSubtitleFormatter = () => ''

	defaultSearchResultTitleFormatter = record => record.singleLine

	formatSearchRecordsForDisplay(records) {
		const titleMapper = typeof this.searchResultTitleFormatter === 'function'
			? this.searchResultTitleFormatter : this.defaultSearchResultTitleFormatter
		const subtitleMapper = typeof this.searchResultSubtitleFormatter === 'function'
			? this.searchResultSubtitleFormatter : this.defaultSearchResultSubtitleFormatter
		const titles = records.map(titleMapper)
		const subtitles = records.map(subtitleMapper)
		return records.map((record, index) => ({
			...record,
			title: titles[index],
			subtitle: subtitles[index],
		}))
	}
	/*@api addressLine1;
	@api city;*/

	handleAddressChange(event) {
		const target = event.target;
		
		this.address = {
			...this.address,
			[target.name]: target.type === "checkbox" ? target.checked : target.value
		};
		const searchTerm = { ...this.address };

		// Fire the custom event to inform the parent with the change event
		this.dispatchEvent(new CustomEvent("valuechange", { detail: { searchTerm } }));

		// Reflect update in UI
		this.setAddressSearchTerm(
			[
				this.address.addressLine1,
				this.address.addressLine2,
				this.address.city,
				this.address.state,
				this.address.postcode
			].filter(
				str => !!str?.trim()
			).join(' '),
			true
		);

		this.fireChangeHandlers();
	}

	fireChangeHandlers() {
		if (typeof this.addressChangeHandler === 'function') {
			this.addressChangeHandler({ ...this.address });
		}

		if (typeof this.addressSearchTermChangeHandler === 'function') {
			this.addressSearchTermChangeHandler(this.searchAddressTerm);
		}
	}


	mergeAddressFields(address) {
		// Creates the event with the data.
		const streetDetails = this.address;
		const manualChangeEvent = new CustomEvent("streetchange", {
			detail: this.address
		});
		// Dispatches the event.
		this.dispatchEvent(manualChangeEvent);
		return `${address.addressLine1 ? `${address.addressLine1},` : ''} ${address.addressLine2 ? ` ${address.addressLine2},` : ''} ${address.city || ''} ${address.state || ''} ${address.postcode || ''} ${address.countrycode || ''}`
	}

	openSearchResultsList() {
		if (this.searchResults.length > 0 || this.isLoading) {
			this.setDropDownVisibility(true);
		}
	}

	@api reportValidity() {
		const inputComponents = this.template.querySelectorAll(".address-input");
		const inputsArray = inputComponents ? [...inputComponents] : [];
		inputsArray.forEach(inputCmp => inputCmp.reportValidity());
	}

	@api checkValidity() {
		const inputComponents = this.template.querySelectorAll(".address-input");
		const inputsArray = inputComponents ? [...inputComponents] : [];
		return inputsArray.reduce((acc, inputCmp) => {
			inputCmp.reportValidity();
			return acc && inputCmp.checkValidity();
		}, true);
	}

	/**
	 * Align list behaviour/visibility with focus switching
	 * - prevent flicker when different elements within the component are focussed
	 * @param {*} event 
	 */
	handleFocusIn(event) {
		this.gotFocus = true;
	}

	/**
	 * Align list behaviour/visibility with focus switching
	 * - prevent flicker when different elements within the component are focussed
	 * @param {*} event 
	 */
	handleFocusOut(event) {
		delete this.gotFocus;
		this.delayedLostFocus();
	}

	handleKeyPress(event) {
		if(['Escape', 'Enter'].indexOf(event.key) >= 0) {			
			if (event.key === 'Enter') {
				// perform select
				this.selectElement();
			}

			this.searchInput = '';
			this.setDropDownVisibility(false);
			event.preventDefault();
		} else if (['ArrowDown', 'ArrowUp', 'Home', 'End'].indexOf(event.key) >= 0) {
			let selectIndex = this.activeIndex;

			if (event.key === 'ArrowDown') {
				selectIndex++;
			// Disable Home/End key as this disrupts the address input behaviour
			// } else if (event.key === 'Home') {
			// 	selectIndex = 0;
			// } else if (event.key === 'End') {
			// 	selectIndex = this.searchResults.length;
			} else if (event.key === 'ArrowUp') {
				selectIndex = selectIndex > -1 
					? selectIndex - 1 : -1;
			}

			this.setSelectedIndex(selectIndex);
			event.preventDefault();
		}
	}

	handleSelect(event) {
		const { nodeName } = event.target;
		if (nodeName === NODE_SERARCH_RESULT) {
			this.selectSearchOption(event);
		} else if (nodeName === 'LI' && event.target.dataset?.name === 'liSelectManual') {
			this.selectManually(event);
		}
	}

	setDropDownVisibility(visible) {
		const elems = this.getElements([
			SELECTOR_COMBOBOX,
			SELECTOR_INPUT
		]);

		elems.cmpCombobox?.classList.toggle('slds-is-open', visible);
		elems.cmpSearchInput.setAttribute('aria-expanded', visible);
		this.isShowDropDown = visible;
	}

	/***
	 * Returns a map of elements by data-name attribute value
	 * @param {string[]} selectorArr List of query selectors
	 */
	getElements(selectorArr) {
		return [
			...this.template.querySelectorAll(selectorArr.join(','))
		].reduce(
			(r, elem) => Object.assign(r, { [ elem.dataset.name ] : elem } ),
			{ }
		);
	}

	setSelectedIndex(itemIndex) {
		const elemSelectors = [
			SELECTOR_OPTIONS,
			SELECTOR_INPUT
		];

		const allElems = [...this.template.querySelectorAll(elemSelectors.join(','))];
		const listElems = allElems.filter(elem => elem.nodeName === 'LI');
		const activeListElem = listElems.find(elem => elem.hasAttribute(ATTRIB_ACTIVE_DESC));

		if (itemIndex !== listElems.indexOf(activeListElem)) {
			activeListElem?.removeAttribute(ATTRIB_ACTIVE_DESC);
		}

		if (itemIndex >= listElems.length) {
			itemIndex = listElems.length - 1;
		}

		this.activeIndex = itemIndex;

		if (itemIndex >= 0) {
			listElems[itemIndex].setAttribute(ATTRIB_ACTIVE_DESC, '');
			listElems[itemIndex].scrollIntoView(SCROLL_OPTIONS);
		} else {
			// Focus search input 
			const inputElem = allElems.find(elem => elem.nodeName === NODE_INPUT);
			inputElem?.focus();
		}
	}

	selectElement() {
		const elemSelector = `li[${ATTRIB_ACTIVE_DESC}]`;
		const activeElem = this.template.querySelector(elemSelector);

		if (activeElem) {
			activeElem.removeAttribute(ATTRIB_ACTIVE_DESC);
			if (this.activeIndex < 0) {
				return;
			} else if (this.activeIndex < this.searchResults.length) {
				this.selectSearchOption({ detail : this.searchResults[this.activeIndex] });
				this.activeIndex = -1;
			} else {
				// manually enter address
				this.selectManually();
			}
		}
	}

	/**
	 * Disable keyboard navigation when mouse is used to select an address
	 * @param {*} event 
	 */
	handleMouseMove(event) {
		if (this.activeIndex !== -1) {
			this.setSelectedIndex(-1);
		}
	}
}