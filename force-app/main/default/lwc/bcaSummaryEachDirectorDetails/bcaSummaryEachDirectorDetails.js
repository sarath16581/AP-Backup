/*
/* @author avula.jansirani@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Single director summary details . Used for showing a single director details entered in the input step
                for review before submitting a credit form.
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au
*
*/

import { LightningElement, api } from 'lwc';
import {replaceHTML, formatPhone, formatAddress} from 'c/bcaCommonMethods';

export default class BcaSummaryEachDirectorDetails extends LightningElement {
    @api director;
    @api directorsSize;
    @api showHeader = false;
    @api headerLabel = false;

    get currentResidentialAddress() {
        var address = '';
        if (this.director.currentResidentialAddress) {
            address = formatAddress(this.director.currentResidentialAddress);
        }
        return address;
    }

    get prevResidentialAddress() {
        var address = '';
        if (this.director.previousResidentialAddress) {
            address = formatAddress(this.director.previousResidentialAddress);
        }
        return address;
    }

    get directorSubHeaderLabel(){
        if(this.directorsSize > 1)
           return this.headerLabel + ' ' + this.director.index + ' of '+this.directorsSize;
        else
        return  this.headerLabel;
    }

    get name(){
        return  this.director.firstName + ' '+(this.director.middleName ? this.director.middleName+' ':'') +this.director.lastName;
    }

    get showPreviousName(){
        return this.director.knownByOtherName == 'true' ? true : false;
    }
    /*get prviousName(){
        return  this.director.otherFirstName + ' '+this.director.otherMiddleName ? this.director.otherMiddleName+' ':'' +this.director.otherLastName;
    }*/

    get showPreviousAddress(){
        return this.director.timeAtAddress === 'Less than 12 months';
    }

    get formattedPhone() {
        if (this.director.phone)
            return formatPhone(this.director.phone);
        else
            return '';
    }

    @api getHTML() {
        var cmpHtml = this.template.querySelectorAll('[data-id="director"]')[0].innerHTML;

        if (cmpHtml.indexOf("<c-bca-summary-step-header") != -1)
            //--getting header cmp HTML
            cmpHtml = replaceHTML(cmpHtml,
                this.template.querySelector('c-bca-summary-step-header').getHTML(),
                '<c-bca-summary-step-header', '</c-bca-summary-step-header>');

        // getting data rows HTML
        for (var i = 0; i < this.template.querySelectorAll('c-bca-summary-row').length; i++) {
            cmpHtml = replaceHTML(cmpHtml,
                                  this.template.querySelectorAll('c-bca-summary-row')[i].getHTML(),
                                  '<c-bca-summary-row', '</c-bca-summary-row>');
            ;
        }

      return cmpHtml;
    }
    
}