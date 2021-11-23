/*
/* @author avula.jansirani@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Business Type summary details . Used for showing a single  Business type details entered in the input step
                for review before submitting a credit form .
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au
*
*/
import { LightningElement, api } from 'lwc';
import { getDirectorLabel, isToDisplayNoOfDirectors } from 'c/bcaStepBase';
import {replaceHTML} from 'c/bcaCommonMethods';

export default class BcaSummaryBusinessTypeDetails extends LightningElement {

    @api businessTypeDetails;
    @api stepName;
    @api entityTypeGroup;
    @api trustType;


    get btIndustryDivision() {
        return this.businessTypeDetails.industryDivision ? (this.businessTypeDetails.industryDivision) : '';
    }

    get btIndustryClass() {
        return this.businessTypeDetails.industryClass ? this.businessTypeDetails.industryClass : '';
    }

    get btNoOfDirectors() {
        return this.businessTypeDetails.noOfDirectors ? this.businessTypeDetails.noOfDirectors : '';
    }

    
    //getter to display 'no of directors' label
    get noOfDirectorsLabel() {
        return 'No. of '.concat(getDirectorLabel(this.entityTypeGroup, this.trustType).toLowerCase(), 's') ;//getNOfDirectorsLabel(this.entityTypeGroup);
    }

    //getter to display 'no of directors or not'
    get isDisplayNoOfDirectors() {
        return isToDisplayNoOfDirectors(this.entityTypeGroup, this.trustType);
    }

    @api getHTML() {
        var cmpHtml = this.template.querySelectorAll('[data-id="bcasummaryBT"]')[0].innerHTML;
        cmpHtml = replaceHTML(cmpHtml,
            this.template.querySelector('c-bca-summary-step-header').getHTML(),
            '<c-bca-summary-step-header', '</c-bca-summary-step-header>');

        for (var i = 0; i < this.template.querySelectorAll('c-bca-summary-row').length; i++) {
            cmpHtml = replaceHTML(cmpHtml,
                this.template.querySelectorAll('c-bca-summary-row')[i].getHTML(),
                '<c-bca-summary-row', '</c-bca-summary-row>');
            ;
        }

        return cmpHtml;
    }

}