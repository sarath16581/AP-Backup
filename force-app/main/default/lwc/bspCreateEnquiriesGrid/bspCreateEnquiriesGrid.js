/*
* @author Jansi(avula.jansirani@crmit.com)
* @date 24/07/2020
* @description common js methods for BSP community
* --------------------------------------- History --------------------------------------------------
* 24/07/2020		avula.jansirani@crmit.com		Initial updation to lightning uplift
* 15/08/2023		hasantha.liyanage@auspost.com.au	added credit claim form tiles
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
		console.log('allConstants');
		console.log(JSON.stringify(data));
		if (data) {
			this.userBillingAccountScope = data;
		} else {
			// this.error = error;
		}
	}

	get isVisibleApCreateEnqiries() {
		console.log('billing account scope:' + this.userBillingAccountScope);
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

	navigationPage;
	enquiryType;
	accountHeldWith;
	handleClick(event) {
		const button = event.detail;
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
		}//To do: add correct URL
		else if (button === 'stDelivery'){
			this.navigationPage = 'BSP_ST_Delivery_Enquiry__c';
		}
		else if (button === 'stPickupBookings'){
			this.navigationPage = 'BSP_ST_Pickup_Booking_Enquiry__c';
		}
		else if (button === 'creditClaimAP'){
			this.navigationPage = 'BSP_Credit_Claim_Form__c';
			this.accountHeldWith = 'ap';
		}
		else if (button === 'creditClaimST'){
			this.navigationPage = 'BSP_Credit_Claim_Form__c';
			this.accountHeldWith = 'st';
		}

		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				name: this.navigationPage
			},
			state: {
				enquiryType: this.enquiryType,
				trackingId : this.trackingId,
				accountHeldWith : this.accountHeldWith,
				userBillingAccountScope : this.userBillingAccountScope
			}
		}, false);
	}
}