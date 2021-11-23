/* eslint-disable no-console */
/* eslint-disable no-unused-vars */
/**
  * @author       : Rufus Solomon
  * @date         : 08/05/2019
  * @description  : Staff Feedback form
--------------------------------------- History --------------------------------------------------
08.05.2019    RSolomon      Created
22.08.2019    Gunith Devasurendra     Phone number mandatory and supporting 13XXXX format (REQ1886690)
26.05.2021    Naveen Rajanna           REQ2513603 Show Print button when submitted and hide few tags upon print
**/

import { track } from 'lwc'
import LwcForm from 'c/lwcForm'
import getNetworkUsers from '@salesforce/apex/MyNetworkSmartFormsService.getListOfNetworksForLoginUser'
import getProductPickListValues from '@salesforce/apex/MyNetworkSmartFormsService.getProductPickListValues'
import getNetworks from '@salesforce/apex/MyNetworkSmartFormsService.getListOfNetworksByRecordTypes'
import createCase from '@salesforce/apex/MyNetworkSmartForms.createCase'
import { get, ausPhoneNumberRegEx } from 'c/utils'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class myNetworkStaffFeedbackForm extends LwcForm {

    yesNoOptions = [
        { value: 'yes', label: 'Yes' },
        { value: 'no', label: 'No' },
    ]

    sendCaseToFacilityConfig = {
        parentName: 'facilityOutlet',
        showFor: 'yes',
    }

    senderOrAddresseeOptions = [
        { value: 'Sender', label: 'Sender' },
        { value: 'Addressee', label: 'Addressee' },
    ]

    complimentOrComplaintOptions = [
        { value: 'Staff Compliment', label: 'Compliment' },
        { value: 'Staff Complaint', label: 'Complaint' },
    ]

    typeOfDamageOptions = [
        { value: 'Packaging Only', label: 'Packaging Only' },
        { value: 'Contents - repairable', label: 'Contents - repairable' },
        { value: 'Contents - not repairable', label: 'Contents - not repairable' },
        { value: 'Contents Missing - evidence of tampering', label: 'Contents Missing - evidence of tampering' },
        { value: 'Contents Missing - no evidence of tampering', label: 'Contents Missing - no evidence of tampering' },
        { value: 'Damaged after delivery', label: 'Damaged after delivery' },
    ]

    productCategoryOptions = [
        { value: 'Domestic Letters', label: 'Domestic Letters' },
        { value: 'Domestic Parcels', label: 'Domestic Parcels' },
        { value: 'International Letters', label: 'International Letters' },
        { value: 'International Parcels', label: 'International Parcels' },
        { value: 'Post Office & Business Hub Services', label: 'Post Office & Business Hub Services' },
    ]

    phoneNumberRegEx = ausPhoneNumberRegEx;

    productSubCategoryOptions = []

    printVisibleData = () => {}
    
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
    productCategoryDependentValues = []

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

        getProductPickListValues()
        .then(data => {
            this.formatProductPickListValues(data)
        })
        .catch(error => {
            console.log(error)
        })

        getNetworks()
        .then(data => {
            this.networkOptions = this.formatNetworkRecordsToNeworkPicklistOptions(data)
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

    formatProductPickListValues(productPickListValues){
        var key;
        for(key in productPickListValues){
            if(Object.prototype.hasOwnProperty.call(productPickListValues, key)){
                this.productCategoryDependentValues.push({value:productPickListValues[key], key:key});
            }
        }
    }

    handleProductCategoryChange(event){
        var subCategory = [], key, keyData, scValue;
        for(key in this.productCategoryDependentValues){
            if(Object.prototype.hasOwnProperty.call(this.productCategoryDependentValues, key)){
                keyData = this.productCategoryDependentValues[key].key;
                if(keyData===event.target.value){
                    for(scValue in this.productCategoryDependentValues[key].value){
                        if(Object.prototype.hasOwnProperty.call(this.productCategoryDependentValues[key].value, scValue)){
                            subCategory.push({value:this.productCategoryDependentValues[key].value[scValue],label:this.productCategoryDependentValues[key].value[scValue]});
                        }
                    }
                }
            }
        }
        this.productSubCategoryOptions = subCategory    
    }

    formatNetworkRecordsToNeworkPicklistOptions(networks){
        const networkMap = networks
        .reduce((acc, network) => {
            if (network) {
                acc[network.Id] = network.Name
            }
            return acc
        }, {})
        return Object.entries(networkMap).map(([networkId, networkName]) => ({ 'label': networkName, 'value': networkId }))
    }

    handleSubmit = () => {
        const formId = "staffFeedback"
        const formValues = this.getVisibleData()
        const formJson = JSON.stringify(formValues)
        console.log('datatosubmit:'+ formJson)
        console.log('formId:'+ formId)
        const allValid = this.validateInputs()
        
        //smartFormIdJson[formId] = formJson;
        
        const formData = [{
            formId,
            ...formValues,
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

    senderAddressSearchTermChangeHandler = mergedAddress => {
        this.setFormValue({ senderAddressSearchTerm: mergedAddress })
    }

    addresseeAddressSearchTermChangeHandler = mergedAddress => {
        this.setFormValue({ addresseeAddressSearchTerm: mergedAddress })
    }

    cutomerAddressSearchTermChangeHandler = mergedAddress => {
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

    networkSearchResultSelectHandler = (record) => {
        const formattedNetworkSearchResult = this.formatNetworkSearchRecord(record)
        this.setFormValue(formattedNetworkSearchResult)
    }

    formatNetworkSearchRecord = record => ({
        networkName: record.Name,
        networkId: record.Id,
    })

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