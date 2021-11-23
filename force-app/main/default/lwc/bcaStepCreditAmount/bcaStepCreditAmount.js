/*
* @author Victor.Cheng@auspost.com.au
* @date 2020-12-17
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Step in Credit Application Form to input Business Credit Amount details
* @changelog
* 2020-12-17 Victor.Cheng@auspost.com.au  Created
* 2020-12-17 avula.jansirani@auspost.com.au  Updated
* 2021-06-30 avula.jansirani@auspost.com.au added 'validLowerMonthlyAmount()' [STP-6333]
*/

import { LightningElement, track, wire, api } from 'lwc';
import noOfTimesCreditLimit from '@salesforce/apex/BCAFormBase.noOfTimesCreditLimit';

import {
    Enter_ESTIMATED_COST_VALUE_MISSING_VALIDATION_MESSAGE,
    ENTER_VALID_ESTIMATED_MONTHLY_POSTAGE_COST,
    formatAmount
} from 'c/bcaCommonMethods'
import bcaStepBase from "c/bcaStepBase";

export default class BcaStepCreditAmount extends bcaStepBase {

    @track _creditAmount = { acceptAmount: "true" ,'monthlyAmount':'', 'recommendedAmount':'0'}; //[Jansi: To re check 'acceptAmount' not using anywhere]
    @track noOfTimes;
    @track roundNearest;
    enterEstimatedCostValidationMsg = Enter_ESTIMATED_COST_VALUE_MISSING_VALIDATION_MESSAGE;
    enterValieCostMsg = ENTER_VALID_ESTIMATED_MONTHLY_POSTAGE_COST;

    @api get creditAmount() {
        return this._creditAmount;
    }

    //wire method to get 'no of time' to calculate 'Recommended credit amount'
    @wire(noOfTimesCreditLimit, {}) wiredNoOfTimes({ error, data }) {
        if (data){
            this.noOfTimes = data.noOfTimes;
            this.roundNearest = data.roundNearest;
        }
 
        if (error){}
    }

    //change handler
    onChangeField = (event) => {
        const field = event.target.dataset.id;
        let newValue = event.detail.value;
        this.checkValidationOfField(field);  //Refering from 'bcaStepBase'
        switch (field) {
            case 'monthlyAmount':
                let numberValue = newValue.replace(/\D/g,'');
                event.target.value = formatAmount(numberValue);
                this._creditAmount[field] = Number(numberValue);
                this._creditAmount.recommendedAmount = this.getRecommendedAmount(numberValue);
                this.validLowerMonthlyAmount(numberValue, field);       // Added 30-06-2021  [STP-6333]
                break;
            default:
                this._creditAmount[field] = newValue;
                break;
        }
    }

    validLowerMonthlyAmount(numValue, datasetId) {
        const inputCmp = this.template.querySelectorAll('[data-id="' + datasetId + '"]');
        if (numValue) {
            if (numValue < 1)
                inputCmp[0].setCustomValidity(this.enterValieCostMsg);
            else
                inputCmp[0].setCustomValidity('');

            inputCmp[0].reportValidity();
            return inputCmp[0].checkValidity();
        } else
            return true;

    }

    // focusout handler
    handleFocusOut(event) {
        if(!event.target.value.replace(/\D/g,'')) event.target.value = null; // Added 30-06-2021 , because 'missing value' vaildation mesaage was not showing(due to added $ char) on clear up the monthly amount

        this.checkValidationOfField(event.target.dataset.id);
        this.validLowerMonthlyAmount(event.target.value.replace(/\D/g,''), event.target.dataset.id);       // Added 30-06-2021  [STP-6333]
    }

    getRecommendedAmount(numberValue) {
        
        let recommendedAmount = this.noOfTimes * Number(numberValue);
        if(recommendedAmount > this.creditAssessment.lowerCreditLimitVal){
            recommendedAmount = Math.ceil(recommendedAmount/this.roundNearest) * this.roundNearest;
        } 
        
        return recommendedAmount;
    }

    enforceFormat = (event) => {
        // not allowing LWC currency alphabets  'e' 't' 'k' 'b' 'm' '-' [STP-4818: issue fix]
        const key = event.keyCode;
        if (key === 69 || key === 84 || key === 75 || key === 66 || key === 77 || key === 189)
            event.preventDefault();
    }

    //validity method: to check all required fields validation
    @api checkAllValidity() {
        const inputCmp = this.template.querySelectorAll('[data-id="monthlyAmount"]');

        const inputComponents = this.template.querySelectorAll('lightning-input');
        return this.checkAllInputCmpValidity(inputComponents) &&
            this.validLowerMonthlyAmount(inputCmp[0].value.replace(/\D/g, ''), 'monthlyAmount'); // Added 30-06-2021  [STP-6333]
    }
}