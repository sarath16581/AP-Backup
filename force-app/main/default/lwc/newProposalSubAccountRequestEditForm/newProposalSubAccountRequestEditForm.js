/*
  * @author       : Dheeraj Mandavilli. dheeraj.mandavilli@auspost.com.au
  * @date         : 06/05/2021
  * @description  : This lWC component is used in Sub Account Request creation from Proposal flow. It has following features
  *                 1. It contains the sub account request creation input form.
*********************************History*******************************************************************
06.05.2021    Dheeraj Mandavilli   Created
18.05.2021    Dheeraj Mandavilli   Updated logic to auto populate contact with opportunity.key contact value.
20.05.2021    Dheeraj Mandavilli   Added elms Enabled Lodgement Points Hyperlink on the form.
30.07.2021    Naveen Rajanna       REQ2570608 - Set fieldList to empty at start of onsubmitHandler and commented console log statements
01.08.2022    Prerna Rahangdale     - Added the the validation for lodgement point records to be same as Proposal.
*/

import { LightningElement ,track, wire, api} from 'lwc';
import getProposalDetails from "@salesforce/apex/CreateSubAccountsController.getProposalDetails";
import createSubAccountRequests from '@salesforce/apex/CreateSubAccountsController.createSubAccounts';
import { NavigationMixin } from 'lightning/navigation';
import { reduceErrors } from 'c/ldsUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class NewProposalSubAccountRequestEditForm extends NavigationMixin(LightningElement) {
    @api recordId;
    @api subAccountRecord;
    @api subAccountId;
    //@track billingAccountRecord;
    @track proposalRecord;
    @track subAccountName;
    @track subAccountName2;
    @track subAccountContactFirstName;
    @track subAccountContactLastName;
    @track subAccountContactEmail;
    @track subAccountContactTelephone;
    @track contactId;
    //@track productSelected;
    @track isParcelSendLoginReq;
    @track showContact = false;
    @track eParcelEnabled = false;
    @track addContractRates = true;
    @track addContractRatesPickVal = 'Yes';
    @track eLMSEnabled = false;
    @track eLMSPickVal;
    @track sourceOfSubAccountRequest = 'Proposal';
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
    @track chargeAccountId= '';
    @track message;
    @track showMessage = false;
    @track messageType;
    @track errField = '';


    connectedCallback() {
        // console.log('inside connectedCallback');
        // console.log('subAccountRecord inside form>>>>>',this.subAccountRecord);

        getProposalDetails({ proposalRecord: this.recordId })
            .then(result =>{
            // console.log('result>>',result);
        this.proposalRecord = result;
        // console.log('this.proposalRecord>>>',this.proposalRecord);
        // console.log('charegeAccountId>>>',this.proposalRecord.APT_Credit_Assessment__r.APT_Charge_Account__c);
        this.chargeAccountId = this.proposalRecord.APT_Credit_Assessment__r.APT_Charge_Account__c;
        // console.log('contactId::>>>',this.proposalRecord.Apttus_Proposal__Opportunity__r.KeyContact__c);
        this.contactId = this.proposalRecord.Apttus_Proposal__Opportunity__r.KeyContact__c;

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
            this.addContractRatesPickVal = this.subAccountRecord.APT_eParcel_Enabled__c;
            this.subAccountName1 = this.subAccountRecord.APT_Account_Name_2__c;
            this.subAccountContactFirstName =this.subAccountRecord.APT_Sub_Account_Contact_First_Name__c;
            this.subAccountContactLastName = this.subAccountRecord.APT_Sub_Account_Contact_Last_Name__c;
            this.subAccountContactEmail = this.subAccountRecord.APT_Sub_Account_Contact_Email_Address__c;
            this.subAccountContactTelephone = this.subAccountRecord.APT_Sub_Account_Contact_Telephone__c;
            this.eLMSPickVal = this.subAccountRecord.APT_eLMS_Enabled__c;
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
            this.isParcelSendLoginReq = this.subAccountRecord.Is_Parcel_Send_Login_Required__c;
            // console.log('isParcelSendLoginReq Selected ',this.isParcelSendLoginReq);
            if(this.isParcelSendLoginReq === 'Yes'){
                this.showContact = true;
            }
        }


    }
    onsubmitHandler(event){
        // console.log('inside onsubmitHandler>>>1');
        this.fieldList = [];
        //let errField ;
        this.showValidationErr = false;
        if(this.subAccountName === undefined || this.subAccountName === ''){
            // console.log('subAccountName:::',this.subAccountName);
            this.errField = 'Sub Account Name cannot be Blank';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.addContractRatesPickVal === 'Yes' && this.eLMSPickVal === 'No' && (this.lodgementPointVar.length > 1 || this.lodgementPointVar.length === 0)){
            this.errField = 'Contracted rates apply to 1 Lodgement point only. Input only 1 Lodgement name';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.addContractRatesPickVal === 'Yes' && this.eLMSPickVal === 'Yes' && (this.lodgementPointVar.length > 1 || this.lodgementPointVar.length === 0)){
            this.errField = 'You need to input minimum 1 lodgement point when eLMS flag & Add Contract Rate? flag has been selected';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.proposalRecord.APT_Legal_Entity_Name__c === this.subAccountName){
            // console.log('subAccountName:::',this.subAccountName);
            // console.log('Legal Entity Name:::',this.proposalRecord.APT_Legal_Entity_Name__c);
            this.errField = 'Sub Account Name cannot be same as Organisation/Legal Entity Name.Please Enter Unique Value';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.isParcelSendLoginReq === '' || this.isParcelSendLoginReq === null || this.isParcelSendLoginReq === undefined ){
            this.errField = 'Is Parcel Send Login Request? field cannot be blank.Please select a value';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.isParcelSendLoginReq === 'Yes' && (this.contactId === null || this.contactId === undefined || this.contactId === '')){
            this.errField = 'Sub Account Contact data should be input when “Is Parcel Send Login Required? has been selected.';
            this.fieldList.push(this.errField);
            this.showValidationErr = true;
        }
        if(this.eLMSPickVal === '' || this.eLMSPickVal === null || this.eLMSPickVal === undefined ){
            this.errField = 'eLMS field cannot be blank.Please select a value';
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
                APT_Quote_Proposal__c:this.proposalRecord.Id,
                APT_Charge_Account__c:this.chargeAccountId,
                APT_Organisation__c:this.proposalRecord.Apttus_Proposal__Account__c,
                Sub_Account_Name__c : this.subAccountName,
                Name : this.subAccountName,
                APT_Account_Name_2__c : this.subAccountName2,
                APT_Sub_Account_Contact_First_Name__c : this.subAccountContactFirstName,
                APT_Sub_Account_Contact_Last_Name__c : this.subAccountContactLastName,
                APT_Sub_Account_Contact_Email_Address__c : this.subAccountContactEmail,
                APT_Sub_Account_Contact_Telephone__c : this.subAccountContactTelephone,
                APT_eParcel_Enabled__c : this.addContractRatesPickVal,
                APT_eLMS_Enabled__c : this.eLMSPickVal,
                APT_Source_of_Sub_Account_Request__c : this.sourceOfSubAccountRequest,
                APT_Sub_Account_Request_Status__c : this.subAccountRequestStatus,
                APT_Postal_Address_Street_Name__c:this.street,
                APT_Postal_Address_Suburb__c:this.city,
                APT_Postal_Address_State__c:this.state,
                APT_Postal_Address_Street_Postcode__c:this.postcode,
                Lodgement_Point_to_Work_Centre_Code__c: this.lodgementPointList,
                Is_Parcel_Send_Login_Required__c:this.isParcelSendLoginReq,
                SubAccountContact__c :this.contactId
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
                    this.message ='The selected Sub Account Contact Organisation (Legal Entity) does not match the Proposal Organisation (Legal Entity). Please select a Contact that is linked to the same Organisation (Legal Entity) as the associated Proposal.';
                    alert(this.message);
                }else if(this.message.includes("DUPLICATE_VALUE")){
                    this.message ='Sub-account name already exists. Enter unique value';
                    alert(this.message);
                }
                else if(this.message.includes("FIELD_FILTER_VALIDATION_EXCEPTION")){
                    this.message ='Email field on created contact record is blank.Please update contact with valid email value.';
                    alert(this.message);
                }
                else if(this.message.includes("LODGEMENT_POINT_NOMATCH")){
                    this.message ='Lodgement point selected must be within one of the primary lodgement zone/s entered in the shopping cart.';
                    alert(this.message);
                }
                else{
                    alert(this.message);
                }
            }
        })



        }
    }

    onchangehandler(event){
        // console.log('on change handler2');
        // console.log('eventName1>>',event.target.name);
        this.showValidationErr = false;
        this.errField = '';
        this.fieldList = [];
        this.fieldList.push(this.errField);
        if(event.target.name === "subAccountName1"){
            // console.log('Coming here');
            this.subAccountName = event.target.value;
        }else if(event.target.name === "subAccountName2"){
            this.subAccountName2 = event.target.value;
        }else if(event.target.name === "subAccountContact") {
            this.contactId = event.target.value;
            // console.log('Contact Id:::', this.contactId);
        }else if(event.target.name === "isParcelSendLoginReq"){
            this.isParcelSendLoginReq =event.target.value;
            // console.log('Parcel Login Req::',this.isParcelSendLoginReq);
            if(this.isParcelSendLoginReq === "Yes"){
                this.showContact = true;
            }else{
                this.showContact = false;
            }
        }else if(event.target.name === "addContractRatesPickVal"){
            this.addContractRatesPickVal = event.target.value;
            // console.log("Add Contract Rates value::",this.addContractRatesPickVal);
        } else if(event.target.name === "eLMSPickVal"){
            this.eLMSPickVal = event.target.value;
        }else if(event.target.name === "sourceOfSubAccountRequest"){
            this.sourceOfSubAccountRequest = event.target.value;
        }else if(event.target.name === "result"){
            this.result = event.target.value;
        }else if(event.target.name === "resultDetails"){
            this.resultDetails = event.target.value;
        }else if(event.target.name === "subAccountRequestStatus"){
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
        this.errField = '';
        this.fieldList = [];
        this.fieldList.push(this.errField);

        if (event.detail) {
            this.senderAddressVar = event.detail;
            this.disableSaveRequestBtn = false;
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
                // console.log('State Value:::',this.state);
            }
            if(this.senderAddressVar.postcode  !== null){
                this.postcode = this.senderAddressVar.postcode;
                // console.log('Post Code Value:::',this.postcode);
            }
        }
        event.preventDefault();
        return false;
    }
    selectedHandler(event){
        this.showValidationErr = false;
        this.errField = '';
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
        window.location.assign('/'+this.recordId);
    }
}