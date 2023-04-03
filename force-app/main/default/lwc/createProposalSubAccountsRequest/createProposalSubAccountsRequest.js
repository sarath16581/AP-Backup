/**
 * @author Dheeraj Mandavilli
 * @date 2021-05-06
 * @group Controller
 * @tag Controller
 * @domain CreditAssessment
 * @description This lWC component is used in Sub Account Request creation from Proposal flow. It has following the features
 * 1. It contains logic which checks for existing sub account requests to display form or summary page based upon sub account requests.
 * @changelog
 * 2021-05-06 - Dheeraj Mandavilli - Created
 * 2023-03-29 - Harry Wang - Added support for contextId
 */
import { LightningElement, track, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import getRelatedSubAccountRequestsforProposal from "@salesforce/apex/CreateSubAccountsController.getRelatedSubAccountRequestsforProposal";

export default class CreateProposalSubAccountsRequest extends NavigationMixin(LightningElement) {
    @api recordId;
    @api contextId;
    @api initialLoad;
    @api isModalOpen;
    @track subAccountList = [];
    @track proposalRecord;
    @track showSubAccountListForm = false ;
    @track showSubAccountNewForm = false ;
    @track subAccountRecord;
    @track index;

    //@wire (getBillingAccountDetails,{billingAccountRecord: '$recordId'})
    //billingAccountRecord;

    connectedCallback() {
        console.log('recordId>>>>',this.recordId);
        console.log('contextId>>>>',this.contextId);
        console.log('initialLoad>>>>',this.initialLoad);
        console.log('proposalRecord>>>>',this.proposalRecord);


        getRelatedSubAccountRequestsforProposal({ proposalRecord: this.recordId })
            .then(result =>{
            console.log('result>>onload',result);
        this.subAccountList = result;

        if(this.subAccountList.length > 0){
            this.showSubAccountListForm = true;
            //this.isproposal = true;
        }else{
            this.showSubAccountNewForm = true;
        }
    })
    .catch(error =>{

        })
        //}
        this.isloading = false;




    }
    newsubaccountrecordhandler(event){
        console.log('Inside Save Form method');
        //console.log('this.index>>>>>>>>>',this.index);
        let newSubAccountRequest = event.detail;
        console.log('newSubAccountRequest>>>>',newSubAccountRequest);
        let newSubAccountRequestObject = JSON.parse(newSubAccountRequest);
        console.log('newSubAccountRequestObject>>>>',newSubAccountRequestObject.Name);
        //if(this.index){
        //console.log('Update of list is required>>>>');
        //this.subAccountList[this.index]= newSubAccountRequestObject;
        //}else{
        this.subAccountList.push(newSubAccountRequestObject);

        refreshApex(this.subAccountList);

        console.log('subAccountList>>>>>',this.subAccountList);

        this.showSubAccountNewForm = false;
        window.location.reload();
        //this.showSubAccountListForm = true;
    }
    editsubaccounthandler(event){
        console.log('inside edit flow');
        console.log('data>>>>',event.detail);
        this.subAccountRecord = event.detail.subAccountRecordVar;
        this.showSubAccountListForm = false;
        this.showSubAccountNewForm = true;
        console.log('this.subAccountRecord>>>>', event.detail.subAccountRecordVar);
        //console.log('index>>>>', event.detail.indexValue);
        //this.index = event.detail.indexValue;
    }
    saveAndNewHandler(event){
        console.log('Inside save and new handler');
    }
    createNewSubAccountHandler(event){

    }
    showformeventhandler(event){
        console.log('inside shor form handler');
        this.initialLoad = true;
        this.showSubAccountListForm = false;
        this.showSubAccountNewForm = true;
    }


}