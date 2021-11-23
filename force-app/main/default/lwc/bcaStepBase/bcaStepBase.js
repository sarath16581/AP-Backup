/*
* @author Victor.Cheng@auspost.com.au
* @date 2020-10-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Business Creidit Application Base Step Componet
* @changelog
* 2020-10-12 Victor.Cheng@auspost.com.au  Created
*
*/
import {track, api, LightningElement} from 'lwc';
import{checkCustomValidity, checkAllCmpValidity, reportAllCmpValidity, formatPhone} from 'c/bcaCommonMethods';

export const acceptedFileFormats = () => {
    return ['image/png', 'image/jpg', 'image/jpeg', '.pdf','.png','.jpg','.jpeg'];
}

export const pageIds = () => {
    return {
        abn: 'abn'
        , trust: 'trust'
        , businessAddress: 'businessAddress'
        , businessType: 'businessType'
        , directorDetails: 'directorDetails'
        , digitalId: 'digitalId'
        , notVerified: 'notVerified'
        , businessContact: 'businessContact'
        , businessPerson1: 'businessPerson1'
        , businessPerson2: 'businessPerson2'
        , businessPersonsList: 'businessPersonsList'
        , emailCorrespondence: 'emailCorrespondence'
        , creditAmount: 'creditAmount'
        , creditEnd: 'creditEnd'
        , directDebit: 'directDebit'
        , businessReference: 'businessReference'
        , businessReferenceList: 'businessReferenceList'
        , postalOutlets: 'postalOutlets'
        , review: 'review'
        , success: 'success'
    };
}

export const abnTypes = () => {
    return {
        COMPANY: 'company'
        , GOVERNMENT: 'government'
        , TRUST: 'trust'
        , TRUSTEE_PERSON: 'person'
        , TRUSTEE_COMPANY: 'company'
        , INDIVIDUAL: 'individual'
        , PARTNERSHIP: 'partnership'
        , OTHER_PARTNERSHIP: 'other partnership'
        , OTHER_INCORPORATED_ENTITY: 'other incorporated entity'
    }
}

export const creditLimits = () => {
    return {
        lower: 1000,
        upper: 50000
    }
}


export const getDirectorLabel = (entityTypeGroup, trustType) => {
   // let entityTypeGroup = abnDetails.EntityTypeGroup.toLowerCase();
    switch (entityTypeGroup.toLowerCase()) {
        case abnTypes().PARTNERSHIP:
            return 'Partner';
            break;
        case abnTypes().INDIVIDUAL:
            return 'Proprietor';
            break;
        case abnTypes().TRUST:
            switch (trustType.toLowerCase()) {
                case abnTypes().TRUSTEE_PERSON:
                    return 'Trustee';
                    break;
                case abnTypes().TRUSTEE_COMPANY:
                default:
                    return 'Director';
                    break;
            }
            break;
        case 'government':
            return 'N/A';
            break;
        default:
            return 'Director';

    }
}

//-- get 'No of Directors' label
/*export const getNOfDirectorsLabel = (entityTypeGroup) => {
    var labelText;
    switch (entityTypeGroup) {
        case abnTypes().COMPANY:
            labelText = 'No. of directors'; 
            break;
        case abnTypes().PARTNERSHIP:
            labelText = 'No. of partners';
            break;
        case abnTypes().TRUSTEE_COMPANY:
            labelText = 'No. of directors';
            break;
        default:
            labelText = 'No. of directors';
    }
    return labelText;
}*/

//-- is  'No of Directors' to disply or hide
export const isToDisplayNoOfDirectors = (entityTypeGroup, trustType) => {
    var isDisplay;
    switch (entityTypeGroup.toLowerCase()) {
        case abnTypes().INDIVIDUAL:
            isDisplay = false;
            break;
        case abnTypes().GOVERNMENT:
            isDisplay = false;
            break;
        case abnTypes().TRUST:
            switch (trustType.toLowerCase()) {
                case abnTypes().TRUSTEE_PERSON:
                    isDisplay = false;
                    break;
                default:
                    isDisplay = true;
                    break;
            }
            break;
        default:
            isDisplay = true;
    }
    return isDisplay;
}

export default class BcaStepBase extends LightningElement {
    // constants
    @api CONSTANTS = {
        DIRECTOR_PREFIX : 'director',
        SOMEONE_ELSE_VAL : '_someoneElse',
        MANUAL_ENTRY: '_manualEntry'
    };

    @track errorMessage = '';

    /*
    @api ABNTYPES = {
        COMPANY: 'company'
        , GOVERNMENT: 'government'
        , TRUST: 'trust'
        , TRUSTEE_PERSON: 'person'
        , TRUSTEE_COMPANY: 'company'
        , INDIVIDUAL: 'individual'
        , PARTNERSHIP: 'partnership'
        , OTHER_PARTNERSHIP: 'other partnership'
        , OTHER_INCORPORATED_ENTITY: 'other incorporated entity'
    }
     */
    @api ABNTYPES = abnTypes();
    ACCEPTED_FILE_FORMATS = acceptedFileFormats();

    @api abnStepIndex = '1';
    @api trustDetailsStepIndex = '2';
    @api businessAddressDetailStepIndex = '3';
    @api businessTypeDetailsStepIndex = '4';
    @api directorsStepIndex = '5';
    @api businessContactStepIndex = '6';
    @api emailForCorrespondenceStepIndex = '7';
    @api creditAmountStepIndex = '8';
    @api directDebitStepIndex = '9';
    @api referenceStepIndex = '10';
    @api creditAtPostOfficeStepIndex = '11';
    @api preferredPostalStepIndex = '12';

    // the record on load
    @api creditAssessment;

    @api validate(){
        return this.template.querySelector('lightning-input').reportValidity();
    }

    updateNavButtons(showBack, showNext)
    {
        this.dispatchEvent(new CustomEvent('navupdated', {
            bubbles: true,
            detail: {
                backButton: showBack
                , nextButton: showNext
            }
        }));
    }

    updateNavPrintButton(showPrint)                 // Jansi added this method without updating above(above is used in multiple places so ..)
    {
        this.dispatchEvent(new CustomEvent('navupdated', {
            bubbles: true,
            detail: {
                 printButton: showPrint
            }
        }));
    }

    jumpToStep(pageId)
    {
        this.dispatchEvent(new CustomEvent('stepjumped', {
            bubbles: true,
            detail: {
                pageId:pageId
            }
        }));
    }

    moveToNextStep()
    {
        this.dispatchEvent(new CustomEvent('nextstep', {
            bubbles: true,
            detail: {
            }
        }));
    }

    checkValidationOfField(datasetId) {
        const inputCmp = this.template.querySelectorAll('[data-id="' + datasetId + '"]');
        //--Checking the custom validation on change of a field value
        if (inputCmp != undefined && inputCmp.length > 0) {
            checkCustomValidity(inputCmp[0]);
        }
    }

    // focusout handler
    handleFocusOut(event) { 
        this.checkValidationOfField(event.target.dataset.id);
    }

    // focusout handler
    checkAllInputCmpValidity(inputComponents, isGenInputCmp = true) {
        return checkAllCmpValidity(inputComponents, isGenInputCmp);
    }

 
    formatPhoneNumber( newValue){
        return formatPhone(newValue);

    }



    outputLog = (sLog, lvl) => {
        if(!this.creditAssessment || this.creditAssessment.skipValidation){
            sLog = this.template.host.localName + '::' + sLog;
            switch (lvl){
                case 'log':
                    break;
                case 'error':
                    break
                case 'warn' :
                    break;
                default:
                    break;
            }

        }
    }
}