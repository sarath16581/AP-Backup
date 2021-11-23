/* eslint-disable no-console */
/* eslint-disable no-unused-vars */
/**
  * @author       : Rufus Solomon
  * @date         : 08/05/2019
  * @description  : Mail redirection/hold form
--------------------------------------- History --------------------------------------------------
08.05.2019    RSolomon      Created
22.08.2022.08.2019    Gunith Devasurendra   Phone number mandatory and supporting 13XXXX format (REQ1886690)
26.05.2021    Naveen Rajanna        REQ2513603 Show Print button when submitted and hide few tags upon print
19.08.2021    Naveen Rajanna        REQ2595177 Introduce Copy to buttons and logic to Copy customer details to sender/addressee and 
                                    validation to restrict having same addressfor 'Old' and 'New' Mailhold
**/

import { track } from 'lwc'
import LwcForm from 'c/lwcForm'
import getNetworkUsers from '@salesforce/apex/MyNetworkSmartFormsService.getListOfNetworksForLoginUser'
import createCase from '@salesforce/apex/MyNetworkSmartForms.createCase'
import { get, getOrEmpty, ausPhoneNumberRegEx } from 'c/utils'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class myNetworkMailRedirectForm extends LwcForm {

    custRefNoConfig = {
        parentName: 'custRefNo',
        showFor: 'yes',
    }

    mailRedirectionConfig = {
        parentName: 'productSubCategory',
        showFor: 'Mail redirection',
    }

    mailHoldConfig = {
        parentName: 'productSubCategory',
        showFor: 'Mail hold',
    }

    yesNoOptions = [
        { value: 'yes', label: 'Yes' },
        { value: 'no', label: 'No' },
    ]

    mailRedirectOrHoldOptions = [
        { value: 'Mail redirection', label: 'Mail redirection' },
        { value: 'Mail hold', label: 'Mail hold' },
    ]

    typeOfServiceOptions = [
        { value: 'Domestic Letters', label: 'Letter' },
        { value: 'Domestic Parcels', label: 'Parcel' },
    ]

    domesticOrInternationalServiceOptions = [
        { value: 'Domestic', label: 'Domestic' },
        { value: 'International', label: 'International' },
    ]
    
    productCategoryOptions = [
        { value: 'Domestic Letter', label: 'Domestic Letter' },
        { value: 'Domestic Parcel', label: 'Domestic Parcel' },
        { value: 'International Letter', label: 'International Letter' },
        { value: 'International Parcel', label: 'International Parcel' },
    ]

    printVisibleData = () => {}

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
    customerName

    @track
    displayErrorMsg = false

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

    //REQ2595177
    validateForm() {
        let isValid = false
        let errorMsg = ''
        
        if(!(this.isUndefinedOrNull(this.getVisibleData().productSubCategory)) &&
                this.getVisibleData().productSubCategory === this.mailRedirectionConfig.showFor &&
                this.getVisibleData().senderAddressSearchTerm === this.getVisibleData().addresseeAddressSearchTerm) {
            isValid = false
            errorMsg = 'Old address cannot be the same as the new address'
        } else {
            isValid = true
            errorMsg = ''
        }
        const oldAddressCmp = this.template.querySelector('c-qas-address-validation[data-id="mailredirect-old-address-input"]')
        oldAddressCmp.setCustomValidity(isValid, errorMsg)
        const newAddressCmp = this.template.querySelector('c-qas-address-validation[data-id="mailredirect-new-address-input"]')
        newAddressCmp.setCustomValidity(isValid, errorMsg)

        isValid = this.validateInputs()
        return isValid; 
    }

    handleSubmit = () => {
        const formId = "mailRedirectHold"
        const formJson = JSON.stringify(this.getVisibleData())
        console.log('datatosubmit:'+ formJson)
        console.log('formId:'+ formId)
        const allValid = this.validateForm()
        //smartFormIdJson[formId] = formJson;
        
        const formData = [{
            formId,
            ...this.getVisibleData()
        }]
        
        if (!allValid) {
            this.displayErrorMsg = true
        }
        else { // Valid scenario
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
                    mode : 'pester',
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

    senderAddressChangeHandler = address => {
        this.setFormValue({ senderAddress: address })
    }

    addresseeAddressChangeHandler = address => {
        this.setFormValue({ addresseeAddress: address })
    }

    customerAddressChangeHandler = address => {
        this.setFormValue({ customerAddress: address })
    }

    mailHoldAddressChangeHandler = address => {
        this.setFormValue({ mailHoldAddress: address })
    }

    mailRedirectOldAddressChangeHandler = address => {
        this.setFormValue({ mailRedirectOldAddress: address })
    }

    mailRedirectNewAddressChangeHandler = address => {
        this.setFormValue({ mailRedirectNewAddress: address })
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

    mailHoldAddressSearchTermChangeHandler = mergedAddress => {
        this.setFormValue({ mailHoldAddressSearchTerm: mergedAddress })
    }

    mailRedirectOldAddressSearchTermChangeHandler = mergedAddress => {
        this.setFormValue({ mailRedirectOldAddressSearchTerm: mergedAddress })
    }

    mailRedirectNewAddressSearchTermChangeHandler = mergedAddress => {
        this.setFormValue({ mailRedirectNewAddressSearchTerm: mergedAddress })
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

    isUndefinedOrNull(field) {
        return (typeof field === 'undefined' || field === null);
    }
    
    getFormCustomerAddress = formData => ({
        addressLine1: getOrEmpty(formData, 'customerAddress.addressLine1'),
        addressLine2: getOrEmpty(formData, 'customerAddress.addressLine2'),
        city: getOrEmpty(formData, 'customerAddress.city'),
        state: getOrEmpty(formData, 'customerAddress.state'),
        postcode: getOrEmpty(formData, 'customerAddress.postcode'),
        countrycode: getOrEmpty(formData, 'customerAddress.countrycode'),
    })

    handleCopyToOldAddress(event) {
        const formData = this.getVisibleData()
        const senderAddress = this.getFormCustomerAddress(formData)
        const senderAddressSearchTerm = getOrEmpty(formData, 'customerAddressSearchTerm', '')
        const senderAddressValidationComponent = this.template.querySelector('.mailredirect-old-address')
        senderAddressValidationComponent.setAddressSearchTerm(senderAddressSearchTerm)
        senderAddressValidationComponent.setAddress(senderAddress)

        this.setFormValue({ 
            senderAddress,
            senderAddressSearchTerm,
        });
    }
    
    handleCopyToNewAddress(event) {
        const formData = this.getVisibleData()
        const addresseeAddress = this.getFormCustomerAddress(formData)
        const addresseeAddressSearchTerm = getOrEmpty(formData, 'customerAddressSearchTerm', '')
        const addresseeAddressValidationComponent = this.template.querySelector('.mailredirect-new-address')
        addresseeAddressValidationComponent.setAddressSearchTerm(addresseeAddressSearchTerm)
        addresseeAddressValidationComponent.setAddress(addresseeAddress)

        this.setFormValue({ 
            addresseeAddress,
            addresseeAddressSearchTerm
        });
    } 
    
    handleCopyToMailHoldAddress(event) {
        const formData = this.getVisibleData()
        const addresseeAddress = this.getFormCustomerAddress(formData)
        const addresseeAddressSearchTerm = getOrEmpty(formData, 'customerAddressSearchTerm', '')
        const addresseeAddressValidationComponent = this.template.querySelector('.mailhold-address')
        addresseeAddressValidationComponent.setAddressSearchTerm(addresseeAddressSearchTerm)
        addresseeAddressValidationComponent.setAddress(addresseeAddress)

        this.setFormValue({ 
            addresseeAddress,
            addresseeAddressSearchTerm
        });
    } 
}