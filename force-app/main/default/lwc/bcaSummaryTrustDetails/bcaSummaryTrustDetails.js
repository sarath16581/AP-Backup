/*
* @author avula.jansirani@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Truestee summary details . Used for showing Truestee details entered in the input step
                for review before submitting a credit form .
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au  Created
*
*/
import { LightningElement, api } from 'lwc';
import {replaceHTML} from 'c/bcaCommonMethods';

export default class BcaSummaryTrustDetails extends LightningElement {
    @api stepName;
    @api trustFiles;
    
    get files(){
        return this.trustFiles;
    }

    @api getHTML() {
        var cmpHtml = this.template.querySelectorAll('[data-id="bcasummaryTrustDocs"]')[0].innerHTML;
      
        //header cmp html
        cmpHtml = replaceHTML(cmpHtml,
            this.template.querySelector('c-bca-summary-step-header').getHTML(),
            '<c-bca-summary-step-header', '</c-bca-summary-step-header>');

            //row cmps HTML
        for (var i = 0; i < this.template.querySelectorAll('c-bca-summary-row').length; i++) {
            cmpHtml = replaceHTML(cmpHtml,
                this.template.querySelectorAll('c-bca-summary-row')[i].getHTML(),
                '<c-bca-summary-row', '</c-bca-summary-row>');
            ;
        }

        return cmpHtml;
    }
}