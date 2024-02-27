/**
 * @author       : Dheeraj Mandavilli<dheeraj.mandavilli@auspost.com.au>
 * @date         : 01/10/2019
 * @description  : Component that integrates with AME address validation API and provides
 *                 autocomplete and validation behaviour
 --------------------------------------- History --------------------------------------------------
 11.09.2019    Dheeraj Mandavilli          Created
 **/
import { LightningElement, track, api } from 'lwc'
import searchAddress from '@salesforce/apex/AMEAddressValidationController1.searchAddress'
import getAddressDetails from '@salesforce/apex/AMEAddressValidationController1.getAddressDetails'

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
@track enterAddressDetails = true

@api setAddress(address) {
        this.address = {...address}
    }

@api setAddressSearchTerm(searchAddressTerm) {
        this.searchAddressTerm = searchAddressTerm
    }

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
            const addressResponse = await getAddressDetails({address: record.dpid})
            const parsedAddress = JSON.parse(addressResponse)

            const formattedAddress =  this.formatParsedAddress(parsedAddress)
            this.address = formattedAddress;
            this.address.addressLine= formattedAddress.addressLine1;
            this.address.addressLine3=formattedAddress.addressLine2;
            this.address.city=formattedAddress.locality;
            this.address.state=formattedAddress.state;
            this.address.postcode=formattedAddress.postcode;
            this.address.latitude=formattedAddress.latitude;
            this.address.longitude=formattedAddress.longitude;
            this.address.dpid=formattedAddress.delpointId;
            this.searchAddressTerm = formattedAddress.address;
            const selectedEvent = new CustomEvent("searchtermchange", {
                detail: this.address
				//detail: {"address":this.address}

            });
            // Dispatches the event.
            this.dispatchEvent(selectedEvent);

            this.fireChangeHandlers()
        } catch (error) {
            //  eslint-disable-next-line no-console
            console.log(JSON.parse(JSON.stringify(error)))
        } finally {
            this.isSearchingAddressDetails = false
            this.closeSearchResultsList()
        }
    }

    formatParsedAddress([parsedAddress]) {
        const address = parsedAddress.singleLine;
        const addressDetails = parsedAddress.semiStructured;
        const [geoData] = parsedAddress.geoDataList;
        const addressLine1 = parsedAddress.semiStructured.addressLines[0];
        const addressLine2 = parsedAddress.semiStructured.addressLines[1];
        const delpointId=parsedAddress.dpid;
        return {
            address,
            delpointId,
            ... addressDetails,
            ... geoData,
            addressLine1,
            addressLine2,
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
        // Creates the event with the data.
        const manualChangeEvent = new CustomEvent("streetchange", {
            detail: this.address
        });
        // Dispatches the event.
        this.dispatchEvent(manualChangeEvent);
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

    handleCheckBoxChange(event){
        this.CheckBox=event.target.checked;
        if(this.CheckBox === true) {
            this.enterAddressDetails=false
        }else{
            this.enterAddressDetails=true
        }

    }

@api reportValidity(){
        const inputComponents = this.template.querySelectorAll(".address-input");
        const inputsArray = inputComponents ? [...inputComponents] : [];
        inputsArray.forEach(inputCmp => inputCmp.reportValidity())
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