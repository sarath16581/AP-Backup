/*
/* @author avula.jansirani@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: business credit amount summary details . Used for showing a business credit amount details entered in the input step
                for review before submitting a credit form .
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au
*
*/
import { LightningElement, api } from 'lwc';
import {replaceHTML} from 'c/bcaCommonMethods';

export default class BcaSummaryCreditAmount extends LightningElement {

    @api creditAmount;
    @api stepName;

    get showRequestedAmount() {
        return this.creditAmount && this.creditAmount.acceptAmount == true ? true : false;
    }
    
    @api getHTML() {
        var cmpHtml = this.template.querySelectorAll('[data-id="bcasummaryCreditAmt"]')[0].innerHTML;
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