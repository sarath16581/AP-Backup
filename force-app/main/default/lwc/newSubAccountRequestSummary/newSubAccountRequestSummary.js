/**
 * @author 
 * @date 2021-04-06
 * @group Billing Accounts
 * @tag Billing Account
 * @description: Sub Account Summary Screen for managing(create,edit,delete,submit) Sub-Account Requests from Billing Account Flow
 *               This component is used for creation of Auspost Billing account From Sub-Account Request through SAP Integration.
 * @changelog
 * 2021-04-06 MandavilD Created
 * 2021-05-12 seth.heang@auspost.com.au           Added Submission popup and controller binding
 * 2021-06-07 Dheeraj.Mandavilli@auspost.com.au   Added Logic to check sub account request count to navigate to accurate landing page as part of STP-5934.
 * 2021-06-16 Dheeraj.Mandavilli@auspost.com.au   Updated Toast Message to Alert popup for Submit Button as part of STP-6155 UAT Feedback.
 */

 import { LightningElement,track,api} from 'lwc';
 import {refreshApex} from '@salesforce/apex';
 import deleteSubAccounts from '@salesforce/apex/CreateSubAccountsController.deleteSubAccounts';
 import { NavigationMixin } from 'lightning/navigation';
 import generateExternalOnboardingRecord from '@salesforce/apex/CreateSubAccountsController.generateExternalOnboardingRecord';
 import setFailStatus from '@salesforce/apex/CreateSubAccountsController.setFailStatus';
 import subAccountCreationRequest from '@salesforce/apexContinuation/CreateSubAccountsController.subAccountCreationRequest';
 import { ShowToastEvent } from 'lightning/platformShowToastEvent';
 import getRelatedSubAccountRequests from "@salesforce/apex/CreateSubAccountsController.getRelatedSubAccountRequests";
 
 
 const COLS=[
     {label:'Parent Billing Account Number',fieldName:'APT_Billing_Account_Number__c', type:'text'},
     {label:'Sub Account Name',fieldName:'Sub_Account_Name__c', type:'text'},
     {label:'Add Contracted Rates?',fieldName:'APT_eParcel_Enabled__c', type:'text'},
     {label:'Lodgement Point Name',fieldName:'Lodgement_Point_to_Work_Centre_Code__c', type:'text'},
     {label:'Sub Account Contact',fieldName:'Contact_Name__c', type:'text'},
     {label:'Sub Account Request Status',fieldName:'APT_Sub_Account_Request_Status__c', type:'text'}
 ];
 
 export default class newSubAccountRequestSummary extends NavigationMixin(LightningElement) {
     @api subAccountList;
     @track subAccounts;
     @track showForm ;
     @api recordId;
     @track subAccountRecord;
     @track isModalOpen = false;
     @track isSubmitModalOpen = false;
     @track submitRequestInProgress = false;
     @track submitRequestComplete = false;
     @track subAccountCreationSuccessful;
     @track inProgressSpinner = false;
     @track integrationComplete = false;
     @track integrationInitiated = false;
     @track inProgressSpinner = false;
     @track subAccountCount;
     @track parentBillNum;
     @track subAccountRequestsList;
     @track failedErrMsg = '<h3><b>There seems to be an issue while creating the sub account.<br/><br/>Please report an IT issue via the ‘Report a Fault’ icon on the MyIT Service Portal and select the following details:</b><br/><br/>'+
                       '<ul><li>Please select the area this relates to: 2.Applications & Software<br/></li>'+
                       '<li>What does this relate to? Salesforce<br/></li>'+
                       '<li>What best describes your issue? Received message from Camunda stating that service is currently unavailable<br/></li>'+
                       '<li>Can you provide a short description:  SAP sub account integration not working</li><ul></h3>';
 
     cols=COLS;
 
     connectedCallback(){
         console.log('subAccountList>>>>',this.subAccountList);
         this.subAccounts = this.subAccountList;
         this.parentBillNum = this.subAccountList[0].APT_Billing_Account_Number__c;
         console.log('subAccounts>>>>',this.subAccounts);
         console.log('IsProposal flag>>>',this.isproposal);
     }
 
     deleteRecord(){
 
         this.isModalOpen = false;
         var selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
         console.log('Selected Record::',selectedRecords);
 
             deleteSubAccounts({subAccountList: selectedRecords})
                 .then(result=>{
                 console.log('Records Deleted>>',result);
             if ( result === true){
                 window.location.reload();
             }
         })
         .catch(error=>{
                 alert('Cloud not delete'+JSON.stringify(error));
         })
 
     }
 
     addMoreHandler(){
         this.showForm = {
             initialLoad : true,
             showSubAccountNewForm : true,
             showSubAccountListForm :false
         }
         let showFormJson = JSON.stringify(this.showForm);
         this.dispatchEvent(
             new CustomEvent("showformevent", {
                 detail: showFormJson
             })
         );
     }
 
 
     openModal() {
         // to open modal set isModalOpen track value as true
         var selectedRecords =
             this.template.querySelector("lightning-datatable").getSelectedRows();
         console.log('Selected Record::',selectedRecords);
         if(selectedRecords.length === 0){
             alert('Please select records for Deletion');
         }else {
             this.isModalOpen = true;
         }
     }
     closeModal() {
         // to close modal set isModalOpen track value as false
         this.isModalOpen = false;
     }
 
     editSubAccountRequestHandler(event){
         console.log('Inside View Sub Account Request handler');
         console.log('event>>>1',event.detail);
         var selectedItem = this.template.querySelector("lightning-datatable").getSelectedRows();
         console.log('Selected Item::',selectedItem.length);
         if(selectedItem.length > 1){
             alert('Please select only 1 record for editing');
         }else if (selectedItem.length === 0) {
             alert('Please select a record for editing');
         }else{
 
             let subAccountRecordVar = selectedItem[0];
             console.log('subAccountRecordVar>>>>>',subAccountRecordVar);
 
             let eventData = {
                 subAccountRecordVar: subAccountRecordVar,
                 initialLoad : true,
                 showSubAccountNewForm : true,
                 showSubAccountListForm :false,
             }
             this.dispatchEvent(
                 new CustomEvent("editsubaccount", {
                     detail: eventData
                 })
             );
         }
 
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
     showformeventhandler(event){
         console.log('inside shor form handler');
         this.initialLoad = true;
         this.showSubAccountListForm = false;
         this.showSubAccountNewForm = true;
     }
 
     /**
      * @description: Method to open a Modal popup for submission and perform basic validation on UI
      *  */ 
     openSubmitModal(){
         // to open modal set isModalOpen track value as true
         var selectedRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();
         this.subAccountCount = selectedRecords.length;
         // Validation check when no record is selected prior to clicking 'Submit Request' button
         if(selectedRecords.length === 0){
             alert('Please select records for submission');
         }else {
             // Open up Modal Popup
             this.isSubmitModalOpen = true;
         }
         // Validation check on each selected records, only those with "Draft" and "Error" status can proceed for submission
         selectedRecords.forEach(element => {
             if(element.APT_Sub_Account_Request_Status__c !== "Draft" && 
             element.APT_Sub_Account_Request_Status__c !== "Error"){
                 alert('You can only select Sub Account Request with either "Draft" or "Error" status for finalization');
                 // Open up Modal Popup
                 this.isSubmitModalOpen = false;
             }
         });
     }
 
     // Method to close the submission confirmation Modal popup
     closeSubmitModal() {
         // to close modal set isModalOpen track value as false
         this.isSubmitModalOpen = false;
     }
 
     
     // Method to close the submission Modal popup
     closeSubmitInProgressModal() {
         // to close modal set submitRequestInProgress track value as false
         this.submitRequestInProgress = false;

         var selectedRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();
        
         // Salesforce to Camunda has a failed connection
        if(this.subAccountCreationSuccessful === false){
            // Set Sub Account Request Integration Status to Error
            setFailStatus({ subAccountList: selectedRecords })
            .then(result =>{
                this.selectedRecords = result;
                // refresh the page
                window.location.reload();
            })
            .catch(error => {
                console.log('error:::' + error);
            });
         }
     }
 
     /**
      * @description: Method to submit the selected Sub Account Request and send the request to Camunda or having Mocked Response
      *  */ 
     submitRequestHandler(){
         this.isSubmitModalOpen = false;
         this.submitRequestInProgress = true;
         this.submitRequestComplete= false;
         this.integrationInitiated = true;
         this.inProgressSpinner = true;
         // get selected records prior to submission
         var selectedRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();
         generateExternalOnboardingRecord({subAccountRecList: selectedRecords, billingAccId: this.recordId})
         .then(result => {
             let responseVar = result;
             // actual connection to Camunda
             if(responseVar.connected){
                 subAccountCreationRequest({externalOnboardingRequestWithConnectionDetailsVar : JSON.stringify(responseVar)})
                     .then(res =>{
                         this.submitRequestComplete= true;
                         if(res){
                             // display Success popup
                             this.submitRequestComplete= true;
                             this.subAccountCreationSuccessful = true;
                         }else{
                             // display Error popup
                             this.submitRequestComplete= true;
                             this.subAccountCreationSuccessful = false;
                         }
                         this.inProgressSpinner = false;
                     })
                     .catch(err =>{
                        // display Error popup
                        this.submitRequestComplete= true;
                        this.subAccountCreationSuccessful = false;
                        this.inProgressSpinner = false;
                        console.log('Error while call out', err);
                     })
             }
             // mock response from Camunda
             else{
                 let integrationStatus = responseVar.integrationStatus;
                 integrationStatus = 'Success';
                 // display Success popup
                 if(integrationStatus == 'Success'){
                     this.submitRequestComplete = true;
                     this.subAccountCreationSuccessful = true;
                 }
                 // display Error popup
                 else if(integrationStatus == 'Error'){
                     this.subAccountCreationSuccessful = false;
                     this.submitRequestComplete = true;
                 }
                 this.inProgressSpinner = false;
             }
         })
         .catch(error => {
            // display Error popup
            this.submitRequestComplete= true;
            this.subAccountCreationSuccessful = false;
            this.inProgressSpinner = false;
             console.log('error:::' + error);
         });
     }


    // Method to close the Finalize Modal popup and Navigate to accurate page.
    closeFinalSubmitModal() {
        getRelatedSubAccountRequests({ billingAccountRecord: this.recordId })
            .then(result =>{
            console.log('result>>onload',result);
        this.subAccountRequestsList = result;
        console.log('SubAccountRequest List:::',this.subAccountRequestsList.length);
        if(this.subAccountRequestsList.length === 0){
            window.location.assign('/'+this.recordId);
        }else{
            window.location.reload();
        }
    })
    }
     
 }