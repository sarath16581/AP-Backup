/*
* @author Victor.Cheng@auspost.com.au
* @date 2021-01-19
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Step in Credit Application Form to input Business Contact details
* @changelog
* 2021-01-19 Victor.Cheng@auspost.com.au  Created
* 2021-02-26 avula.jansirani@auspost.com.au  updated
*
*/

import { LightningElement, wire, api, track } from 'lwc';
import {  abnTypes } from 'c/bcaStepBase';
import {
    reportAllCmpValidity,
    EMAIL_ADDRESS_VALUE_MISSING_VALIDATION_MESSAGE,
    EMAIL_ADDRESS_PATTERN_MISMATCH_VALIDATION_MESSAGE,
    FIELD_LENGTH_30,//,EMAIL_REG_EXP_PATTERN
    FIELD_LENGTH_80,
    FIELD_LENGTH_40,
    //FIELD_LENGTH_10
} from 'c/bcaCommonMethods';

import bcaStepBase from "c/bcaStepBase";

export default class BcaStepBusinessContact extends bcaStepBase {

    @api label = 'Who is the business contact person?';


    @api contactPersonOptions;
    @api selectedContact;
    //@api director ;
    @api directors = [] ;
    @api showAuthorizedBannerText = false;
    @api radioButtonId='contactPerson';   // [Jansi]The same Id of radio button giving an issue in reusable of this cmp, so created a api variable to pass diff Id
    
    emailAddressValueMissingMsg = EMAIL_ADDRESS_VALUE_MISSING_VALIDATION_MESSAGE;
    emailAddressPatternMismatchMsg = EMAIL_ADDRESS_PATTERN_MISMATCH_VALIDATION_MESSAGE;
    emailFieldMaxLength = FIELD_LENGTH_80;
    fullNameFieldLength = FIELD_LENGTH_80;
    lastNameFieldLength = FIELD_LENGTH_40;
    positionTitleFieldLength = FIELD_LENGTH_30;
    //emailRegEx = EMAIL_REG_EXP_PATTERN;
    
    @track someoneElse = false;
    @track contactSomeoneElse = { index: '_someoneElse' };
    @track _businessContact = {};
    phoneMaxLength = 10;

    @api get businessContact() {
        if (this.selectedContact == '_someoneElse')
            return this.contactSomeoneElse;
        else{
            //this._businessContact = this.director;
            for(let i = 0; i < this.directors.length; ++i) {
                if(this.directors[i].index.toString() == this.selectedContact) {
                    this._businessContact = this.directors[i];
                    break;
                }
            }
            return this._businessContact;
        }
            
    }

    get showContactOptions(){
        return this.contactPersonOptions ? true : false;
    }

    get showSomeOneElseForm() {
        if (this.selectedContact && this.selectedContact == '_someoneElse')
            return true;
        else return false;
    }

    onSelectContactPerson = (event) => {
        const field = event.target.dataset.id;
        let newValue = event.detail.value;

        if (newValue === '_someoneElse') {
            this.selectedContact = '_someoneElse';
        }
        else {
            for(let i = 0; i < this.directors.length; ++i) {
                if(this.directors[i].index.toString() == newValue) {
                    this._businessContact = this.directors[i];
                    this.selectedContact = newValue;
                    break;
                }
            }
           /* if (this.director) {
                //this._businessContact = this.director;
                this.selectedContact =  'director'; //this.director.firstName + (this.director.middleName ? this.director.middleName : '') + this.director.lastName;
            }*/

        }
    }

    onChangeField = (event) => {
        const field = event.target.dataset.id;
        let newValue = event.target.value;

        switch (field) {
            case 'phone':
                this.updatePhoneMaxLength(newValue);
                let phoneFormatted = this.formatPhoneNumber( newValue);
                // display formatted
                event.target.value = phoneFormatted;
                this.contactSomeoneElse.phoneFormatted = phoneFormatted;
                // store the stripped version
                this.contactSomeoneElse[field] = newValue.replace(/\D/g, '');
                //this.checkValidationOfField(field);
                break;
            default:
                //--Checking the custom validation on change of a field value
                //this.checkValidationOfField(field);
                this.contactSomeoneElse[field] = newValue;
                break;

        }
    }

    updatePhoneMaxLength(inputRaw) {
        const inputMobile = inputRaw.replace(/\D/g, '').substring(0, 2); // First two digits to find mobile or landline
        if (inputMobile === '04')
            this.phoneMaxLength = 12;
        else
            this.phoneMaxLength = 14;
    }

    get showBanner() {
        return this.showAuthorizedBannerText && this.selectedContact &&
            (this.selectedContact == '_someoneElse' || this.selectedContact == 'businessContact');
    }

    //validation method
    @api checkValidity () {
        const inputComponents = this.template.querySelectorAll('lightning-radio-group,lightning-input');
        return this.checkAllInputCmpValidity(inputComponents);

    }

    @api reportValidity() {
        const inputComponents = this.template.querySelectorAll('lightning-input, lightning-radio-group');
        reportAllCmpValidity(inputComponents);
    }

}