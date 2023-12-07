/** 
--------------------------------------- History --------------------------------------------------
29.10.2020	swati.mogadala@auspost.com.au	REQ2316589- Removed 3 Call purpose picklist values on BSP portal
07.12.2023	thang.nguyen231@auspost.com.au	added adobe analytics details
*/
import { LightningElement, wire, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { checkAllValidity, valueMissingErrorMsg, topGenericErrorMessage, scrollToHeight } from 'c/bspCommonJS';

import getSTDeliveyEnquiryRecordType from '@salesforce/apex/bspEnquiryUplift.getSTDeliveyEnquiryRecordType';
import PURPOSE_FIELD from '@salesforce/schema/Case.Call_Purpose__c';
import searchConsignmentStarTrack from '@salesforce/apexContinuation/bspEnquiryUplift.searchConsignmentStarTrack';
import createDeliveryEnquiryStarTrack from '@salesforce/apexContinuation/bspEnquiryUplift.createDeliveryEnquiryStarTrack';
import validateConsignmentNumber from '@salesforce/apex/bspEnquiryUplift.validateConsignmentNumber';
import retrieveBspCommunityURL from '@salesforce/apex/bspBaseUplift.retrieveCommunityURL';

//adobe analytics
import { analyticsTrackPageLoad } from 'c/adobeAnalyticsUtils';

export default class BspFormSTDeliveryEnquiry extends NavigationMixin(LightningElement) {

	@track enquiry = {
		Subject: '',
		Call_Purpose__c: '',
		Description: '',
		CCUEnquiryType__c: 'StarTrack Delivery Enquiry'
	};
	@track uploadedFiles = [];
	@track STDeliveryEnquiryResultsWapper;

	// page parameters
	currentPageReference;

	recordTypeId;
	purposePicklistVales;
	consignmentNumber;
	errorMessage;
	isLoading = false;
	successCreation = false;
	caseNumber;
	isConsinMentNumIsValid = true;
	prevConsignmentNuber;
	requiredValMissingErrorMsg = valueMissingErrorMsg;
	existingCasesErrorMsg = '';
	communityURL = '';
	renderLoadCount = 0;
	submitClicked = false;

	//analytics variables
	pageName = 'auspost:bsp:st:stdeliveries';	

	@wire(CurrentPageReference)
	setCurrentPageReference(currentPageReference) {
		this.currentPageReference = currentPageReference;
		this.consignmentNumber = this.currentPageReference.state.trackingId;
	}

	renderedCallback() {
		if (this.currentPageReference && this.currentPageReference.state.trackingId && this.renderLoadCount == 0) {
			this.callContinuation(true, false);
			this.renderLoadCount = this.renderLoadCount + 1;
		}

		if((this.errorMessage || this.existingCasesErrorMsg ||
			(this.STDeliveryEnquiryResultsWapper && this.STDeliveryEnquiryResultsWapper.errorMessage))
			&& this.submitClicked) {
			this.submitClicked = false;
			scrollToHeight(this.template.querySelectorAll('[data-id="error"]'));
		} 
	}

	async connectedCallback() {
		try {
			this.communityURL = await retrieveBspCommunityURL();
			this.pushPageAnalyticsOnLoad();
		} catch (er) {
			console.error(er)
		}
	}

	pushPageAnalyticsOnLoad(){
		const pageData = {
			sitePrefix: 'auspost:bsp',
			pageAbort: 'true',
			pageName: this.pageName
		};
		analyticsTrackPageLoad(pageData);
	}	

	get displayDeliveryStatus(){
		return this.STDeliveryEnquiryResultsWapper ? (this.STDeliveryEnquiryResultsWapper.article ? true : false) : false;
	}

		/**
	 * get recordType
		 */
	@wire(getSTDeliveyEnquiryRecordType) getSTDeliveyEnquiryRecordType({ error, data }) { //TO Do: can do with 'getObjectInfo'?
		if (data)
			this.recordTypeId = data;
	}

	/**
	 * Get picklist values
	 */
	@wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: PURPOSE_FIELD })
	wiredPicklistVals({ error, data }) {
		if (data) {
			//-- remove 'Late Delivery','Depot Created' and 'Not Case Related' values
			this.purposePicklistVales = data.values.filter(function (item) {
				return item.label !== 'Late Delivery' && item.label !== 'Depot Created' && item.label !== 'Not Case Related' && item.label !== 'Controlled Returns' && item.label !=='Account Manager Support'  && item.label !== 'Card left - No Attempt Made';
			});;
		}

	}

	/**
	 * handle change of input fields
	 */
	handleChange(event) {
		let tempEnq = Object.assign({}, this.enquiry);
		const field = event.target.dataset.id;
		if (field === 'subject')
			tempEnq.Subject = event.target.value;
		else if (field === 'description')
			tempEnq.Description = event.target.value;
		else if (field === 'purpose')
			tempEnq.Call_Purpose__c = event.target.value;
		else if (field === 'consignmentNumber') {
			this.consignmentNumber = event.target.value.trim();
			this.validateConsignmentNumber();
			// this.resetSTSearchResults();   [Jansi:11-09-2020, commented as we ae not clearing up on o change any error messages]
		}
		this.enquiry = tempEnq;
	}

	/**
	 * validate consignment number //TO DO: can do with pattern here, check with Rufus /Ankur
	 */
	validateConsignmentNumber() {
		validateConsignmentNumber({
			consignmentNumber: this.consignmentNumber,
		}).then(result => {
			if (result) {
				this.isConsinMentNumIsValid = false;
				this.template.querySelectorAll('[data-id="consignmentNumber"]')[0].
					setCustomValidity(result);
			} else {
				this.isConsinMentNumIsValid = true;
				this.template.querySelectorAll('[data-id="consignmentNumber"]')[0].
					setCustomValidity('');
			}
		}).catch(error => {
			//alert(JSON.stringify(error));
			this.isLoading = false;
		}
		);
	}

	/**
	 * handleFocusOut
	 */
	handleFocusOut(event) {
		if (event.target.dataset.id === 'consignmentNumber' && this.consignmentNumber) {
			this.callContinuation(false, false);
		}
	}

	/**
	 * handle seach
	 */
	handleSeach(event) {
		this.callContinuation(true, false);
	}

	/**
	 * handle submits
	 */
	handleSubmit() {
		this.errorMessage = null;
		this.submitClicked = true;

		//--not allowing to create case when 1). consignment is not found against user billing account 
		//(or) 2) non closed cases exists for this consignment number. so no need form validation also
		if (this.STDeliveryEnquiryResultsWapper 
			&& this.STDeliveryEnquiryResultsWapper.notAllowedToCreateEnquiry
			&& this.prevConsignmentNuber == this.consignmentNumber){
			scrollToHeight(this.template.querySelectorAll('[data-id="error"]'));
			return;
		}   

		const allValid = checkAllValidity(this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox'), false);
		if (allValid && this.isConsinMentNumIsValid) {
			this.isLoading = true;

			//-- check if user is done consignment search, if not initiate search
			if (!this.STDeliveryEnquiryResultsWapper || 
				this.prevConsignmentNuber != this.consignmentNumber) {
				this.callContinuation(false, true);
				return;
			}

			createDeliveryEnquiryStarTrack({
				consignNumber: this.consignmentNumber,
				enqObj: JSON.stringify(this.enquiry),
				stWrapper: this.STDeliveryEnquiryResultsWapper,
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
			}
			);

		} else {
			this.errorMessage = topGenericErrorMessage;
		}

	}

	/**
	 * call consinment number search
	 */
	callContinuation(isDisplayLoading, requestFromSubmit) 
	{   
		if (this.isConsinMentNumIsValid && checkAllValidity(this.template.querySelectorAll('[data-id="consignmentNumber"]'))) 
		{
			this.resetSTSearchResults();
			this.errorMessage = null;
			
			if (isDisplayLoading)
				this.isLoading = true;
			searchConsignmentStarTrack({
				consignNumber: this.consignmentNumber,
				enqObj: JSON.stringify(this.enquiry),
			}).then(result => {
				if (result) {
					this.prevConsignmentNuber = this.consignmentNumber;
					this.STDeliveryEnquiryResultsWapper = result;
					this.submitClicked = true;
					this.setExistingCaseErrorMessage();
					
					if (isDisplayLoading)
						this.isLoading = false;

					if (requestFromSubmit) {
						if (this.STDeliveryEnquiryResultsWapper.article != null && this.STDeliveryEnquiryResultsWapper.multipleCaseError == null)
							this.handleSubmit();
						else
							this.isLoading = false;
					}

				} else {
					this.errorMessage = 'Consignment Search response is empty. Please contact you system admin';
					resetSTSearchResults();
					if (isDisplayLoading)
						this.isLoading = false;
				}
			}).catch(error => {
				// alert(JSON.stringify(error));
				this.errorMessage = error.body.message;
				this.prevConsignmentNuber = null;
				if (isDisplayLoading || requestFromSubmit)
					this.isLoading = false;

			});
		}
	}

	/**
	 * Handle Existing Multiple Case Error
	 */
	setExistingCaseErrorMessage(){
		this.existingCasesErrorMsg = this.STDeliveryEnquiryResultsWapper.multipleCaseError;
		if(this.STDeliveryEnquiryResultsWapper.multipleCaseError &&  this.STDeliveryEnquiryResultsWapper.caseNumbersStrList){
			this.existingCasesErrorMsg += '<br>';
			for(let caseNum of this.STDeliveryEnquiryResultsWapper.caseNumbersStrList){
				this.existingCasesErrorMsg += 
					'<a href="' + this.communityURL + '/s/EnquiryDetail?enquiryNumber=' + caseNum + '" target="_blank" class="slds-text-color_error">' + caseNum + ' </a>';
			}
		}
	}


	/**
	 * reset consignment results
	 */
	resetSTSearchResults() {
		this.STDeliveryEnquiryResultsWapper = null;
	}

	/**
	 * navigate to case details
	 */
	navigateToCaseDetail(event)
	{
		this[NavigationMixin.GenerateUrl]({
			type: 'comm__namedPage',
			attributes: {
				name: 'BSP_Enquiry_Details__c'
			},
			state: {
				enquiryNumber: this.caseNumber
			}
		}).then(generatedUrl => {
			window.open(generatedUrl, "_blank");
		});
	}

	/**
	 * handle cancel
	 */
	handleCancel() {
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

	/**
	 * fileupload eventHandler
	 **/
	onFileUploadHandler(event){
		this.uploadedFiles = event.detail;
	}

}