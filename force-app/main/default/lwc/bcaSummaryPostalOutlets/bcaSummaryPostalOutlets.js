/*
* @author avula.jansirani@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Preferred postal outlets summary details . Used for showing Preferred postal outlets details entered in the input step
                for review before submitting a credit form.
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au
*
*/
import { LightningElement, api } from 'lwc';
import {replaceHTML} from 'c/bcaCommonMethods';

export default class BcaSummaryPostalOutlets extends LightningElement {
    @api stepName;
    @api postalOutlets;

    @api getHTML() {
        var cmpHtml = this.template.querySelectorAll('[data-id="postalOutlets"]')[0].innerHTML;
        
        //--getting header cmp HTML
        cmpHtml = replaceHTML(cmpHtml,
                             this.template.querySelector('c-bca-summary-step-header').getHTML(),
                             '<c-bca-summary-step-header', '</c-bca-summary-step-header>');

        // getting data rows HTML
        for (var i = 0; i < this.template.querySelectorAll('c-bca-summary-each-postal-outlet-details').length; i++) {
            cmpHtml = replaceHTML(cmpHtml,
                                  this.template.querySelectorAll('c-bca-summary-each-postal-outlet-details')[i].getHTML(),
                                  '<c-bca-summary-each-postal-outlet-details', '</c-bca-summary-each-postal-outlet-details>');
            
        }

      return cmpHtml;
    }

}