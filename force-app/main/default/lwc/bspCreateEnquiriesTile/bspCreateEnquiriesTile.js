/*
 * @author Ankur Gandhi(ankur.gandhi@auspost.com.au)
 * @date 13/08/2020
 * @description Create enquiry time component functions
 * --------------------------------------- History --------------------------------------------------
	13/08/2020		ankur.gandhi@auspost.com.au	Initial updation to lightning uplift
*/

import { LightningElement, track, api } from 'lwc'

export default class BspCreateEnquiriesTile extends LightningElement {

    @api iconName = '';
    @api buttonLabel = '';
    @api tileSubText = '';
    @api tileHeaderText = '';
    @api buttonDataId = '';
    @api left = false;

    divCssClass = 'slds-col slds-wrap slds-grid slds-size_1-of-1 slds-medium-size_1-of-2 slds-large-size_1-of-2 slds-m-bottom_small slds-grid_align-spread enquiry-card brand-secondary-button';
    divCssRightMedium = ' slds-m-right_medium ';

    handleClick(event){
        const createEnquiryEvent = new CustomEvent('createenquiryevent', {
            detail: event.target.dataset.id
        });
        this.dispatchEvent(createEnquiryEvent);
    }

    get divCss(){
        return (this.left ? this.divCssClass + this.divCssRightMedium : this.divCssClass);
    }

}