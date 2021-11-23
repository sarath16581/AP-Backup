/* eslint-disable no-unused-vars */
/* eslint-disable no-console */
/**
  * @author       : Rufus Solomon
  * @date         : 08/05/2019
  * @description  : Delivery concerns/requests form
--------------------------------------- History --------------------------------------------------
08.05.2019    RSolomon      Created
22.08.2019    Gunith Devasurendra     Phone number mandatory and supporting 13XXXX format (REQ1886690)
14.08.2019    Gunith Devasurendra     Support clear address fields when Article ID is changed (REQ1885859)
26.05.2021    Naveen Rajanna           REQ2513603 Show Print button when submitted and hide few tags upon print
18.08.2021    Naveen Rajanna           REQ2588480 Introduce Copy to buttons and logic to Copy customer details to sender/addressee
**/

import { track } from 'lwc'
import LwcForm from 'c/lwcForm'
import getNetworkUsers from '@salesforce/apex/MyNetworkSmartFormsService.getListOfNetworksForLoginUser'
import getProductPickListValues from '@salesforce/apex/MyNetworkSmartFormsService.getProductPickListValues'
import getNetworks from '@salesforce/apex/MyNetworkSmartFormsService.getListOfNetworksByRecordTypes'
import createCase from '@salesforce/apex/MyNetworkSmartForms.createCase'
import { get, getOrEmpty, emptySearch, ausPhoneNumberRegEx } from 'c/utils'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

export default class myNetworkDeliveryConcernForm extends LwcForm {

    complaintOrRequestRenderConfig = {
        parentName: 'complaintOrRequestCheck',
        showFor: 'yes',
    }

    enquiryLinkedArticleConfig = {
        parentName: 'enquiryLinkedArticle',
        showFor: 'yes',
    }

    yesNoOptions = [
        { value: 'yes', label: 'Yes' },
        { value: 'no', label: 'No' },
    ]

    sendCaseToNetworkConfig = {
        parentName: 'facilityOutlet',
        showFor: 'yes',
    }

    senderOrAddresseeOptions = [
        { value: 'Addressee', label: 'Addressee' },
        { value: 'Sender', label: 'Sender' },
    ]

    complaintOrRequestOptions = [
        { value: 'Delivery request', label: 'Request' },
        { value: 'Delivery complaint', label: 'Complaint' },
    ]
    
    productCategoryOptions = [
        { value: 'Domestic Letters', label: 'Domestic Letters' },
        { value: 'Domestic Parcels', label: 'Domestic Parcels' },
        { value: 'International Letters', label: 'International Letters' },
        { value: 'International Parcels', label: 'International Parcels' },
    ]

    productSubCategoryOptions = []

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
    customerName

    @track
    articleId

    @track
    displayErrorMsg=false

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
                this.productCategoryDepenendentValues.push({value:productPickListValues[key], key:key});
            }
        }
    }

    handleProductCategoryChange(event){
        var subCategory = [], key, keyData, scValue;
        for(key in this.productCategoryDepenendentValues){
            if(Object.prototype.hasOwnProperty.call(this.productCategoryDepenendentValues, key)){
                keyData = this.productCategoryDepenendentValues[key].key;
                if(keyData===event.target.value){
                    for(scValue in this.productCategoryDepenendentValues[key].value){
                        if(Object.prototype.hasOwnProperty.call(this.productCategoryDepenendentValues[key].value, scValue)){
                            subCategory.push({value:this.productCategoryDepenendentValues[key].value[scValue],label:this.productCategoryDepenendentValues[key].value[scValue]});
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
        const formId = "deliveryConcern"
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
            senderName: getOrEmpty(record, 'articleDetails.proxyArticle.SenderName__c'),
            senderEmail: getOrEmpty(record, 'articleDetails.proxyArticle.SenderEmail__c'),
            senderCompany: getOrEmpty(record, 'articleDetails.proxyArticle.SenderCompany__c'),
            addresseeName: getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverName__c'),
            addresseeEmail: getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverEmail__c'),
            articleId: get(record, 'articleDetails.proxyArticle.ArticleID__c'),
        }
    }

    extractSenderAddress = record => ({
        addressLine1: getOrEmpty(record, 'articleDetails.proxyArticle.SenderAddressLine1__c'),
        addressLine2: `${getOrEmpty(record, 'articleDetails.proxyArticle.SenderAddressLine2__c') || ''}${getOrEmpty(record, 'articleDetails.proxyArticle.SenderAddressLine3__c') ? `, ${getOrEmpty(record, 'articleDetails.proxyArticle.SenderAddressLine3__c')}` : ''}`,
        city: getOrEmpty(record, 'articleDetails.proxyArticle.SenderCity__c'),
        state: getOrEmpty(record, 'articleDetails.proxyArticle.SenderState__c'),
        postcode: getOrEmpty(record, 'articleDetails.proxyArticle.SenderPostcode__c'),
        countrycode: getOrEmpty(record, 'articleDetails.proxyArticle.SenderCountry__c'),
    })

    extractSenderAddressSearchTerm = record => getOrEmpty(record, 'articleDetails.proxyArticle.SenderAddress__c')

    extractAddresseeAddress = record => ({
        addressLine1: getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverAddressLine1__c'),
        addressLine2: `${get(record, 'articleDetails.proxyArticle.ReceiverAddressLine2__c') || ''}${getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverAddressLine3__c') ? `, ${getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverAddressLine3__c')}` : ''}`,
        city: getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverCity__c'),
        state: getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverState__c'),
        postcode: getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverPostcode__c'),
        countrycode: getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverCountry__c'),
    })

    extractAddresseeAddressSearchTerm = record => getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverAddress__c')


    setFormValue = newValues => {
        this.updateValuesAndVisibilities(newValues)
    }

    handleFormUpdateWithArticleData = data => {
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
    
    networkSearchResultSelectHandler = (record) => {
        const formattedNetworkSearchResult = this.formatNetworkSearchRecord(record)
        this.setFormValue(formattedNetworkSearchResult)
    }

    formatRecordForFormUpdate = record => {
        return record
    }

    formatNetworkSearchRecord = record => ({
        networkName: record.Name,
        networkId: record.Id,
    })

    printVisibleData = () => {
        console.log(this.getVisibleData())
        console.log(this.validateInputs())
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

    // To hold on to the Article ID value irrespective of whether the user searched for the Article
    handleFormArticleID = data => {
        this.articleId=data;
        //console.log('articleId on the form:' +this.articleId)
    }
    
    handleArticleIDValueChange(event){
        const articleId=this.articleId

        // Load an empty search to update the address fields with empty values
        this.handleFormUpdateWithArticleData(emptySearch);

        this.setFormValue({
            articleId,
        })
    }   
     
    printScreen(event){
        window.print();
    }
    
    getFormCustomerAddress = formData => ({
        addressLine1: getOrEmpty(formData, 'customerAddress.addressLine1'),
        addressLine2: getOrEmpty(formData, 'customerAddress.addressLine2'),
        city: getOrEmpty(formData, 'customerAddress.city'),
        state: getOrEmpty(formData, 'customerAddress.state'),
        postcode: getOrEmpty(formData, 'customerAddress.postcode'),
        countrycode: getOrEmpty(formData, 'customerAddress.countrycode'),
    })

    handleCopyToSenderDetails(event) {
        const formData = this.getVisibleData()
        const senderAddress = this.getFormCustomerAddress(formData)
        const senderAddressSearchTerm = getOrEmpty(formData, 'customerAddressSearchTerm', '')
        const senderAddressValidationComponent = this.template.querySelector('.sender-address')
        senderAddressValidationComponent.setAddressSearchTerm(senderAddressSearchTerm)
        senderAddressValidationComponent.setAddress(senderAddress)

        this.setFormValue({ 
            senderName: getOrEmpty(formData, 'FirstName', '') + ' ' + getOrEmpty(formData, 'LastName', ''),
            senderEmail: getOrEmpty(formData, 'Email', ''),
            senderAddress,
            senderAddressSearchTerm,
        });
    }
    
    handleCopyToAddresseeDetails(event) {
        const formData = this.getVisibleData()
        const addresseeAddress = this.getFormCustomerAddress(formData)
        const addresseeAddressSearchTerm = getOrEmpty(formData, 'customerAddressSearchTerm', '')
        const addresseeAddressValidationComponent = this.template.querySelector('.addressee-address')
        addresseeAddressValidationComponent.setAddressSearchTerm(addresseeAddressSearchTerm)
        addresseeAddressValidationComponent.setAddress(addresseeAddress)

        this.setFormValue({ 
            addresseeName: getOrEmpty(formData, 'FirstName', '') + ' ' + getOrEmpty(formData, 'LastName', ''),
            addresseeEmail: getOrEmpty(formData, 'Email', ''),
            addresseeAddress,
            addresseeAddressSearchTerm
        });
    } 
}