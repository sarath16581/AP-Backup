/*
* @author avula.jansirani@auspost.com.au
* @date 2020-11-12
* @channel Business Credit Account
* @tag Business Credit Account
* @description: Reusable Summary header section(for each input step) display. Used in 'Review and submit' step of BCA form
* @changelog
* 2020-01-20 avula.jansirani@auspost.com.au  Created
*
*/
import { LightningElement, api } from 'lwc';

export default class BcaSummaryStepHeader extends LightningElement {

    @api headerLabel;
    @api stepName;

    navigateToEditStep(){
        const c = new CustomEvent("editdetails", { bubbles: true, composed : true, detail: this.stepName });
        this.dispatchEvent(c);
    }

    @api getHTML(){
        return this.template.querySelectorAll('[data-id="bcasummarystepheader"]')[0].innerHTML;
    }

    get showEditIcon(){
        if(this.creditAssessment && this.creditAssessment.showSpinner){
            return false;
        }

        return true;
    }
}