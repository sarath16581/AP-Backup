/**
 * @author Thang Nguyen
 * @date 2023-08-11
 * @group lwc
 * @domain BSP
 * @description lwc for the BSP Credit Claim form
 * @changelog
 * 2023-08-11 - Thang Nguyen - Created
 * 2023-08-16 - Hasantha Liyanage - auto populate account held with
 */
import {LightningElement, track, wire, api} from 'lwc';
import {CurrentPageReference, NavigationMixin} from 'lightning/navigation';
import {checkAllValidity, checkCustomValidity, topGenericErrorMessage, scrollToHeight} from 'c/bspCommonJS';
import {getObjectInfo, getPicklistValues} from 'lightning/uiObjectInfoApi';

// case object
import CASE_OBJECT from '@salesforce/schema/Case';
import BUSINESS_UNIT_FIELD from '@salesforce/schema/Case.Business_Unit__c';
import ENQUIRY_TYPE_FIELD from '@salesforce/schema/Case.Enquiry_Type__c';
import REASON_CREDIT_CLAIM_FIELD from '@salesforce/schema/Case.ReasonforCreditClaim__c';

// apex methods
import getUserProfileDetails from '@salesforce/apex/bspProfileUplift.getUserProfileDetails';
import deleteAttachment from '@salesforce/apex/bspEnquiryUplift.deleteAttachment';
import createCreditClaim from '@salesforce/apex/BSPCreditClaimController.createCreditClaim';

export default class bspFormAPEnquiry extends NavigationMixin(LightningElement) {

	//	enquiryType = 'Missing Item';
	spinnerAltText = 'loading';
	errorGeneric = 'An error has occurred';
	//	errorOnSearch = 'An error has occurred while searching';
	errorOnValidate = 'Please correct the errors in your input';

	showLog = false;
	// page parameters
	currentPageReference;
	submitClicked = false;

	formTitle = 'Create a credit claim';

	// spinner control
	showSpinner = false;
	successCreation = false;
	// error messages
	errorMessage = false;
	// output logs
	logs = [];

	// user object
	uploadedFiles = [];
	// the temp Case to hold values for submission
	tempCase = {};

	// form fields
	// ui options
	accountHeldWithList = [];
	disputeTypeList = [];
	reasonClaimList = [];
	// dislay value
	businessName;
	businessAccountNumber;
	contactName;
	contactEmailAddress;
	contactPhoneNumber;
	accountHeldWith;
	disputeType;
	reasonClaim;
	claimAmount;
	description;

	//temporary data
	recordTypeId;
	reasonClaimFieldData;

	//login user details
	user = {
		FirstName: '',
		LastName: '',
		Email: '',
		Phone: '',
		MobilePhone: ''
	};
	acceptedFileFormats = '.doc,.docx,.eml,.jpeg,.jpg,.msg,.pdf,.png,.ppt,.pptx,.txt,.xls,.xlsx,.zip';

	@wire(getObjectInfo, { objectApiName: CASE_OBJECT })
	wiredObjectInfo({data, error}) {
		if (error) {
			// handle Error
		} else if (data) {
			const rtis = data.recordTypeInfos;
			this.recordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === 'Enterprise Credit Dispute Claim');
		}
	}

	@wire(getPicklistValues, {recordTypeId: "$recordTypeId", fieldApiName: BUSINESS_UNIT_FIELD })
	businessUnitInfo({data, error}) {
		if (data) this.accountHeldWithList = data.values;
	}

	@wire(getPicklistValues, {recordTypeId: "$recordTypeId", fieldApiName: ENQUIRY_TYPE_FIELD })
	enquiryTypeInfo({data, error}) {
		let enquiryTypeOptions = [];
		if (data) {
			data.values.forEach(enquiryTypeOption =>{
					let etOption = {...enquiryTypeOption};
					if (etOption.label === 'Billing Dispute' || etOption.label === 'Service Performance'){
						enquiryTypeOptions.push(etOption);
					}
				}
			)
		}
		this.disputeTypeList = enquiryTypeOptions;		
	}

	@wire(getPicklistValues, {recordTypeId: "$recordTypeId", fieldApiName: REASON_CREDIT_CLAIM_FIELD })
	reasonClaimInfo({data, error}) {
		if (data) this.reasonClaimFieldData = data;
	}

	handleEnquiryTypeChange(event) {
		let key = this.reasonClaimFieldData.controllerValues[event.target.value]; 
		this.reasonClaimList = this.reasonClaimFieldData.values.filter(opt => opt.validFor.includes(key));
	}

	//get current user profile details
	@wire(getUserProfileDetails) userProfileDetails({
		error,
		data
	}) {
		if (data) {
			if (data.user)
				this.user = data.user
			if (data.businessName)
				this.businessName = data.businessName;

			this.showSpinner = false;

		} else if (error) {
			this.errorMessage = this.errorGeneric;
			this.showSpinner = false;
		}
	}

	/**
	 * Initialize the lwc, waits for the page url to be available first. This is to avoid order of execution
	 * issues between loading the static picklist data and preloaded consignment ID for search (if any)
	 * @param currentPageReference - standard property to get the url parameters
	 */
	@wire(CurrentPageReference)
	setCurrentPageReference(currentPageReference) {
		this.currentPageReference = currentPageReference;
		// set the account held with field
		switch (this.currentPageReference.state.accountHeldWith) {
			case 'ap':
				this.accountHeldWith = 'Australia Post';
				break;
			case 'st':
				this.accountHeldWith = 'StarTrack';
				break;
			default:
				break;
		}
	}

	renderedCallback() {
		if(this.errorMessage && this.submitClicked) {
			this.submitClicked = false;
			scrollToHeight(this.template.querySelectorAll('[data-id="error"]'));
		}
	}

	onChangeField(event) {
		const field = event.target.dataset.id;
		switch(field)
		{
			case 'businessName':
				this.businessName = event.detail.value;
				break;
			case 'businessAccountNumber':
				this.businessAccountNumber = event.detail.value;
				break;
			case 'contactName':
				this.contactName = event.detail.value;
				break;
			case 'contactEmailAddress':
				this.contactEmailAddress = event.detail.value;
				break;
			case 'contactPhoneNumber':
				this.contactPhoneNumber = event.detail.value;
				break;
			case 'accountHeldWith':
				this.accountHeldWith = event.detail.value;
				break;
			case 'disputeType':
				this.disputeType = event.detail.value;
				this.handleEnquiryTypeChange(event);
				break;
			case 'reasonClaim':
				this.reasonClaim = event.detail.value;
				break;
			case 'claimAmount':
				this.claimAmount = event.detail.value;
				break;
			case 'description':
				this.description = event.detail.value;
				break;
			default:
				console.error('unhandled field change:' + field);
				break;
		}

	}

	handleFocus(event) {
		const inputCmp = this.template.querySelectorAll('[data-id="' + event.target.dataset.id + '"]');
		inputCmp[0].setCustomValidity('');
	}

	handleFocusOut(event) {
		this.checkValidationOfField(event.target.dataset.id);
	}

	checkValidationOfField(datasetId) {
		const inputCmp = this.template.querySelectorAll('[data-id="' + datasetId + '"]');
		//--Checking the custom validation on change of a field value
		if (inputCmp !== undefined && inputCmp.length > 0) {
			checkCustomValidity(inputCmp[0], inputCmp[0].messageWhenValueMissing);
		}
	}

	onUploadFinished(event)
	{
		this.uploadedFiles = event.detail;
	}

	onDeleteUpload(event)
	{
		this.showSpinner = true;
		let fileId = event.target.dataset.id;
		deleteAttachment({fileId:fileId})
			.then(result => {
				//console.log('file:' + fileId + ' removed');

				this.removeFromUploadedByFileId(fileId);
				this.showSpinner = false;
			}).catch(error => {
			console.error('error occured');
			console.error(error);
			this.showSpinner = false;
		});
	}

	/**
	 * Removing the file from the display list. the files are uploaded against the user, only attached to the case at submit
	 * @param fileId
	 */
	removeFromUploadedByFileId(fileId)
	{
		for(let i = 0; i < this.uploadedFiles.length; ++i)
		{
			let objFile = this.uploadedFiles[i];
			if(objFile.documentId === fileId)
			{
				this.uploadedFiles.splice(i, 1);
				return;
			}

		}
	}

	/**
	 * On Submit request
	 * @param event
	 */
	onSubmitRequest(event) {

		this.showSpinner = true;
		this.submitClicked = true;
		this.errorMessage = '';

		const inputComponents = this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox');
		const inputDisputeItems = this.template.querySelector("c-bsp-dispute-items");
		let disputeItemValid;
		if (inputDisputeItems === null){
			disputeItemValid = false;
		}else{
			disputeItemValid = inputDisputeItems.checkAllValidity();
		}
		const allValid = checkAllValidity(inputComponents) && disputeItemValid;
		

		if (!allValid) {
			this.showSpinner = false;
			this.errorMessage = topGenericErrorMessage;
			return;
		}

		this.tempCase.RecordTypeId =  this.recordTypeId;
		this.tempCase.Billing_Number__c = this.businessAccountNumber;
		this.tempCase.Name__c = this.contactName;
		this.tempCase.Email_Address__c = this.contactEmailAddress;
		this.tempCase.Phone__c = this.contactPhoneNumber;
		this.tempCase.Business_Unit__c = this.accountHeldWith;
		this.tempCase.Enquiry_Type__c = this.disputeType;
		this.tempCase.ReasonforCreditClaim__c = this.reasonClaim;
		this.tempCase.Amount_Claimed__c  = this.claimAmount;
		this.tempCase.Origin = 'BSP';
		this.tempCase.Status = 'New';
		this.tempCase.Priority = 'Normal';
		this.tempCase.Description = this.description;
		this.tempCase.CCUEnquiryType__c = 'Credit Claim';
		this.tempCase.Subject = 'Credit Claim';

		//get disputeItems 
		let disputeItems = inputDisputeItems.getDisputedItems();

		createCreditClaim({
			caseRecord: this.tempCase,
			uploadedFiles: this.uploadedFiles,
			disputeItems: disputeItems
		}).then(result =>{
			if(result.status == 'error'){
				this.errorMessage = result.message;
			} else {
				this.tempCase = result.caseRecord;
				this.successCreation = true;
			}
			this.showSpinner = false;
		}).catch(error => {
			console.error('error occured');
			console.error(error);
			this.showSpinner = false;
		})

	}


	navigateHome(event)
	{
		this[NavigationMixin.Navigate]({
			type: 'comm__namedPage',
			attributes: {
				name: 'Home'
			}
		});
	}

	get showDisputedTransactionSection(){
		if (this.accountHeldWith){
			return true;
		}else{
			return false;
		}
	}
}