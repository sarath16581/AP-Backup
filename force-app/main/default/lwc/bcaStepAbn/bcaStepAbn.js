/* @author
* @date 2020-12-10
* @channel Credit Application
* @tag Credit Application
* @description: Step in Credit Application Form to input ABN/ACN
* @changelog
* 2020-12--10 vcheng@salesforce.com Created
*/

import {LightningElement, api, wire, track} from 'lwc';
import bcaStepBase from "c/bcaStepBase";

// callout search
import queryABN from '@salesforce/apexContinuation/BCAFormController.queryABN';
import {
    ERROR_NO_ABN,
    ERROR_NO_ACN,
    ERROR_INVALID_ABN_FORMAT,
    ERROR_INVALID_ABN_CHARACTERS,
    ERROR_INVALID_ACN_FORMAT,
    ERROR_INACTIVE_ABN,
    ERROR_INACTIVE_ACN,
    ERROR_NOT_FOUND_ACN,
    ERROR_NOT_FOUND_ABN,
    ERROR_GENERIC__ABN_ACN_SEARCH,
    ERROR_INVALID_ENTITY_TYPE,
    isNumericInput,
    isModifierKey
} from 'c/bcaCommonMethods'

export default class BcaStepAbn extends bcaStepBase {
    ERROR_NO_ABN = ERROR_NO_ABN;
    ERROR_NO_ACN = ERROR_NO_ACN;
    ERROR_INVALID_ABN_FORMAT = ERROR_INVALID_ABN_FORMAT;
    ERROR_INVALID_ABN_CHARACTERS = ERROR_INVALID_ABN_CHARACTERS;
    ERROR_INVALID_ACN_FORMAT = ERROR_INVALID_ACN_FORMAT;
    ERROR_INACTIVE_ABN = ERROR_INACTIVE_ABN;
    ERROR_INACTIVE_ACN = ERROR_INACTIVE_ACN;
    ERROR_NOT_FOUND_ACN = ERROR_NOT_FOUND_ACN;
    ERROR_NOT_FOUND_ABN = ERROR_NOT_FOUND_ABN;
    ERROR_GENERIC__ABN_ACN_SEARCH = ERROR_GENERIC__ABN_ACN_SEARCH;
    ERROR_INVALID_ENTITY_TYPE = ERROR_INVALID_ENTITY_TYPE;

    ABN_STATUSES = {
        Active: 'ACT'
        , Cancelled : 'CAN'
        , Replaced : 'REP'
    }

    @track abnShowLoader = false;
    @track acnShowLoader = false;
    //@track errorMessage = '';

    @track abnFieldError = '';
    @track acnFieldError = '';

    // this will begin on true, only search when there's a value entered
    @track disableSearch;
    @track disableSearchACN;

    // abn results - this will be retrieved by the containing lwc
    @track searchResults;
    //@track selectedOrg;
    @track businessNames;

    @track tradingNames;
    @track acnTradingNames;   //jansi

    // return object to form
    @track _abnDetails = {};
    @api get abnDetails() { return this._abnDetails;}
    @track searchString;
    formattedABN;
    formattedACN;

    // ACN search
    @track acnErrorMessage = '';
    @track searchACN;

    @track trustTypes;

    connectedCallback() {
        if(this.creditAssessment && this.creditAssessment.abnDetails)
        {
            // prepopulate fields
            this._abnDetails = this.creditAssessment.abnDetails;
            this.searchString = this._abnDetails.ABN;
        }
        this.disableSearch = true;
        this.disableSearchACN = true;

        this.trustTypes = [
            {
                label: 'Person', value: this.ABNTYPES.TRUSTEE_PERSON
            },{
                label: 'Company', value: this.ABNTYPES.TRUSTEE_COMPANY
            }
        ];
    }

    get abnSearchBtnClass () {
        let sClass = "slds-button slds-button_icon slds-button_icon-border abcn-search-aligned-input-button";

        if(!this._abnDetails.ABN)
        {
            sClass += ' red-icon-button';
        }

        if(this.abnShowLoader){
            sClass += ' red-icon-button loading-true';
        }
        return sClass;
    }

    get acnSearchBtnClass () {
        let sClass = "slds-button slds-button_icon slds-button_icon-border abcn-search-aligned-input-button inner-form-padding";

        if(this.isTrusteeCompany && !this._abnDetails.acnDetails)
        {
            sClass += ' red-icon-button';
        }

        if(this.acnShowLoader){
            sClass += ' red-icon-button loading-true';
        }
        return sClass;
    }

    get abnSearchInputClass () {
        let sClass = "search-aligned-input-field abcn-search-input";

        if(this.abnFieldError)
            sClass += ' slds-has-error';
        return sClass;
    }

    get acnSearchInputClass () {
        let sClass = "search-aligned-input-field abcn-search-input";

        if(this.acnFieldError)
            sClass += ' slds-has-error';
        return sClass;
    }

    onChangeField = (event) => {
        const field = event.target.dataset.id;
        let newValue = event.detail.value;
        //--Checking the custom validation on change of a field value
        this.checkValidationOfField(field);  // added by Jansi
        switch (field) {
            case 'abn':
                this.searchString = newValue;
                this.formattedABN = this.formatABN(event);
                this.disableSearch = false;
                if (!newValue)
                    this.disableSearch = true;
                break;
            case 'acn':
                this.searchACN = newValue;
                this.formattedACN = this.formatACN(event);
                this.disableSearchACN = false;
                if (!newValue)
                    this.disableSearchACN = true;
                break;
            case 'tradingName':
                this._abnDetails.tradingName = newValue;
            case 'acnTradingName': // added by Jansi STP-4298
                 this._abnDetails.acnDetails.tradingName = newValue;
                 break;
             case 'acnOtherTradingName': // added by Jansi STP-4298
                 this._abnDetails.acnDetails.otherTradingName = newValue;
                 break;
            case 'trustType':                  // added by Jansi 
                this._abnDetails[field] = newValue;
                if (newValue == this.ABNTYPES.TRUSTEE_PERSON) {
                    //-- show 'Back' and 'Continue' button
                    this.updateNavButtons(true, true);
                } else if (newValue == this.ABNTYPES.TRUSTEE_COMPANY) {
                    this.acnErrorMessage = null; //[Fix for a Bug [STP-4806]]
                    //-- check if ACN details are entered if Yes show 'Continue' button otherwise 'Disable'
                    if (this._abnDetails.acnDetails != null)  //[Check with Victor if this check is sufficient]
                        this.updateNavButtons(true, true);
                    else
                        this.updateNavButtons(true, false);
                }
                break;
            default:
                this._abnDetails[field] = newValue;
                break;

        }
    }

    get otherTradingName() {
        if(this._abnDetails.tradingName && this._abnDetails.tradingName === this.CONSTANTS.MANUAL_ENTRY &&
             this._abnDetails.ABNStatus == this.ABN_STATUSES.Active && 
              this._abnDetails.EntityTypeGroup.toLowerCase() != this.ABNTYPES.OTHER_PARTNERSHIP)
            return true;
        return false;
    }

    get otherACNTradingName() {// added by Jansi STP-4298
        if(this._abnDetails.acnDetails.tradingName && this._abnDetails.acnDetails.tradingName === this.CONSTANTS.MANUAL_ENTRY && this._abnDetails.acnDetails.ABNStatus == this.ABN_STATUSES.Active)
            return true;
        return false;
    }

    get hasTradingNames() {
        return this.tradingNames.length > 1 && this._abnDetails.EntityTypeGroup.toLowerCase() != this.ABNTYPES.OTHER_PARTNERSHIP;
    }

    get hasACNTradingNames() {
        return this.acnTradingNames.length > 1;
    }

    get tradingNameLabel() {
        if(this.hasTradingNames)
        {
            return 'Enter trading name';
        }
        return 'Trading name';
    }

    get isTrust() {
        if(this._abnDetails && this._abnDetails.EntityTypeGroup.toLowerCase() === this.ABNTYPES.TRUST)
        {
            return true;
        }
        return false;
    }

    get isTrusteeCompany() {
        return this._abnDetails.trustType === this.ABNTYPES.TRUSTEE_COMPANY;
    }


    //validates the ABN based on ABR rules
    validateABN (value) {
        if(!value)
        {
            return false;
        }

        let weights = [10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19],
            //abn = value.replace(/[^\d]/, ''),
            abn = value.toString().replace(/[^a-zA-Z\d]/gi, ''),
            result = false;


        //check if there are alpha chars in there
        let isNum = /^\d+$/.test(abn);
        if(!isNum)
        {
            this.abnFieldError = this.ERROR_INVALID_ABN_CHARACTERS;
            return false;
        }


        // check length is 11 digits
        if (abn.length === 11) {

            // apply ato check method
            let sum = 0,
                weight;

            for (let index = 0; index <= weights.length - 1; index++) {
                weight = weights[index];
                let digit = abn[index] - (index ? 0 : 1);
                sum += weight * digit;
            }

            result = sum % 89 === 0;
        }

        if(!result)
        {
            this.abnFieldError = this.ERROR_INVALID_ABN_FORMAT;
        }
        return result;
    }

    //validates the ACN based on ABR rules
    validateACN(value){
        if (!value) {
            return false;
        }

        // strip non-alphanumeric characters
        const acn = value.toString().replace(/[^a-zA-Z\d]/gi, '');
        const weights = [8, 7, 6, 5, 4, 3, 2, 1];

        // check if length is 9 digits
        if (acn.length !== 9) {
            return false;
        }

        // apply ato check method
        let sum = 0;
        for (let position = 0; position < weights.length; position += 1) {
            const weight = weights[position];
            const digit = parseInt(acn[position], 10);
            sum += weight * digit;
        }

        const checksum = (10 - (sum % 10)) % 10;

        return checksum === parseInt(acn[8], 10);
    }

    async onClickSearchAcn(event)
    {
        this.updateNavButtons(true, false);  // Jansi - Disable 'Continue' during ACN Search
        this.acnFieldError = '';
        this._abnDetails.acnDetails = null;
        if(!this.searchACN){
            this.acnFieldError = this.ERROR_NO_ACN;
            return;
        }

        if(!this.validateACN(this.searchACN)){
            this.acnFieldError = this.ERROR_INVALID_ACN_FORMAT;
            return;
        }

        // loading
        this.acnShowLoader = true;
        this.disableSearchACN = true;
        this.acnFieldError = '';

        await queryABN({abn: null, acn:this.searchACN})
            .then(result=>{
           
                if(result == null)
                {
                    this.acnErrorMessage = this.ERROR_NOT_FOUND_ACN;
                    return;
                }
                else if(result.status === 'error')
                {
                    this.acnErrorMessage = this.ERROR_GENERIC__ABN_ACN_SEARCH;//'An error has occurred, please try again later';
                    return;
                }
                else
                {

                    if(result.searchResults.length > 0)
                    {
                        let acnResult = result.searchResults[0];
                        acnResult.statusString = this.parseABNStatus(acnResult.ABNStatus);// + ' from ' + acnResult.ABNStatusFromDate;
                        this._abnDetails.acnDetails = acnResult;
                        this._abnDetails.acnDetails.formattedABN = this.formattedACN;
                        this.acnTradingNames = [];
                        // push any trading names as the first option
                        if (this._abnDetails.acnDetails.TradingNameStr) {
                            this.acnTradingNames.push({
                                label: this._abnDetails.acnDetails.TradingNameStr,
                                value: this._abnDetails.acnDetails.TradingNameStr
                            });
                        }

                        for (let i = 0; i < this._abnDetails.acnDetails.entities.length; ++i) {
                            let entity = this._abnDetails.acnDetails.entities[i];
    
                            this.acnTradingNames.push({
                                label: entity.entityName, value: entity.entityName
                            })
                        }

                        // add an option to manually enter the trading name
                        this.acnTradingNames.push(
                            {
                                label: 'Other...',
                                value: this.CONSTANTS.MANUAL_ENTRY
                            }
                        )
                        this._abnDetails.acnDetails.tradingName = this.acnTradingNames[0].value;
                        
                        if( this._abnDetails.acnDetails.ABNStatus !== this.ABN_STATUSES.Active) { //If ACN status inactive then 'disable' Continue button
                                this.acnErrorMessage = this.ERROR_INACTIVE_ACN;
                                this.updateNavButtons(true, false);
                            }
                            else{
                                this.acnErrorMessage = '';
                                this.updateNavButtons(true, true);
                            }

                        //-- show 'Back' and 'Continue' button
                        //this.updateNavButtons(true, true);            // Added by Jansi
                    }
                }
            })
            .catch(error => {
                //this.errorMessage = 'An error occurred:' + error.body.message;
                this.acnErrorMessage = this.ERROR_GENERIC__ABN_ACN_SEARCH;//'An error has occurred, please try again later';
                this.disableSearch = false;
            });

        this.acnShowLoader = false;
    }

    async onClickSearchAbn(event)
    {
        this.errorMessage = '';
        this.updateNavButtons(true, false);
        this.searchResults = null;
        this._abnDetails = {};
        this.searchACN = null; 
        this.formattedACN = null;
        this.acnErrorMessage = '';  //Jansi[To do] can we move all clearing values to a method and call them
        this.abnFieldError = '';
        
        if(!this.searchString){
            this.abnFieldError = this.ERROR_NO_ABN;
            return;
        }

        // client side validation of format
        if(false === this.validateABN(this.searchString)){
            return;
        }

        let abn = this.searchString;

        // else continue
        this.abnShowLoader = true;

        // disable the search button
        this.disableSearch = true;
        // clear error message pane
        this.errorMessage = '';

        await queryABN({abn: abn, acn:null})
            .then(result=>{
                this._abnDetails.tradingName = '';

                if(result == null){
                    this.errorMessage =this.ERROR_NOT_FOUND_ABN;
                    return;
                }
                else if(result.status === 'error'){
                    this.errorMessage = this.ERROR_GENERIC__ABN_ACN_SEARCH;//'An error has occurred, please try again later';
                    return;
                }
                else
                {
                    if(result.searchResults.length > 0)
                    {
                        this._abnDetails = result.searchResults[0];
                        this._abnDetails.statusString = this.parseABNStatus(this._abnDetails.ABNStatus);

                        this._abnDetails.formattedABN = this.formattedABN; //To display in Summary
                        // parse the results for display
                        this.tradingNames = [];

                        // push any trading names as the first option
                        if(this._abnDetails.TradingNameStr) {
                            this.tradingNames.push({
                                label: this._abnDetails.TradingNameStr,
                                value: this._abnDetails.TradingNameStr
                            });
                        }

                        for(let i = 0; i < this._abnDetails.entities.length; ++i)
                        {
                            let entity = this._abnDetails.entities[i];
    
                            this.tradingNames.push({
                                label:entity.entityName, value:entity.entityName
                            })
                        }

                        // add an option to manually enter the trading name
                        this.tradingNames.push(
                            {
                                label: 'Other...',
                                value:this.CONSTANTS.MANUAL_ENTRY
                            }
                        )
                        this._abnDetails.tradingName = this.tradingNames[0].value;

                        let entityTypeGroup = this._abnDetails.EntityTypeGroup.toLowerCase();

                        // default trust type to person if it's a trust
                        if(entityTypeGroup === this.ABNTYPES.TRUST)
                        {
                            this._abnDetails.trustType = this.ABNTYPES.TRUSTEE_PERSON;
                        }
                        else
                        {
                            this._abnDetails.trustType = '';
                        }

                        // if Other Partnership OR INACTIVE end
                        if(entityTypeGroup === this.ABNTYPES.OTHER_PARTNERSHIP){
                            this.errorMessage = this.ERROR_INVALID_ENTITY_TYPE;
                            this.updateNavButtons(true, false);
                        }else if(this._abnDetails.ABNStatus !== this.ABN_STATUSES.Active){
                            this.errorMessage = this.ERROR_INACTIVE_ABN;
                            this.updateNavButtons(true, false);
                        }
                        else
                        {
                            this.errorMessage = '';
                            this.updateNavButtons(true, true);
                        }
                    }
                }
            })
            .catch(error => {
                this.errorMessage = 'An error occurred, please try again';
                this.disableSearch = false;
            });

        this.abnShowLoader = false;
    }


    parseABNStatus(sStatus)
    {
        switch (sStatus)
        {
            case this.ABN_STATUSES.Active:
                return 'Active';
            case this.ABN_STATUSES.Cancelled:
                return 'Cancelled';
            case this.ABN_STATUSES.Replaced:
                return 'Replaced';
            default:
                return sStatus;
        }
    }


    @api checkAllValidity() {
        const inputComponents = this.template.querySelectorAll('lightning-input');
        let allValid = this.checkAllInputCmpValidity(inputComponents);
        return allValid;
    }

    enforceFormat = (event) => {
        // Input must be of a valid number format or a modifier key
        if (!isNumericInput(event) && !isModifierKey(event)) {
            event.preventDefault();
        }
    };

    formatABN = (event) => {
        if (isModifierKey(event)) { return; }

        const target = event.target;
        const input = event.target.value.replace(/\D/g, '').substring(0, 14); // First ten digits of input only

        const first = input.substring(0, 2);
        const second = input.substring(2, 5);
        const third = input.substring(5, 8);
        const fourth = input.substring(8, 11);

        if (input.length > 8) { target.value = `${first} ${second} ${third} ${fourth}`; }
        else if (input.length > 5) { target.value = `${first} ${second} ${third}`; }
        else if (input.length > 2) { target.value = `${first} ${second}`; }
        else if (input.length > 0) { target.value = `${first}`; }
        return target.value;
    };

    formatACN = (event) => {
        if (isModifierKey(event)) { return; }

        const target = event.target;
        const input = event.target.value.replace(/\D/g, '').substring(0, 11); // First ten digits of input only

        const first = input.substring(0, 3);
        const second = input.substring(3, 6);
        const third = input.substring(6, 9);

        if (input.length > 6) { target.value = `${first} ${second} ${third}`; }
        else if (input.length > 3) { target.value = `${first} ${second}`; }
        else if (input.length > 0) { target.value = `${first}`; }
        return target.value;
    };

    preventDeletion(event) {
        const key = event.keyCode;
        if (key === 8 || key === 46) { //preventing backspace and delete keys
            event.preventDefault();
        }
    }

}