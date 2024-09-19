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
01.03.2023    Deepak Kemidi        CI-703 - Changes to display a message when APPC product is selected by the user. Message is displayed if the product selected contains APPC and if all the APPC contracts have Contract Relationship as Billing Account
*/

import { LightningElement ,track, wire, api} from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import getBillingAccountDetails from "@salesforce/apex/CreateSubAccountsController.getBillingAccountDetails";
import createSubAccountRequests from '@salesforce/apex/CreateSubAccountsController.createSubAccounts';
import { NavigationMixin } from 'lightning/navigation';
import { reduceErrors } from 'c/ldsUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkAPPCContracts from '@salesforce/apex/CreateSubAccountsController.checkAPPCContracts';

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
	@track showModal = false;
	@track displayMessage='';
    @track addContractRates = false;
    @track eLMSEnabled = false;
    @track sourceOfSubAccountRequest = 'Billing Account';
    @track subAccountRequestStatus = 'Draft';
	@track newBillingRequestRecordJson='';
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
        getBillingAccountDetails({ billingAccountRecord: this.recordId })
            .then(result =>{
        this.billingAccountRecord = result;
        this.orgId=this.billingAccountRecord.Organisation__c;
        console.log('Org Id::',this.orgId);
        this.isloading = false;
		})
		.catch(error =>{

		})

        if(this.subAccountRecord){
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
            this.subAccountId = this.subAccountRecord.Id;
            this.contactId = this.subAccountRecord.SubAccountContact__c;
            this.productSelected = this.subAccountRecord.Product__c;
            //REQ2570608
            this.isEParcel = this.productSelected && (this.productSelected.includes("eParcel") || this.productSelected.includes("Fulfilio") || this.productSelected.includes("International"));
            this.isParcelSendLoginReq = this.subAccountRecord.Is_Parcel_Send_Login_Required__c;
            if(this.isParcelSendLoginReq === 'Yes'){
                this.showContact = true;
            }
            if(this.addContractRates === 'Yes'){
                this.showProducts = true;
            }
        }


    }
    onsubmitHandler(event){
        //console.log('inside onsubmitHandler>>>1');
        this.fieldList = [];
       // let errField = '' ;
        this.showValidationErr = false;
        if(this.subAccountName === undefined || this.subAccountName === ''){
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

            createSubAccountRequests({ subAccountRec: this.newBillingRequestRecord,lodgementPointWCCs: this.lodgementPointList})
                .then(result =>{
					console.log('Record Created>>',result);
					if(result != null){
						this.newBillingRequestRecordJson = JSON.stringify(result);
						//CI-703 Display message to the user if atleast one APPC contracts have Contract Relationship as Billing Account and if the Product selected includes APPC
						//This is just an informational message and a timeout has been set for 5 seconds before we move the subaccount record creation event
						if(result.Product__c.includes('APPC')){
							checkAPPCContracts({billingAccRecId: this.recordId})
							.then(showMessage =>{
							if (showMessage) {
								this.showModal=true;
								this.displayMessage='To apply rates at a billing account for APPC, please create an opportunity post successful sub account creation.';
							}
							else{
								this.dispatchEvent(
									new CustomEvent("newsubaccountrecord", {detail: this.newBillingRequestRecordJson})
								)
							}
							})
							.catch(error =>{
								console.log(error)
							})
						}else{
							this.dispatchEvent(
								new CustomEvent("newsubaccountrecord", {detail: this.newBillingRequestRecordJson})
							)
						}


					}
				})
				.catch(error =>{
						if (error.body.message) {
						this.message = error.body.message;
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
	//CI-703 funtion to close modal and redirect to summary page
	closeModalAndRedirect = () => {
        this.showModal = false;
		this.dispatchEvent(
			new CustomEvent("newsubaccountrecord", {detail: this.newBillingRequestRecordJson})
		)
    }

    onchangehandler(event){
        this.showValidationErr = false;
        this.errfield = '';
        this.fieldList = [];
        this.fieldList.push(this.errField);
        if(event.target.name === "subAccountName1") {
            this.subAccountName = event.target.value;
        }
        else if(event.target.name === "subAccountContact") {
            this.contactId = event.target.value;
        }else if(event.target.name === "productSelected"){
            this.productSelected = event.target.value;
            this.isEParcel = this.productSelected && (this.productSelected.includes("eParcel") || this.productSelected.includes("Fulfilio") || this.productSelected.includes("International"));
        } else if(event.target.name === "subAccountName2"){
            this.subAccountName2 = event.target.value;
        }else if(event.target.name === "addContractRates"){
            this.addContractRates = event.target.value;
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
            if(this.isParcelSendLoginReq === "Yes"){
                this.showContact = true;
            }else{
                this.showContact = false;
                this.contactId = '';
            }
        } else if(event.target.name === "eLMSEnabled"){
            this.eLMSEnabled = event.target.value;
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
        this.showValidationErr = false;
        this.errfield = '';
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
            }
            if(this.senderAddressVar.postcode  !== null){
                this.postcode = this.senderAddressVar.postcode;
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
        if( event.detail.selRecords !== undefined){
            this.lodgementPointVar = event.detail.selRecords;
            this.lodgementPointList = JSON.stringify(event.detail.selRecords);
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