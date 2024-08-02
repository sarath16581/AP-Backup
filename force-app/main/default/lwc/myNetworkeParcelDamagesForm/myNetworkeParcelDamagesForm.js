/* eslint-disable no-console */
/* eslint-disable no-unused-vars */
/**
  * @author       : Sameed Khan<sameed.khan@mav3rik.com>
  * @date         : 01/05/2019
  * @description  : Eparcel Damages Form Component
--------------------------------------- History --------------------------------------------------
01.04.2019    Sameed Khan(Mav3rik)    Created
14.08.2019    Gunith Devasurendra     Support clear address fields when Article ID is changed (REQ1885859)
18.11.2019    saiswetha.pingali@auspost.com.au Fix to display article Id on case confirmation screen (INC1496938)
22.03.2021    Suman Gunaganti          MW0004436: Wine Damages instructions changes
26.03.2021    Madhuri Awasthi          REQ2447384 -Wine Damanges new fields and check for 1500 character check 
16.04.2021    Madhuri Awasthi          REQ2447384 -eParcel/Wine Damanges Field length check
19.05.2021    Madhuri Awasthi          REQ2496280 - Resetting the fields on Article change
26.05.2021    Naveen Rajanna           REQ2513603 Show Print button when submitted and hide few tags upon print
09.06.2021    Naveen Rajanna           REQ2525818 Retrieve Customer_Ref__c from SAP data and store in formdata in custRefID
**/

import { track } from 'lwc'
import LwcForm from 'c/lwcForm'
import getNetworkUsers from '@salesforce/apex/MyNetworkSmartFormsService.getListOfNetworksForLoginUser'
import createCase from '@salesforce/apex/MyNetworkSmartForms.createCase'
import getDamageInstructions from '@salesforce/apex/MyNetworkSmartFormsService.getDamageInstructions'
import { get, getOrEmpty, emptySearch } from 'c/utils'
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import Wine_Damage_Deliver_as_Addressed	from '@salesforce/label/c.Wine_Damage_Deliver_as_Addressed'
import Wine_Damage_Discard from '@salesforce/label/c.Wine_Damage_Discard'
import Wine_Damage_RTS from '@salesforce/label/c.Wine_Damage_RTS'
import Wine_Damage_No_Instructions from '@salesforce/label/c.Wine_Damage_No_Instructions'


export default class myNetworkeParcelDamagesForm extends LwcForm {
    howDamageOccuredOptionalOtherRenderConfig = {
        parentName: 'howDamageOccured',
        showFor: ['other'],
    }

    consignementRenderConfig = {
        parentName: 'isPartOfConsignment',
        showFor: 'yes',
    }

    containsWineRenderConfig = {
        parentName: 'doesContainWine',
        showFor: 'yes',
    }

    doesNotcontainWineRenderConfig = {
        parentName: 'doesContainWine',
        showFor: 'no',
    }

    containsSustainedDamage = {
        parentName: 'sustainedDamage',
        showFor: 'yes',       
    }

    doesNotcontainSustainedDamage = {
        parentName: 'sustainedDamage',
        showFor: 'no',       
    }
	sufficientlyPackaged = {
        parentName: 'sufficientPackage',
        showFor: 'yes',       
    }
	notSufficientlyPackaged = {
        parentName: 'sufficientPackage',
        showFor: 'no',       
    }
    notAdequateCartonRenderConfig = {
        parentName: 'isCartonAdequate',
        showFor: 'no'
    }

    notAdequateDividerRenderConfig = {
        parentName: 'isDividerAdequate',
        showFor: 'no'
    }

    yesNoOptions = [
        { value: 'yes', label: 'Yes' },
        { value: 'no', label: 'No' },
    ]

    howDamageOccuredOptions = [
        { value: 'Dropped whilst sorting', label: 'Dropped whilst sorting' },
        { value: 'Dropped whilst delivering', label: 'Dropped whilst delivering' },
        { value: 'Received broken', label: 'Received broken' },
        { value: 'other', label: 'Other' },
    ]

    actionTakenOptions = [
        { value: 'Return To Sender', label: 'Return to sender' },
        { value: 'Deliver as Addressed', label: 'Deliver as addressed' },
        { value: 'Discard', label: 'Discard' },
    ]

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
    caseResponse = []

    @track
    articleId

    @track
    senderName

    @track
    addresseeName

    @track
    billingAccountId

    @track
    isArticleInsured

    @track
    displayErrorMsg=false

    @track
    damageDetailsLength=1500  

    @track
    locationDetailsLength=500

    @track
    sustainedDamageDetailsLength=1500

    @track
    cartonadqlength=500

	@track
    sufficientlyPackagedDetailsLength=1500
    
	@track
    divideradqlength=500

    @track
    additionalInfolength=500

    @track 
    loading = false

    @track 
    additionalCommentsMandatory = false

    @track
    articleDamageStandingInstructions

    @track 
    showActionTaken = false

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

    handleSubmit = () => {

        const formId = "eParcel"
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
        AddressLine1: getOrEmpty(record, 'articleDetails.proxyArticle.SenderAddressLine1__c'),
        AddressLine2: `${getOrEmpty(record, 'articleDetails.proxyArticle.SenderAddressLine2__c') || ''}${getOrEmpty(record, 'articleDetails.proxyArticle.SenderAddressLine3__c') ? `, ${getOrEmpty(record, 'articleDetails.proxyArticle.SenderAddressLine3__c')}` : ''}`,
        City: getOrEmpty(record, 'articleDetails.proxyArticle.SenderCity__c'),
        State: getOrEmpty(record, 'articleDetails.proxyArticle.SenderState__c'),
        Postcode: getOrEmpty(record, 'articleDetails.proxyArticle.SenderPostcode__c'),
        Countrycode: getOrEmpty(record, 'articleDetails.proxyArticle.SenderCountry__c'),
    })

    extractSenderAddressSearchTerm = record => getOrEmpty(record, 'articleDetails.proxyArticle.SenderAddress__c')

    extractAddresseeAddress = record => ({
        AddressLine1: getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverAddressLine1__c'),
        AddressLine2: `${getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverAddressLine2__c') || ''}${getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverAddressLine3__c') ? `, ${getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverAddressLine3__c')}` : ''}`,
        City: getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverCity__c'),
        State: getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverState__c'),
        Postcode: getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverPostcode__c'),
        Countrycode: getOrEmpty(record, 'articleDetails.proxyArticle.ReceiverCountry__c'),
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
        this.billingAccountId = getOrEmpty(data,'articleDetails.proxyArticle.Billing_Account__c')
        this.isArticleInsured = getOrEmpty(data,'articleDetails.proxyArticle.InsuranceAmount__c', 0)>0
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
            isArticleInsured: this.isArticleInsured?'yes':'no',
            //REQ2525818
            custRefID: getOrEmpty(data,'articleDetails.proxyArticle.Customer_Ref__c')
        })

        if (valuesToUpdate.articleId !== undefined)
        {this.articleId = valuesToUpdate.articleId;}
        this.addresseeName = valuesToUpdate.addresseeName;
        this.senderName = valuesToUpdate.senderName;
    }

    senderAddressChangeHandler = address => {
        this.setFormValue({ senderAddress: address })
    }

    addresseeAddressChangeHandler = address => {
        this.setFormValue({ addresseeAddress: address })
    }

    senderAddressSearchTermChangeHandler = mergedAddress => {
        this.setFormValue({ senderAddressSearchTerm: mergedAddress })
    }

    addresseeAddressSearchTermChangeHandler = mergedAddress => {
        this.setFormValue({ addresseeAddressSearchTerm: mergedAddress })
    }

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
            doesContainWine: null,
            totalBottlesInCarton: null,
            totalBottlesDamaged: null,
			totalBottlesNotDamaged: null,
            noOfCapsDamaged: null,
            noOfLabelsDamaged: null,
            actionTaken: null,
            additionalInformation: null,
            contactId: null,
            damageInstructions: null,
            //Adding fields to reset
            sustainedDamage:null,
            damageDetails:null,
            damageLocation:null,
            sustainedDamageDetails:null,
            howDamageOccured:null,
            isPartOfConsignment:null,
            totalArticlesInConsignment:null,
			sufficientPackage:null,
			sufficientPackageDetails:null,
            totalItemInParcel:null,
            cartonInadequecyDetails:null,
            dividerInadequecyDetails:null 

        })
        this.articleDamageStandingInstructions = null
        this.additionalCommentsMandatory = false
    }

    handleSenderNameChange(event){
        this.senderName=event.target.value
        const senderName=this.senderName
        this.setFormValue({
            senderName,
        })
    }

    handleAddresseeNameChange(event){
        this.addresseeName=event.target.value
        const addresseeName=this.addresseeName
        this.setFormValue({
            addresseeName,
        })
    }

    //function to calculate the number of characters left for user to enter as he enters text in Product and Location of damage.
    handleDetailsChange(event){
        if (event.target.name === 'damageDetails')
        {this.damageDetailsLength = (1500 - event.detail.value.length) ;} 
        if (event.target.name === 'damageLocation')
        {this.locationDetailsLength = (500 - event.detail.value.length) ;} 
        if (event.target.name === 'sustainedDamageDetails')
        {this.sustainedDamageDetailsLength  = (1500 - event.detail.value.length) ;}
		if (event.target.name === 'sufficientPackageDetails')
        {this.sufficientlyPackagedDetailsLength  = (1500 - event.detail.value.length) ;}  
        this.handleValueChange(event)
    }
    
    //function to calculate the number of characters left for user to enter as he enters text in 'Provide Details' fields
    handleInadeqdetailschange(event){
        if (event.target.name === 'cartonInadDetails')
        {this.cartonadqlength = (500 - event.detail.value.length) ;} 
        if (event.target.name === 'dividerInadDetails')
        {this.divideradqlength = (500 - event.detail.value.length) ;} 
    }

    //function to calculate the number of characters left for user to enter as he enters text in 'Additional Information' fields
    handleAdditionalInformationDetails(event){
        if(event.target.name === 'additionalInformationDetails')
        {this.additionalInfolength = (500 - event.detail.value.length);}
    }
    //handles action taken events
    handleActionTakenChange(event){
        if(event.target.value != this.getVisibleData()['damageInstructions']){
            this.setFormValue({actionTaken:event.target.value})
            const evt = new ShowToastEvent({
                title: 'Warning',
                message: 'You have chosen a result different to the preferred action.  Please let us know why',
                variant: 'warning',
            });
            this.dispatchEvent(evt)
            this.additionalCommentsMandatory = true
        }
        else
        this.additionalCommentsMandatory = false

    }
    //handle wine damage change event
    handleDoesContainWineChange(event){
        if(event.detail.value === 'yes' && this.billingAccountId){
            this.loading = true
            getDamageInstructions({ billingAccountId: this.billingAccountId })
            .then(data => {
                console.log(data)
                const damagesInstructions =  getOrEmpty(data, 'Organisation__r.Wine_Damage_Instruction__c',null)
                const contactId = getOrEmpty(data,'Organisation__r.eParcelDamagesDelegate__c')
                this.setFormValue({
                    contactId,
                })
                switch (true) {
                    default:
                        this.articleDamageStandingInstructions = (damagesInstructions == 'Return To Sender')?Wine_Damage_RTS:
                                                                (damagesInstructions == 'Deliver as Addressed')?Wine_Damage_Deliver_as_Addressed:
                                                                (damagesInstructions == 'Discard')?Wine_Damage_Discard:null
                        this.setFormValue({ damageInstructions: damagesInstructions })
                        this.setFormValue({actionTaken: damagesInstructions})
                        this.showActionTaken = true 
                        break;
                    case (damagesInstructions == null || contactId == null || this.isArticleInsured):
                        this.setFormValue({ damageInstructions: 'No instructions' })
                        this.articleDamageStandingInstructions = Wine_Damage_No_Instructions
                        this.showActionTaken = false
                        break;
                }
            })
            .catch(error => {
                console.log(error)
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: 'Unexpected Error',
                    variant: 'error',
                });
                this.dispatchEvent(evt)
            })
            .finally(() => {
                this.loading = false
             }) 
        }
        else {
            this.setFormValue({ damageInstructions: 'No instructions' })
            this.articleDamageStandingInstructions = Wine_Damage_No_Instructions
            this.showActionTaken = false
        }
    }
    
    printScreen(event){
        window.print();
    }
}