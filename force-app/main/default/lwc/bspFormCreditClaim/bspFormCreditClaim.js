/**
 * @author Thang Nguyen
 * @date 2023-08-11
 * @group lwc
 * @domain BSP
 * @description lwc for the BSP Credit Claim form
 * @changelog
 * 2023-08-11 - Thang Nguyen - Created
 * 2023-08-16 - Hasantha Liyanage - auto populate account held with
 * 2023-09-27 - Hasantha Liyanage - Account Number and Other Account number functionality with type ahead component
 * 2023-10-23 - Hasantha Liyanage - added credit claim reason display help text capability
 * 2023-12-05 - Thang Nguyen - added adobe analytics details
 * 2024-01-23 - Thang Nguyen - fixed defect SB-269
 * 2024-02-28 - Thang Nguyen - fixed defect SB-279
 */
import {LightningElement, wire} from 'lwc';
import {CurrentPageReference, NavigationMixin} from 'lightning/navigation';
import {checkAllValidity, checkCustomValidity, topGenericErrorMessage, scrollToHeight} from 'c/bspCommonJS';
import {getObjectInfo, getPicklistValues} from 'lightning/uiObjectInfoApi';

//adobe analytics
import { analyticsTrackPageLoad } from 'c/adobeAnalyticsUtils';

// case object
import CASE_OBJECT from '@salesforce/schema/Case';
import BUSINESS_UNIT_FIELD from '@salesforce/schema/Case.Business_Unit__c';
import ENQUIRY_TYPE_FIELD from '@salesforce/schema/Case.Enquiry_Type__c';
import REASON_CREDIT_CLAIM_FIELD from '@salesforce/schema/Case.ReasonforCreditClaim__c';

// apex methods
import getUserProfileDetails from '@salesforce/apex/bspProfileUplift.getUserProfileDetails';
import deleteAttachment from '@salesforce/apex/bspEnquiryUplift.deleteAttachment';
import createCreditClaim from '@salesforce/apex/BSPCreditClaimController.createCreditClaim';
import getBillingAccounts from '@salesforce/apex/bspEnquiryUplift.buildBillingAccountOptions';
import getCreditClaimReasonHelpTexts from '@salesforce/apex/bspEnquiryUplift.buildReasonForClaimHelpText';
import getRelatedSuperAdminRoles from '@salesforce/apex/BSPCreditClaimController.getSuperAdminRoles';
import isValidBillingAccount from '@salesforce/apex/BSPCreditClaimController.isValidBillingAccount';
import acceptedFileFormats from '@salesforce/label/c.BSP_Accepted_file_formats_credit_claim';
export default class bspFormCreditClaim extends NavigationMixin(LightningElement) {
	//	enquiryType = 'Missing Item';
	spinnerAltText = 'loading';
	errorGeneric = 'An error has occurred';
	//	errorOnSearch = 'An error has occurred while searching';
	errorOnValidate = 'Please correct the errors in your input';
	fileUploadLabel = 'Attach a document or image to support your claim';

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
	businessAccountNumber = null;
	billingNumber
	contactName;
	contactEmailAddress;
	contactPhoneNumber;
	accountHeldWith;
	disputeType;
	reasonClaim;
	reasonClaimLabel;
	reasonClaimHelpText = {};
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
	acceptedFileFormats = acceptedFileFormats;
	allBillingAccOptions = [];
	creditClaimReasonHelpTexts = [];
	superAdminRoles;
	showBilling = false;
	defaultValue = {}; // contains default value for billing account dropdown
	requestAccessContent = {}; // store the extra information to generate other account number content
	isValidOtherBillingAccount = false;
	isShowOtherBillingAccountField = false;
	isShowRequestAccessContent = false; // render request access content based on the other billing account field's value is a valid billing account or not
	otherOptions = [{
		value:'other',
		label:'Other account number',
		isCustom:true
	}];
	additionalFormData = {
		businessAccountNumber:'',
		isOther: false
	};
	isValidateFileUploaded = false;

	//analytics variables
	pageName = '';

	/**
	 * handle billing account input search focus out event
	 * @param event
	 */
	handleOnInputFocusOutBillingAccount(event) {
		// show hide other option dependant components
		const selectedValue = event.detail.selected;
		if(selectedValue.value === this.otherOptions[0].label) {
			this.isShowOtherBillingAccountField = true;
		} else {
			this.isShowOtherBillingAccountField = false;
			this.isShowRequestAccessContent = false;
			this.billingNumber = null;
		}

		// if the billing account is not selected and empty, remove the values, otherwise this will still hold old value in the backend
		if(!selectedValue.value) {
			this.businessAccountNumber = null;
		}
	}

	/**
	 * handle billing account input search selected accounts
	 * billingNumber variable matches the Billing_Name__c [Text]
	 * businessAccountNumber variable matches the Related_Billing_Account__c [Id]
	 * the event is fired at the child component level and contains selected value details
	 * @param event
	 */
	handleOnSelectionBillingAccount(event){
		const selectedValue = event.detail.selected;
		// if other option selected
		if(selectedValue.value === this.otherOptions[0].value) {
			this.isShowOtherBillingAccountField = true;
			this.businessAccountNumber = null; // clear any previously selected values, otherwise Related Billing Account will be linked if found
			this.additionalFormData.isOther = true;
			this.additionalFormData.businessAccountNumber = '';
			this.accountHeldWith = '';
		} else {
			this.isShowOtherBillingAccountField = false;
			this.businessAccountNumber = selectedValue.value; // selected value passed from search component is an ID value
			this.additionalFormData.businessAccountNumber = selectedValue.label; // passing the label values for case comments
			this.additionalFormData.isOther = false;
			this.billingNumber = null; // there is no billing Number passed in to apex when Id exists
			// prefill the account held with dropdown
			this.autoSelectAccountHeldWith(selectedValue.value);
		}
	}

	/**
	 * Based on the selection of Account number account held with values are auto selected,
	 * When it is the initial load, url parameters are considered
	 * @param selectedValue
	 */
	autoSelectAccountHeldWith(businessUnit) {
		const selectedOption = this.allBillingAccOptions.find(option => option.value === businessUnit);
		if (selectedOption.key === 'TEAM') {
			this.accountHeldWith = 'StarTrack';
		} else if (selectedOption.key === 'SAP ERP') {
			this.accountHeldWith = 'Australia Post'
		}
	}

	async connectedCallback() {
		await this.initialLoad();
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

	async initialLoad() {
		// billing accounts to be populated in the typeahead component
		// we select all the billing accounts at once
		await getBillingAccounts()
			.then((data) => {
				this.allBillingAccOptions = data;
				if(this.allBillingAccOptions.length === 1) {
					this.defaultValue = this.allBillingAccOptions[0];
					this.businessAccountNumber = this.allBillingAccOptions[0].value;
					this.autoSelectAccountHeldWith(this.allBillingAccOptions[0].value);
				}

			})
			.catch((error) => {
				console.error(error);
			}).finally(() => {
				this.showBilling = true;
			});

		// getting the super admin roles to display in the other account number section for user to request access
		await getRelatedSuperAdminRoles()
			.then((data) => {
				this.superAdminRoles = data;
				this.requestAccessContent.superAdminRoles = data;
				this.requestAccessContent.businessName = this.businessName;
				this.requestAccessContent.loggedInUserEmail = this.user.Email;
			})
			.catch((error) => {
				console.error(error);
			}).finally(() => {

			});

		await getCreditClaimReasonHelpTexts()
			.then((data) => {
				this.creditClaimReasonHelpTexts = data;
				console.log(this.creditClaimReasonHelpTexts);
				console.log('this.creditClaimReasonHelpTexts');
			})
			.catch((error) => {
				console.error(error);
			}).finally(() => {
			});
	}

	@wire(getObjectInfo, { objectApiName: CASE_OBJECT })
	wiredObjectInfo({data, error}) {
		if (error) {
			console.error(error);
		} else if (data) {
			const rtis = data.recordTypeInfos;
			this.recordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === 'Enterprise Credit Dispute Claim');
		}
	}

	@wire(getPicklistValues, {recordTypeId: "$recordTypeId", fieldApiName: BUSINESS_UNIT_FIELD })
	businessUnitInfo({data, error}) {
		if(error){
			console.error(error);
			return;
		}
		if (data) this.accountHeldWithList = data.values;
	}

	@wire(getPicklistValues, {recordTypeId: "$recordTypeId", fieldApiName: ENQUIRY_TYPE_FIELD })
	enquiryTypeInfo({data, error}) {
		if (error){
			console.error(error);
			return;
		}
		let enquiryTypeOptions = [];
		if (data) {
			data.values.forEach(enquiryTypeOption =>{
					let etOption = {...enquiryTypeOption};
					if (etOption.label === 'Billing dispute' || etOption.label === 'Service performance'){
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
			if (data.user){
				this.user = data.user
				this.contactName = this.user.FirstName + ' ' + this.user.LastName;
				this.contactEmailAddress = this.user.Email;
				if (data.user.Phone){
					this.contactPhoneNumber = this.user.Phone;
				}else{
					this.contactPhoneNumber = this.user.MobilePhone;
				}
			}
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
				this.pageName = 'auspost:bsp:ap:creditclaim';
				break;
			case 'st':
				this.accountHeldWith = 'StarTrack';
				this.pageName = 'auspost:bsp:st:creditclaim';
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
		switch(field) {
			case 'businessName':
				this.businessName = event.detail.value;
				break;
			case 'businessAccountNumberOther':
				this.billingNumber = event.target.value;
				this.additionalFormData.businessAccountNumber = this.billingNumber
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
				this.setHelpText();
				break;
			case 'disputeType':
				this.disputeType = event.detail.value;
				this.handleEnquiryTypeChange(event);
				this.reasonClaimHelpText = {}; // clear the reason's help text
				this.reasonClaim = ''; // clear the reason value.
				this.reasonClaimLabel = ''; // clear the reason label.
				break;
			case 'reasonClaim':
				this.reasonClaim = event.detail.value;
				this.reasonClaimLabel = this.reasonClaimList.find(reason => reason.value === event.detail.value).label;
				this.setHelpText();
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

	/**
	 * Setting the help text
	 */
	setHelpText() {
		this.reasonClaimHelpText.text = '';
		let businessUnit = '';
		if (this.accountHeldWith === 'Australia Post') {
			businessUnit = 'ap';
		} else if (this.accountHeldWith === 'StarTrack') {
			businessUnit = 'st';
		}
		const stringWithoutSpaces = this.reasonClaim.replace(/\s+/g, '').toLowerCase();
		const reasonHelpText = this.creditClaimReasonHelpTexts[stringWithoutSpaces + '_' + businessUnit];
		this.reasonClaimHelpText.text = reasonHelpText.Message__c;
		this.reasonClaimHelpText.isAttachmentRequired = reasonHelpText.IsAttachmentRequired__c;
	}

	handleFocus(event) {
		const inputCmp = this.template.querySelectorAll('[data-id="' + event.target.dataset.id + '"]');
		inputCmp[0].setCustomValidity('');
	}

	handleFocusOut(event) {
		this.checkValidationOfField(event.target.dataset.id);
	}

	checkValidationOfField(datasetId) {
		this.showSpinner = true;
		const inputCmp = this.template.querySelectorAll('[data-id="' + datasetId + '"]');
		switch(datasetId){
			case 'businessAccountNumberOther':
				if(inputCmp[0].value && inputCmp[0].validity.valid){
					this.isValidOtherBillingAccount = false;
					// validating the value of custom billing account [other] field
					isValidBillingAccount({billingAccountValue: inputCmp[0].value})
						.then(result => {
							// if entered is an invalid billing account, we expect a message here
							if(result) {
								if(result.status === 'ERROR') {
									inputCmp[0].setCustomValidity(result.message);
									inputCmp[0].reportValidity();
								} else if(result.status === 'SUCCESS') {
									this.isValidOtherBillingAccount = true;
									if (result.billingAccount.Source_System__c === 'TEAM') {
										this.accountHeldWith = 'StarTrack';
									} else if (result.billingAccount.Source_System__c === 'SAP ERP') {
										this.accountHeldWith = 'Australia Post'
									}
								}
							}
							this.showSpinner = false;
						}).catch(error => {
							console.error(error);
							this.showSpinner = false;
						}).finally(() => {
							this.isShowRequestAccessContent = true;
						});
				} else {
					// when value is empty
					checkCustomValidity(inputCmp[0], inputCmp[0].messageWhenValueMissing);
					this.isShowRequestAccessContent = false;
					this.showSpinner = false;
				}
				break;
			default:
				//Checking the custom validation on change of a field value
				if (inputCmp !== undefined && inputCmp.length > 0) {
					checkCustomValidity(inputCmp[0], inputCmp[0].messageWhenValueMissing);
				}
				break;
		}
	}

	onUploadFinished(event)
	{
		this.uploadedFiles = event.detail;
		if(this.uploadedFiles.length) {
			this.isValidateFileUploaded = true;
		} else {
			this.isValidateFileUploaded = false;
		}
	}

	onDeleteUpload(event)
	{
		this.showSpinner = true;
		let fileId = event.target.dataset.id;
		deleteAttachment({fileId:fileId})
			.then(result => {
				//TODO: need error handling once deleted based on the response
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
	removeFromUploadedByFileId(fileId){
		for(let i = 0; i < this.uploadedFiles.length; ++i) {
			let objFile = this.uploadedFiles[i];
			if(objFile.documentId === fileId) {
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
		event.preventDefault();
		this.showSpinner = true;
		this.submitClicked = true;
		this.errorMessage = '';

		const {inputDisputeItems, allValid} = this.validateAll();

		// if not valid, show the generic message
		if (!allValid) {
			this.showSpinner = false;
			this.errorMessage = topGenericErrorMessage;
			return;
		}

		this.tempCase.RecordTypeId =  this.recordTypeId;
		this.tempCase.Business_Name__c = this.businessName;
		this.tempCase.Billing_Number__c = this.billingNumber;
		this.tempCase.Related_Billing_Account__c = this.businessAccountNumber;
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

		if(!this.isValidateFileUploaded && this.reasonClaimHelpText.isAttachmentRequired) {
			this.openModal(); // open attachment confirmation
			return;
		} else if(this.showModal){
			this.closeModal(); // close modal if submit anyway otherwise modal will appear on confirmation
			this.isValidateFileUploaded = false; // reset the attachment validation confirmation modal
		}

		createCreditClaim({
			caseRecord: this.tempCase,
			uploadedFiles: this.uploadedFiles,
			disputeItems: disputeItems,
			formData: this.additionalFormData
		}).then(result =>{
			if(result.status === 'error'){
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
		});
	}

	/**
	 * Validate before submitting the form
	 * @returns {{allValid: (*|boolean), inputDisputeItems: bspDisputeItems}} valid disputed items and the validity state of the values
	 */
	validateAll() {
		// all generic input elements
		let inputElements = this.template.querySelectorAll(
			'[data-validation="creditClaimForm"]'
		);
		const inputComponentsValidity = checkAllValidity(inputElements, false);
		// dispute items validation
		const inputDisputeItems = this.template.querySelector("c-bsp-dispute-items");
		let disputeItemValid;
		if (inputDisputeItems === null) {
			disputeItemValid = false;
		} else {
			disputeItemValid = inputDisputeItems.checkAllValidity();
		}

		// if the other account number field is selected and the field should have a valid value
		const isOtherBillingAccountChecked = (this.isShowOtherBillingAccountField && this.isValidOtherBillingAccount) || !this.isShowOtherBillingAccountField;
		const isBillingAccountSSelected = (this.isShowOtherBillingAccountField && this.businessAccountNumber === null) || (!this.isShowOtherBillingAccountField && this.businessAccountNumber !== null)

		// validate account number field if not Other account number selected
		if (!this.isShowOtherBillingAccountField) {
			this.template.querySelector("c-bsp-type-ahead").checkValidity();
		}

		// final check for all validation
		const allValid = isOtherBillingAccountChecked && isBillingAccountSSelected && inputComponentsValidity && disputeItemValid;
		return {inputDisputeItems, allValid};
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
		}
		return false;
	}


	showModal = false;
	openModal() {
		this.showModal = true;
		this.showSpinner = false;
	}

	closeModal() {
		this.showModal = false;
	}

	handleButtonClick(event) {
		const buttonName = event.target.dataset.buttonname;
		if (buttonName === 'close') {
			this.showModal = false;
		} else if (buttonName === 'submitAnyway') {
			this.isValidateFileUploaded = true;
			this.template.querySelector('[data-id="submit"]').click();
		}
	}
}