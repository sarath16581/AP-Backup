/*
/* @author avula.jansirani@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: List of Director/Partner summary details . Used for showing list of director details details entered in the input step
                for review before submitting a credit form.
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au
*
*/
import { LightningElement, api } from 'lwc';
import {replaceHTML} from 'c/bcaCommonMethods';
import {getDirectorLabel} from 'c/bcaStepBase';

export default class BcaSummaryDirectorDetails extends LightningElement {
    @api directorDetails;
    @api stepName;
    @api entityTypeGroup;
    @api trustType;

    navigateToStep(){
        const c = new CustomEvent("editdetails", { detail: "directorStep" });
        this.dispatchEvent(c);
    }

    get labelHeader(){
        return getDirectorLabel(this.entityTypeGroup, this.trustType) + ' details';
    }

    get label(){
        return getDirectorLabel(this.entityTypeGroup, this.trustType);
    }

    get showHeader(){
        return this.directorDetails && this.directorDetails.length > 1; // check if needs other logic here than length
    }

    get directorsSize(){
        return this.directorDetails ? this.directorDetails.length : '0';
    }

    @api getHTML() {
        var cmpHtml = this.template.querySelectorAll('[data-id="directorDetail"]')[0].innerHTML;
        //--getting header cmp HTML
        cmpHtml = replaceHTML(cmpHtml,
                             this.template.querySelector('c-bca-summary-step-header').getHTML(),
                             '<c-bca-summary-step-header', '</c-bca-summary-step-header>');

        // getting data rows HTML
        for (var i = 0; i < this.template.querySelectorAll('c-bca-summary-each-director-details').length; i++) {
            cmpHtml = replaceHTML(cmpHtml,
                                  this.template.querySelectorAll('c-bca-summary-each-director-details')[i].getHTML(),
                                  '<c-bca-summary-each-director-details', '</c-bca-summary-each-director-details>');
            ;
        }

      return cmpHtml;
    }
    
    
}