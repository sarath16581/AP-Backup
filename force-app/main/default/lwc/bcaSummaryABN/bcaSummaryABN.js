/*
/* @author avula.jansirani@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: ABN summary details . Used for showing a ABN details entered in the input step
                for review before submitting a credit form.
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au
*
*/
import { LightningElement, api } from 'lwc';
import {replaceHTML} from 'c/bcaCommonMethods';

export default class BcaSummaryABN extends LightningElement {
    @api abnDetails;
    @api stepName;
    @api tradingNameManualEntryConst;

    @api reqFrom = 'ABN';

    get headerName() {
        if (this.reqFrom == 'ABN')
            return 'Business registration details';
        else
            return 'Trustee company details';
    }

    get AbnOrAcnLabel() {
        if (this.reqFrom == 'ABN')
            return 'ABN';
        else
            return 'Trustee ACN';
    }

    get AbnOrAcnStatus() {
        if (this.reqFrom == 'ABN')
            return 'ABN status';
        else
            return 'ACN status';
    }


    get tradingName() {
        if (this.abnDetails.tradingName != this.tradingNameManualEntryConst)
            return this.abnDetails.tradingName;
        else
            return this.abnDetails.otherTradingName;
    }

    @api getHTML() {
        var cmpHtml = this.template.querySelectorAll('[data-id="bcasummaryabn"]')[0].innerHTML;
        //--getting header cmp HTML   //[Jansi: can we move this code to reusable for all other summary cmps?? the summary cmps are not extending bcaStepBase]
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