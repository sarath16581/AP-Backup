/* eslint-disable no-console */
/* eslint-disable no-unused-vars */
/**
  * @author       : Rufus Solomon
  * @date         : 08/05/2019
  * @description  : Something else - Others form
--------------------------------------- History --------------------------------------------------
08.05.2019    RSolomon      Created
13.08.2019    Ronnie Yang   REQ1885741 Added compensation section to this form
20.08.2019    Ronnie Yang   REQ1885886 - Only displays product category section if the user has answered the previous question
22.08.2019    Gunith Devasurendra     Phone number mandatory and supporting 13XXXX format (REQ1886690)
22.10.2019    Gunith Devasurendra     UI changes when Cases auto close for Feedback cases (REQ1982330)
26.05.2021    Naveen Rajanna           REQ2513603 Show Print button when submitted and hide few tags upon print
**/

import { track } from 'lwc'
import LwcForm from 'c/lwcForm'
import getNetworkUsers from '@salesforce/apex/MyNetworkSmartFormsService.getListOfNetworksForLoginUser'
import getProductPickListValuesByNames from '@salesforce/apex/MyNetworkSmartFormsService.getProductPickListValuesByNames'
import getEnquirySubTypeValues from '@salesforce/apex/MyNetworkSmartFormsService.getTypeAndProductEnqSubTypePickListValues'
import createCase from '@salesforce/apex/MyNetworkSmartForms.createCase'
import { get, ausPhoneNumberRegEx } from 'c/utils'
import getSubCatValuesToDisableCompensation from '@salesforce/apex/MyNetworkSmartFormsService.getSubCatValuesToDisableCompensation'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class myNetworkOthersForm extends LwcForm {

	contactCustomerConfig = {
		parentName: 'caseType',
		showFor: 'Feedback',
	}

	compensationRenderConfig = {
		parentName: 'compensationBeingPaid',
		showFor: 'yes',
	}

	caseTypeOptions = [
		{ value: 'Investigation', label: 'Yes' },
		{ value: 'Feedback', label: 'No' },
	]

	yesNoOptions = [
		{ value: 'yes', label: 'Yes' },
		{ value: 'no', label: 'No' },
	]
	
	categoryRenderConfig = {
		parentName: 'caseType',
		showIfExists: true,
	}
	
	productCategoryOptions = []

	productSubCategoryOptions = []

	enquirySubTypeOptions = []

	printVisibleData = () => {}

	phoneNumberRegEx = ausPhoneNumberRegEx;

	phoneNumberRegEx = ausPhoneNumberRegEx;

	@track
	facilityOptions = [] 

	@track
	caseNumber

	@track
	caseId

	@track
	fileName = ''

	@track
	submitted = false

	@track
	submitting = false

	@track
	fileUploaded = false

	@track
	productCategoryDepenendentValues = []

	@track
	subCatvaluesToDisableCompensation = []
	
	@track
	displayCategorySection = false

	@track
	displayCompensationMessage = false

	@track
	displayCompensationSection = false

	@track
	enquirySubTypeValues = []

	@track
	customerName

	@track
	displayErrorMsg = false

	@track
	displayCustomerNotProvidedResponse = false;

	get acceptedFormats() {
		return ['.jpg', '.png', '.pdf']
	}

	handleUploadFinished(event) {
		// Get the list of uploaded files
		const uploadedFiles = event.detail.files
		if(uploadedFiles.length > 0) {
			this.fileName = uploadedFiles[0].name
		}
		this.fileUploaded = true
	}

	connectedCallback() {
		getNetworkUsers()
		.then(data => {
			this.facilityOptions = this.formatNetworkUsersRecordsToFacilityPicklistOptions(data)
		})
		.catch(error => {
			console.log(error)
		}) 

		getProductPickListValuesByNames()
		.then(data => {
			this.formatProductPickListValuesByNames(data)
		})
		.catch(error => {
			console.log(error)
		})

		getEnquirySubTypeValues()
		.then(data => {
			this.formatEnquirySubTypePickListValues(data)
		})
		.catch(error => {
			console.log(error)
		})

		getSubCatValuesToDisableCompensation()
		.then(data => {
			this.formatToDisableCompensation(data)
		})
	}

	formatNetworkUsersRecordsToFacilityPicklistOptions(networkUsers) {
		const networkMap = networkUsers
		.reduce((acc, networkUser) => {
			if (networkUser.Network__r) {
				acc[networkUser.Network__r.Id] = networkUser.Network__r.Name
			}
			return acc
		}, {})
		return Object.entries(networkMap).map(([networkId, networkName]) => ({ 'label': networkName, 'value': networkId }))
	}

	formatProductPickListValuesByNames(productPickListValues){
		let Category = [], key;
		for(key in productPickListValues){
			if(Object.prototype.hasOwnProperty.call(productPickListValues, key)){
				this.productCategoryDepenendentValues.push({value:productPickListValues[key], key:key}); //Here we are creating the array to show on UI.
				Category.push({value:key,label:key})
			}
		}
		this.productCategoryOptions = Category
	}

	handleProductCategoryChange(event){
		let subCategory = [], key, keyData, scValue;
		for(key in this.productCategoryDepenendentValues){
			if(Object.prototype.hasOwnProperty.call(this.productCategoryDepenendentValues, key)){
				keyData = this.productCategoryDepenendentValues[key].key;
				if(keyData===event.target.value){
					for(scValue in this.productCategoryDepenendentValues[key].value){
						if(Object.prototype.hasOwnProperty.call(this.productCategoryDepenendentValues[key].value, key)){
							subCategory.push({value:this.productCategoryDepenendentValues[key].value[scValue],label:this.productCategoryDepenendentValues[key].value[scValue]})
						}
					}
				}
			}
			
		}
		this.productSubCategoryOptions = subCategory    

		// Reset Product Sub Category and Type of Damage fields when Product Category is changed
		this.template.querySelector(".productSubCategory").value = '';
		this.template.querySelector(".enquirySubType").value = '';
		this.setFormValue({ 
			productSubCategory: '',
			enquirySubType: '' 
		})
	}
	
	formatEnquirySubTypePickListValues(enquirySubTypePickListValues){
		let key;
		for(key in enquirySubTypePickListValues){
			if(Object.prototype.hasOwnProperty.call(enquirySubTypePickListValues, key)){
				this.enquirySubTypeValues.push({value:enquirySubTypePickListValues[key], key:key});
			}
		}
	}

	formatToDisableCompensation(valuesToDisable){
		let key;
		for (key in valuesToDisable){
			if(Object.prototype.hasOwnProperty.call(valuesToDisable, key)){
				this.subCatvaluesToDisableCompensation.push({value:valuesToDisable[key], key:key});
			}
		}
	}

	handleProductSubCategoryChange(event){
		let enquirySubType = [], key, keyData, scValue;
		let valueToCompare = this.values.caseType + '|' + this.values.productCategory + '|' + event.target.value;
		console.log('valueToCompare'+valueToCompare);

		this.enquirySubTypeOptions = enquirySubType 
		for(key in this.enquirySubTypeValues){
			if(Object.prototype.hasOwnProperty.call(this.enquirySubTypeValues, key)){
				keyData = this.enquirySubTypeValues[key].key;
				if(keyData===valueToCompare){
					for(scValue in this.enquirySubTypeValues[key].value){
						if(Object.prototype.hasOwnProperty.call(this.enquirySubTypeValues[key].value, scValue)){
							enquirySubType.push({value:this.enquirySubTypeValues[key].value[scValue],label:this.enquirySubTypeValues[key].value[scValue]})
						}
					}
				}
			}
		}

		//responsive compensation section based on sub-category selection
		this.displayCompensationMessage = false
		this.displayCompensationSection = false
		for(key in this.subCatvaluesToDisableCompensation){
			if(Object.prototype.hasOwnProperty.call(this.subCatvaluesToDisableCompensation, key)){
				keyData = this.subCatvaluesToDisableCompensation[key].key;
				if(keyData===this.values.productCategory){
					scValue = this.subCatvaluesToDisableCompensation[key].value;
					if(scValue.includes(event.target.value)){
						this.displayCompensationMessage = true
						this.displayCompensationSection = false
					}
					else{
						this.displayCompensationSection = true
					}
				}
			}
		}
	}

	handleContactCustomerChange(changeEvent){
		//Display the next section (Category selection)
		this.displayCategorySection = true

		// Reset Product Sub Category and Type of Damage fields when Product Category is changed
		this.template.querySelector(".productCategory").value = '';
		this.template.querySelector(".productSubCategory").value = '';
		this.template.querySelector(".enquirySubType").value = '';
		this.setFormValue({ 
			productCategory: '',
			productSubCategory: '',
			enquirySubType: '' 
		})

		if (changeEvent.target.value == 'Feedback'){
			this.displayCustomerNotProvidedResponse = true;
		} else {
			this.displayCustomerNotProvidedResponse = false;
		}
	}

	/**
	 * onchange for compensationBeingPaid.
	 * If yes, Does the customer need to be contacted? becomes 'no' and disabled. Also showing a warning message.
	 * If no, undo the above
	 */
	compensationBeingPaidChangeHandler(changeEvent){
		if (changeEvent.target.value == 'yes'){
			this.values.caseType = 'Feedback';
			this.displayCustomerNotProvidedResponse = true;
			this.template.querySelector(".caseType").disabled = true;

		} else {
			this.template.querySelector(".caseType").disabled = false;
		}

		this.values.compensationBeingPaid = changeEvent.target.value;
	}

	handleSubmit = () => {
		const formId = "somethingElse"
		const formJson = JSON.stringify(this.getVisibleData())
		console.log('datatosubmit:'+ formJson)
		console.log('formId:'+ formId)
		const allValid = this.validateInputs()
		//smartFormIdJson[formId] = formJson;
		
		const formData = [{
			formId,
			...this.getVisibleData()
		}]

		if (!allValid) {
			this.displayErrorMsg = true  
		}

		if (allValid) {
			this.displayErrorMsg = false  
			this.submitting = true  
			
			createCase({
				smartFormIdJson : JSON.stringify(formData)
			})
			.then(data => {
				this.formatCreateCaseResponse(data)
			})
			.catch(error => {
				console.log('Case creation failed...'+JSON.stringify(error));
				const evt = new ShowToastEvent({
					message : 'Case creation failed',
					variant : 'error',
					mode : 'sticky',
				});
				this.dispatchEvent(evt);
				this.submitting = false;
			})
		}

		// This customerName is displayed on Case Confirmation screen
		this.customerName = this.getVisibleData().FirstName + ' '+this.getVisibleData().LastName;
	}

	formatCreateCaseResponse(caseDetails){
		const networkMap = caseDetails
		.reduce((acc, caseDetail) => {
			if (caseDetail) {
				this.caseNumber = caseDetail.CaseNumber
				this.caseId = caseDetail.Id
				this.submitted = true
				this.submitting = false
			}
			return acc
		}, {})
	}

	formatDataForFormUpdate = record => {
		return {
			senderName: get(record, 'articleDetails.proxyArticle.SenderName__c'),
			senderEmail: get(record, 'articleDetails.proxyArticle.SenderEmail__c'),
			senderCompany: get(record, 'articleDetails.proxyArticle.SenderCompany__c'),
			addresseeName: get(record, 'articleDetails.proxyArticle.ReceiverName__c'),
			addresseeEmail: get(record, 'articleDetails.proxyArticle.ReceiverEmail__c'),
		}
	}

	extractSenderAddress = record => ({
		addressLine1: get(record, 'articleDetails.proxyArticle.SenderAddressLine1__c'),
		addressLine2: `${get(record, 'articleDetails.proxyArticle.SenderAddressLine2__c') || ''}${get(record, 'articleDetails.proxyArticle.SenderAddressLine3__c') ? `, ${get(record, 'articleDetails.proxyArticle.SenderAddressLine3__c')}` : ''}`,
		city: get(record, 'articleDetails.proxyArticle.SenderCity__c'),
		state: get(record, 'articleDetails.proxyArticle.SenderState__c'),
		postcode: get(record, 'articleDetails.proxyArticle.SenderPostcode__c'),
		countrycode: get(record, 'articleDetails.proxyArticle.SenderCountry__c'),
	})

	extractSenderAddressSearchTerm = record => get(record, 'articleDetails.proxyArticle.SenderAddress__c')

	extractAddresseeAddress = record => ({
		addressLine1: get(record, 'articleDetails.proxyArticle.ReceiverAddressLine1__c'),
		addressLine2: `${get(record, 'articleDetails.proxyArticle.ReceiverAddressLine2__c') || ''}${get(record, 'articleDetails.proxyArticle.ReceiverAddressLine3__c') ? `, ${get(record, 'articleDetails.proxyArticle.ReceiverAddressLine3__c')}` : ''}`,
		city: get(record, 'articleDetails.proxyArticle.ReceiverCity__c'),
		state: get(record, 'articleDetails.proxyArticle.ReceiverState__c'),
		postcode: get(record, 'articleDetails.proxyArticle.ReceiverPostcode__c'),
		countrycode: get(record, 'articleDetails.proxyArticle.ReceiverCountry__c'),
	})

	extractAddresseeAddressSearchTerm = record => get(record, 'articleDetails.proxyArticle.ReceiverAddress__c')


	setFormValue = newValues => {
		this.updateValuesAndVisibilities(newValues)
	}

	handleFormUpdateWithAtricleData = data => {
		const valuesToUpdate = this.formatDataForFormUpdate(data)
		// set address and address search terms
		const senderAddressValidationComponent = this.template.querySelector('.sender-address')
		const senderAddress = this.extractSenderAddress(data)
		const senderAddressSearchTerm = this.extractSenderAddressSearchTerm(data)
		senderAddressValidationComponent.setAddressSearchTerm(senderAddressSearchTerm)
		senderAddressValidationComponent.setAddress(senderAddress)

		const addresseeAddressValidationComponent = this.template.querySelector('.addressee-address')
		const addresseeAddress = this.extractAddresseeAddress(data)
		const addresseeAddressSearchTerm = this.extractAddresseeAddressSearchTerm(data)
		addresseeAddressValidationComponent.setAddressSearchTerm(addresseeAddressSearchTerm)
		addresseeAddressValidationComponent.setAddress(addresseeAddress)

		this.setFormValue({
			...valuesToUpdate,
			senderAddress,
			senderAddressSearchTerm,
			addresseeAddress,
			addresseeAddressSearchTerm,
		})
	}

	compensationAmountChangeHandler = compAmount => {
		this.setFormValue({ compensationAmount: compAmount })
	}

	postageValueChangeHandler = postageVal => {
		this.setFormValue({ postageValue: postageVal })
	}

	senderAddressChangeHandler = address => {
		this.setFormValue({ senderAddress: address })
	}

	addresseeAddressChangeHandler = address => {
		this.setFormValue({ addresseeAddress: address })
	}

	customerAddressChangeHandler = address => {
		this.setFormValue({ customerAddress: address })
	}

	senderAddressSearchTermChangeHandler = mergedAddress => {
		this.setFormValue({ senderAddressSearchTerm: mergedAddress })
	}

	addresseeAddressSearchTermChangeHandler = mergedAddress => {
		this.setFormValue({ addresseeAddressSearchTerm: mergedAddress })
	}

	customerAddressSearchTermChangeHandler = mergedAddress => {
		this.setFormValue({ customerAddressSearchTerm: mergedAddress })
	}

	searchResultSelectHandler = (record) => {
		const formattedRecord = this.formatRecordForFormUpdate(record)
		this.setFormValue({
			...formattedRecord,
			contactId:record.Id,
		})
	}

	formatRecordForFormUpdate = record => {
		return record
	}

	handleFacilityValueChange(event){
		const facilityId = event.target.value;
		const selectedFacilityOption = this.facilityOptions.find(facilityOption => facilityOption.value === facilityId)
		const facilityName = selectedFacilityOption && selectedFacilityOption.label
		this.setFormValue({
			facilityId,
			facilityName,
		})
	}
	
	printScreen(event){
		window.print();
	}  
}