/*
/* @author avula.jansirani@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: List of Business reference summary details . Used for showing the Business reference details entered in the input step
                for review before submitting a credit form submissionts.
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au
*
*/
import { LightningElement, api } from 'lwc';
import {replaceHTML} from 'c/bcaCommonMethods';

export default class BcaSummaryBusinessRefs extends LightningElement {

    @api businessRefs;
    @api stepName;

    @api getHTML() {
        var cmpHtml = this.template.querySelectorAll('[data-id="businessRefDetails"]')[0].innerHTML;
        
        //--getting header cmp HTML
        cmpHtml = replaceHTML(cmpHtml,
                             this.template.querySelector('c-bca-summary-step-header').getHTML(),
                             '<c-bca-summary-step-header', '</c-bca-summary-step-header>');

        // getting data rows HTML
        for (var i = 0; i < this.template.querySelectorAll('c-bca-summary-each-business-ref-details').length; i++) {
            cmpHtml = replaceHTML(cmpHtml,
                                  this.template.querySelectorAll('c-bca-summary-each-business-ref-details')[i].getHTML(),
                                  '<c-bca-summary-each-business-ref-details', '</c-bca-summary-each-business-ref-details>');
            
        }

      return cmpHtml;
    }
    

}