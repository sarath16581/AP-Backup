/*
* @author avula.jansirani@auspost.com.au
* @date 2021-02-05
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Step in Credit Application Form to input Business Type details
* @changelog
* 2021-02-05 avula.jansirani@auspost.com.au  Created
*
*/
import { LightningElement, track, api, wire } from 'lwc';
import { getDirectorLabel, isToDisplayNoOfDirectors } from 'c/bcaStepBase';
import bcaStepBase from "c/bcaStepBase";
import {
    BUSINESS_TYPE_DETAILS__INDUSTRY_DIVISION__VALUE_MISSING_ERROR_MSG,
    BUSINESS_TYPE_DETAILS__INDUSTRY_CLASS__VALUE_MISSING_ERROR_MSG
} from 'c/bcaCommonMethods'
import getObjectRecordFieldValues from '@salesforce/apex/BCAFormBase.getObjectRecordFieldValues';
import getIndustryDivisionValues from '@salesforce/apex/BCAFormBase.getIndustryDivisionValues';

export default class BcaStepBusinessTypeDetails extends bcaStepBase {
   
    @api get businessTypeStepDetails() { return this._businessTypeStepDetails;}
    @api entityTypeGroup;
    @api trustType;

    industryDivisionValueMissing = BUSINESS_TYPE_DETAILS__INDUSTRY_DIVISION__VALUE_MISSING_ERROR_MSG;
    industryClassValueMissing = BUSINESS_TYPE_DETAILS__INDUSTRY_CLASS__VALUE_MISSING_ERROR_MSG;

    @track _businessTypeStepDetails = {}
    
    @track numberOfDirOptons = [
        { label: '1', value: '1' },
        { label: '2', value: '2' },
        { label: '3', value: '3' },
        { label: '4', value: '4' },
        { label: '5', value: '5' },
        { label: '6', value: '6' }

    ];

    @track isIndustryClassDisabled = true;
    @track industryDivisionOptons = [{}];
    @track industryClassOptons = [{}];

    //wire method to get Industry Division values
    @wire(getIndustryDivisionValues, {
    }) wiredGetIndustryDivisionValues({ error, data }) {
        if (data) {
            this.industryDivisionOptons = data;
        }
    }

    // change handler
    handleChange(event) {
        var inputElement = event.target.dataset.id;
        this._businessTypeStepDetails[inputElement] = event.target.value;
        if (inputElement == 'industryDivision') {
            this._businessTypeStepDetails.industryClass = null;
            this.template.querySelectorAll('[data-id="industryClass"]')[0].value = null; 
            this.populateIndustryClass(event.target.value);
        }
        //--Checking the custom validation on change of a field value
        this.checkValidationOfField(inputElement);
    }
    

    //fetch and populate industry class values
    populateIndustryClass(industryDivisionVal) {
        this.industryClassOptons = [{}];
        let whereCondition = "WHERE ANZSIC_Division__c='" + industryDivisionVal + "'";
        getObjectRecordFieldValues({
            sObjectApiName: 'ANZSIC_Code__c',
            fieldApiName: 'Code_Description__c',
            criteria: whereCondition,
            isDistinct: false
        }).then(result => {
            this.industryClassOptons = result;
            this.isIndustryClassDisabled = false;
        }).catch(error => {
            this.isIndustryClassDisabled = false;
        });
    }

     //getter to display 'no of directors' label
     get noOfDirectorsLabel() {
        return 'No. of '.concat(getDirectorLabel(this.entityTypeGroup, this.trustType).toLowerCase(), 's') ;
    }

    //getter to display 'no of directors or not'
    get isDisplayNoOfDirectors() {
        return isToDisplayNoOfDirectors(this.entityTypeGroup, this.trustType);
    }


    //validity method: to check all required fields validation
    @api checkAllValidity() {
        const inputComponents = this.template.querySelectorAll('lightning-combobox');
        return this.checkAllInputCmpValidity(inputComponents);
    }

    handleBlur(event){
        this.template.querySelector('[data-id="noOfDirectors1"]').closeDropdown();
    }

    enforceFormat(event) {
        const key = event.keyCode;
        if (key === 8 || key === 46) { //preventing backspace and delete keys
            event.preventDefault();
        }
    }

}