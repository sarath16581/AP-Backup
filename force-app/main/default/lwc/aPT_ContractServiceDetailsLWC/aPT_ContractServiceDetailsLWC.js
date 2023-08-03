/**
 * @author Yatika Bansal
 * @date 2023-06-03
 * @description
 * * Lightning Web Component is launched from two places:
 * 	-A custom checkout action in Apttus Shopping cart (aPT_CheckOutLWC),
 *  -A formula field 'Create Contract' on Proposal to trigger Contract Generation Process
 * Objective: It is used to create contract and service details creation.
 * Change log: 
 * 9-04-2023 : Yatika Bansal : Added logic for amend/renew
*/
import { LightningElement, api, wire, track} from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import createContractRecord from '@salesforce/apex/APT_ContractServiceDetailsController.createContractRecord';
import getServiceDetail from '@salesforce/apex/APT_ContractServiceDetailsController.getServiceDetail';
import getCurrentAddress from '@salesforce/apex/APT_ContractServiceDetailsController.getCurrentAddress';
import updateCollectionAddress from '@salesforce/apex/APT_ContractServiceDetailsController.updateCollectionAddress';
import { NavigationMixin } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';

import Id from '@salesforce/user/Id';
import UserProfileField from '@salesforce/schema/User.Profile.Name';

import ENTITY_FIELD from '@salesforce/schema/Apttus__APTS_Agreement__c.APT_Contracting_Entity1__c';
import CONTACT_FIELD from '@salesforce/schema/Apttus__APTS_Agreement__c.Apttus__Primary_Contact__c';
import CONDITION_FIELD from '@salesforce/schema/Apttus__APTS_Agreement__c.Term__c';
import OFFER_EXP_FIELD from '@salesforce/schema/Apttus__APTS_Agreement__c.Contract_Expiration_Date__c';
import START_DATE_FIELD from '@salesforce/schema/Apttus__APTS_Agreement__c.Apttus__Contract_Start_Date__c';
import INCL_PRODLINE_FIELD from '@salesforce/schema/Apttus__APTS_Agreement__c.Included_Product_Lines__c';
import TYPE_FIELD from '@salesforce/schema/Apttus__APTS_Agreement__c.APT_Contract_Type__c';
import END_DATE_FIELD from '@salesforce/schema/Apttus__APTS_Agreement__c.Apttus__Contract_End_Date__c';
import TERM_FIELD from '@salesforce/schema/Apttus__APTS_Agreement__c.Apttus__Term_Months__c';

import SERVICE_START_FIELD from '@salesforce/schema/Apttus__AgreementLineItem__c.Apttus_CMConfig__EffectiveDate__c';
import SERVICE_END_FIELD from '@salesforce/schema/Apttus__AgreementLineItem__c.Apttus_CMConfig__EndDate__c';

export default class APT_ContractServiceDetailsLWC extends NavigationMixin(LightningElement) {
	@api existingContractId ; // receive as paramenters from Parent in case of edit
	@api currentStatus; // receive as paramenters from Parent in case of edit
	@api proposalId; // receive as paramenters from Parent
	@api isST; // receive as paramenters from Parent
	@api isManualContract; // receive as paramenters from Parent
	@api isAmend;  // receive as paramenters from Parent
	@api isRenew;  // receive as paramenters from Parent
	isAppc;
	error;
	contractId;
	address;
	isLoading = true;
	hasRendered = false;
	hideComp = false;
	progress = 10000;
	customerOnboardingUserProfile = 'Enterprise Onboarding';
	salesUserProfile = 'BG Base';
	currentAddress; //to show in case of edit

	contractObjName = 'Apttus__APTS_Agreement__c';
	openEnd = 'Open Ended';
	fixedTerm = 'Fixed Term';
	restrictedStatuses = new Set(['Fully Signed', 'SFDC Case Created', 'Activated', 'Other Party Signatures']);
	parcelContractLine = 'Parcel Contract';
	aliObjName = 'Apttus__AgreementLineItem__c';
	@track serviceIds = [];   //Stores Service Records Ids

	//flags for controlling fields access
	termFieldDisabled;
	termFieldRequired;
	startDateRequired;
	aggstartDateDisabled;
	// store url for navigation
	contractValidationUrl = '/apex/APT_CreateContractValidation?id=' ;
	linkBillingAccUrl = '/lightning/cmp/c__APT_LinkingBillingAccountToContractWrapper?c__recordId=';
	manageLodgementPointUrl = '/apex/APT_ManageContractLodgementPoint?agId=' ;

	entityField = ENTITY_FIELD;
	contactField = CONTACT_FIELD;
	conditionField = CONDITION_FIELD ;
	expDateField = OFFER_EXP_FIELD;
	startDateField =  START_DATE_FIELD;
	inclProdField =  INCL_PRODLINE_FIELD;
	typeField = TYPE_FIELD ;
	endDateField = END_DATE_FIELD;
	termField =  TERM_FIELD;

	serviceStartField = SERVICE_START_FIELD;
	serviceEndField =SERVICE_END_FIELD;
	//stores values of fields
	ownerValue;
	startDateValue;
	endDateValue;
	expDateValue;
	termValue;
	serviceStartValue;
	serviceEndValue;

	//error messages
	expiryDateBeforeMsg = 'Service Expiry Date cannot be before Service Commencement Date and/or Agreement Commencement Date';
	expiryDateAfterMsg = 'Service Expiry Date cannot be after Agreement Expiry Date';
	expDateRequiredMsg = 'Service Expiry Date cannot be blank';
	startDateAfterMsg = 'Service Commencement Date cannot be after Agreement Expiry Date';
	startDatePopulateMsg = 'To nominate service commencement date, Agreement Commencement Date cannot be blank or after the service commencement date';
	scdRequiredMsg = 'Service Commencement Date cannot be blank';
	scdCantBeInPastMsg = 'Service Commencement Date cannot be in the past';
	scdCantBeAfterOfferExpMsg = 'Service commencement date is outside the proposal/offer expiration date. You need to review the service commencement date to proceed';
	expDateMsg = 'Agreement commencement date cannot be after offer expiration date';
	startDateRequiredMsg = 'Agreement Commencement Date cannot be blank';
	acdCantBeInPastMsg = 'Agreement Commencement Date cannot be in the past';
	contractSentForSignMsg = 'This contract has been sent for signing. To edit the contract information, you need to withdraw the signature request, regenerate the contract document, and resend for signing';
	//termMsg = 'Term of Agreement (Months) cannot be blank';
	termWholeMsg = 'Term of Agreement (Months) is required and can only be a positive whole number';
	credAssessPromptMsg = 'Prospect customer requires credit assessment to be completed and approved prior generating contract document. Click "OK" to submit credit assessment.';
	datesError;
	startError;
	endError;
	termError;
	readyToShowComponent = false;
	tempBool = false;

	//disable button in case of error
	get disableButton(){
		return (this.error || this.datesError || this.startError ||this.endError || this.termError);
	}

	connectedCallback(){
		if(!this.hasRendered){
			//Create Contract
			if(!this.existingContractId){
				//function to create Contract Record onLoad
				createContractRecord({proposalId : this.proposalId})
				.then((result) => {
					if (result.includes('Incomplete')) {
						//prompt to complete cred assess
						LightningAlert.open({
							message: this.credAssessPromptMsg,
							theme: 'info',
							label: "Credit Assessment"
						}).then(() => {
							//navigate to opp to complete credit assessment
							let opportunityRecordURL = 'https://' + window.location.host + '/' +  result.split('_')[1];
							this[NavigationMixin.Navigate]({
								type: 'standard__webPage',
								attributes: {
									url: opportunityRecordURL,
								}
							});
						});
					}
					else if(result.includes('Error')){
						this.error = result;
						this.isLoading = false;
						this.hasRendered = true;
					}else{
						this.contractId = result;
						//some delay before getting child line items
						this._interval = setInterval(() => {
							this.progress = this.progress + 10000;
							this.getServiceDetails();
						}, this.progress);
					}
				})
				.catch((error) => {
					this.error = error.body.message;
					this.isLoading = false;
				});
			}

			//Edit Contract
			else{
				this.contractId = this.existingContractId;
				this.getServiceDetails();
			}
		}
	}

	/**
	* function to check current user and show component accordingly
	*/
	@wire(getRecord, { recordId: Id, fields: [UserProfileField] })
	currentUserInfo({ error, data }) {
		if (data) {
			if(getFieldValue(data, UserProfileField) === this.salesUserProfile){
				if(this.restrictedStatuses.has(this.currentStatus)){
					this.hideComp = true;
				}
			}
		} else if (error) {
			this.error = error.body.message;
		}
	}

	/**
	* function to get contract owner name
	*/
	@wire(getRecord, { recordId: '$contractId', fields: ['Apttus__APTS_Agreement__c.Owner.Name'] })
	getContractOwner({ error, data }) {
		if (data && this.ownerValue == null) {
			this.ownerValue = data.fields.Owner.value.fields.Name.value;
		} else if (error) {
			this.error = error.body.message;
		}
	}

	/**
	* function to get agreement services details
	*/
	getServiceDetails(){
		getServiceDetail({contractId : this.contractId})
		.then((result) => {
			result.forEach(rec => {
				this.serviceIds.push(rec);
			});
			//If service Id received, clear interval and stop loading
			if ( this.serviceIds.length !== 0 ) {
				clearInterval(this._interval);

				//Get current address only in case of edit
				if(this.existingContractId){
					this.getCurrentCollectionAddress();
				}else{
					this.isLoading = false;
					this.hasRendered = true;
				}
			}
			this.readyToShowComponent = true;
		})
		.catch((error) => {
			this.error = error;
			this.isLoading = false;
		});
	}

	/**
	* function to get current collection address
	*/
	getCurrentCollectionAddress(){
		getCurrentAddress({contractId : this.contractId})
		.then((result) => {
			this.currentAddress = result;
			this.isLoading = false;
			this.hasRendered = true;
		})
		.catch((error) => {
			this.error = error.body.message;
			this.isLoading = false;
		});
	}

	/**
	* function to perform some logic onload of contract form
	*/
	handleOnLoad(){

		//Check for APPC
		let prodLine = this.template.querySelector('.prodLinesField').value;
		if(prodLine !== null){
			this.isAppc = prodLine.includes(this.parcelContractLine);
		}

		//ACD should be set to today on a new contract
		if(!this.existingContractId && this.isAmend !== 'true'){
			this.template.querySelector('.startDateField').value = this.calculateToday();
		}

		//Initialize values onLoad
		if(this.isAmend === 'true'){
			this.aggstartDateDisabled = true;
		}
		if(!this.existingContractId && this.isRenew === 'true'){
			this.template.querySelector('.condField').value = this.fixedTerm;
			this.template.querySelector('.endDateField').value = null;
		}

		this.startDateValue = this.template.querySelector('.startDateField').value;
		this.endDateValue = this.template.querySelector('.endDateField').value;
		this.expDateValue = this.template.querySelector('.expDateField').value;
		this.termValue = this.template.querySelector('.termField').value;

		if(this.template.querySelector('.condField').value != null)
			this.checkContractConditions(this.template.querySelector('.condField').value);
	}

	/**
	* function to perform some logic onload of service form
	*/
	handleOnLoadService(){
		if(!this.existingContractId && this.isRenew === 'true'){
			this.template.querySelectorAll('.serviceEndField').forEach((cmp) => {cmp.value = null});
		}
		this.serviceStartValue = this.template.querySelector('.serviceStartField').value;
		this.serviceEndValue = this.template.querySelector('.serviceEndField').value;
	}

	/**
	* function to update term field access on contract type change
	* @param event
	*/
	handleConditionsChange(event){
		this.checkContractConditions(event.target.value);

		//Run dependent validations when conditions are changed
			if(event.target.value === this.openEnd){
				//Run dependent validations
				this.validateAggStartDate(this.template.querySelector('.startDate'));
				this.validateTerm(this.template.querySelector('.term'));

				this.template.querySelector('.endDate').value = '2999-12-31';
				this.template.querySelector('.term').value = '';
			this.template.querySelectorAll('.serviceEnd').forEach((cmp) => {cmp.value = '2999-12-31'});
			}
			else if(event.target.value === this.fixedTerm){
				//Reset dependent fields
				this.template.querySelector('.endDate').value = null;
			this.template.querySelectorAll('.serviceEnd').forEach((cmp) => {cmp.value = null});
		}

		this.validateStartDate();
		this.validateEndDate();
	}

	/**
	* function to set address whenever confirmAddress event is fired from child
	* @param event
	*/
	handleAddressChange(event){
		this.address = event.detail.address;
	}

	/**
	* function to handle agreement commencement date changes
	* @param event
	*/
	handleAggStartDateChange(event){
		this.validateAggStartDate(event.target);

		let condField = this.template.querySelector('.condField').value;

		//Set agreement end date
		if(!this.datesError && condField === this.fixedTerm){
			this.calculateAED();
		}

		//Run dependent validations
		this.validateStartDate();
		this.validateEndDate();
	}

	/**
	* function to handle term field changes
	* @param event
	*/
	handleTermChange(event){
		this.validateTerm(event.target);

		//Set agreement end date
		if(!this.termError){
			this.calculateAED();
		}

		//Run dependent validations
		this.validateStartDate();
		this.validateEndDate();
	}

	/**
	* function to handle start date changes
	* @param event
	*/
	handleStartDateChange(event){
		this.validateStartDate();

		//Run dependent validations
		this.validateEndDate();
	}

	/**
	* function to handle expiry date changes
	* @param event
	*/
	handleEndDateChange(event){
		this.validateEndDate();
	}

	/**
	* function to update records on click of next button
	*/
	handleNext(){
		//run validations again
		this.validateAggStartDate(this.template.querySelector('.startDate'));
		this.validateTerm(this.template.querySelector('.term'));
		this.validateEndDate();

		if(!this.startError && !this.endError && !this.termError && !this.datesError && !this.error){
			//Set Values
			this.setFinalValues();
			this.isLoading = true;
			this.template.querySelectorAll('lightning-record-edit-form').forEach((form) => {form.submit()});
			this.updateAddress(this.address);
		}
	}

	/**
	* function to update collection address
	*/
	updateAddress(address){
		updateCollectionAddress({contractId : this.contractId, address : address})
		.then((result) => {
			if(result.includes('Error')){
				this.error = result;
				this.isLoading = false;
			}else{
				this.navigate();
			}
		})
		.catch((error) => {
			this.error = error.body.message;
			this.isLoading = false;
		});
	}

	/**
	* function to navigate to different pages based on Selected Products
	*/
	navigate(){

		let url;
		let count = 0;
		let inclProdLines = this.template.querySelector('.prodLinesField').value;

		//Existing Contract
		if(this.existingContractId){
			url = '/' + this.contractId;
		}else{
			//ST product
			if(this.isST === 'Yes'){
				if(this.isManualContract === 'true'){
					//navigate to contract for manual process
					url = '/' + this.contractId;
				}else{
					//includes Parcel Contract
					if(inclProdLines.includes(this.parcelContractLine)){
						count = 1;
					}
					url = this.contractValidationUrl + this.contractId +'&count=' + count ;
				}
			}
			// AP product
			else{
				//includes Parcel Contract
				if(inclProdLines.includes(this.parcelContractLine)){
					url = this.linkBillingAccUrl + this.contractId;
				}else{
					url = this.manageLodgementPointUrl + this.contractId;
				}
			}
		}

		//Navigate to Url
		this[NavigationMixin.Navigate]({
			type: 'standard__webPage',
			attributes: {
				url: url,
			}
		});
	}

	/**
	* function to control term field access based on contract type
	* @param value
	*/
	checkContractConditions(value){
		if(value === this.openEnd || this.isAmend === 'true'){
			this.termFieldRequired = false;
			this.termFieldDisabled = true;
		}else if(value === this.fixedTerm){
			this.termFieldRequired = true;
			this.termFieldDisabled = false;
		}
	}

	/**
	* function to handle validations on agreement start date
	* @param cmp
	*/
	validateAggStartDate(cmp){
		cmp.setCustomValidity("");
		this.datesError = false;

		let offerExpDate = this.template.querySelector('.expDate').value;
		if(cmp.value !== null && cmp.value !== '' && cmp.value > offerExpDate){
			cmp.setCustomValidity(this.expDateMsg);
			this.datesError = true;
		}
		if((cmp.value === null  || cmp.value === '') ){
			cmp.setCustomValidity(this.startDateRequiredMsg);
			this.datesError = true;
		}
		if(this.isAmend !== 'true' && cmp.value !== null && cmp.value !== '' && cmp.value < this.calculateToday() ){
			cmp.setCustomValidity(this.acdCantBeInPastMsg);
			this.datesError = true;
		}
		cmp.reportValidity();
	}

	/**
	* function to handle validations on service start date
	* @param cmp
	*/
	validateStartDate(){
		this.startError = false;
		this.template.querySelectorAll('.serviceStart').forEach((cmp) => {
			cmp.setCustomValidity("");

		let contractStartDate = this.template.querySelector('.startDate').value;
		let contractEndDate = this.template.querySelector('.endDate').value;
		let offerExpDate = this.template.querySelector('.expDate').value;

		if((cmp.value === null  || cmp.value === '') ){
			cmp.setCustomValidity(this.scdRequiredMsg);
			this.startError = true;
		}
		if(cmp.value !== null  && cmp.value !== '' &&
		(contractStartDate === null || contractStartDate === '' || cmp.value < contractStartDate)){
			cmp.setCustomValidity(this.startDatePopulateMsg);
			this.startError = true;
		}
		if(this.termFieldRequired && contractEndDate !== null && contractEndDate !== '' && cmp.value > contractEndDate){
			cmp.setCustomValidity(this.startDateAfterMsg);
			this.startError = true;
		}
		if(cmp.value !== null && cmp.value !== '' && cmp.value < this.calculateToday() ){
			cmp.setCustomValidity(this.scdCantBeInPastMsg);
			this.startError = true;
		}
		if((this.isAmend === 'true' || this.isRenew === 'true' ) && cmp.value !== null && cmp.value !== '' && cmp.value > offerExpDate ){
			cmp.setCustomValidity(this.scdCantBeAfterOfferExpMsg);
			this.startError = true;
		}

		cmp.reportValidity();
		});
	}

	/**
	* function to handle validations on service end date
	* @param cmp
	*/
	validateEndDate(){
		this.endError = false;
		this.template.querySelectorAll('.serviceEnd').forEach((cmp) => {
			cmp.setCustomValidity("");

		let serviceStartDate = this.template.querySelector('.serviceStart').value;
		let contractStartDate = this.template.querySelector('.startDate').value;
		let contractEndDate = this.template.querySelector('.endDate').value;
		let condField = this.template.querySelector('.condField').value;

		if(cmp.value !== null  && cmp.value !== '' &&  (cmp.value < serviceStartDate || cmp.value < contractStartDate)){
			cmp.setCustomValidity(this.expiryDateBeforeMsg);
			this.endError = true;
		}
		if(cmp.value !== null  && cmp.value !== '' && contractEndDate !== null && contractEndDate !== '' &&
		condField === this.fixedTerm && cmp.value > contractEndDate){
			cmp.setCustomValidity(this.expiryDateAfterMsg);
			this.endError = true;
		}
		if(condField === this.openEnd && (cmp.value === null  || cmp.value === '')){
			cmp.setCustomValidity(this.expDateRequiredMsg);
			this.endError = true;
		}
		cmp.reportValidity();
		});
	}

	/**
	* function to handle validations on term field
	* @param cmp
	*/
	validateTerm(cmp){
		// Setting temporary value to avoid Value Missing error message
		if (!this.termFieldRequired && !cmp.value ) {
			cmp.value = 0;
		}
		cmp.setCustomValidity("");
		this.termError = false;

		/*if(this.termFieldRequired && cmp.value === ''){
			cmp.setCustomValidity(this.termMsg);
			this.termError = true;
		}*/

		if(this.termFieldRequired && (cmp.value === '' || !cmp.value.match(/^([1-9]\d*)$/))){
			cmp.setCustomValidity(this.termWholeMsg);
			this.termError = true;
		}

		cmp.reportValidity();
	}

	/**
	* function to set final field values
	*/
	setFinalValues(){
		//If SCD/SED is blank set it to ACD/AED
		this.template.querySelectorAll('.serviceStart').forEach((cmp) => {
			if(cmp.value === null || cmp.value ==='' ){
				cmp.value = this.template.querySelector('.startDate').value;
			}
		});
		this.template.querySelectorAll('.serviceEnd').forEach((cmp) => {
			if(cmp.value === null || cmp.value ===''){
				cmp.value = this.template.querySelector('.endDate').value;
			}
		});

		this.template.querySelector('.startDateField').value = this.template.querySelector('.startDate').value ;
		this.template.querySelector('.serviceStartField').value = this.template.querySelector('.serviceStart').value ;
		this.template.querySelector('.serviceEndField').value = this.template.querySelector('.serviceEnd').value ;
		this.template.querySelector('.endDateField').value = this.template.querySelector('.endDate').value;

		//temp value should not be saved
		if(this.template.querySelector('.term').value !== 0){
			this.template.querySelector('.termField').value = this.template.querySelector('.term').value ;
		}
	}

	/**
	* function to calculate AED
	*/
	calculateAED(){
		if(this.template.querySelector('.startDate').value !== null && this.template.querySelector('.startDate').value !== '' && this.template.querySelector('.term').value !== '' && this.template.querySelector('.term').value !== null){
			let parts =this.template.querySelector('.startDate').value.split('-');
			let startDT = new Date(parts[0], parts[1]-1, parts[2]);
			let day = startDT.getDate();
			let month = startDT.getMonth();
			let year = startDT.getFullYear();

			month = month + parseInt(this.template.querySelector('.term').value);

			//aed should be a day before calculated date
			if(day === 1){
				day = new Date(year, month, 0).getDate();
				month = month - parseInt('1');
			}else{
				day = day - parseInt('1');
			}

			let endDT = new Date(year, month, day);
			let endDTday = ("0" + endDT.getDate()).slice(-2);
			let endDTMonth = ("0" + (endDT.getMonth() + 1)).slice(-2);
			this.template.querySelector('.endDate').value = endDT.getFullYear()+'-'+endDTMonth+'-'+endDTday;
		}
	}

	/**
	* function to calculate today's date
	*/
	calculateToday(){
		var today = new Date();
		var dd = ("0" + today.getDate()).slice(-2);
		var mm = ("0" + (today.getMonth() + 1)).slice(-2);
		var yyyy = today.getFullYear();
		return yyyy+'-'+ mm +'-'+ dd;
	}

	/**
	* function to redirect back to contract 
	*/
	handleClose(){
		this[NavigationMixin.Navigate]({
			type: 'standard__webPage',
			attributes: {
				url: '/' + this.contractId,
			}
		});
	}
}