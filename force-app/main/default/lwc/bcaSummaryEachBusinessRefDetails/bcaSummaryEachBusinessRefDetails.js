/*
/* @author avula.jansirani@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Single Business reference summary details . Used for showing a single Business reference details entered in the input step
                for review before submitting a credit form submissionts.
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au  Created
*
*/

import { LightningElement, api } from 'lwc';
import { formatPhone, replaceHTML} from 'c/bcaCommonMethods';

export default class BcaSummaryEachBusinessRefDetails extends LightningElement {
    @api businessRef;

   /* get header(){
        return 'Business reference' + ' ' + this.businessRef.index;
    }*/

    get label(){
        return 'Reference '+this.businessRef.index;
    }

    get value(){
        let businessName = this.businessRef.businessName;
        let nameAndPosition = this.businessRef.fullName+' - '+this.businessRef.positionTitle;
        let phone = this.businessRef.phone ? formatPhone(this.businessRef.phone) :'';
        return [{"val":businessName},{"val":nameAndPosition},{"val":phone}];//businessName+'~~~'+nameAndPosition+'~~~'+formatPhone(phone); // assume all fields are required in input step
    }

    @api getHTML() {
        var cmpHtml = this.template.querySelectorAll('[data-id="businessReference"]')[0].innerHTML;

        // getting data rows HTML
        for (var i = 0; i < this.template.querySelectorAll('c-bca-summary-row').length; i++) {
            cmpHtml = replaceHTML(cmpHtml,
                this.template.querySelectorAll('c-bca-summary-row')[i].getHTML(),
                '<c-bca-summary-row', '</c-bca-summary-row>');

        }

        return cmpHtml;
    }
}