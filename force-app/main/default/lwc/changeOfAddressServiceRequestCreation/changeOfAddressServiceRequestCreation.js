import { LightningElement, api } from 'lwc';
import frameServicerequests from '@salesforce/apex/ChangeOfAddressController.frameServicerequests';


export default class ChangeOfAddressServiceRequestCreation extends LightningElement {
	@api accountRecord;//This scenario is only applicable for (Enterprise, Financial, Intermediaries) Account Types. This covers Billing Account selection for both AP and ST Accounts.
	@api accountId; 
	@api newBillingAddress;
	@api newPhysicalAddress;
	@api currentBillingAddress;
	@api currentPhysicalAddress;
	@api billingAccsSelectedAP = [];
	@api billingAccsSelectedST = [];
	@api productSelected; // Potential values AP, ST, Both
	creditDSRAPRec;
	creditDSRSTRec;
	onboardingDSRSTRec;
	phyAddressAPMessage;
	emailCaseAPRec;
	emailCaseSTRec;
	title;
	//customer request attachment has to be created as CV and 2 CDL's has to be created

    get acceptedFormats() {
        return ['.csv', '.png'];
    }
	connectedCallback() {
		this.title='Service Request Form';
	}
    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        alert('No. of files uploaded : ' + uploadedFiles.length);
		if(this.creditDSRAPRec){
			this.creditDSRAPRec.Customer_Request_Attached__c = 'Yes';
		}
		if(this.creditDSRSTRec){
			this.creditDSRSTRec.Customer_Request_Attached__c = 'Yes';
		}
    }

	filter = {
		criteria: [
			{
				fieldPath: 'accountId',
				operator: 'eq',
				value: this.accountId,
			}
		]
	};

	getapPhysicalAddressChange(){
		if(this.productSelected==='AP' || this.productSelected==='Both'){
			if(this.isPhysicalAddressChanged){
				return true;
			}
		}
		return false;
	}
	
	frameServicerequests(){
		const requestDetails = {};
        requestDetails.apBillingAccCount = this.billingAccsSelectedAP?this.billingAccsSelectedAP.length:0;
        requestDetails.stBillingAccCount = this.billingAccsSelectedST?this.billingAccsSelectedST.length:0;
        requestDetails.customerRequestAttached = 'No';
		requestDetails.baOptionSelected = this.productSelected;
		requestDetails.accType = this.accountRecord.Sales_Segment__c;
		requestDetails.newBillingAddress = this.newBillingAddress;
		requestDetails.isBillingAddressChanged = this.newBillingAddress? true : false;
		requestDetails.isPhysicalAddressChanged = this.newPhysicalAddress? true : false;
		requestDetails.newPhysicalAddress = this.newPhysicalAddress;
		requestDetails.accountId = this.accountId;
		requestDetails.accountRecord = this.accountRecord;
		
		frameServicerequests({reqParams: requestDetails})
		.then(result => {
			// Returned result if from sobject and can't be extended so objectifying the result to make it extensible
			if(!result.error){
				if(result.creditDSRAPRec){
					this.creditDSRAPRec = result.creditDSRAPRec;
				}
				if(result.creditDSRSTRec){
					this.creditDSRSTRec = result.creditDSRSTRec;
				}
				if(result.onboardingDSRSTRec){
					this.onboardingDSRSTRec = result.onboardingDSRSTRec;
				}
				if(result.emailCaseAPRec){
					this.emailCaseAPRec = result.emailCaseAPRec;
				}
				if(result.emailCaseSTRec){
					this.emailCaseSTRec = result.emailCaseSTRec;
				}
			}else if(result.error){
				this.error = result.error;
			}
		})
		.catch(error => {
			this.error = error;
			console.log('error : ' + JSON.stringify(this.error));
		});
	}

}