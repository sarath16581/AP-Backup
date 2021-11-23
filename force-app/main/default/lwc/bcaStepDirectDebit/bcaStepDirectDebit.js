/*
* @author Victor.Cheng@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Step in Credit Application Form to input Business Direct Debit details
* @changelog
* 19/01/2021 Victor.Cheng@auspost.com.au  Created
*
*/
import { LightningElement, wire, api, track } from 'lwc';
import getDirectTC from '@salesforce/apex/BCAFormBase.getDirectTC';
import getDirectDebitTCDownloadURL from '@salesforce/apex/BCAFormBase.getDirectDebitTCDownloadURL';
import validateBSB from '@salesforce/apex/BCAFormBase.validateBSB';

import bcaStepBase from "c/bcaStepBase";
import {
    isNumericInput, isModifierKey
    , BSB_INPUT_ID, BSB_LENGTH, ACCOUNT_NUMBER_INPUT_ID, ACCOUNT_NUMBER_MIN_LENGTH, ACCOUNT_NUMBER_MAX_LENGTH
} from 'c/bcaCommonMethods'

export default class BcaStepDirectDebit extends bcaStepBase {

    bsbInputId = BSB_INPUT_ID;
    bsbLength = BSB_LENGTH + 1;
    accountInputId = ACCOUNT_NUMBER_INPUT_ID;
    accountMinLen = ACCOUNT_NUMBER_MIN_LENGTH;
    accountMaxLen = ACCOUNT_NUMBER_MAX_LENGTH;
    BSB_INVALID_MESSAGE = 'Enter a valid BSB number';


    @track _directDebit = {bsb:''};
    @api get directDebit() {return this._directDebit;}

    // this needs to be true before we continue
    @track bsbValid = false;

    @track errorWhenNotAccepted = 'You must confirm you are authorised to operate on the nominated account in order to proceed';
    @track errorWhenNotAcceptedLabel2 = 'You must agree to the direct debit request service agreement terms and conditions in order to proceed';

    termsAndConditions;
    directDebitTCDownloadURL = '';

    @wire(getDirectTC)
    wiredDirectTC({ error, data }) {
        if (data) {
            // this.header = data.Header__c;
            this.termsAndConditions = data.Message__c;
        }
    }

    @wire(getDirectDebitTCDownloadURL)
    wiredDirectDebitTCURL({ error, data }) {
        if (data) {
            // this.header = data.Header__c;
            this.directDebitTCDownloadURL = data;
        }
    }

    connectedCallback() {
        if(this.creditAssessment && this.creditAssessment.directDebit)
        {
            this._directDebit = this.creditAssessment.directDebit;
        }
    }

    get applicantOptions() {
        let directorOptions = [];
        if(this.creditAssessment.directors)
        {
             directorOptions = Array.prototype.map.call(this.creditAssessment.directors, (director, index) => {
                let directorName = director.firstName + (director.middleName ? ' ' + director.middleName : '') + ' ' + director.lastName;
                let directorOption = {
                    label: directorName + ' (director)',
                    // forcing it to be a string, lwc radio bug
                    value: this.CONSTANTS.DIRECTOR_PREFIX +  director.index
                };
                return directorOption;
            });
        }

        if(this.creditAssessment.businessContact && this.CONSTANTS.SOMEONE_ELSE_VAL == this.creditAssessment.businessContact.index)
        {
            let contact = this.creditAssessment.businessContact;
            directorOptions.push({
                label: contact.firstName + (contact.lastName ? ' ' + contact.lastName : '') + ' (' + contact.positionTitle + ')',
                value: contact.index
            })
        }

        return directorOptions;
    }


    onChangeField = (event) => {
        const field = event.target.dataset.id;
        let newValue = event.detail.value;

        switch (field) {
            case this.bsbInputId:
                this.checkBSB(event.target.value);
                event.target.value = this.formatBSB(newValue);
                this._directDebit[field] = this.formatBSB(newValue);
                break;
            case this.accountInputId:
                let sTrimmed = newValue.replace(/\D/g,'');
                event.target.value = sTrimmed.substring(0, this.accountMaxLen);
                this._directDebit[field] = event.target.value;
                break;
            default:
                this._directDebit[field] = newValue;
                break;
        }
    }

    formatBSB = (inputRaw) => {
        let sFormat = inputRaw.replace(/\D/g,'');
        if(sFormat.length > 3)
        {
            let sHead = sFormat.substring(0, 3);
            let sTail = sFormat.substring(3, this.bsbLength - 1);
            sFormat = sHead + '-' + sTail;
        }
        return sFormat;
    }

    checkBSB = (bsbInput) => {
        // set to false, to re-validate
        this.bsbValid = false;

        const bsbTrimmed = bsbInput.replace(/\D/g,'');

        if(bsbTrimmed.length != BSB_LENGTH){
            // bsb incorrect length, don't check
            return;
        }

        validateBSB({bsb: bsbTrimmed})
            .then(result => {
                //console.log('validate bsb:' + bsbTrimmed + ', result = ' + JSON.stringify(result));
                if(result){
                    this.bsbValid = true;
                }
                this.bsbReportValidity();
            })
            .catch(error => {
            });

        return this.bsbValid;
    }

    bsbReportValidity = () => {
        const bsbInput = this.template.querySelector('[data-id="'+ this.bsbInputId + '"]');
        if(!this.bsbValid){
            bsbInput.setCustomValidity(this.BSB_INVALID_MESSAGE);
        }
        else{
            bsbInput.setCustomValidity('');
        }

        //console.log('bsb on blur:' + this.bsbValid);
        bsbInput.reportValidity();
    }

    enforceFormat = (event) => {
        // Input must be of a valid number format or a modifier key
        if (!isNumericInput(event) && !isModifierKey(event)) {
            event.preventDefault();
        }
    };


    get TC() {
        return this.termsAndConditions ? this.termsAndConditions : '';
    }


    @api checkAllValidity() {
        //console.log('bsb valid:' + this.bsbValid);
        // update the message separately for BSB
        this.bsbReportValidity();

        return this.checkAllInputCmpValidity(this.template.querySelectorAll('lightning-input:not([data-id="'+ this.bsbInputId + '"])')) &&
        this.checkAllInputCmpValidity(this.template.querySelectorAll('[data-id="reviewTC"]'), false)
            && this.bsbValid;
    }

}