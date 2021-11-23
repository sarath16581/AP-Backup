import { LightningElement, track, api } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
//import getEnquiry from '@salesforce/apex/bspEnquiryDetail.getEnquiry';

export default class BspEnquiryDetailsHeaderSection extends NavigationMixin(LightningElement) {
    @api enq;

    get iconName() {
        if (this.enq.Enquiry_Status__c == "Resolved") return "complete";
        else if (this.enq.Enquiry_Status__c == "Closed") return "complete";
        else if (this.enq.Enquiry_Status__c == "Action required")
            return "warning-alert";
        else if (this.enq.Enquiry_Status__c == "In progress") return "complete";
        else return "complete";
    }

    get iconColor() {
        if (this.enq.Enquiry_Status__c == "Resolved") return "#1D964F";
        else if (this.enq.Enquiry_Status__c == "Closed") return "#777777";
        else if (this.enq.Enquiry_Status__c == "Action required") return "#DC1928";
        else if (this.enq.Enquiry_Status__c == "In progress") return "#3587DA";
        else return "#3587DA";
    }

    get enquiryType() {
        if (this.enq && this.enq.CCUEnquiryType__c) {
            if (this.enq.CCUEnquiryType__c.toLowerCase() == "missing item")
                return "Missing Parcel";
            else if (this.enq.CCUEnquiryType__c.toLowerCase() == "starTrack delivery enquiry")
                return "ST Delivery";
            else if (this.enq.CCUEnquiryType__c.toLowerCase() == "starTrack pickup booking enquiry")
                return "ST Pickup Booking";
            else
                return this.enq.CCUEnquiryType__c;
        } else {
            return '';
        }
    }
}