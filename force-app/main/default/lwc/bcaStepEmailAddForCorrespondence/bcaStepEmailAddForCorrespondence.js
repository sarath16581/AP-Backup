/*
* @author avula.jansirani@auspost.com.au
* @date 05/02/2021
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Step in Credit Application Form to input Business Email address to contact
* @changelog
* 05/02/2021 avula.jansirani@auspost.com.au  Created
*
*/
import {LightningElement, api, track} from 'lwc';
import bcaStepBase from "c/bcaStepBase";
import {
    EMAIL_ADDRESS_VALUE_MISSING_VALIDATION_MESSAGE,
    EMAIL_ADDRESS_PATTERN_MISMATCH_VALIDATION_MESSAGE,
    FIELD_LENGTH_80, 
    formatPhone
} from 'c/bcaCommonMethods';

export default class BcaStepEmailAddForCorrespondence extends bcaStepBase {

    @track _emailForCorrespondence = {};
    //@api emailCorrespondenceVal;
    
    emailAddressValueMissingMsg = EMAIL_ADDRESS_VALUE_MISSING_VALIDATION_MESSAGE;
    emailAddressPatternMismatchMsg = EMAIL_ADDRESS_PATTERN_MISMATCH_VALIDATION_MESSAGE;
    emailFieldMaxLength = FIELD_LENGTH_80;

    @api get emailForCorrespondence(){
        this._emailForCorrespondence.email = this.template.querySelectorAll('[data-id="email"]')[0].value;//this.emailCorrespondenceVal;
        return this._emailForCorrespondence;
    }

    get displayValue() {
        if(this.creditAssessment && this.creditAssessment.businessContact) {
            return this.creditAssessment.businessContact.email;
        }
        return null;
    }

    handleChange = (event) => {
        const field = event.target.dataset.id;
        let newValue = event.detail.value;
        //this.emailCorrespondenceVal = newValue;
        this._emailForCorrespondence[field] = newValue;
        //--Checking the custom validation on change of a field value
        this.checkValidationOfField(field);
    }
 
     //validity method: to check all required fields validation
     @api checkAllValidity() {
        const inputComponents = this.template.querySelectorAll('lightning-input');
        return this.checkAllInputCmpValidity(inputComponents);
    }

    
}