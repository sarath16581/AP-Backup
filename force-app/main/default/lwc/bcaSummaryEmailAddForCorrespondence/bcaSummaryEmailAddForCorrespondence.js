/*
/* @author avula.jansirani@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Email address for correspondence summary details . Used for showing a Email address for correspondence details entered in the input step
                for review before submitting a credit form.
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au
*
*/
import { LightningElement, api } from 'lwc';
import {replaceHTML} from 'c/bcaCommonMethods';

export default class BcaSummaryEmailAddForCorrespondence extends LightningElement {
    @api emailForCorrespondence;
    @api stepName;
    
    get email(){
        return this.emailForCorrespondence.email ? this.emailForCorrespondence.email : '';
    }

    @api getHTML() {
        var cmpHtml = this.template.querySelectorAll('[data-id="bcaSummaryEmailForCorrespondence"]')[0].innerHTML;
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