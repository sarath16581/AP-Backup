/**
  * @author       : Sameed Khan<sameed.khan@mav3rik.com>
  * @date         : 01/05/2019
  * @description  : Component that integrates with QAS address validation API and provides 
  *                 autocomplete and validation behaviour
--------------------------------------- History --------------------------------------------------
01.04.2019    Sameed Khan(Mav3rik)    Created
19.08.2021    Naveen Rajanna          REQ2595146 Address details to be cleared when user clicked on close button in search input
**/
import { LightningElement, track, api } from 'lwc'
import searchAddress from '@salesforce/apex/QASAddressValidationController.searchAddress'
import getAddressDetails from '@salesforce/apex/QASAddressValidationController.getAddressDetails'

import { debounce } from 'c/utils'

export default class Lookup extends LightningElement {
    @api placeholder = 'Search for address'
    @api label = 'Address'
    @api addressChangeHandler
    @api addressSearchTermChangeHandler
    @api formUpdateCallback
    @api required = false
    @api searchAddressTerm = ''
    @api fieldLevelHelp = 'If address not found, please expand and manually enter address'

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
    @api address = {}


    @track showAddressDetails = false
    @track selectedRecord
    @track isLoading = false
    @track isSearchingAddressDetails = false
    @track searchResults = []
    @track shouldShowDropDown = false

    @api setAddress(address) {
        this.address = {...address}
    }
 
    @api setAddressSearchTerm(searchAddressTerm) {
        this.searchAddressTerm = searchAddressTerm
    }

    /* Commented out until customvalidity is included into the component. Currently able to bypass validation by collapsing this section on the respective form */
    /*
    get toggleButtonIcon() {
        return this.showAddressDetails === true ? 'utility:dash' : 'utility:add'
    }

    toggleAddressDetails() {
        this.showAddressDetails = !this.showAddressDetails
    } */

    search(event) {
        this.showAddressDetails=true
        const searchAddressTerm = event.target.value
        this.searchAddressTerm = searchAddressTerm
        if (searchAddressTerm.length >= 2) {
            this.debouncedSearchHandler(searchAddressTerm);
        }
    }

    async handleSearchResultSelect(event) {
        const record = event.detail
        this.isSearchingAddressDetails = true
        try {
            const addressResponse = await getAddressDetails({address: record.address}) 
            const parsedAddress = JSON.parse(addressResponse)
            if (parsedAddress.verified) parsedAddress.countrycode = 'AU' // the country code doesn't come through from QAS but we always expect the country code to be AU for verified addresses
            this.address = parsedAddress
            this.searchAddressTerm = record.address
            this.fireChangeHandlers()
        } catch (error) {
            //  eslint-disable-next-line no-console
            console.log(JSON.parse(JSON.stringify(error)))
        } finally {
            this.isSearchingAddressDetails = false
            this.closeSearchResultsList()
        }
    }

    focusOnSearchInput() {
        const searchInput = this.template.querySelector('input')
        if (searchInput) {
            searchInput.focus()
        }
    }

    debouncedSearchHandler = debounce(this.handleSearch, 200)

    async handleSearch(searchAddressTerm) {
        this.openSearchResultsList()
        this.isLoading = true
        try {
            const response = await searchAddress({ searchTerm: searchAddressTerm})
            const result = JSON.parse(response)
            this.searchResults = this.formatSearchRecordsForDisplay(result)
        } catch (error) {
            //  eslint-disable-next-line no-console
            console.log(JSON.parse(JSON.stringify(error)))
        } finally {
            this.isLoading = false
        }
    }

    // takes the records returned from the search and concatanates the data contained
    // in the queried fields (except 'Id', 'Name', 'FirstName' and 'LastName') joins it with a '|' for diplay
    // and puts in in a new field called 'additionalFieldData'
    defaultSearchResultSubtitleFormatter = () => ''

    defaultSearchResultTitleFormatter = record => record.address

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
    
    //REQ2595146
    handleAddressInputChange(event) {
        const value = event.target.value;
        if(value == '') { // if address value is empty that is when user clicks on close button
            this.searchAddressTerm = '';
            this.address = {};
            this.showAddressDetails = false;
            this.closeSearchResultsList();
        }
    }

    handleAddressChange(event) {
        const target = event.target;
        const value = target.type === "checkbox" ? target.checked : target.value;
        const key = target.name;
        this.address = { ...this.address, [key]: value }
        this.searchAddressTerm = this.mergeAddressFields(this.address)
        this.fireChangeHandlers()
    }

    fireChangeHandlers() {
        if (typeof this.addressChangeHandler === 'function') {
            this.addressChangeHandler({...this.address})
        }
        if (typeof this.addressSearchTermChangeHandler === 'function') {
            this.addressSearchTermChangeHandler(this.searchAddressTerm)
        }
    }

    mergeAddressFields(address) {
        return `${address.addressLine1 ? `${address.addressLine1},` : ''} ${address.addressLine2 ? ` ${address.addressLine2},` : ''} ${address.city || ''} ${address.state || ''} ${address.postcode || ''} ${address.countrycode || ''}`
    }

    openSearchResultsList() {
        if (this.searchResults.length > 0 || this.isLoading) {
            this.shouldShowDropDown = true
        }
    }

    closeSearchResultsList() {
        this.shouldShowDropDown = false
    }

    @api reportValidity(){
        const inputComponents = this.template.querySelectorAll(".address-input");
        const inputsArray = inputComponents ? [...inputComponents] : [];
        inputsArray.forEach(inputCmp => inputCmp.reportValidity())
    }

    @api setCustomValidity(isValid, errorMessage){
        let srchCmp = this.template.querySelector('[data-id="address-search"]');
        if(isValid){
            srchCmp.setCustomValidity("");
        } else {
            srchCmp.setCustomValidity(errorMessage);
        }
        srchCmp.reportValidity();
    }

    @api checkValidity(){
        const inputComponents = this.template.querySelectorAll(".address-input");
        const inputsArray = inputComponents ? [...inputComponents] : [];
        return inputsArray.reduce((acc, inputCmp) => {
            inputCmp.reportValidity();
            return acc && inputCmp.checkValidity();
        }, true)
    }
}