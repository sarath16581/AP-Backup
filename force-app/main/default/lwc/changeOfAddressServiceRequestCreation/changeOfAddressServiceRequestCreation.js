import { LightningElement, api } from 'lwc';
import frameServicerequests from '@salesforce/apex/ChangeOfAddressController.frameServicerequests';


export default class ChangeOfAddressServiceRequestCreation extends LightningElement {
	@api orgRecord;//This scenario is only applicable for (Enterprise, Financial, Intermediaries) Account Types. This covers Billing Account selection for both AP and ST Accounts.
	@api orgId; 
	@api isBillingAddressChanged;
	@api isPhysicalAddressChanged;
	@api accType; //Contains whether the Account Type is Enterprise, Financial, Intermediaries or Business Account. or Small/Medium business
	@api newBillingAddress;
	@api newPhysicalAddress;
	@api cmpCalledFrom;
	@api billingAccsSelectedAP = [];
	@api billingAccsSelectedST = [];
	@api billingAccOptionSelected; // Potential values AP, ST, Both
	creditDSRAPRec;
	creditDSRSTRec;
	onboardingDSRSTRec;
	phyAddressAPMessage;
	emailCaseAPRec;
	emailCaseSTRec;
	//customer request attachment has to be created as CV and 2 CDL's has to be created

    get acceptedFormats() {
        return ['.csv', '.png'];
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

	frameServicerequests(){
		const requestDetails = {};
        requestDetails.apBillingAccCount = this.billingAccsSelectedAP?this.billingAccsSelectedAP.length:0;
        requestDetails.stBillingAccCount = this.billingAccsSelectedST?this.billingAccsSelectedST.length:0;
        requestDetails.customerRequestAttached = 'No';
		requestDetails.baOptionSelected = this.billingAccOptionSelected;
		requestDetails.accType = this.accType;
		requestDetails.newBillingAddress = this.newBillingAddress;
		requestDetails.isBillingAddressChanged =  this.isBillingAddressChanged;
		requestDetails.isPhysicalAddressChanged = this.isPhysicalAddressChanged;
		requestDetails.newPhysicalAddress = this.newPhysicalAddress;
		
		frameServicerequests({reqParams: requestDetails})
		.then(result => {
			// Returned result if from sobject and can't be extended so objectifying the result to make it extensible
			if(!result.error){
				this.creditDSRAPRec = result.creditDSRAPRec;
				this.creditDSRSTRec = result.creditDSRSTRec;
				this.onboardingDSRSTRec = result.onboardingDSRSTRec;
			}else if(result.error){
				this.error = result.error;
			}
		})
		.catch(error => {
			this.error = error;
			console.log('error : ' + JSON.stringify(this.error));
		});
	}

	handleCancel(){
		const cancelEvent = new CustomEvent("handlecancel", {
			detail:{
				backScreen: this.cmpCalledFrom,
				cameFrom:'servicerequestcreation'
			}
		});
		// dispatch the event
		this.dispatchEvent(cancelEvent);
	}

	handleBack(){
		const backEvent = new CustomEvent("handleback", {
			detail:{
				backScreen: this.cmpCalledFrom,
				cameFrom:'servicerequestcreation'
			}
		});
		// dispatch the event
		this.dispatchEvent(backEvent);
	}

	handleNext(){
		const nextEvent = new CustomEvent("handlenext", {
			detail:{
				backScreen: this.cmpCalledFrom,
				cameFrom:'servicerequestcreation'
				//selectedcontacts:this.fulldataselected  
			}
		});
		// dispatch the event
		this.dispatchEvent(nextEvent);
	}
}