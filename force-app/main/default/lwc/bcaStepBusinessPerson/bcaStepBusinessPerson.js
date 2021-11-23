/*
* @author Victor.Cheng@auspost.com.au
* @date 2021-02-05
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Step in Credit Application Form to input Business Person details(Directors/Partners)
* @changelog
* 2021-02-05 Victor.Cheng@auspost.com.au  Created
*
*/

import {LightningElement, track, wire, api} from 'lwc';
import bcaStepBase from "c/bcaStepBase";
import {
    EMAIL_ADDRESS_VALUE_MISSING_VALIDATION_MESSAGE,
    EMAIL_ADDRESS_PATTERN_MISMATCH_VALIDATION_MESSAGE,
    FIELD_LENGTH_30,//,EMAIL_REG_EXP_PATTERN
    FIELD_LENGTH_32,
    FIELD_LENGTH_48,
    FIELD_LENGTH_80
} from 'c/bcaCommonMethods';


export default class BcaStepBusinessPerson extends bcaStepBase {

    @api personIndex;

    emailAddressValueMissingMsg = EMAIL_ADDRESS_VALUE_MISSING_VALIDATION_MESSAGE;
    emailAddressPatternMismatchMsg = EMAIL_ADDRESS_PATTERN_MISMATCH_VALIDATION_MESSAGE;
    emailFieldMaxLength = FIELD_LENGTH_80;
    firstNameMaxLength = FIELD_LENGTH_32;
    middleNameMaxLength = FIELD_LENGTH_32;
    lastNameMaxLength = FIELD_LENGTH_48;
    fullNameMaxLength = FIELD_LENGTH_80;
    //emailRegEx = EMAIL_REG_EXP_PATTERN;

    driverLicensePatternMismatchMsg = 'Enter a valid driver’s licence';
    driverLicenseMissingMsg = 'Enter a driver’s licence';

    // options
    yesNoOptions = [
        {label:'No', value:'false'},
        {label:'Yes', value:'true'}
    ];
    timeAtAddressOptions = [
        {label:'More than 12 months', value:'More than 12 months'},
        {label:'Less than 12 months', value:'Less than 12 months'}
    ];

    PHONE_FIELD = 'phone';
    DOB_FIELD = 'dob';
    DRIVERS_LICENSE_FIELD = 'driversLicense';

    MAX_LENGTH_NAMES = 40;
    PREVIOUS_NAME_MAX_LENGTH = 80;
    
    @track showLicensePopup;

    @track isMiddleNameVerified;
    @track isMiddleNameVerified;

    // need this hack because radio groups with the same name, even in a different component will clash
    get knownByOtherNameId () {
        return 'knownByOtherName' + this.personIndex;
    }
    get showOtherNameFields() {
        return this._director.knownByOtherName === 'true';
    }

    get timeAtAddressId () {
        return 'timeAtAddressId' + this.personIndex;
    }
    get showPreviousAddressFields() {
        return this._director.timeAtAddress === 'Less than 12 months';
    }

    @track _director = {
        firstName: '', lastName : ''
        , knownByOtherName:'false'
        , timeAtAddress:'More than 12 months'
        , positionTitle: '',
        currentResidentialAddress:{  // [Added by Jansi : 02-03-2021]
            line1: '',
            line2: '',
            city: '',
            state: '',
            postcode: '',
            dpid: '',
            country: '',
            countryName: ''
        },
        previousResidentialAddress:{
            line1: '',
            line2: '',
            city: '',
            state: '',
            postcode: '',
            dpid: '',
            country: '',
            countryName: ''
        }
    };
    @api get director() {
        this._director.positionTitle = this.directorLabel;
        this._director.index = this.personIndex
        return this._director;
    }

    get showTitle() {
        if(this.creditAssessment.abnDetails && this.creditAssessment.abnDetails.EntityTypeGroup)
        {

            let entityTypeGroup = this.creditAssessment.abnDetails.EntityTypeGroup.toLowerCase();
            switch (entityTypeGroup) {
                case this.ABNTYPES.PARTNERSHIP:
                    return true;
                    break;
                default:
                    return false;
            }
        }
        return false;
    }

    get totalDirectors() {
        if(this.creditAssessment.businessTypeDetails)
        {
            return this.creditAssessment.businessTypeDetails.noOfDirectors;
        }
        return 1;
    }

    get directorLabel()
    {
        if(this.creditAssessment.abnDetails && this.creditAssessment.abnDetails.EntityTypeGroup)
        {
            let entityTypeGroup = this.creditAssessment.abnDetails.EntityTypeGroup.toLowerCase();

            switch (entityTypeGroup)
            {
                case this.ABNTYPES.PARTNERSHIP:
                    return 'Partner';
                    break;
                case this.ABNTYPES.INDIVIDUAL:
                    return 'Proprietor';
                    break;
                case this.ABNTYPES.TRUST:
                    return 'Trustee';
                    break;
                case this.ABNTYPES.GOVERNMENT:
                    return 'N/A';
                    break;
                default:
                    return 'Director';

            }
        }
        return 'Director';
    }

    /**
     * if this person details have data coming from digital Id endpoint
     * @returns {boolean}
     */
    get isVerified() {
    
        if(this.personIndex === '1') {
            // verification only happens for person 1
            if (this.creditAssessment.directors && this.creditAssessment.directors[0] && !this.computedVerified) {

                Object.assign(this._director, this.creditAssessment.directors[0]);

                if(this._director.middleName)
                    this.isMiddleNameVerified = true;

                this.validateDOBFromDigitalId();
                this.computedVerified = true;
                return true;
            }
        }
        return this.computedVerified;
    }


    @track computedVerified;
    validateDOBFromDigitalId() {
        if(!this.computedVerified)
        {
            this.validateDOB();
        }
    }

    onChangeField = (event) => {
        const field = event.target.dataset.id;
        let newValue = event.target.value;

        switch (field) {
            case this.DRIVERS_LICENSE_FIELD:
                const formattedDL = newValue.replace(/[^0-9a-z]/gi, '');
                this._director[field] = formattedDL;
                event.target.value = formattedDL;
                break;
            case this.DOB_FIELD:
                this._director[field] = newValue;
                this.validateDOB();
                break;
            case this.PHONE_FIELD:
                this.updatePhoneMaxLength(newValue);
                let phoneFormatted = this.formatPhoneNumber( newValue);
                
                // display formatted
                event.target.value = phoneFormatted;

                // store the stripped version
                newValue = newValue.replace(/\D/g, '');
                this._director[field] = newValue;
                break;
            default:
                this._director[field] = newValue;
                break;

        }
    }


    @track phoneMaxLength = 10;

    updatePhoneMaxLength(inputRaw) {
        const inputMobile = inputRaw.replace(/\D/g, '').substring(0, 2); // First two digits to find mobile or landline
        if (inputMobile === '04')
            this.phoneMaxLength = 12;
        else
            this.phoneMaxLength = 14;
    }

    get minDOB() {
        let dobDate = new Date();
        return (dobDate.getFullYear() - 100) + '-01-01'
    }

    get maxDOB() {
        let dobDate = new Date();
        return (dobDate.getFullYear() - 16) + '-01-01'
    }

    get defaultDOB() {
        let dobDate = new Date();
        return (dobDate.getFullYear() - 40) + '-01-01'
    }

    //address change event handler [Added by Jansi : 02-03-2021]
    handleAddressChange(event) {
        if (event.target.dataset.id == 'currentResidentialAddress')
            this._director.currentResidentialAddress = event.detail.address;
        else
            this._director.previousResidentialAddress = event.detail.address;
    }

    //new address entered manually handlr
    handleManualChange(event) {
        this._director.currentResidentialAddress = Object.assign(this._director.currentResidentialAddress, event.detail.address);
        this._director.currentResidentialAddress.line1 = this._director.currentResidentialAddress.addressLine1;
        this._director.currentResidentialAddress.line2 = this._director.currentResidentialAddress.addressLine2;
    }

    handlePreviousManualChange(event) {
        this._director.previousResidentialAddress = Object.assign(this._director.previousResidentialAddress, event.detail.address);
        this._director.previousResidentialAddress.line1 = this._director.previousResidentialAddress.addressLine1;
        this._director.previousResidentialAddress.line2 = this._director.previousResidentialAddress.addressLine2;
    }

    validateDOB = () =>{
        // if blank, do nothing
        if(!this._director.dob)
        {
            return false;
        }

        // check dob is older than 18
        let dob = Date.parse(this._director.dob);

        let today = new Date(Date.now());
        let birthDate = new Date(Date.parse(this._director.dob));
        let ageYears = today.getFullYear() - birthDate.getFullYear();
        let m = today.getMonth() - birthDate.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
            ageYears--;
        }

        let validDOB = (ageYears >= 18);
        let dobCmp = this.template.querySelector("[data-id='" + this.DOB_FIELD + "']");

        dobCmp.value = this._director.dob;

        const cmpDisabled = dobCmp.disabled;
        dobCmp.disabled = false;
        dobCmp.setCustomValidity(validDOB ? '' : 'Must be over 18 years of age');
        dobCmp.reportValidity();
        dobCmp.disabled = cmpDisabled;

        return validDOB;
    }


    cancelLicenseWarning(event) {
        this.showLicensePopup = false;
    }

    continueLicenseWarning(event) {
        this.showLicensePopup = false;
    }

    @api checkAllValidity() {
        // when called by bcaForm, the fields will actually be hidden, so, the validation is done on the saving
        // of each entry
        const inputComponents = this.template.querySelectorAll('lightning-input');
        let valid = this.checkAllInputCmpValidity(inputComponents);

        // check 18+
        let validDOB = this.validateDOB();

        let validPrevAddress = true;
        if (this.showPreviousAddressFields)
            validPrevAddress = this.checkAllInputCmpValidity(this.template.querySelectorAll('[data-id="previousResidentialAddress"]'), false);
        return this.checkAllInputCmpValidity(this.template.querySelectorAll('[data-id="currentResidentialAddress"]'), false) &&
            valid &&
            validDOB &&
            validPrevAddress;
    }
}