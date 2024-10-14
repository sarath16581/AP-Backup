/* eslint-disable no-unused-vars */
/* eslint-disable no-console */
/**
  * @author       : Gnana
  * @date         : 06/06/2019
  * @description  : Component that shows Compenstaion Amount and Postage Value fields on LostArticle form
  *                 and also provides validation behaviour
--------------------------------------- History --------------------------------------------------
06/06/2019    Gnana   Created 
18/11/2019    saiswetha.pingali@auspost.com.au MW0003819 
08.10.2024	  Talib Raza			   REQ3526971 - Compensation amount field hidden and Message changes
**/

import { LightningElement,api,track} from 'lwc'
import LwcForm from 'c/lwcForm'

export default class compensationAndPostageValue extends LwcForm {
    
    @track amountNotValid = false
 //   @track compensationAmountData
 //   @track postageValueData
    @api compensationChangeHandler
    @api compensationPostageChangeHandler

    connectedCallback() {  
  
        this.values.compensationAmount = 0; 
        this.compensationAmountData = 0;
        this.fireChangeHandlerCompensationAmount();
  
    }

    handleCompensationValueChange(event){

        this.amountNotValid = false
        this.compensationAmountData = event.target.value;
        const compensationValue = event.target.value;
     //   const key = event.target.name;

        const postageCalc = this.template.querySelector(".postageValue").value

        if(Number(compensationValue) >100){
            //this.amountNotValid = true;  
            event.target.setCustomValidity('As total exceeds $100, click \'No\' to send to CCC for review');
            event.target.reportValidity();       
        }
        else if(Number(compensationValue)+Number(postageCalc)<=0)
        {    event.target.setCustomValidity('Please enter an amount ');
             event.target.reportValidity();
             this.template.querySelector(".postageValue").setCustomValidity('Please enter an amount  ');
             this.template.querySelector(".postageValue").reportValidity(); 
        }
        else if(Number(compensationValue) <100 && Number(postageCalc) <50 )
        {   event.target.setCustomValidity('');
            event.target.reportValidity();
            this.template.querySelector(".postageValue").setCustomValidity('');
            this.template.querySelector(".postageValue").reportValidity(); 
        }
        else
        {   event.target.setCustomValidity('');
            event.target.reportValidity();  
        }

        this.fireChangeHandlerCompensationAmount();
    }

    handlePostageValueChange(event){

        this.amountNotValid = false
        this.postageValueData = event.target.value;
        const postageValue = event.target.value;
     //   const key = event.target.name;    

        const compensationCalc = this.template.querySelector(".compensationAmount").value

        if(Number(postageValue) >50)
        {//this.amountNotValid = true;
            //EventTarget.setCustomValidity('Errored');
            event.target.setCustomValidity('As postage exceeds $50, click \'No\' to send to CCC for review');
            event.target.reportValidity();
        }
        else if(Number(postageValue)+Number(compensationCalc)<=0)
        {        event.target.setCustomValidity('Please enter an amount ');
                 event.target.reportValidity();
                 this.template.querySelector(".compensationAmount").setCustomValidity('Please enter an amount ');
                 this.template.querySelector(".compensationAmount").reportValidity(); 
        }
        else if(Number(postageValue) <50 && Number(compensationCalc) <100 )
        {       event.target.setCustomValidity('');
                event.target.reportValidity();
                this.template.querySelector(".compensationAmount").setCustomValidity('');
                this.template.querySelector(".compensationAmount").reportValidity(); 
        }
        else
        {       event.target.setCustomValidity('');
                event.target.reportValidity();
        }
        
        this.fireChangeHandlerPostValue();
    }

    fireChangeHandlerCompensationAmount() {

        if (typeof this.compensationChangeHandler === 'function') {
            this.compensationChangeHandler(this.compensationAmountData);
        }
    }

    fireChangeHandlerPostValue() {

        if (typeof this.compensationPostageChangeHandler === 'function') {
            this.compensationPostageChangeHandler(this.postageValueData);
        }
    }

    @api reportValidity(){
        const inputComponents = this.template.querySelectorAll(".form-input");
        //const inputComponents = this.template.querySelectorAll(".form-input");
        const inputsArray = inputComponents ? [...inputComponents] : [];
        inputsArray.forEach(inputCmp => inputCmp.reportValidity())
    }

    @api checkValidity(){
        const inputComponents = this.template.querySelectorAll(".form-input");
        //const inputComponents = this.template.querySelectorAll(".form-input");
        const inputsArray = inputComponents ? [...inputComponents] : [];
        return inputsArray.reduce((acc, inputCmp) => {
            inputCmp.reportValidity();
            return acc && inputCmp.checkValidity();
        }, true)
    }

}