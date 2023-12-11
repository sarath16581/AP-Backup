/**
 * Created by vcheng on 19/08/2020.
 * --------------------------------------- History --------------------------------------------------
* 07/12/2023		thang.nguyen231@auspost.com.au		added adobe analytics details
 */

import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { reportAllValidity, checkAllValidity, checkCustomValidity, topGenericErrorMessage} from 'c/bspCommonJS';
import createEnquiryAusPost from '@salesforce/apex/bspEnquiryUplift.createEnquiryAusPost';

//adobe analytics
import { analyticsTrackPageLoad } from 'c/adobeAnalyticsUtils';

export default class bspFormGeneral extends NavigationMixin(LightningElement) {

	// spinner control
	@track showSpinner = false;
	// user object
	@track currentUser = {};
	// the temp Case
	@track tempCase = {};
	@track disableSubmit = false;
	@track errorMessage;
	spinnerAltText = 'loading';
	successCreation = false;

	//analytics variables
	pageName = 'auspost:bsp:ap:generalenquiry';	

	onChangeField(event) {
		const field = event.target.dataset.id;
		switch (field) {
			case 'yourReference':
				this.tempCase.CCUYourReference__c = event.detail.value;
				break;
			case 'description':
				this.tempCase.Description = event.detail.value;
				break;
		}
		this.checkValidationOfField(field);
	}

	handleFocusOut(event) {
		this.checkValidationOfField(event.target.dataset.id);
	}

	checkValidationOfField(datasetId) {
		const inputCmp = this.template.querySelectorAll('[data-id="' + datasetId + '"]');
		//--Checking the custom validation on change of a field value
		if (inputCmp != undefined && inputCmp.length > 0) {
			checkCustomValidity(inputCmp[0]);
		}
	}

	onClickCancel() {
		this.navigateHome();
	}

	//[To check, can move this to common JS]
	navigateHome() {
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				name: 'Home'
			}
		});
	}

	navigateToCaseDetails(event)
	{
		this[NavigationMixin.GenerateUrl]({
			type: 'comm__namedPage',
			attributes: {
				name: 'BSP_Enquiry_Details__c'
			},
			state: {
				enquiryNumber: this.tempCase.CaseNumber
			}
		}).then(generatedUrl => {
			window.open(generatedUrl, "_blank");
		});
	}


	onSubmitRequest(event) {
		
		// initialise
		this.tempCase.CCUEnquiryType__c = 'General Enquiry';
		console.debug(JSON.stringify(this.tempCase));

		const inputComponents = this.template.querySelectorAll('[data-validate="doValidate"]');
		const allValid = checkAllValidity(inputComponents);
		if (allValid) {
			this.showSpinner = true;
			this.disableSubmit = true;
			
			createEnquiryAusPost({
				enq: this.tempCase,
				uploadedFiles: this.uploadedFiles
			}).then(result => {
				console.debug(result);
				if(result.status == 'error')
				{
					this.errorMessage = result.message;
				}
				else
				{
					this.tempCase = result.enquiry;
					this.successCreation = true;
				}
				this.showSpinner = false;
			})
			.catch(error => {
				console.error('error occured');
				console.error(error);
				this.showSpinner = false;
				this.disableSubmit = false;
			});
		} else {
			this.errorMessage = topGenericErrorMessage;
		}
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