/*
* @author avula.jansirani@auspost.com.au
* @date 2020-01-20
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Business address details step to input the business street and postal address. 
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au created
*
*/
import { LightningElement, track, api } from 'lwc';
import bcaStepBase from "c/bcaStepBase";

export default class BcaStepBusinessAddressDetails extends bcaStepBase {

    @track _businessAddressStepDetails = {
        isBusNStreetAddressSame: 'yes'
    };
    @api get businessAddressStepDetails()
    {
        return this._businessAddressStepDetails;
    }

    @track streetAddress = {
        line1: '',
        line2: '',
        city: '',
        state: '',
        postcode: '',
        dpid: '',
        country: '',
        countryName: ''
    };

    @track postalAddress = {
        line1: '',
        line2: '',
        city: '',
        state: '',
        postcode: '',
        dpid: '',
        country: '',
        countryName: ''
    };

    @track isBusNStreetAddressSame;

    get options() {
        return [
            { label: 'Yes', value: 'yes' },
            { label: 'No', value: 'no' },
        ];
    }


    get isDisplayPostalAddress() {
        return this.isBusNStreetAddressSame && this.isBusNStreetAddressSame == 'no' ? true : false;
    }

    //change handler
    handleChange(event) {
        var inputElement = event.target.dataset.id;
        if (inputElement == 'PS') {
            this.isBusNStreetAddressSame = event.target.value;
            this.businessAddressStepDetails.isBusNStreetAddressSame = event.target.value;
        }
        //--Checking the custom validation on change of a field value
        this.checkValidationOfField(inputElement);
    }


    //address change event handler
    handleAddressChange(event) {
        if (event.target.dataset.id == 'streetAddress') {
            this.streetAddress = event.detail.address;
            this.businessAddressStepDetails.streetAddress = event.detail.address;
            this.businessAddressStepDetails.streetAddressString = event.detail.addressString;
        }
        else {
            this.postalAddress = event.detail.address;
            this.businessAddressStepDetails.postalAddress = event.detail.address;
            this.businessAddressStepDetails.postalAddressString = event.detail.addressString;
        }
    }


    //validation method
    @api checkAllValidity() {
        const inputComponents = this.template.querySelectorAll('lightning-radio-group');
        var allValid = this.checkAllInputCmpValidity(inputComponents) &
            this.checkAllInputCmpValidity(this.template.querySelectorAll('[data-id="streetAddress"]'), false);
        if (this.isDisplayPostalAddress)
            allValid = allValid & this.checkAllInputCmpValidity(this.template.querySelectorAll('[data-id="postalAddress"]'), false);
        return allValid;
    }

}