/*
* --------------------------------------- History --------------------------------------------------
* 07/12/2023		thang.nguyen231@auspost.com.au		added adobe analytics details
*/

import {LightningElement, track, wire, api} from 'lwc';
import {CurrentPageReference, NavigationMixin} from 'lightning/navigation';
import { checkAllValidity, checkCustomValidity, topGenericErrorMessage, scrollToHeight } from 'c/bspCommonJS';
// apex methods
import initMissingItemFormApex from '@salesforce/apex/bspEnquiryUplift.initMissingItemForm';
import createEnquiryAusPost from '@salesforce/apex/bspEnquiryUplift.createEnquiryAusPost';
import deleteAttachment from '@salesforce/apex/bspEnquiryUplift.deleteAttachment';
import search from '@salesforce/apexContinuation/BSPConsignmentSearchUplift.search';

//adobe analytics
import { analyticsTrackPageLoad } from 'c/adobeAnalyticsUtils';

export default class bspFormAPEnquiry extends NavigationMixin(LightningElement) {

	enquiryType = 'Missing Item';
	spinnerAltText = 'loading';
	errorGeneric = 'An error has occurred';
	errorOnSearch = 'An error has occurred while searching';
	errorOnValidate = 'Please correct the errors in your input';
	showLog = false;
	// page parameters
	currentPageReference;
	// don't track the actual objects, rather, track the display strings
	latestEvent = {};
	article = {};
	articleRecordType;
	consignmentWithMultipleArticles = false;
	trackingIdForDeliveryStatusCmp = '';
	submitClicked = false;

	// ui options
	@track articleTypes = [{label:1,value:'one'}];
	@track serviceTypes = [];
	containsMedicationOptions = [{label:'Yes',value:'Yes'}, {label:'No',value:'No'}];
	sentimentalOptions = [{label:'Yes',value:'Yes'}, {label:'No',value:'No'}];

	@track formTitle = '';
	// spinner control
	@track showSpinner = false;
	@track successCreation = false;
	// error messages
	@track errorMessage = false;
	// output logs
	@track logs = [];

	// user object
	@track currentUser = {};
	@track uploadedFiles = [];
	// the temp Case to hold values for submission
	@track tempCase = {};
	// display values
	@track trackingId;
	@track lodgementDate;
	@track reference;
	@track description;
	@track descriptionOfContents;
	isContainsMedication;
	isSentimental;
	itemValue;
	@track articleType;
	@track serviceUsed;
	@track showEvent = false;
	@track lastEventName  = '';
	@track lastEventDate = '';
	@track showNoEvents = false;
	@track expectedDeliveryDate = '';
	@track searchResult;
	enteredTrackingNumber='';
	isDisplayDeliveryStatus = false;

	//analytics variables
	pageName = 'auspost:bsp:ap:lostormissingparcel';	

	/**
	 * Initialize the lwc, waits for the page url to be available first. This is to avoid order of execution
	 * issues between loading the static picklist data and preloaded consignment ID for search (if any)
	 * @param currentPageReference - standard property to get the url parameters
	 */
	@wire(CurrentPageReference)
	setCurrentPageReference(currentPageReference) {
		this.currentPageReference = currentPageReference;

		// set the enquiry type
		this.enquiryType = this.currentPageReference.state.enquiryType;
		this.setFormTitle();
		this.showSpinner = true;
		//this.tempCase.ReferenceID__c = this.currentPageReference.state.trackingId;
		this.trackingId = this.currentPageReference.state.trackingId;

		// get picklist value data
		initMissingItemFormApex({
			//trackingId: this.tempCase.ReferenceID__c
		}).then(result =>{
			//console.log(result);

			this.currentUser = result["currentUser"];
			this.articleTypes = result["articleTypes"];
			this.serviceTypes = result["serviceTypes"];

			if(result.status == 'error')
			{
				this.errorMessage = result.message;
				this.showSpinner = false;
				return;
			}

			// do search if prepopulated
			if(this.trackingId)
			{
				this.doSearch();
			}
			else
			{
				this.showSpinner = false;
			}
		}).catch(error => {
				this.errorMessage = this.errorGeneric;
		});
	}

	renderedCallback() {
		if(this.errorMessage && this.submitClicked) {
			this.submitClicked = false;
			scrollToHeight(this.template.querySelectorAll('[data-id="error"]'));
		}
	}

	/**
	 * Search using consignment Id, called either on init, or from onClickSearchTracking (or enter key)
	 * @returns {Promise<void>}
	 */
	async doSearch()
	{
		// clear previous search
		this.clearPreviousDetails();

		//await searchAPAsync({searchString: this.tempCase.ReferenceID__c})
		await search({consignNumber: this.trackingId})
			.then(result=>{

				if(result == null || result == undefined)
				{
					// if a result is returned, parse it and display
					this.errorMessage = this.errorOnSearch;
					this.showSpinner = false;
					this.consignmentWithMultipleArticles = false;
					this.latestEvent = {};
					this.articleRecordType = 'Article';
					this.trackingIdForDeliveryStatusCmp = '';
					return;
				}
				else
				{
					if('errorMessages' in result && result.errorMessages.length > 0)
					{
						this.errorMessage = result.errorMessages.join(', ');
					} else
					{
						this.isDisplayDeliveryStatus = true;
					}

					this.searchResult = result;
					this.trackingIdForDeliveryStatusCmp = this.trackingId;
					this.parseLatestEvent();
					if(this.searchResult.singleCon)
						this.parseArticleDetails(this.searchResult.singleCon);
				}
			})
			.catch(error => {
				//console.error('bspFormMissingItem: error occurred');
				//console.error(error);
				this.errorMessage = this.errorOnSearch;
			});

		this.showSpinner = false;
	}

	get displayDeliveryStatus(){
		return  (this.isDisplayDeliveryStatus ? (this.searchResult ? (this.searchResult.singleCon ? true : false): false) : false);
	}

	// handle 'enter' key press
	checkSearchEnter(event)
	{
		if(event.keyCode == 13)
		{
			//console.log(event);
			this.onClickSearchTracking(event);
		}
	}

	/**
	 * handle the button click to initiate the search
	 * @param event
	 * @returns {Promise<void>}
	 */
	async onClickSearchTracking(event) {
		// hide previous details
		this.showEvent = false;
		this.errorMessage = '';
		const trackingComp = this.template.querySelectorAll('[data-id="trackingNumber"]'); //".address-input"
		if(this.enteredTrackingNumber != this.trackingId){
			this.isDisplayDeliveryStatus = false;
			this.showSpinner = true;
			if(!checkAllValidity(trackingComp))
			{
				this.errorMessage = 'Please enter a tracking number';
				this.showSpinner = false;
				return;
			}
			this.enteredTrackingNumber = this.trackingId;
			this.doSearch();
		}
	}

	/**
	 * Display a different title depending on the enquiry type
	 */
	setFormTitle(){
		if(!this.enquiryType)
			this.enquiryType = 'Missing Item';
		switch(this.enquiryType.toLowerCase())
		{
			case 'delivery':
				this.formTitle = 'Create a delivery issue enquiry';
				this.pageName = 'auspost:bsp:ap:deliveryissue';
				break;
			case 'rts':
				this.formTitle = 'Create a Return To Sender enquiry';
				this.pageName = 'auspost:bsp:ap:returntosender';
				break;

			case 'missing item':
			default:
				this.formTitle = 'Create a late or missing parcel enquiry';
				break;
		}
	}

	/**
	 * Clear details from the previous search
	 */
	clearPreviousDetails()
	{
		let refId = this.tempCase.ReferenceID__c;
		this.tempCase = {ReferenceID__c:  refId, BSPLodgementDate__c : null};

		this.article = {};
		this.expectedDeliveryDate = '';
		this.lastEventDate = '';
		this.lastEventName = '';
		//this.errorMessage = '';

		// sender Details
		let senderAddressCmp = this.getSenderAddressCmp();
		senderAddressCmp.firstName = '';
		senderAddressCmp.lastName = '';
		senderAddressCmp.businessName = '';
		senderAddressCmp.address = null;

		// receiver details
		let receiverAddressCmp = this.getReceiverAddressCmp();
		receiverAddressCmp.firstName = '';
		receiverAddressCmp.lastName = '';
		receiverAddressCmp.businessName = '';
		receiverAddressCmp.address = null;
	}

	/**
	 * Get the bsp address input for sender address, centralized here as it is used in multiple places
	 * @returns {Element}
	 */
	getSenderAddressCmp()
	{
		return this.template.querySelector('c-bsp-address-input[data-id="senderAddress"]');
	}

	/**
	 * Get the bsp address input for receiver address, centralized here as it is used in multiple places
	 * @returns {Element}
	 */
	getReceiverAddressCmp()
	{
		return this.template.querySelector('c-bsp-address-input[data-id="receiverAddress"]');
	}

	/**
	 * Parse the details of the search result for display
	 * @param article
	 */
	parseArticleDetails(article)
	{
		this.article = article;

		// lodgement date
		this.lodgementDate = this.article.ArticleLodgementDate__c;
		this.articleRecordType = this.article.RecordType ? this.article.RecordType.Name : 'Article';

		// article type
		// prepopulate the Item Type select
		this.parseItemTypeFromArticle();
		this.serviceUsed = this.article.ProductCategory__c;

		// display delivery date
		this.expectedDeliveryDate = '';
		if('ExpectedDeliveryDate__c' in this.article)
		{
			let arrExpectedDate = this.article.ExpectedDeliveryDate__c.split('-');
			this.expectedDeliveryDate = arrExpectedDate[2] +'/'+arrExpectedDate[1] +'/'+ arrExpectedDate[0];
		}

		// sender Details
		let senderAddressCmp = this.getSenderAddressCmp();

		if('SenderAddress__c' in this.article) {
			senderAddressCmp.address = this.parseAddressAsObject(true);
		}
		else
		{
			senderAddressCmp.address = null;
		}

		if('SenderName__c' in this.article)
		{
			let senderFullName = this.article.SenderName__c.split(' ');
			if(senderFullName){
				senderAddressCmp.firstName = senderFullName[0];
				if(senderFullName.length > 1) senderAddressCmp.lastName = senderFullName[1];
			}

		}
		else
		{
			senderAddressCmp.firstName = '';
			senderAddressCmp.lastName = '';
		}

		senderAddressCmp.businessName = this.article.SenderCompany__c?this.article.SenderCompany__c : '';


		// receiver details
		let receiverAddressCmp = this.getReceiverAddressCmp();
		if('ReceiverAddress__c' in this.article) {
			receiverAddressCmp.address = this.parseAddressAsObject(false);
		}
		else
		{
			receiverAddressCmp.address = null;
		}

		if('ReceiverName__c' in this.article)
		{
			let receiverFullName = this.article.ReceiverName__c.split(' ');
			if(receiverFullName){
				receiverAddressCmp.firstName = receiverFullName[0];
				if(receiverFullName.length > 1) receiverAddressCmp.lastName = receiverFullName[1];
			}
		}
		else
		{
			receiverAddressCmp.firstName = '';
			receiverAddressCmp.lastName = '';
		}
		receiverAddressCmp.businessName = this.article.ReceiverCompany__c?this.article.ReceiverCompany__c:'';


	}

	parseItemTypeFromArticle()
	{
		//this.tempCase.ArticleType__c = this.article.ProductCategory__c;

		if(!this.article.ProductCategory__c) {
			//this.tempCase.ArticleType__c = null;
			this.articleType = null;
			return;
		}

		for(let i = 0; i < this.articleTypes.length; ++i)
		{
			let type = this.articleTypes[i];
			if(this.article.ProductCategory__c.includes(type.value))
			{
				//this.tempCase.ArticleType__c = type.value;
				this.articleType = type.value;
				return;
			}

		}
	}

	/**
	 * Parse the article details into an object for the bsp-address-input child components
	 * @param isSender
	 * @returns {{city: *, countrycode: *, postcode: *, dpid: string, addressLine1: *, addressLine2: *, state: *}}
	 */
	parseAddressAsObject(isSender) {
		let addLine1 = '', addLine2 = '', addCity = '', addState = '', addPostCode = '', addCountry = '', addCountryName = '';

		if(isSender){
			addLine1 = this.article.SenderAddressLine1__c;
			addLine2 = this.article.SenderAddressLine2__c;
			addCity = this.article.SenderCity__c;
			addState = this.article.SenderState__c;
			addPostCode = this.article.SenderPostcode__c;
			addCountry = this.article.SenderCountry__c;
			addCountryName = this.article.SenderCountryName__c; //Added 09.11.2020
		} else {
			addLine1 = this.article.ReceiverAddressLine1__c;
			addLine2 = this.article.ReceiverAddressLine2__c;
			addCity = this.article.ReceiverCity__c;
			addState = this.article.ReceiverState__c;
			addPostCode = this.article.ReceiverPostcode__c;
			addCountry = this.article.ReceiverCountry__c;
			addCountryName = this.article.ReceiverCountryName__c; //Added 09.11.2020
		}

		let objAddress = {
			addressLine1: addLine1,
			addressLine2: addLine2,
			city: addCity,
			state: addState,
			postcode: addPostCode,
			countrycode: addCountry,
			dpid: '',
			countryName : addCountryName  //Added 09.11.2020
		};
		return objAddress;
	}


	parseLatestEvent()
	{
		if(this.searchResult){
			let les = this.searchResult.labelEvents;
			let ces = this.searchResult.consignmentEvents;

			if(les && les.length > 0){
				this.latestEvent = les[0];
				this.consignmentWithMultipleArticles = les.length > 1 ? true : false;
			}else if(ces && ces.length > 0){
				this.latestEvent = ces[0];
				this.consignmentWithMultipleArticles = false;
			}
		}

		//console.log(this.latestEvent);
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
		if (inputCmp != undefined && inputCmp.length > 0) {
			checkCustomValidity(inputCmp[0], inputCmp[0].messageWhenValueMissing);
		}
	}

	onChangeField(event) {
		const field = event.target.dataset.id;
		switch(field)
		{
			case 'trackingNumber':
				this.trackingId = event.detail.value;
				//this.tempCase.ReferenceID__c = event.detail.value;
				break;
			case 'lodgementDate':
				this.lodgementDate = event.detail.value;
				//this.tempCase.BSPLodgementDate__c = event.detail.value;
				break;
			case 'itemType':
				this.articleType = event.detail.value;
				//this.tempCase.ArticleType__c = event.detail.value;
				break;
			case 'serviceUsed':
				this.serviceUsed = event.detail.value;
				//this.tempCase.CCUServiceUsed__c = event.detail.value;
				break;
			case 'yourReference':
				this.reference = event.detail.value;
				//this.tempCase.CCUYourReference__c = event.detail.value;
				break;
			case 'description':
				this.description = event.detail.value;
				//this.tempCase.Description = event.detail.value;
				break;
			case 'descriptionOfContents':
				this.descriptionOfContents = event.detail.value;
				//this.tempCase.Description_of_contents__c = event.detail.value;
				break;
			case 'isContainsMedication':
				this.isContainsMedication = event.detail.value;
				break;
			case 'isSentimental':
				this.isSentimental = event.detail.value;
				break;
			case 'itemValue':
				this.itemValue = event.detail.value;
				break;
			default:
				console.error('unhandled field change:' + field);
				break;
		}

	}

	onUploadFinished(event)
	{
		//this.uploadedFiles = event.detail.files;
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
			if(objFile.documentId == fileId)
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

		const inputComponents = this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox, lightning-radio-group');
		const addressCmp = this.template.querySelectorAll('[data-validate="doAddressValidate"]');
		const allValid = checkAllValidity(inputComponents) & checkAllValidity(addressCmp, false);

		if (!allValid) {
			this.showSpinner = false;
			this.errorMessage = topGenericErrorMessage;
			return;
		}

		this.tempCase.ReferenceID__c = this.trackingId;
		this.tempCase.BSPLodgementDate__c = this.lodgementDate;
		this.tempCase.ArticleType__c = this.articleType;
		this.tempCase.CCUServiceUsed__c = this.serviceUsed;
		this.tempCase.CCUYourReference__c = this.reference;
		this.tempCase.Description = this.description;
		this.tempCase.DescriptionofContents__c = this.descriptionOfContents;
		this.tempCase.ValueofContents__c  = this.itemValue;
		this.tempCase.EstimatedDelivery__c = this.article.ExpectedDeliveryDate__c;

		this.setCasePriority(this.isContainsMedication);
		this.setCasePriority(this.isSentimental);

		// set the case type definitions
		this.caseTypeAttributes();

		// get the address stuff
		this.getAddressesFromInput();

		createEnquiryAusPost({
		    enq: this.tempCase,
			uploadedFiles: this.uploadedFiles,
			additionalData: {containsEssentialMedicine: this.isContainsMedication, isSentimental: this.isSentimental}
        }).then(result =>{
			if(result.status == 'error'){
				this.errorMessage = result.message;
			} else {
				this.tempCase = result.enquiry;
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
	 * Setting the case priority based on the questions;
	 * Does the item contain essential medication?
	 * Is the item urgent, sentimental or high value?
	 * IF either of questions set to high we do not set it back to low
	 * @param value
	 */
	setCasePriority(value){
		switch (value.toLowerCase())
		{
			case 'yes':
				this.tempCase.Priority = 'High';
				break;
			case 'no':
				if(this.tempCase.Priority != 'High') {
					this.tempCase.Priority = 'Low';
				}
				break;
		}
	}
	caseTypeAttributes()
	{

		this.tempCase.Type = 'Investigation';
		switch (this.enquiryType.toLowerCase())
		{
			case 'missing item':
				this.tempCase.CCUEnquiryType__c = 'Missing Item';
				break;
			case 'delivery':
				this.tempCase.CCUEnquiryType__c = 'Delivery Issue';
				break;
			case 'rts':
				this.tempCase.CCUEnquiryType__c = 'RTS Request';
				break;

		}
	}

	getAddressesFromInput()
	{
		// sender Details
		let senderAddressCmp = this.template.querySelector('c-bsp-address-input[data-id="senderAddress"]');
		this.tempCase.BSP_Sender_Name__c = senderAddressCmp.firstName + ' ' + senderAddressCmp.lastName;
		this.tempCase.BSP_Sender_Company__c = senderAddressCmp.businessName;
		this.tempCase.BSP_Sender_Address__c = this.mergeAddressFields(senderAddressCmp.address);

		// receiver details
		let receiverAddressCmp = this.template.querySelector('c-bsp-address-input[data-id="receiverAddress"]');
		this.tempCase.BSP_Addressee_Name__c = receiverAddressCmp.firstName + ' ' + receiverAddressCmp.lastName;
		this.tempCase.BSP_Addressee_Company__c = receiverAddressCmp.businessName;
		this.tempCase.BSP_Addressee_Address__c = this.mergeAddressFields(receiverAddressCmp.address);
	}

	mergeAddressFields(address)
	{
		return `${address.addressLine1 ? `${address.addressLine1},` : ''} ${address.addressLine2 ? ` ${address.addressLine2},` : ''} ${address.city || ''} ${address.state || ''} ${address.postcode || ''} ${address.countryName || ''}`//updated 'countrycode' with 'countryName' as no 'countrycode' 09.11.2020
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

	debugLog(sLog) {
		this.logs.push(sLog);
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