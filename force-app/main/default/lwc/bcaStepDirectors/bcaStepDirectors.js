/*
* @author Victor.Cheng@auspost.com.au
* @date 2020-12-11
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Step in Credit Application Form to input Business Director detail
* @changelog
* 2020-12-11 Victor.Cheng@auspost.com.au  Created
*
*/

import {LightningElement, track, wire, api} from 'lwc';
import bcaStepBase from "c/bcaStepBase";
//import {  checkCustomValidity } from 'c/bcaStepBase';

export default class BcaStepDirectors extends bcaStepBase {

    @track showLicensePopup;

    @track showEditing = false;
    @track _directors;
    @api get directors()
    {
        return this._directors;
    }

    @track editingDirector;

    yesNoOptions = [
        {label:'No', value:'false'},
        {label:'Yes', value:'true'}
    ];
    timeAtAddressOptions = [
        {label:'More than 12 months', value:'true'},
        {label:'Less than 12 months', value:'false'}
    ];

    connectedCallback() {
        if(this.creditAssessment.directors){
            this._directors = this.creditAssessment.directors;
        }
        else{
            this._directors = [];
        }
    }

    get totalDirectors() {
        return this._directors.length;
    }

    get showAddButton() {
        return this._directors.length < 6;
    }


    clickAdd(event) {
        this.addDirector();
        this.editingDirector = this._directors[this._directors.length-1];
        this.showEditing = true;
        this.updateNavButtons(false, false);
    }

    addDirector(event) {
        let dobDate = new Date();

        this.editingDirector = {
            collapsed :false
            ,index: this._directors.length + 1
            ,firstName:'',middleName:'',lastName:''
            ,knownByOtherName:'false', timeAtAddress:'true'
            , currentResidentialAddress : {}
            , previousResidentialAddress : {}
            , dob: (dobDate.getFullYear() - 40) + '-01-01'
        };
        this._directors.push(this.editingDirector);
    }

    deleteDirector = (event) =>{
        let index = 0;
        if(event.currentTarget.dataset.id)
        {
            index = event.currentTarget.dataset.id - 1;
        }
        else
        {
            index = event.target.dataset.id - 1;
        }

        this._directors.splice(index, 1);

        // hack to force LWC to track the change in the array
        this._directors = [...this._directors];

        // rename the indices
        for(let i = 0; i < this._directors.length; ++i)
        {
            let director = this._directors[i];
            director.index = i + 1;
        }
    }


    editDirector=(event)=> {
        let index = 0;
        if(event.currentTarget.dataset.id)
        {
            index = event.currentTarget.dataset.id - 1;
        }
        else
        {
            index = event.target.dataset.id - 1;
        }
        this.editingDirector = this._directors[index];

        this.populatedAddress = false;

        this.showEditing = true;

        this.updateNavButtons(false, false);
    }

    get directorKnownByOtherName () {
        return this.editingDirector.knownByOtherName == 'true';
    }

    get showPreviousAddress () {
        return this.editingDirector.timeAtAddress == 'false';
    }

    populatedAddress = true;
    renderedCallback() {
        if(!this.populatedAddress)
        {
            let currAddressCmp = this.template.querySelector("c-address-search-cmp[data-id='currentResidentialAddress']");
            currAddressCmp.setAddress(this.editingDirector.currentResidentialAddress);

            let prevAddressCmp  = this.template.querySelector("c-address-search-cmp[data-id='previousResidentialAddress']");
            if(prevAddressCmp)
                prevAddressCmp.setAddress(this.editingDirector.previousResidentialAddress);
        }
        this.populatedAddress = true;
    }

    validateDOB() {
        // check dob is older than 18
        let dob = Date.parse(this.editingDirector.dob);
        let diff = Date.now() - dob;
        let ageDate = new Date(diff);
        let ageYears = Math.abs(ageDate.getUTCFullYear() - 1970);
        return ageYears >= 18;
    }

    closeEditing(event) {
        // other input fields
        let valid = this.checkAllValidity();

        // check 18+
        let validDOB = this.validateDOB();
        let dobCmp = this.template.querySelector("[data-id='dob']");
        dobCmp.setCustomValidity('');
        if(!validDOB)
        {
            dobCmp.setCustomValidity('Must be older than 18 years');
        }
        dobCmp.reportValidity();

        if(valid && validDOB)
        {

            // check driver's license
            if(!this.editingDirector.driversLicence || this.editingDirector.driversLicence.trim() === '')
            {
                this.showLicensePopup = true;
                return;
            }

            this.editingDirector = null;
            this.showEditing = false;
            this.updateNavButtons(true, true);
        }
        else
        {
            // TODO - error
        }
    }

    cancelLicenseWarning(event) {
        this.showLicensePopup = false;
    }

    continueLicenseWarning(event) {
        this.showLicensePopup = false;
        this.showEditing = false;
        this.updateNavButtons(true, true);
    }


    onChangeField = (event) => {
        const field = event.target.dataset.id;
        let newValue = event.detail.value;

        switch (field) {
            default:
                this.editingDirector[field] = newValue;
                break;

        }
    }

    clickPageJump(event){
        this.jumpToStep(event.target.dataset.id);
    }

    @track currentResidentialAddress = {
        line1: '',
        line2: '',
        city: '',
        state: '',
        postcode: '',
        dpid: '',
        country: '',
        countryName: ''
    };

    handleAddressChange(event) {
        this.editingDirector.currentResidentialAddress = Object.assign(this.editingDirector.currentResidentialAddress, event.detail.address);
        this.editingDirector.currentResidentialAddress.line1 = this.editingDirector.currentResidentialAddress.addressLine1;
        this.editingDirector.currentResidentialAddress.line2 = this.editingDirector.currentResidentialAddress.addressLine3;
    }

    handlePreviousAddressChange(event) {
        this.editingDirector.previousResidentialAddress = Object.assign(this.editingDirector.previousResidentialAddress, event.detail.address);
        this.editingDirector.previousResidentialAddress.line1 = this.editingDirector.previousResidentialAddress.addressLine1;
        this.editingDirector.previousResidentialAddress.line2 = this.editingDirector.previousResidentialAddress.addressLine3;
    }

    //new address entered manually handlr
    handleManualChange(event) {
        this.editingDirector.currentResidentialAddress = Object.assign(this.editingDirector.currentResidentialAddress, event.detail.address);
        this.editingDirector.currentResidentialAddress.line1 = this.editingDirector.currentResidentialAddress.addressLine1;
        this.editingDirector.currentResidentialAddress.line2 = this.editingDirector.currentResidentialAddress.addressLine2;
    }

    handlePreviousManualChange(event) {
        this.editingDirector.previousResidentialAddress = Object.assign(this.editingDirector.previousResidentialAddress, event.detail.address);
        this.editingDirector.previousResidentialAddress.line1 = this.editingDirector.previousResidentialAddress.addressLine1;
        this.editingDirector.previousResidentialAddress.line2 = this.editingDirector.previousResidentialAddress.addressLine2;
    }

    /*
    get minDob() {
        let date = new Date();
        date.setFullYear(date.getFullYear() - 100);
        return date;
    }

    get maxDob() {
        let date = new Date();
        date.setFullYear(date.getFullYear() - 18);
        return date;
    }

     */

    get directorLabel()
    {
        if(this.creditAssessment.abnDetails && this.creditAssessment.abnDetails.EntityTypeGroup)
        {
            let entityTypeGroup = this.creditAssessment.abnDetails.EntityTypeGroup.toLowerCase();

            switch (entityTypeGroup)
            {
                case 'partnership':
                    return 'Partner';
                    break;
                case 'individual':
                    return 'Proprietor';
                    break;
                case 'trust':
                    return 'Trustee';
                    break;
                case 'government':
                    return 'N/A';
                    break;
                default:
                    return 'Director';

            }
        }
        return 'Director';
    }

    get addLabel()
    {
        return 'Add ' + this.directorLabel;
    }

    @api checkAllValidity() {
        // when called by bcaForm, the fields will actually be hidden, so, the validation is done on the saving
        // of each entry
        const inputComponents = this.template.querySelectorAll('lightning-input');
        let valid =  this.checkAllInputCmpValidity(inputComponents);

        return valid;
    }
}