/*
@author avula.jansirani@auspost.com.au
* @date 2020-01-20
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Component used to search for an address. It has following features
  *                 1. Integrates with AME service, returns a valid address if found
  *                 2. User can enter address manually, if address not found
                  
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au  Updated 'ameAddressValidation1' cmp  
*/

import { LightningElement, track, api, wire } from 'lwc'
import { checkAllCmpValidity, reportAllCmpValidity, checkCustomValidity, DEFAULT_VALUE_MISSING_VALIDATION_MESSAGE } from 'c/bcaCommonMethods'; //To check with @Ankur to move validation methods to here as this is reusable cmp
import { debounce } from 'c/utils'
import searchAddress from '@salesforce/apex/AMEAddressValidationController1.searchAddress'
import getAddressDetails from '@salesforce/apex/AMEAddressValidationController1.getAddressDetails'
import getCountries from '@salesforce/apex/AMEAddressValidationController1.getCountries'

export default class AddressSearchCmp extends LightningElement {
    @api inputError = false
    @api inputFieldError = false
    @api errorMessage = ''
    @api placeholder = ''
    @api label = 'Delivery address'
    @api addressChangeHandler
    @api addressSearchTermChangeHandler
    @api formUpdateCallback
    @api required = false
    @api searchAddressTerm = ''
    @api fieldLevelHelp = ''
    @api address = {}
    @api addressOnLoad;
    @api showCountryInManualEnrtryForLocalAddress = 'yes';
    @api disableCountryInManualEnrtryForLocalAddress = 'yes';
    @api optionalLabelClass ='optional-label';   // passs empty  (or) pass the specific css class name
    
    @track showAddressDetails = false
    @track selectedRecord
    @track isLoading = false
    @track isSearchingAddressDetails = false
    @track searchResults = []
    @track shouldShowDropDown = false
    @track enterAddressDetails = true
    requiredValMissingErrorMsg = DEFAULT_VALUE_MISSING_VALIDATION_MESSAGE;;
    @track countries;
    @track defaultStates = {};//[
       // { label: 'Other', value: 'Other' }
   // ];

    @track defaultCountry = [
        { label: 'Australia', value: 'Australia' }
    ];

    //--The below flag indicate to show country drop down values for internation address in manual entry
    @api isAllowInternationalAddress='no';

    get countryValues() {
        return this.isAllowInternationalAddress != 'yes' ? this.defaultCountry : this.countries ;
    }

    connectedCallback() {
        if (this.addressOnLoad) {
            this.setAddress(this.address);
        }
        if (this.isAllowInternationalAddress != 'yes') {
            this.countries = this.defaultCountry;
            const keyName = 'countryName';
            this.address = {
                ...this.address,
                [keyName]: 'Australia'
            }
            this.setStateOptions('Australia');
        }
    }

    @api setAddress(address) {
        this.address = {
            ...address
        }
        
        // this should only happen if the parent comp has already got the data and don't need to search
        this.searchAddressTerm = this.mergeAddressFields(this.address).trim();

    }

    @api setAddressSearchTerm(searchAddressTerm) {
        this.searchAddressTerm = searchAddressTerm
    }

     /**
     * get countries
      */
    @wire(getCountries) getCountries({ error, data }) {
        if (data)
            this.countries = data;
    }


    /* checks for form validity errors and sets the error class*/
    get searchboxClass() {
        return this.inputError ? 'searchbox-err' : 'searchbox';
    }
    /* checks for form validity errors and sets the error class, like blank fields etc*/
    get checkValidityClass() {
        let fieldInputClass = '';
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
        } else {
            return fieldInputClass;
        }

    }

    search(event) {
        //this.checkValidationOfField(event.target.dataset.id);
        this.address = {};//Jansi added 10-09-2020
        //this.isAddressTyped = true;
        this.showAddressDetails = false
        this.inputError = false
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
            detail: {
                "searchAddressTerm":searchAddressTerm
            }
        });
        // Fire the custom event to inform the parent component with the address typed
        this.dispatchEvent(addressTyped);
    }

    selectManually(event) {
        this.address = {};//Jansi added 10-09-2020

        if (this.isAllowInternationalAddress !='yes'){ //Jansi added 11-02-2021
            this.address = {'countryName':'Australia'};
        }
        
        this.required = true
        this.CheckBox = true;
        const addressOverride = new CustomEvent("addressOverride", {
            detail: {
                selected: this.CheckBox,
            }
        });
        // Fire the custom event to inform the parent component with the manually entered address
        this.dispatchEvent(addressOverride);
        if (this.CheckBox === true) {
            this.enterAddressDetails = false
        }
        event.preventDefault();
        this.showAddressDetails = true;
        this.closeSearchResultsList();
    }


    handleCheckBoxChange(event) {}

    handleSwitchBack(event){
        this.showAddressDetails = false;
        this.searchAddressTerm = '';
    }

    async handleSearchResultSelect(event) {
        const record = event.detail
        this.isSearchingAddressDetails = true

        try {
            const addressResponse = await getAddressDetails({
                address: record.dpid
            })
            const parsedAddress = JSON.parse(addressResponse)

            const formattedAddress = this.formatParsedAddress(parsedAddress)
            this.address = formattedAddress;
            this.address.countryName = formattedAddress.countryName;  //Added 09.11.2020
           // this.address.addressLine = formattedAddress.addressLine1;
            //this.address.addressLine3 = formattedAddress.addressLine2;
            this.address.line1 = formattedAddress.addressLine1;
            this.address.line2 = formattedAddress.addressLine2;
            this.address.city = formattedAddress.locality;
            this.address.state = formattedAddress.state;
            this.address.postcode = formattedAddress.postcode;
            this.address.latitude = formattedAddress.latitude;
            this.address.longitude = formattedAddress.longitude;
            this.address.dpid = formattedAddress.delpointId;
            if (this.showCountryInManualEnrtryForLocalAddress == 'no' && this.isAllowInternationalAddress != 'yes')
                this.searchAddressTerm = formattedAddress.address;
            else
                this.searchAddressTerm = formattedAddress.address + ' ' + formattedAddress.countryName;

            //Added 'formattedAddress.countryName' 09.11.2020
           // const selectedEvent = new CustomEvent("searchtermchange", {
            const manualChangeEvent = new CustomEvent("addresschange", {
                detail: {
                    address: this.address,
                    addressString: this.mergeAddressFields(this.address),
                }

            });
            this.dispatchEvent(selectedEvent);
            this.fireChangeHandlers()
        } catch (error) {
        } finally {
            this.isSearchingAddressDetails = false
            this.closeSearchResultsList();
            this.handleSearchBoxFocusOut(event);
        }
    }

    formatParsedAddress([parsedAddress]) {
        const address = parsedAddress.singleLine;
        const addressDetails = parsedAddress.semiStructured;
        const [geoData] = parsedAddress.geoDataList;
        const addressLine1 = parsedAddress.semiStructured.addressLines[0];
        const addressLine2 = parsedAddress.semiStructured.addressLines[1];
        const delpointId = parsedAddress.dpid;
        return {
            address,
            delpointId,
            ...addressDetails,
            ...geoData,
            addressLine1,
            addressLine2,
        }

    }

    focusOnSearchInput() {
        const searchInput = this.template.querySelectorAll('[data-id="searchbox"]');
        //const searchInput = this.template.querySelector('input')
        if (searchInput) {
            searchInput.focus()
        }
    }

    debouncedSearchHandler = debounce(this.handleSearch, 200)

    async handleSearch(searchAddressTerm) {
        this.openSearchResultsList();
        this.isLoading = true;
        try {
            const response = await searchAddress({
                searchTerm: searchAddressTerm
            })
            const result = JSON.parse(response);
            let tempSearchResults = this.formatSearchRecordsForDisplay(result);
            this.searchResults = tempSearchResults.slice(0,5);
        } catch (error) {
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
        const titleMapper = typeof this.searchResultTitleFormatter === 'function' ?
            this.searchResultTitleFormatter : this.defaultSearchResultTitleFormatter
        const subtitleMapper = typeof this.searchResultSubtitleFormatter === 'function' ?
            this.searchResultSubtitleFormatter : this.defaultSearchResultSubtitleFormatter
        const titles = records.map(titleMapper)
        const subtitles = records.map(subtitleMapper)
        return records.map((record, index) => ({
            ...record,
            title: titles[index],
            subtitle: subtitles[index],
        }))
    }
    
    handleAddressChange(event) {
        const target = event.target;
        const value = target.type === "checkbox" ? target.checked : target.value;
        const key = target.name;
        this.address = {
            ...this.address,
            [key]: value
        }
        if (event.target.dataset.id == 'countryName') {
             this.setStateOptions(value);
         }
        this.searchAddressTerm = this.mergeAddressFields(this.address);
        this.fireChangeHandlers()
        this.handleSearchBoxFocusOut();
    }

    setStateOptions(value){
        const key1 = 'state';
        if (value.toLowerCase() == 'australia') {
            this.defaultStates = [
                { label: 'Select...', value: '' },
                { label: 'ACT', value: 'ACT' },
                { label: 'NSW', value: 'NSW' },
                { label: 'NT', value: 'NT' },
                { label: 'QLD', value: 'QLD' },
                { label: 'SA', value: 'SA' },
                { label: 'TAS', value: 'TAS' },
                { label: 'VIC', value: 'VIC' },
                { label: 'WA', value: 'WA' },
            ];
            this.address = {
               ...this.address,
               [key1]: ''
           }
        } else {
            this.defaultStates = [
                { label: 'Other', value: 'Other' }
            ];
            this.address = {
               ...this.address,
               [key1]: 'Other'
           }
        }
    }

    fireChangeHandlers() {
        if (typeof this.addressChangeHandler === 'function') {
            this.addressChangeHandler({
                ...this.address
            })
        }
        if (typeof this.addressSearchTermChangeHandler === 'function') {
            this.addressSearchTermChangeHandler(this.searchAddressTerm)
        }
    }


    mergeAddressFields(address) {
        // Creates the event with the data.
        const streetDetails = this.address;
        let addressString;

        if (this.showCountryInManualEnrtryForLocalAddress == 'no' && this.isAllowInternationalAddress != 'yes'){
            addressString = `${address.line1 ? `${address.line1},` : ''} ${address.line2 ? ` ${address.line2},` : ''} ${address.city || ''} ${address.state || ''} ${address.postcode || ''} ` //updated 'countrycode' with 'countryName'  09.11.2020
        }else{
            addressString = `${address.line1 ? `${address.line1},` : ''} ${address.line2 ? ` ${address.line2},` : ''} ${address.city || ''} ${address.state || ''} ${address.postcode || ''} ${address.countryName || ''}` //updated 'countrycode' with 'countryName'  09.11.2020
        }
        
        // adding 'country code' 18-05-2021
        if( this.isAllowInternationalAddress != 'yes' && !this.address.countryCode){
            this.address.countryCode = 'AU';
        }


        const manualChangeEvent = new CustomEvent("addresschange", {
            detail: {
                address: this.address,
                addressString: addressString,
            }
        });
        // Dispatches the event.
        this.dispatchEvent(manualChangeEvent);

        return addressString;
        
    }

    openSearchResultsList() {
        this.inputError = false;
        if (this.searchResults.length > 0 || this.isLoading) {
            this.shouldShowDropDown = true
        }
    }

    closeSearchResultsList() {
        this.shouldShowDropDown = false
    }

    @api reportValidity() {
        const inputComponents = this.template.querySelectorAll('lightning-input, lightning-combobox'); //".address-input"
        reportAllCmpValidity(inputComponents);
        this.validateTheAddress();
    }

    @api checkValidity() {
        const inputComponents = this.template.querySelectorAll('lightning-input, lightning-combobox'); //".address-input"
       // const inputCmp = this.template.querySelectorAll('[data-id="state"]');
        //var x = checkCustomValidity(inputComponents[0]);
        return checkAllCmpValidity(inputComponents) && this.validateTheAddress() ;
    }

    handleSearchBoxFocusOut(event) {
        const inputCmp = this.template.querySelectorAll('[data-id="searchbox"]');
        if (inputCmp != undefined && inputCmp.length > 0) {
            checkCustomValidity(inputCmp[0]);
        }
    }

    handleFocusOut(event) {
        this.checkValidationOfField(event.target.dataset.id);
    }

    checkValidationOfField(datasetId) {
        const inputCmp = this.template.querySelectorAll('[data-id="' + datasetId + '"]');
        //--Checking the custom validation on change of a field value
        if (inputCmp != undefined && inputCmp.length > 0) {
            checkCustomValidity(inputCmp[0]);
        }
    }
    @api validateTheAddress(){
        var isValid = true;
        
        if ((Object.keys(this.address).length === 0 && this.address.constructor === Object) ||
            (this.address.countryName && this.address.countryName.toLowerCase() == 'australia' && !this.address.state)) {   //-- assume state should not be empty for both manual and selecetd address  
            this.searchAddressTerm =null;
            this.template.querySelectorAll('[data-id="searchbox"]')[0].setCustomValidity('Address not found. Try editing or select "Enter address manually instead" from the list');
            this.template.querySelectorAll('[data-id="searchbox"]')[0].reportValidity();
            isValid = false;
        }
        /*if(this.isAddressTyped){   //--if user tried any address change
            if(!this.address.state){   //-- assume this should not be empty for both manual and selecetd address  
                this.searchAddressTerm =null;
                this.template.querySelectorAll('[data-id="searchbox"]')[0].setCustomValidity('Address not found. Try editing or select "Enter address manually instead" from the list');
                this.template.querySelectorAll('[data-id="searchbox"]')[0].reportValidity();
                isValid = false;
            }*/

           /* if(this.showAddressDetails && !this.address.state){
               this.template.querySelectorAll('[data-id="searchbox"]')[0].reportValidity();
                isValid = false;
            }
            else if(!this.address.dpid){
                this.searchAddressTerm =null;
                this.template.querySelectorAll('[data-id="searchbox"]')[0].setCustomValidity('xxx');
                this.template.querySelectorAll('[data-id="searchbox"]')[0].reportValidity();
                isValid = false;
            }*/
        //}
        return isValid;
    }

    get stateVal(){
        return this.address.state ? this.address.state != 'Other'? this.address.state : 'Other' : '';
    }

    get countryName(){
        if (this.isAllowInternationalAddress !='yes') {
            return 'Australia';    
        }
        else return this.address.countryName ? this.address.countryName != 'Australia'? this.address.countryName : 'Australia' : '';
    }

    get defaultStatesList(){
        return this.defaultStates ? this.defaultStates : {};
    }


    get showState(){
        if (this.isAllowInternationalAddress !='yes') {
            return true;    
        }
        else return  this.address.countryName ? true : false;
    }

    get showCountry() {
        if (this.showCountryInManualEnrtryForLocalAddress == 'no' && this.isAllowInternationalAddress != 'yes')
            return false;
        else
            return true;
    }

    get isDisableCountry() {
        if (this.showCountryInManualEnrtryForLocalAddress == 'yes' && this.isAllowInternationalAddress != 'yes' && this.disableCountryInManualEnrtryForLocalAddress == 'yes')
            return true;
        else return false;
    }

    preventDeletion(event) {
        const key = event.keyCode;
        if (key === 8 || key === 46) { //preventing backspace and delete keys
            event.preventDefault();
        }
    }
}