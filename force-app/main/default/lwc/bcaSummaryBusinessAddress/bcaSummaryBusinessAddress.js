/*
/* @author avula.jansirani@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Business address summary details . Used for showing business address details entered in the input step
                for review before submitting a credit form.
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au
*
*/
import { LightningElement, api } from 'lwc';
import {replaceHTML, formatAddress} from 'c/bcaCommonMethods';

export default class BcaSummaryBusinessAddress extends LightningElement {

    @api businessAddressDetails;
    @api stepName;

    get bdStreetAddress() {
        return formatAddress(this.businessAddressDetails.streetAddress);
    }

    get bdPostalAddress() {
        if (this.businessAddressDetails.isBusNStreetAddressSame == 'no')
            return formatAddress(this.businessAddressDetails.postalAddress);
        else
            return this.bdStreetAddress; //This will cover undefined and yes scenario
    }


    @api getHTML() {
        var cmpHtml = this.template.querySelectorAll('[data-id="bcasummarybd"]')[0].innerHTML;
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