/*
* @author Victor.Cheng@auspost.com.au
* @date 21/12/2020
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Step in Credit Application Form to input postal outlet details
* @changelog
* 21/12/2020 Victor.Cheng@auspost.com.au  Created
*
*/

import {LightningElement, track, wire, api} from 'lwc';
import bcaStepBase from "c/bcaStepBase";

import searchNetworks from "@salesforce/apex/BCAFormController.searchNetworks";
import getAddressDetails from '@salesforce/apex/GoolgeMapsAutocompleteController.getPlaceDetails'
import searchAddress from '@salesforce/apex/GoolgeMapsAutocompleteController.getAutoComplete'

export default class BcaStepPostalOutlets extends bcaStepBase {


    WEEKDAY_NAMES = ["SUN", "MON", "TUES", "WED", "THURS", "FRI", "SAT"];

    MAX_SELECTION = 4;
    @track totalSelection = 0;

    // this is so that we only reload if there are changes
    @track _businessAddress;
    get businessAddress(){
        if(this.creditAssessment && this.creditAssessment.businessAddressDetails)
        {
            if(this.creditAssessment.businessAddressDetails.streetAddress
                && this._businessAddress !== this.creditAssessment.businessAddressDetails.streetAddress) {

                this._businessAddress = this.creditAssessment.businessAddressDetails.streetAddress;
                // get the component
                let cmp = this.template.querySelector("c-address-search-cmp");
            }
        }
        return this._businessAddress;
    };

    @track streetAddress;

    @track _postalOutlets = [];
    @api get postalOutlets() { return this._postalOutlets; }

    @track addressDetails = [];
    @track totalRecords = 0;
    @track showLoader = false;
    @track latitude;
    @track longitude;

    connectedCallback() {
        if(this.creditAssessment && this.creditAssessment.postalOutlets){
            this._postalOutlets = this.creditAssessment.postalOutlets;
        }
        else {
            this._postalOutlets = [];
        }
    }

    onDeleteOutlet = (event) => {
        let orgId;
        if(event.currentTarget.dataset.id){
            orgId = event.currentTarget.dataset.id;
        }
        else{
            orgId = event.target.dataset.id;
        }

        this.updateSelection(orgId, false);
    }

    /**
     * On checkbox of a postal outlet
     * @param event
     */
    onChangeOutlet = (event) => {
        const orgId = event.target.dataset.id;
        let newValue = event.target.checked;

        this.updateSelection(orgId, newValue);
    }

    updateSelection = (orgId, adding) => {
        // calculate what the result selection set is
        this.totalSelection = this._postalOutlets.length;
        if(adding)
            ++this.totalSelection;
        else if(adding === false)
            --this.totalSelection;

        let enabled = this.totalSelection < this.MAX_SELECTION;

        // update the checkboxes
        for(let i = 0; i < this.totalRecords; ++i){
            let outlet = this.addressDetails[i];

            if(outlet.orgId === orgId){
                outlet.selected = adding;
                if(adding){
                    // if we're adding, we need to push, if removing, loop below
                    this._postalOutlets.push(outlet)
                }
            }

            // update enabled
            outlet.disabled = !enabled && !outlet.selected;
        }

        // update the selection list if removing, since the checkboxes may not be the same list
        if(!adding){

            for(let i = 0; i < this._postalOutlets.length; ++i){
                let outlet = this._postalOutlets[i];
                if(outlet.orgId === orgId){
                    this._postalOutlets.splice(i, 1);
                }
            }
        }

        this.addressDetails = [...this.addressDetails];
    }

    get searchBtnClass () {
        let sClass = "slds-button slds-button_icon slds-button_icon-border search-aligned-input-button";

        if(this.addressDetails.length < 1){
            sClass += ' red-icon-button';
        }

        if(this.showLoader){
            sClass += ' red-icon-button loading-true';
        }

        return sClass;
    }

    get searchDisabled () {
        // TODO
        return false;
    }

    // update navigation status
    checkForSelection =     () => {
        if(this._postalOutlets.length == 0){
            this.updateNavButtons(true, false);
            return;
        }
        this.updateNavButtons(true, true);
    }

    get prepopulatedAddress() {
        if(this.creditAssessment?.businessAddressDetails?.streetAddressString){
            this.checkForSelection();
            return this.creditAssessment.businessAddressDetails.streetAddressString;
        }
        return null;
    }

    get prepopulatedLat () {
        if(this.creditAssessment?.businessAddressDetails?.streetAddress?.latitude){
            return this.creditAssessment.businessAddressDetails.streetAddress.latitude;
        }else if(this.latitude){
            return this.latitude;
        } 
        return null;
    }

    get prepopulatedLong () {
        if(this.creditAssessment?.businessAddressDetails?.streetAddress?.longitude){
            return this.creditAssessment.businessAddressDetails.streetAddress.longitude;
        }else if(this.longitude){
            return this.longitude;
        }
        return null;
    }

    async handleSearch(searchAddressTerm) {
        try {
            const response = await searchAddress({
                input: searchAddressTerm,
                types: 'geocode',
                components: 'country:AU',
                languages: 'en-AU',
                radius:'10000'
            })

            let places = JSON.parse(response);
            if(places && places.predictions && places.predictions.length > 0){
                const placeDetailResponse = await getAddressDetails({
                    placeId: places.predictions[0].place_id
                })
                const placeDetails = JSON.parse(placeDetailResponse);
                let placeGeometry = placeDetails.result.geometry;
                this.latitude = placeGeometry.location.lat;
                this.longitude = placeGeometry.location.lng;
            } 
        } catch (error) {
        } finally {
            this.isLoading = false
        }
    }

    searchOutlets = async (event) => {

        let searchCmp = this.template.querySelector('c-google-maps-place-search');
        this.showLoader = true;
        if(!searchCmp.lat || !searchCmp.long){
            await this.handleSearch(this.creditAssessment.businessAddressDetails.streetAddressString);
        }
        await searchNetworks({latitude:searchCmp.lat, longitude: searchCmp.long})
            .then(
                result => {

                    this.showLoader = false;
                    if(result && result.length > 0){
                        result.forEach(outlet => {

                            outlet.distance = Math.floor(outlet.distance * 100) / 100;

                            // format the address
                            outlet.addressFormatted = outlet.addressLine1 ? outlet.addressLine1.toLowerCase() : '';
                            if(outlet.addressLine1)
                                outlet.addressFormatted += outlet.addressLine2 ? ', ' + outlet.addressLine2.toLowerCase() : '';
                            else
                                outlet.addressFormatted = outlet.addressLine2 ? outlet.addressLine2.toLowerCase() : '';

                            outlet.addressFormatted += ', ' + outlet.suburb.toLowerCase();
                            outlet.addressFormatted += ', ' + outlet.state;
                            outlet.addressFormatted += ', ' + outlet.postcode;

                            // map link
                            outlet.mapLink = 'https://maps.google.com/?q=Australia Post - ' + outlet.name + ' ' + outlet.networkAddress;
                        })

                        this.addressDetails = [... result];
                        this.totalRecords = this.addressDetails.length;

                        // do another check for maximum
                        this.updateSelection(null, null);
                    }
                    else{

                        this.showAddress =  false;
                        this.searchingFlag = false;
                        this.noResultFound = true;
                        this.noResultMsg = 'No Post Offices found near your location.';
                    }
                }
            )
            .catch(error => {
                this.showLoader = false;
            }
        );
    }

    onClickSearch =async (event) => {
        
        let networks = await searchNetworks({postcode:this.postcode, streetName:this.streetName})
            .then(result=>{
                if(result == null){
                    return;
                }
            })
            .catch(error => {
            });
    }


    @api checkAllValidity() {
        return this._postalOutlets.length > 0;
    }

}