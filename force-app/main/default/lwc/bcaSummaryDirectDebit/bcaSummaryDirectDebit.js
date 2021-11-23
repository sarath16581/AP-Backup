/*
/* @author avula.jansirani@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Direct debit summary details . Used for showing  Direct debit details entered in the input step
                for review before submitting a credit form submissionts.
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au
*
*/
import { LightningElement, api } from 'lwc';
import {replaceHTML} from 'c/bcaCommonMethods';

export default class BcaSummaryDirectDebit extends LightningElement {
    @api stepName;
    @api directDebit;

    @api getHTML() {
        var cmpHtml = this.template.querySelectorAll('[data-id="bcasummaryDD"]')[0].innerHTML;
        
        //-- replace header cmp html
        cmpHtml = replaceHTML(cmpHtml,
            this.template.querySelector('c-bca-summary-step-header').getHTML(),
            '<c-bca-summary-step-header', '</c-bca-summary-step-header>');
        
            //-- replace body rows cmps html
        for (var i = 0; i < this.template.querySelectorAll('c-bca-summary-row').length; i++) {
            cmpHtml = replaceHTML(cmpHtml,
                this.template.querySelectorAll('c-bca-summary-row')[i].getHTML(),
                '<c-bca-summary-row', '</c-bca-summary-row>');
            ;
        }

        return cmpHtml;
    }
}