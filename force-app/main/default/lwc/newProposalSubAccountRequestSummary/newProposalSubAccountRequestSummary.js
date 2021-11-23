/*
* @author       : Dheeraj Mandavilli. dheeraj.mandavilli@auspost.com.au
* @date         : 06/05/2021
* @description  : This lWC component is used in Sub Account Request creation from Proposal flow. It has following features
*                 1. It contains logic for displaying sub account request records on summary from Proposal flow
*********************************History*******************************************************************
06.05.2021    Dheeraj Mandavilli   Created
04.06.2021    Dheeraj Mandavilli   Added Logic to check sub account request count to navigate to accurate landing page as part of STP-5933.
*/

import { LightningElement,track,api} from 'lwc';
import {refreshApex} from '@salesforce/apex';
import deleteSubAccounts from '@salesforce/apex/CreateSubAccountsController.deleteSubAccounts';
import setPendingStatus from '@salesforce/apex/CreateSubAccountsController.setPendingStatus';
import { NavigationMixin } from 'lightning/navigation';
import getRelatedSubAccountRequestsforProposal from "@salesforce/apex/CreateSubAccountsController.getRelatedSubAccountRequestsforProposal";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLS=[
    {label:'Parent Billing Account Number',fieldName:'APT_Billing_Account_Number__c', type:'text'},
    {label:'Sub Account Name',fieldName:'Sub_Account_Name__c', type:'text'},
    {label:'Add Contracted Rates?',fieldName:'APT_eParcel_Enabled__c', type:'text'},
    {label:'Lodgement Point Name',fieldName:'Lodgement_Point_to_Work_Centre_Code__c', type:'text'},
    {label:'Sub Account Contact',fieldName:'Contact_Name__c',type:'text'},
    {label:'Sub Account Request Status',fieldName:'APT_Sub_Account_Request_Status__c', type:'text'}
];


export default class NewProposalSubAccountRequestSummary extends NavigationMixin(LightningElement) {
     @api subAccountList;
     @track subAccounts;
     @track showForm ;
     @api recordId;
     @track subAccountRecord;
     @track isModalOpen = false;
     @track isSubmitModalOpen = false;
     @track isFinalizeModalOpen = false;
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
        //alert('Inside Connected Call Back');
        console.log('subAccountList>>>>',this.subAccountList);
        this.subAccounts = this.subAccountList;
        this.parentBillNum = this.subAccountList[0];
        console.log('subAccounts>>>>',this.subAccounts);
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

    finalizeRequestHandler(){

        this.isSubmitModalOpen = false;

        var selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
        console.log('Selected Record::',selectedRecords);

        setPendingStatus({subAccountList: selectedRecords})
            .then(result=>{
            console.log('Records Updated>>',result);
        if ( result === true){
            this.isFinalizeModalOpen = true;
        }
    })
    .catch(error=>{
            alert('Cloud not update'+JSON.stringify(error));
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
        var selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
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
            //code to fetch lodgement point comes here.
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
        window.location.assign('/'+this.recordId);
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
            alert('Please select records for Finalization');
        }else {

            // Open up Modal Popup
            this.isSubmitModalOpen = true;

        }
    }

    // Method to close the submission confirmation Modal popup
    closeSubmitModal() {
        // to close modal set isModalOpen track value as false
        this.isSubmitModalOpen = false;
    }

    // Method to close the Finalize Modal popup and Navigate to accurate page.
    closeFinalizeModal() {
        getRelatedSubAccountRequestsforProposal({ proposalRecord: this.recordId })
            .then(result =>{
            console.log('result>>onload',result);
        this.subAccountRequestsList = result;
        console.log('SubAccountRequest List:::',this.subAccountRequestsList.length);
        if(this.subAccountRequestsList.length === 0){
            this.isFinalizeModalOpen = false;
            window.location.assign('/'+this.recordId);
        }else{
            this.isFinalizeModalOpen = false;
            window.location.reload();
        }
    })
    }

}