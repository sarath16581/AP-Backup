/**
 * @date         : 19/05/2020
 * @description  : Component that integrates with AME address validation API and provides
 *                 autocomplete and validation behaviour
 --------------------------------------- History --------------------------------------------------
 11.09.2019    Hara Sahoo          Created
 25.05.2021    Snigdha Sahu        INC1774375 : Incomplete address capture from H&S forms
 18.06.2021    Naveen Rajanna      REQ2529715 - Removed the INC1774375 fix and is now handelled in the parse method of AMEFinalResponse class
 **/
import { LightningElement, track, api } from 'lwc'
import searchAddress from '@salesforce/apex/AMEAddressValidationController1.searchAddress'
import getAddressDetails from '@salesforce/apex/AMEAddressValidationController1.getAddressDetails'

import { debounce } from 'c/utils'

export default class chasMissingItemAddressLookup extends LightningElement {
@api inputError = false
@api inputFieldError = false
@api errorMessage = ''
@api placeholder = 'Type your address'
@api label = 'Address'
@api addressChangeHandler
@api addressSearchTermChangeHandler
@api formUpdateCallback
@api required = false
@api searchAddressTerm = ''
@api fieldLevelHelp = 'If address not found, please expand and manually override the address'

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
        this.searchAddressTerm = placeholder;
    }
/* checks for form validity errors and sets the error class*/
get searchboxClass(){
    return this.inputError ? 'searchbox-err' : 'searchbox';
}
/* checks for form validity errors and sets the error class, like blank fields etc*/
get checkValidityClass(){
    let fieldInputClass = 'slds-m-right_x-small';
    if(this.inputFieldError)
   {
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
   else{
      return fieldInputClass;
       }

}

    search(event) {
        this.showAddressDetails=false
        this.inputError=false
        const showError = new CustomEvent("showError", {
            detail: this.inputError
          });
          // Fire the custom event to inform the parent component, that the field has an error
        this.dispatchEvent(showError);

        const searchAddressTerm = event.target.value
        this.searchAddressTerm = searchAddressTerm
        if (searchAddressTerm.length >= 2) {
            this.debouncedSearchHandler(searchAddressTerm);
        }
        const addressTyped = new CustomEvent("addressTyped", {
            detail: {searchAddressTerm}
          });
          // Fire the custom event to inform the parent component with the address typed
        this.dispatchEvent(addressTyped);
    }
    selectManually()
    {
        this.showAddressDetails=true
        this.required=true
        this.CheckBox=true;
        const addressOverride = new CustomEvent("addressOverride", {
            detail: {selected: this.CheckBox,}
          });
          // Fire the custom event to inform the parent component with the manually entered address
        this.dispatchEvent(addressOverride);
        if(this.CheckBox === true) {
            this.enterAddressDetails=false
        }
    }
    handleCheckBoxChange(event){
        

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
        //this.handleChange(this.address.addressLine1 + '|' + this.address.addressLine2 + '|' + this.address.city+ '|' + this.address.state + '|' + this.address.postcode);
        this.handleChange({"addressLine1":this.address.addressLine1,"addressLine2":this.address.addressLine2,"city":this.address.city,"state":this.address.state,"postcode":this.address.postcode})
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
            this.shouldShowDropDown = true
        }
    }

    closeSearchResultsList() {
        this.shouldShowDropDown = false
    }

    handleChange(searchterm) {
        const valueChangeEvent = new CustomEvent("valuechange", {
          detail: { searchterm }
        });
        // Fire the custom event to inform the parent with the change event
        this.dispatchEvent(valueChangeEvent);
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