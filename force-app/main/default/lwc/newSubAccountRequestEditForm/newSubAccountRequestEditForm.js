/*
  * @author       : Dheeraj Mandavilli. dheeraj.mandavilli@auspost.com.au
  * @date         : 24/04/2021
  * @description  : This lWC component is used in Sub Account Request creation from Billing Account Quick Action. It has following features
  *                 1. It contains the sub account request creation input form.
*********************************History*******************************************************************
24.04.2021    Dheeraj Mandavilli   Created
20.05.2021    Dheeraj Mandavilli   Added elms Enabled Lodgement Points Hyperlink on the form.
01.06.2021    Dheeraj Mandavilli   Updated Validation rules for Lodgement Points based upon elMs and Add Contract Rates fields.
30.07.2021    Naveen Rajanna       REQ2570608 - Fix value for this.isEParcel on Edit and commented console log statements
*/

import { LightningElement ,track, wire, api} from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import getBillingAccountDetails from "@salesforce/apex/CreateSubAccountsController.getBillingAccountDetails";
import createSubAccountRequests from '@salesforce/apex/CreateSubAccountsController.createSubAccounts';
import { NavigationMixin } from 'lightning/navigation';
import { reduceErrors } from 'c/ldsUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class newSubAccountRequestEditForm extends NavigationMixin(LightningElement) {
@api recordId;
    @api subAccountRecord;
    @track billingAccountRecord;
    @track subAccountName;
    @track subAccountName2;
    @track subAccountContactFirstName;
    @track subAccountContactLastName;
    @track subAccountContactEmail;
    @track subAccountContactTelephone;
    @track contactId;
    @track productSelected;
    @track isParcelSendLoginReq;
    @track showContact = false;
    @track eParcelEnabled = false;
    @track addContractRates = false;
    @track eLMSEnabled = false;
    @track sourceOfSubAccountRequest = 'Billing Account';
    @track subAccountRequestStatus = 'Draft';
    @track result;
    @track resultDetails;
    @track disableSaveRequestBtn = true;
    @track newBillingRequestRecord = {};
    @track isloading=true;
    @track activeSections = ['A'];
    @track isRequired = true;
    @track fieldList = [];
    @track showValidationErr= false;
    senderAddressVar;
    @track lodgementPointVar;
    @track lodgementPointList;
    @track lpopostCode;
    @track lprecWCC;
    @track isSenderAddressRequired = true;
    @track senderAddress;
    postcodevalue='';
    recWCCvalue ='';
    @track selectedRecords = [];
    //Address Variables
    @track street= '';
    @track city = '';
    @track state = '';
    @track postcode = '';
    @track isEdit = false;
    @track address ='';
    @track lodgementPoints='';
    @track subAccountId= '';
    @track orgId = '';
    @track errorMessage;
    @track saveState;
    @track isEParcel;
    @track showProducts = false;
    @track errField = '';


    connectedCallback() {
        // console.log('inside connectedCallback');
        // console.log('subAccountRecord inside form>>>>>',this.subAccountRecord);

        getBillingAccountDetails({ billingAccountRecord: this.recordId })
            .then(result =>{
            // console.log('result>>',result);
        this.billingAccountRecord = result;
        // console.log('this.billingAccountRecord>>>',this.billingAccountRecord);
        // console.log('Org Id::',this.billingAccountRecord.Organisation__r.Name);
        this.orgId=this.billingAccountRecord.Organisation__c;
        // console.log('Org Id::',this.orgId);
        this.isloading = false;
    })
    .catch(error =>{

        })

        if(this.subAccountRecord){

            // console.log('capturing the Edit Form value',this.subAccountRecord);
            // console.log('capturing the Edit Form value boolean',this.isEdit);
            this.isEdit= true;
            this.isSenderAddressRequired = false;
            this.disableSaveRequestBtn = false;
            this.subAccountName = this.subAccountRecord.Sub_Account_Name__c;
            this.addContractRates = this.subAccountRecord.APT_eParcel_Enabled__c;
            this.subAccountName1 = this.subAccountRecord.APT_Account_Name_2__c;
            this.subAccountContactFirstName =this.subAccountRecord.APT_Sub_Account_Contact_First_Name__c;
            this.subAccountContactLastName = this.subAccountRecord.APT_Sub_Account_Contact_Last_Name__c;
            this.subAccountContactEmail = this.subAccountRecord.APT_Sub_Account_Contact_Email_Address__c;
            this.subAccountContactTelephone = this.subAccountRecord.APT_Sub_Account_Contact_Telephone__c;
            this.eLMSEnabled = this.subAccountRecord.APT_eLMS_Enabled__c;
            this.subAccountRequestStatus = this.subAccountRecord.APT_Sub_Account_Request_Status__c;
            this.lodgementPoints = this.subAccountRecord.Lodgement_Point_to_Work_Centre_Code__c;
            this.street = this.subAccountRecord.APT_Postal_Address_Street_Name__c;
            this.city = this.subAccountRecord.APT_Postal_Address_Suburb__c;
            this.state = this.subAccountRecord.APT_Postal_Address_State__c;
            this.postcode = this.subAccountRecord.APT_Postal_Address_Street_Postcode__c;
            this.address = this.street +' '+this.city+' '+this.state+' '+this.postcode;
            // console.log('addresss::',this.address);
            this.subAccountId = this.subAccountRecord.Id;
            // console.log('record Id ',this.subAccountId);
            this.contactId = this.subAccountRecord.SubAccountContact__c;
            // console.log('contact Id ',this.contactId);
            this.productSelected = this.subAccountRecord.Product__c;
            //REQ2570608
            this.isEParcel = this.productSelected.includes("eParcel") || this.productSelected.includes("Fulfilio") || this.productSelected.includes("International");
            // console.log('Products Selected ',this.productSelected);
            this.isParcelSendLoginReq = this.subAccountRecord.Is_Parcel_Send_Login_Required__c;
            // console.log('isParcelSendLoginReq Selected ',this.isParcelSendLoginReq);
            if(this.isParcelSendLoginReq === 'Yes'){
                this.showContact = true;
            }
            if(this.addContractRates === 'Yes'){
                this.showProducts = true;
            }
        }


    }
    onsubmitHandler(event){
        // console.log('inside onsubmitHandler>>>1');
        this.fieldList = [];
       // let errField = '' ;
        this.showValidationErr = false;
        if(this.subAccountName === undefined || this.subAccountName === ''){
            // console.log('subAccountName:::',this.subAccountName);
            this.errField = 'Sub Account Name cannot be Blank';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.eLMSEnabled === 'No' && this.addContractRates === 'No' && this.lodgementPointVar.length === 0){
            this.errField = 'You need to input minimum 1 Lodgement Point';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.eLMSEnabled === 'Yes' && this.addContractRates === 'No' && this.lodgementPointVar.length === 0){
            this.errField = 'You have enabled eLMS field. You need to input minimum 1 Lodgement Point';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.eLMSEnabled === 'No' && this.addContractRates === 'Yes' && this.isEParcel === true && (this.lodgementPointVar.length > 1 || this.lodgementPointVar.length === 0)){
            this.errField = 'You can only input 1 lodgement point based on product(s) selected & Add Contract Rate? field enabled';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.eLMSEnabled === 'No' && this.addContractRates === 'Yes' && this.isEParcel === false && this.lodgementPointVar.length === 0){
            this.errField = 'You need to input minimum 1 lodgement point based on product(s) selected & Add Contract Rate? field enabled';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.addContractRates === 'Yes' && this.eLMSEnabled === 'Yes' && this.isEParcel === true && (this.lodgementPointVar.length > 1 || this.lodgementPointVar.length === 0)){
            this.errField = 'You can only input minimum and maximum 1 lodgement point based on product(s) selected, eLMS enabled & Add Contract Rate? field enabled';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.addContractRates === 'Yes' && this.eLMSEnabled === 'Yes' && this.isEParcel === false && this.lodgementPointVar.length === 0){
            this.errField = 'You need to input minimum 1 lodgement point based on product(s) selected, eLMS enabled & Add Contract Rate? field enabled';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.addContractRates === 'Yes' && (this.productSelected === null || this.productSelected === undefined || this.productSelected === '')){
            this.errField = 'You need to select at least 1 product to be able to add contract rates';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.isParcelSendLoginReq === '' || this.isParcelSendLoginReq === null || this.isParcelSendLoginReq === undefined ){
            this.errField = 'Is Parcel Send Login Request? field cannot be blank.Please select a value';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
       if(this.addContractRates === '' || this.addContractRates === null || this.addContractRates === undefined ){
            this.errField = 'Add Contract Rates? field cannot be blank.Please select a value';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.eLMSEnabled === '' || this.eLMSEnabled === null || this.eLMSEnabled === undefined ){
            this.errField = 'eLMS field cannot be blank.Please select a value';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.isParcelSendLoginReq === 'Yes' && (this.contactId === null || this.contactId === undefined || this.contactId === '')){
            this.errField = 'Sub Account Contact data should be input when “Is Parcel Send Login Required? has been selected.';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.billingAccountRecord.Name === this.subAccountName){
            // console.log('subAccountName:::',this.subAccountName);
            // console.log('Billing Account Name:::',this.billingAccountRecord.Name);
            this.errField = 'Sub Account Name cannot be same as Parent Billing Account Name.Please Enter Unique Value';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.state === '' || this.state === null || this.state === undefined ){
            this.errField = 'Please input valid state value';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.postcode === '' || this.postcode === null || this.postcode === undefined){
            this.errField = 'Please input valid postcode value';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        let idVar = null;
        if(this.subAccountRecord){
            if(this.subAccountRecord.Id){
                idVar = this.subAccountRecord.Id;
            }
        }
        if(!this.showValidationErr){
            this.newBillingRequestRecord = {
                Id:idVar,
                APT_Billing_Account__c:this.billingAccountRecord.Id,
                APT_Billing_Account_Number__c: this.billingAccountRecord.LEGACY_ID__c,
                APT_Organisation__c:this.orgId,
                Sub_Account_Name__c : this.subAccountName,
                Name : this.subAccountName,
                APT_Account_Name_2__c : this.subAccountName2,
                SubAccountContact__c :this.contactId,
                APT_Sub_Account_Contact_First_Name__c : this.subAccountContactFirstName,
                APT_Sub_Account_Contact_Last_Name__c : this.subAccountContactLastName,
                APT_Sub_Account_Contact_Email_Address__c : this.subAccountContactEmail,
                APT_Sub_Account_Contact_Telephone__c : this.subAccountContactTelephone,
                APT_eParcel_Enabled__c : this.addContractRates,
                APT_eLMS_Enabled__c : this.eLMSEnabled,
                APT_Source_of_Sub_Account_Request__c : this.sourceOfSubAccountRequest,
                APT_Sub_Account_Request_Status__c : this.subAccountRequestStatus,
                APT_Postal_Address_Street_Name__c:this.street,
                APT_Postal_Address_Suburb__c:this.city,
                APT_Postal_Address_State__c:this.state,
                APT_Postal_Address_Street_Postcode__c:this.postcode,
                Lodgement_Point_to_Work_Centre_Code__c: this.lodgementPointList,
                Product__c:this.productSelected,
                Is_Parcel_Send_Login_Required__c:this.isParcelSendLoginReq
            }

            // console.log('newBillingRequestRecord>>>>',this.newBillingRequestRecord);
            // console.log('Lodgement Point Records>>>>',this.lodgementPointList);
            createSubAccountRequests({ subAccountRec: this.newBillingRequestRecord,lodgementPointWCCs: this.lodgementPointList})
                .then(result =>{
                // console.log('Record Created>>',result);
            if(result != null){
                let newBillingRequestRecordJson = JSON.stringify(result);
                // console.log('newBillingRequestRecord>>>>',newBillingRequestRecordJson);
                this.dispatchEvent(
                    new CustomEvent("newsubaccountrecord", {
                        detail: newBillingRequestRecordJson
                    })
                );
            }

        })
        .catch(error =>{
                if (error.body.message) {
                this.message = error.body.message;
                // console.log('Message ::::',this.message);
                if(this.message.includes("FIELD_CUSTOM_VALIDATION_EXCEPTION")){
                    this.message ='The selected Sub Account Contact Organisation (Legal Entity) does not match the Billing Account Organisation (Legal Entity). Please select a Contact that is linked to the same Organisation (Legal Entity) as the associated Billing Account.';
                    alert(this.message);
                }else if(this.message.includes("DUPLICATE_VALUE")){
                    this.message ='Sub-account name already exists. Enter unique value';
                    alert(this.message);
                }else if(this.message.includes("FIELD_FILTER_VALIDATION_EXCEPTION")){
                    this.message ='Email field on created contact record is blank.Please update contact record with valid email value.';
                    alert(this.message);
                }else{
                    alert(this.message);
                }
            }
        })

        }
    }


    onchangehandler(event){
        // console.log('on change handler2');
        // console.log('eventName1>>',event.target.name);
        // console.log('Coming here');
        this.showValidationErr = false;
        this.errfield = '';
        this.fieldList = [];
        this.fieldList.push(this.errField);
        if(event.target.name === "subAccountName1") {
            this.subAccountName = event.target.value;
            // console.log('Sub Account Name:::',this.subAccountName);
        }
        else if(event.target.name === "subAccountContact") {
            this.contactId = event.target.value;
            // console.log('Contact Org Id:::',event.target.value.AccountId);
            // console.log('Contact Id:::',this.contactId);
            // console.log('Contact Org Id:::',this.contactId.AccountId);
        }else if(event.target.name === "productSelected"){
            this.productSelected = event.target.value;
            // console.log('productSelected :::',this.productSelected);
            this.isEParcel = this.productSelected.includes("eParcel") || this.productSelected.includes("Fulfilio") || this.productSelected.includes("International");
            // console.log('Eparcel found :::',this.isEParcel);
        } else if(event.target.name === "subAccountName2"){
            this.subAccountName2 = event.target.value;
        }else if(event.target.name === "addContractRates"){
            this.addContractRates = event.target.value;
            // console.log("Add Contract Rates value::",this.addContractRates);
            if(this.addContractRates === 'Yes') {
                this.showProducts = true;
                this.isParcelSendLoginReq = '';
            }else{
                this.showProducts = false;
                this.showContact = false;
                this.productSelected = '';
                this.isParcelSendLoginReq = 'No';
            }
        }else if(event.target.name === "isParcelSendLoginReq"){
            this.isParcelSendLoginReq =event.target.value;
            // console.log('Parcel Login Req::',this.isParcelSendLoginReq);
            if(this.isParcelSendLoginReq === "Yes"){
                this.showContact = true;
            }else{
                this.showContact = false;
                this.contactId = '';
            }
        } else if(event.target.name === "eLMSEnabled"){
            this.eLMSEnabled = event.target.value;
            // console.log("Add emls value::",this.eLMSEnabled);
        }else if(event.target.name === "sourceOfSubAccountRequest"){
            this.sourceOfSubAccountRequest = event.target.value;
        }
        else if(event.target.name === "subAccountRequestStatus"){
            this.subAccountRequestStatus = event.target.value;
        }

    }
    handleSectionToggle(event) {
        // console.log('inside handleSectionToggler>>>>');
        const openSections = event.detail.openSections;
    }
    handleConfirmedSenderAddress(event) {
        // console.log('Inside confirm 3');
        // console.log('event.detail>>>',event.detail);
        this.showValidationErr = false;
        this.errfield = '';
        this.fieldList = [];
        this.fieldList.push(this.errField);
        if (event.detail) {
            this.senderAddressVar = event.detail;
            this.disableSaveRequestBtn = false;
            // console.log("Address Line2::",this.senderAddressVar.addressLine2);
            if(this.senderAddressVar.addressLine1 !== undefined && this.senderAddressVar.addressLine2 !== undefined){
                this.street = this.senderAddressVar.addressLine1+' '+this.senderAddressVar.addressLine2;
            }else{
                this.street = this.senderAddressVar.addressLine1;
            }
            if(this.senderAddressVar.city  !== null){
                this.city = this.senderAddressVar.city;
            }
            if(this.senderAddressVar.state  !== null){
                this.state = this.senderAddressVar.state;
                // console.log("State Value::",this.state);
            }
            if(this.senderAddressVar.postcode  !== null){
                this.postcode = this.senderAddressVar.postcode;
                // console.log("Postcode Value::",this.postcode);
            }
        }
        event.preventDefault();
        return false;
    }
    selectedHandler(event){
        this.showValidationErr = false;
        this.errfield = '';
        this.fieldList = [];
        this.fieldList.push(this.errField);
        // console.log('event sel record>>>>',event.detail.selRecords);
        if( event.detail.selRecords !== undefined){
            this.lodgementPointVar = event.detail.selRecords;
            // console.log("The size of the array is::",this.lodgementPointVar.length);
            this.lodgementPointList = JSON.stringify(event.detail.selRecords);
            // console.log('The lodgement List',this.lodgementPointList);
        }
        event.preventDefault();
        return false;
    }


    cancel(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'APT_Billing_Account__c',
                actionName: 'view'
            },
        });
    }

}