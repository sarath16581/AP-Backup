/*
@author ankur.gandhi@auspost.com.au
* @date 2020-01-20
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Component used to search for an address. It has following features
*               1. Integrates with Google Place API, returns valid locations
* @changelog
* 2020-01-20 ankur.gandhi@auspost.com.au 
*/

import { LightningElement, track, api, wire } from 'lwc'
import { checkAllCmpValidity, reportAllCmpValidity, checkCustomValidity, DEFAULT_VALUE_MISSING_VALIDATION_MESSAGE } from 'c/bcaCommonMethods'; //To check with @Ankur to move validation methods to here as this is reusable cmp
import { debounce } from 'c/utils'
import searchAddress from '@salesforce/apex/GoolgeMapsAutocompleteController.getAutoComplete'
import getAddressDetails from '@salesforce/apex/GoolgeMapsAutocompleteController.getPlaceDetails'

export default class GoogleMapsPlaceSearch extends LightningElement {

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
    @api lat = ''
    @api long = ''
    requiredValMissingErrorMsg = DEFAULT_VALUE_MISSING_VALIDATION_MESSAGE;;
    
    connectedCallback() {
    }

    search(event) {
        this.address = {};//Jansi added 10-09-2020
        this.showAddressDetails = false
        this.inputError = false
        /*const showError = new CustomEvent("showError", {
            detail: this.inputError
        });

        // Fire the custom event to inform the parent component, that the field has an error
        this.dispatchEvent(showError);*/

        const searchAddressTerm = event.target.value
        this.searchAddressTerm = searchAddressTerm

        if (searchAddressTerm.length >= 2) {
            this.debouncedSearchHandler(searchAddressTerm);
        }
        
        /*const addressTyped = new CustomEvent("addressTyped", {
            detail: {
                searchAddressTerm
            }
        });
        // Fire the custom event to inform the parent component with the address typed
        this.dispatchEvent(addressTyped);*/
    }

    debouncedSearchHandler = debounce(this.handleSearch, 200);

    async handleSearch(searchAddressTerm) {
        this.openSearchResultsList();
        this.isLoading = true;
        try {
            const response = await searchAddress({
                input: searchAddressTerm,
                types: 'geocode',
                components: 'country:AU',
                languages: 'en-AU',
                radius:'10000'
            })

            const result = JSON.parse(response);
            let tempSearchResults = this.formatSearchRecordsForDisplay(result.predictions);
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

    defaultSearchResultTitleFormatter = record => record.description

    formatSearchRecordsForDisplay(records) {
        const titleMapper = this.defaultSearchResultTitleFormatter
        const subtitleMapper = this.defaultSearchResultSubtitleFormatter
        const titles = records.map(titleMapper)
        const subtitles = records.map(subtitleMapper)
        return records.map((record, index) => ({
            ...record,
            title: titles[index],
            subtitle: subtitles[index],
        }))
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

    async handleSearchResultSelect(event) {
        //Do call back to Google API to get the place details.
        const record = event.detail
        this.isSearchingAddressDetails = true

        try {
            const placeDetailResponse = await getAddressDetails({
                placeId: record.place_id
            })
            const placeDetails = JSON.parse(placeDetailResponse);
            let placeGeometry = placeDetails.result.geometry;
            this.lat = placeGeometry.location.lat;
            this.long = placeGeometry.location.lng;
            this.searchAddressTerm = placeDetails.result.formatted_address;

        } catch (error) {
        } finally {
            this.isSearchingAddressDetails = false
            this.closeSearchResultsList();
        }
    }
}