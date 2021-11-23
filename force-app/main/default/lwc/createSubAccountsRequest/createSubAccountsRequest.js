/*
  * @author       : Dheeraj Mandavilli. dheeraj.mandavilli@auspost.com.au
  * @date         : 24/04/2021
  * @description  : This lWC component is used in Sub Account Request creation from Billing Account Quick Action. It has following features
  *                 1. It contains logic whether to populate summary page or form based upon sub account requests.
*********************************History*******************************************************************
24.04.2021    Dheeraj Mandavilli   Created
*/
import { LightningElement,track, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import relatedSubAccountRequests from "@salesforce/apex/CreateSubAccountsController.getRelatedSubAccountRequests"; 
//import getBillingAccountDetails from "@salesforce/apex/CreateSubAccountsController.getBillingAccountDetails";
export default class createSubAccountsRequest extends NavigationMixin(LightningElement) {
    @api recordId;
    @api initialLoad;
    @api isModalOpen;
    @track subAccountList = [];
    @track billingAccountRecord;
    @track showSubAccountListForm = false ;
    @track showSubAccountNewForm = false ;
    @track subAccountRecord;
    @track index;

    //@wire (getBillingAccountDetails,{billingAccountRecord: '$recordId'})
    //billingAccountRecord;

    connectedCallback() {
        console.log('recordId>>>>',this.recordId);
        console.log('initialLoad>>>>',this.initialLoad);
        console.log('billingAccountRecord>>>>',this.billingAccountRecord);


                relatedSubAccountRequests({ billingAccountRecord: this.recordId })
                    .then(result =>{
                    console.log('result>>onload',result);
                this.subAccountList = result;

                if(this.subAccountList.length > 0){
                    this.showSubAccountListForm = true;
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