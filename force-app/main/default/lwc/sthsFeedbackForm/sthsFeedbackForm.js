import { LightningElement } from 'lwc';
import STHS_ICONS from "@salesforce/resourceUrl/STHS_Icons";

export default class SthsTrackingForm extends LightningElement {
    arrowLeft = STHS_ICONS + "/sths_icons/svgs/forms/arrow_left.svg"; //left arrow
    stSupportURL = "https://startrack.com.au/support"; //StarTrack support URL
    showReference = false;
    REFERENCE_REQUIRED_FEEDBACK_TYPES = ['Product & Sales','Pick Up','On-Road','Delivery'];
    get enquiryOptions() {
        return [
            { label: 'Product & Sales', value: 'Product & Sales' },//
            { label: 'Account Management', value: 'Account Management' },
            { label: 'Pick Up', value: 'Pick Up' },//
            { label: 'On-Road', value: 'On-Road' },//
            { label: 'Delivery', value: 'Delivery' },//
            { label: 'Contact Centre', value: 'Contact Centre' },
            { label: 'Billing', value: 'Billing' },
            { label: 'Other', value: 'Other' },
        ];
    }

    //handle enquiry dropdown change
    handleEnquiryChange(event){
        const feedbackType = event.target.value;
        if(this.REFERENCE_REQUIRED_FEEDBACK_TYPES.includes(feedbackType)) {
            this.showReference = true;
        } else {
            this.showReference = false;
        }
    }

    handleInputChange(event) {
        this.formData = De(De({}, this.formData), {}, {
            [event.target.dataset.fieldName]: event.detail.value
        })
    }

    handleSubmitClick(event){
        this.validateForm() && console.log(JSON.parse(JSON.stringify(this.formData)))
    }

    validateForm() {
        let elements = this.template.querySelectorAll('[data-form="feedback"]');
        //return o.validateInputComponents([...elements], !0)
    }
}