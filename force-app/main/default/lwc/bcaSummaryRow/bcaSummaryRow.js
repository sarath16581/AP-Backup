/*
/* @author avula.jansirani@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: reusable summary table row for Business Credit Account form
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au
* 2021-07-13 avula.jansirani@auspost.com.au   added isDataIsAccNumber and used in getHTML() to mask acc number in pdf
*
*/
import { LightningElement, api, track } from 'lwc';
import {replaceHTML} from 'c/bcaCommonMethods';

export default class BcaSummaryRow extends LightningElement {

    @api label;
    @api value;
    @api type = 'text';

    @api abnStatusDate;

    @track multiValsArray=[];

    get isDataIsStringType() {
        return this.type ? (this.type == "text" ? true : false) : false;
    }

    get isDataIsDateType() {
        return this.type ? (this.type == "date" ? true : false) : false;
    }

    get isDataIsDateTimeType() {
        return this.type ? (this.type == "dateTime" ? true : false) : false;
    }

    get isDataIsCurrencyType(){
        return this.type ? (this.type == "currency" ? true : false) : false;
    }

    get isMultiValues(){
        return this.type ? (this.type == "multiSelect" ? true : false) : false;
    }

    get isDataIsABNStatusType() {
        return this.type ? (this.type == "abnStatus" ? true : false) : false;
    }

    get isDataIsAccNumber() {
        return this.type ? (this.type == "accountNumber" ? true : false) : false;
    }

    get multiValues() {
        if (Array.isArray( this.value))
            this.multiValsArray = this.value;
        return this.multiValsArray
    }

    @api getHTML() {
        var rowHTML = this.template.querySelectorAll('[data-id="bcasummaryrow"]')[0].innerHTML;

        if (rowHTML.indexOf("<lightning-formatted-date-time") != -1 && this.isDataIsABNStatusType)  //ABN ststus date, replace 
            rowHTML = replaceHTML(rowHTML,
                this.abnStatusDate,
                '<lightning-formatted-date-time', '</lightning-formatted-date-time>');

        else if (this.isDataIsCurrencyType)// Replace with currency val
            rowHTML = replaceHTML(rowHTML,
                 this.value,
                '<lightning-formatted-number', '</lightning-formatted-number>');

        else if (this.isDataIsDateType || this.isDataIsDateTimeType)// Replace .date' or 'datetime' lwc standard element
            rowHTML = replaceHTML(rowHTML,
                this.value,
                '<lightning-formatted-date-time', '</lightning-formatted-date-time>');

        else if (this.isDataIsAccNumber)//mask account number
            rowHTML = rowHTML.replace(this.value, this.value.replace(/\d(?=\d{4})/g, "*"));
   
        return rowHTML;
    }
}