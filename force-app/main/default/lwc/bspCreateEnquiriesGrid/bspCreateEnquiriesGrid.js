/*
 * @author Jansi(avula.jansirani@crmit.com)
 * @date 24/07/2020
 * @description common js methods for BSP community
 * --------------------------------------- History --------------------------------------------------
    24/07/2020		avula.jansirani@crmit.com		Initial updation to lightning uplift
    25-11-2020    avula.jansirani@auspost.com.au       removed console.log lines
*/

import { LightningElement ,wire, api} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getUserBillingAccountScope from '@salesforce/apex/bspEnquiryUplift.getUserBillingAccountScope'

export default class BspCreateEnquiriesGrid extends NavigationMixin(LightningElement) {

    @api trackingId;  //Jansi added
    accordianSection = '';
    userBillingAccountScope;

    @wire(getUserBillingAccountScope)
    allConstants({
        error,
        data
    }) {
         if (data) {
            this.userBillingAccountScope = data;
        } else {
            // this.error = error;
        }
    }

    get isVisibleApCreateEnqiries() {
        if (this.userBillingAccountScope == 'ALL' || this.userBillingAccountScope == 'AP')
            return true;
        else
            return false;
    }

    get isVisibleStCreateEnqiries() {
        if (this.userBillingAccountScope == 'ALL' || this.userBillingAccountScope == 'ST')
            return true;
        else
            return false;
    }

    handleClick(event) {
        const button = event.detail;
        let navigationPage;
        let enquiryType;

        if (button === 'lateOrMissing'){
            this.navigationPage = 'BSP_AP_Enquiry_Form__c';
        }   
        else if (button === 'returnToSender'){
            this.navigationPage = 'BSP_AP_Enquiry_Form__c'; //To do: add correct URL
            this.enquiryType = 'rts';
        }   
        else if (button === 'deliveryIssue'){
            this.navigationPage = 'BSP_AP_Enquiry_Form__c'; //To do: add correct URL
            this.enquiryType = 'delivery';
        }   
        else if (button === 'generalEnquiry'){
            this.navigationPage = 'BSP_Enquiry_General__c';
        }    //To do: add correct URL
        else if (button === 'stDelivery'){
            this.navigationPage = 'BSP_ST_Delivery_Enquiry__c';
        }    
        else if (button === 'stPickupBookings'){
            this.navigationPage = 'BSP_ST_Pickup_Booking_Enquiry__c'; 
        }   
        
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: this.navigationPage
            },
            state: { 
                enquiryType: this.enquiryType,
                trackingId : this.trackingId
            }
        }, false);
    }
}