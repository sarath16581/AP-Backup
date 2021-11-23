/*
/* @author avula.jansirani@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Business contact person summary details . Used for showing Business contact person details entered in the input step
                for review before submitting a credit form .
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au
*
*/
import { LightningElement, api } from 'lwc';
import { formatPhone, replaceHTML} from 'c/bcaCommonMethods';


export default class BcaSummaryBusinessContactPerson extends LightningElement {
    @api businessContact;
    @api stepName;

    get showDetail(){   //[Jansi: added : update this once you get correct data for selected director]
        return this.businessContact ? true : false;
    }

    get getIndex(){//[Jansi: added : update this once you get correct data for selected director]
        return this.businessContact.index ? this.businessContact.index : '';
    }

    get name() {
        return this.businessContact.firstName +
            (this.businessContact.middleName ? ' ' + this.businessContact.middleName : '') + ' '
            + this.businessContact.lastName;
    }

    get isContactPersonIsSomeOneElse(){
        return  this.businessContact.index &&  this.businessContact.index == '_someoneElse';
    }

    get formattedPhone() {
        if (this.businessContact.phone)
            return formatPhone(this.businessContact.phone);
        else
            return '';
    }

    @api getHTML() {
        var cmpHtml = this.template.querySelectorAll('[data-id="bcaContact"]')[0].innerHTML;
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