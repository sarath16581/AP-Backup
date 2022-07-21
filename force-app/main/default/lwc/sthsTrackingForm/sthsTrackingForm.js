import { LightningElement } from 'lwc';
import STHS_ICONS from "@salesforce/resourceUrl/STHS_Icons";

export default class SthsTrackingForm extends LightningElement {
    arrowLeft = STHS_ICONS + "/sths_icons/svgs/forms/arrow_left.svg"; //left arrow 
    stSupportURL = "https://startrack.com.au/support"; //StarTrack support URL

    get enquiryOptions() {
        return [
            { label: 'Track & Trace', value: 'Track & Trace' },
            { label: 'Pick-ups', value: 'Pick-ups' },
            { label: 'Missed delivery', value: 'Missed delivery' },
            { label: 'Other', value: 'Other' }
        ];
    }

    //handle enquiry dropdown change
    handleEnquiryChange(event){

    }
}