/**
 * History:
 * Created by vcheng on 14/08/2020.
 * Modified by hasantha.liyanage@auspost.com.au on 08/05/2023 DDS-15969 : BSP LOMI form error messages handling for individual fields
 */

import {LightningElement, track, api} from 'lwc';
import { checkAllValidity, reportAllValidity, checkCustomValidity, valueMissingErrorMsg } from 'c/bspCommonJS';

export default class BspAddressInput extends LightningElement {

    @api titleText = 'Address Details';
    @api addressTitle = 'Address';

    @track missingValueMessage = valueMissingErrorMsg;

    @api firstName;
    @api lastName;
    @api businessName;

    @api businessNameRequired;
    @api missingValueMessageFirstName = valueMissingErrorMsg;
    @api missingValueMessageLastName = valueMissingErrorMsg;
    @api missingValueMessageBusinessName = valueMissingErrorMsg;
    @api missingValueMessageAddressSelect = valueMissingErrorMsg;
    @track selectedSearchTerm = '';

    onChangeField(event) {
        const field = event.target.dataset.id;
        //console.log('changed:' + event.detail.value);
        switch(field)
        {
            case 'firstName':
                this.firstName = event.detail.value;
                break;
            case 'lastName':
                this.lastName = event.detail.value;
                break;
            case 'businessName':
                this.businessName = event.detail.value;
                break;
        }
    }

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

    @api
    get address() {
        let addressSearch = this.template.querySelector('c-bsp-address-search');
        return addressSearch.address;
    }
    set address(value)
    {
        //console.log('bspAddressInput set address');
        //console.debug(JSON.stringify(value));
        let addressSearch = this.template.querySelector('c-bsp-address-search');
        addressSearch.setAddress(value);
    }

    @api reportValidity() {
        console.log('in address input report validity');
        const inputComponents = this.template.querySelectorAll('lightning-input'); //".address-input"
        reportAllValidity(inputComponents);

        const addressComps = this.template.querySelectorAll('c-bsp-address-search');
        //console.log(inputComponents.length + ', ' + addressComps.length);
        reportAllValidity(addressComps);
    }

    handleFocusOut(event) {
        this.checkValidationOfField(event.target.dataset.id);
    }

    checkValidationOfField(datasetId) {
        const inputCmp = this.template.querySelectorAll('[data-id="' + datasetId + '"]');
        //--Checking the custom validation on change of a field value
        if (inputCmp != undefined && inputCmp.length > 0) {
            checkCustomValidity(inputCmp[0], inputCmp[0].messageWhenValueMissing);
        }
    }

    @api checkValidity() {
        console.log('in address input check validity');
        const inputComponents = this.template.querySelectorAll('lightning-input'); //".address-input"

        const addressComps = this.template.querySelectorAll('c-bsp-address-search');
        //return checkAllValidity(inputComponents);
        checkAllValidity(addressComps, false);
        return checkAllValidity(inputComponents) & checkAllValidity(addressComps, false);
        /*const inputsArray = inputComponents ? [...inputComponents] : [];
        return inputsArray.reduce((acc, inputCmp) => {
            inputCmp.reportValidity();
        return acc && inputCmp.checkValidity();
    }, true)*/
    }




}