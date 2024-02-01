/*
* --------------------------------------- History --------------------------------------------------
* 07/12/2023		thang.nguyen231@auspost.com.au		added adobe analytics details
*/
import { LightningElement, wire, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from 'lightning/navigation';
import { checkAllValidity, topGenericErrorMessage, valueMissingErrorMsg, scrollToHeight } from 'c/bspCommonJS';

import createPickUpBookingEnquiryStarTrack from '@salesforce/apex/bspEnquiryUplift.createPickUpBookingEnquiryStarTrack';
import getSTPickupBookingRefRecordType from '@salesforce/apex/bspEnquiryUplift.getSTPickupBookingRefRecordType';
import PURPOSE_FIELD from '@salesforce/schema/Case.Call_Purpose__c';

//adobe analytics
import { analyticsTrackPageLoad } from 'c/adobeAnalyticsUtils';

export default class BspFormSTPickupBookingEnquiry extends NavigationMixin(LightningElement) {

	billingAccount;
	recordTypeId;
	purposePicklistVales;
	errorMessage;
	isLoading = false;
	successCreation = false;
	caseNumber;
	requiredValMissingErrorMsg = valueMissingErrorMsg;
	submitClicked = false;
	@track enquiry = {
		Subject: '',
		Call_Purpose__c: '',
		Description: '',
		CCUEnquiryType__c: 'StarTrack Pickup Booking Enquiry',
		Pickup_Booking_Reference__c: ''
	};

	//analytics variables
	pageName = 'auspost:bsp:st:stpickupbookings';

	renderedCallback() {
		if(this.errorMessage && this.submitClicked) {
			this.submitClicked = false;
			scrollToHeight(this.template.querySelectorAll('[data-id="error"]'));
		}   
	}

	/**
	 * get recordType
	 */
	@wire(getSTPickupBookingRefRecordType) getSTDeliveyEnquiryRecordType({ error, data }) 
	{
		if (data)
			this.recordTypeId = data;
	}

	/**
	 * Get picklist values
	 */
	@wire(getPicklistValues, {
		recordTypeId: '$recordTypeId',
		fieldApiName: PURPOSE_FIELD
	})
	wiredPicklistVals({ error, data }) {
		if (data)
			this.purposePicklistVales = data.values;
	}

	/**
	 * Change handler
	 **/
	handleChange(event) {
		let tempEnq = Object.assign({}, this.enquiry);
		const field = event.target.dataset.id;

		if (field === 'subject')
			tempEnq.Subject = event.target.value;
		else if (field === 'description')
			tempEnq.Description = event.target.value;
		else if (field === 'purpose')
			tempEnq.Call_Purpose__c = event.target.value;
		else if (field === 'pickUpBookingRefNumber')
			tempEnq.Pickup_Booking_Reference__c = event.target.value.trim();
		else if (field === 'billingAccount')
			this.billingAccount = event.target.value.trim();
		this.enquiry = tempEnq;
	}

	/**
	 * handle submit
	 **/
	handleSubmit() {
		this.errorMessage = null;
		this.submitClicked = true;
		const allValid = checkAllValidity(this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox'), false);

		if (allValid) {
			this.isLoading = true;

			createPickUpBookingEnquiryStarTrack({
				billingAccountNumber: this.billingAccount,
				enqObj: this.enquiry,
				uploadedFiles: this.uploadedFiles
			}).then(result => {
				// alert(result);
				this.successCreation = true;;
				this.caseNumber = result;
				this.isLoading = false;
			}).catch(error => {
				// alert(JSON.stringify(error));
				this.isLoading = false;
				this.errorMessage = error.body.message;
			});
		} else
			this.errorMessage = topGenericErrorMessage;
	}

	/**
	 * handle Cancel
	 **/
	handleCancel() {
		this.navigateHome();
	}

	/**
	 * Navigation to home page
	 **/
	//[To check, can move this to common JS]
	navigateHome() {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				name: 'Home'
			}
		});
	}
	/**
	 * fileupload eventHandler
	 **/
	onFileUploadHandler(event) {
		this.uploadedFiles = event.detail;
	}

	navigateToCaseDetail(event) {
		//navigateToEnquiryDetail(this.caseNumber);

		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				name: 'BSP_Enquiry_Details__c'
			},
			state: {
				enquiryNumber: this.caseNumber
			}
		});
	}

	connectedCallback() {
		this.pushPageAnalyticsOnLoad();
	}

	pushPageAnalyticsOnLoad(){
		const pageData = {
			sitePrefix: 'auspost:bsp',
			pageAbort: 'true',
			pageName: this.pageName
		};
		analyticsTrackPageLoad(pageData);
	}	
}