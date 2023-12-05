/*
  * @author       : Dheeraj Mandavilli. dheeraj.mandavilli@auspost.com.au
  * @date         : 24/04/2021
  * @description  : This lWC component is used in Sub Account Request creation from Billing Account Quick Action. It has following features
  *                 1. It contains logic whether to populate summary page or form based upon sub account requests.
*********************************History*******************************************************************
2021.04.21   Dheeraj Mandavilli - Created
2023.11.24   Harry Wang - Updated initialLoad type to String. When initialLoad passed from SubAccountsCreationWrapper only string type is supported
*/
import { LightningElement, track, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import relatedSubAccountRequests from "@salesforce/apex/CreateSubAccountsController.getRelatedSubAccountRequests";

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

	get isInitialLoad() {
		return this.initialLoad;
	}

	connectedCallback() {
		relatedSubAccountRequests({ billingAccountRecord: this.recordId })
			.then(result =>{
			console.log('result>>onload',result);
		this.subAccountList = result;

		if(this.subAccountList.length > 0){
			this.showSubAccountListForm = true;
		}else{
			this.showSubAccountNewForm = true;
		}}).catch(error =>{})
		this.isloading = false;
	}
	newSubAccountRecordHandler(event){
		let newSubAccountRequest = event.detail;
		let newSubAccountRequestObject = JSON.parse(newSubAccountRequest);
		this.subAccountList.push(newSubAccountRequestObject);
		refreshApex(this.subAccountList);

		this.showSubAccountNewForm = false;
		window.location.reload();
	}
	editSubAccountHandler(event){
		this.subAccountRecord = event.detail.subAccountRecordVar;
		this.showSubAccountListForm = false;
		this.showSubAccountNewForm = true;
	}

	showFormEventHandler(event){
		this.initialLoad = true;
		this.showSubAccountListForm = false;
		this.showSubAccountNewForm = true;
	}

}