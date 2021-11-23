/*
* @author Victor.Cheng@auspost.com.au
* @date 21/12/2020
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Step in Credit Application Form to input Reference details
* @changelog
* 21/12/2020 Victor.Cheng@auspost.com.au  Created
*
*/

import {LightningElement, track, wire, api} from 'lwc';
import bcaStepBase from "c/bcaStepBase";
import {
    FIELD_LENGTH_30,//,EMAIL_REG_EXP_PATTERN
    FIELD_LENGTH_10,
    FIELD_LENGTH_100
} from 'c/bcaCommonMethods';


export default class bcaStepReference extends bcaStepBase {

    @api personIndex;
    fieldLength30 = FIELD_LENGTH_30;
    fieldLength10 = FIELD_LENGTH_10;
    fieldLength100 = FIELD_LENGTH_100;

    @track _businessReference = {};
    @api get businessReference() {
        this._businessReference.index = this.personIndex;
        return this._businessReference;
    }

    onChangeField = (event) => {
        const field = event.target.dataset.id;
        let newValue = event.detail.value;
        switch (field) {
            case this.PHONE_FIELD:
                this.updatePhoneMaxLength(newValue);
                let phoneFormatted = this.formatPhoneNumber( newValue);
                // display formatted
                event.target.value = phoneFormatted;
                // store the stripped version
                newValue = newValue.replace(/\D/g, '');
                //this.checkValidationOfField(field);
            default:
                this._businessReference[field] = newValue;
                break;
        }
    }

    // focusout handler
    handleFocusOut(event) {
        const field = event.target.dataset.id;
        this.checkValidationOfField(field);
    }


    PHONE_FIELD = 'phone';
    @track phoneMaxLength = 10;
    updatePhoneMaxLength(inputRaw) {
        const inputMobile = inputRaw.replace(/\D/g, '').substring(0, 2); // First two digits to find mobile or landline
        if (inputMobile === '04')
            this.phoneMaxLength = 12;
        else
            this.phoneMaxLength = 14;
    }

    @api checkAllValidity() {
        const inputComponents = this.template.querySelectorAll('lightning-input');
        let valid = this.checkAllInputCmpValidity(inputComponents);
        return valid;
    }

}